`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;


// returns smallest positive root to the given quadratic, 
// along with whether the solution is in fact real and positive
//
// 6-stage pipeline
// (b, 2a, 2c) -> (-b, b^2, 4ac, 2a) -> (-b, b^2 - 4ac, 2a)
// -> (-b, sqrt(b^2-4ac), 2a, real_sol) -> (-b-sqrt(b^2-4ac), -b+sqrt(b^2-4ac), 2a, real_sol)
// -> (sign(t1), sign(t2), sign(2a), t1=(-b-sqrt(b^2-4ac))/2a, t2=(-b+sqrt(b^2-4ac))/2a, real_sol)
// -> (t = min_pos(t1, t2), real_pos_sol)
module quadratic_solver_smallest_positive(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire float16 a2,
    input wire float16 b,
    input wire float16 c2,
    output logic valid_out,
    output logic real_pos_sol,
    output float16 sol
);
    /// Stage 1: (-b, b^2, 4ac, 2a)
    logic s1_valid;
    float16 s1_neg_b;
    float16 s1_b_sq;
    float16 s1_4ac;
    float16 s1_2a;

    always_ff @( posedge clk ) begin
        s1_valid <= valid_in;
        s1_neg_b <= {~b[15], b[14:0]};
        s1_2a <= a2;
    end

    float_multiply s1_mult_b_b (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(valid_in),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(b),              // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(valid_in),            // input wire s_axis_b_tvalid
        .s_axis_b_tdata(b),              // input wire [15 : 0] s_axis_b_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(s1_b_sq)    // output wire [15 : 0] m_axis_result_tdata
    );

    float_multiply s1_mult_2a_2c (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(valid_in),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(a2),              // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(valid_in),            // input wire s_axis_b_tvalid
        .s_axis_b_tdata(c2),              // input wire [15 : 0] s_axis_b_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(s1_4ac)    // output wire [15 : 0] m_axis_result_tdata
    );

    /// Stage 2: (-b, b^2 - 4ac, 2a)
    logic s2_valid;
    float16 s2_neg_b;
    float16 s2_discrim;
    float16 s2_2a;

    always_ff @( posedge clk ) begin 
        s2_valid <= s1_valid;
        s2_neg_b <= s1_neg_b;
        s2_2a <= s1_2a;
    end

    float_add_sub s2_sub_b_sq_4ac (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(s1_valid),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(s1_b_sq),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(s1_valid),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(s1_4ac),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(s1_valid),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),    // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(s2_discrim)          // output wire [15 : 0] m_axis_result_tdata
    );

    /// Stage 3: (-b, sqrt(b^2-4ac), 2a, real_sol)
    logic s3_valid;
    float16 s3_neg_b;
    float16 s3_sqrt_discrim;
    float16 s3_2a;
    logic s3_real_sol;

    always_ff @( posedge clk ) begin
        s3_valid <= s2_valid;
        s3_neg_b <= s2_neg_b;
        s3_2a <= s2_2a;
        s3_real_sol <= ~s2_discrim[15]; // solution is real iff discrim is positive
    end

    float_sqrt s3_sqrt_of_discrim (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(s2_valid),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(s2_discrim),              // input wire [15 : 0] s_axis_a_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(s3_sqrt_discrim)    // output wire [15 : 0] m_axis_result_tdata
    );

    /// Stage 4: (t1_num = -b-sqrt(b^2-4ac), t2_num = -b+sqrt(b^2-4ac), 2a, real_sol)
    logic s4_valid;
    float16 s4_t1_num;
    float16 s4_t2_num;
    float16 s4_2a;
    logic s4_real_sol;

    always_ff @( posedge clk ) begin
        s4_valid <= s3_valid;
        s4_2a <= s3_2a;
        s4_real_sol <= s3_real_sol;
    end

    float_add_sub s4_sub_t1_num (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(s3_valid),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(s3_neg_b),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(s3_valid),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(s3_sqrt_discrim),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(s3_valid),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),    // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(s4_t1_num)          // output wire [15 : 0] m_axis_result_tdata
    );

    float_add_sub s4_add_t2_num (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(s3_valid),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(s3_neg_b),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(s3_valid),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(s3_sqrt_discrim),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(s3_valid),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),    // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(s4_t2_num)          // output wire [15 : 0] m_axis_result_tdata
    );

    /// Stage 5: (t1 = t1_num/2a, t2 = t2_num/2a, sign_t1, sign_t2, real_sol)
    logic s5_valid;
    float16 s5_t1;
    float16 s5_t2;
    logic s5_sign_t1;
    logic s5_sign_t2;
    logic s5_real_sol;

    always_ff @( posedge clk ) begin
        s5_valid <= s4_valid;
        s5_sign_t1 <= s4_t1_num[15] ^ s4_2a[15];
        s5_sign_t2 <= s4_t2_num[15] ^ s4_2a[15];
        s5_real_sol <= s4_real_sol;
    end

    float_divide s5_divide_t1 (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(s4_valid),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(s4_t1_num),              // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(s4_valid),            // input wire s_axis_b_tvalid
        .s_axis_b_tdata(s4_2a),              // input wire [15 : 0] s_axis_b_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(s5_t1)    // output wire [15 : 0] m_axis_result_tdata
    );

    float_divide s5_divide_t2 (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(s4_valid),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(s4_t2_num),              // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(s4_valid),            // input wire s_axis_b_tvalid
        .s_axis_b_tdata(s4_2a),              // input wire [15 : 0] s_axis_b_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(s5_t2)    // output wire [15 : 0] m_axis_result_tdata
    );

    /// Stage 6: (t = min_pos(t1, t2), real_pos_sol)
    float16 s5_s6_t;
    logic s5_s6_pos_sol;

    always_comb begin
        // Note, t1 < t2 always holds since sqrt_disrcim is positive
        if (s5_sign_t1 == 1'b0) begin
            // if t1 is positive, t = t1
            s5_s6_t = s5_t1;
            s5_s6_pos_sol = 1'b1;
        end else if (s5_sign_t2 == 1'b0) begin
            // else if t2 is positive, t = t2
            s5_s6_t = s5_t2;
            s5_s6_pos_sol = 1'b1;
        end else begin
            // if no positive solution, mark as such
            s5_s6_pos_sol = 1'b0;
        end
    end

    logic s6_valid;
    float16 s6_t;
    logic s6_real_pos_sol;

    always_ff @( posedge clk ) begin 
        s6_valid <= s5_valid;
        s6_t <= s5_s6_t;
        s6_real_pos_sol <= s5_real_sol & s5_s6_pos_sol;
    end

    /// Assign outputs
    assign sol = s6_t;
    assign real_pos_sol = s6_real_pos_sol;

endmodule

// returns 2*a, b, and 2*c for use by a quadratic solver
// 4-stage pipeline
module sphere_quadratic(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 src,
    input vec3 dir,
    output logic valid_out,
    output float16 a2,
    output float16 b,
    output float16 c2
);
    // 2*a = 2*(xD^2 + yD^2 + zD^2) = 2 * (D . D)
    float16 dir_dot_2;
    logic dir_dot_2_valid;

    double_dot_product ddp_dir (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .a(dir),
        .b(dir),
        .valid_out(dir_dot_2_valid),
        .a_dot_b_2(dir_dot_2)
    );

    assign a2 = dir_dot_2;
    assign valid_out = dir_dot_2_valid;

    // b = 2*(xS*xD + yS*yD + zS*zD) = 2 * (D . S)
    // 4-stage pipeline

    float16 dir_src_2;
    logic dir_src_2_valid;

    double_dot_product ddp_src (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .a(dir),
        .b(src),
        .valid_out(dir_src_2_valid),
        .a_dot_b_2(dir_src_2)
    );

    assign b = dir_src_2;

    // 2*c = 2*(xS^2 + yS^2 + zS^2 - 1)
    // 4-stage pipeline
    vec3 src_src;
    logic src_src_valid;

    // 1 stage: (xS^2, yS^2, zS^2)
    mult_elementwise mult_src_src(
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .a(src),
        .b(src),
        .valid_out(src_src_valid),
        .a_times_b(src_src)
    );

    // 1 stage: xS^2 + yS^2
    float16 src_src_x_y;
    logic src_src_x_y_valid;

    float_add_sub add_src_src_x_y (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(src_src_valid),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(src_src[0]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(src_src_valid),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(src_src[1]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(src_src_valid),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),    // input wire [7 : 0] s_axis_operation_tdata
        .m_axis_result_tvalid(src_src_x_y_valid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(src_src_x_y)          // output wire [15 : 0] m_axis_result_tdata
    );

    
    // 1 stage: zS^2 - 1
    float16 src_src_z_1;
    logic src_src_z_1_valid;
    float_add_sub add_src_src_z_1 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(src_src_valid),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(src_src[2]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(src_src_valid),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(16'h3C00),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(src_src_valid),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),    // input wire [7 : 0] s_axis_operation_tdata
        .m_axis_result_tvalid(src_src_z_1_valid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(src_src_z_1)          // output wire [15 : 0] m_axis_result_tdata
    );

    // 1 stage: xS^2 + yS^2 + zS^2 - 1
    float16 src_src_x_y_z_1;
    logic src_src_x_y_z_1_valid;
    float_add_sub add_src_src_x_y_z_1 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(src_src_x_y_valid),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(src_src_x_y),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(src_src_z_1_valid),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(src_src_z_1),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(src_src_x_y_valid),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),    // input wire [7 : 0] s_axis_operation_tdata
        .m_axis_result_tvalid(src_src_x_y_z_1_valid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(src_src_x_y_z_1)          // output wire [15 : 0] m_axis_result_tdata
    );


    // 1 stage: 2*(xS^2 + yS^2 + zS^2 - 1)
    float16 src_src_2_x_y_z_1;
    logic src_src_2_x_y_z_1_valid;
    float_add_sub add_src_src_2_x_y_z_1 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(src_src_x_y_z_1_valid),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(src_src_x_y_z_1),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(src_src_x_y_z_1_valid),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(src_src_x_y_z_1),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(src_src_x_y_z_1_valid),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),    // input wire [7 : 0] s_axis_operation_tdata
        .m_axis_result_tvalid(src_src_2_x_y_z_1_valid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(src_src_2_x_y_z_1)          // output wire [15 : 0] m_axis_result_tdata
    );

    assign c2 = src_src_2_x_y_z_1;

endmodule

`default_nettype wire