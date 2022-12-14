`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;


// returns smallest positive root to the given quadratic, 
// along with whether the solution is in fact real and positive
//
// 53-stage pipeline
// -------> (b, 2a, 2c) 
// --[ 6]--> (-b, b^2, 4ac, 2a) 
// --[ 8]--> (-b, b^2 - 4ac, 2a)
// --[15]--> (-b, sqrt(b^2-4ac), 2a, real_sol)
// --[ 8]--> (t1_num = -b-sqrt(b^2-4ac), t2_num = -b+sqrt(b^2-4ac), 2a, real_sol)
// --[15]--> (t1 = t1_num/2a, t2 = t2_num/2a, sign_t1, sign_t2, real_sol)
// --[ 1]--> (t = min_pos(t1, t2), real_pos_sol)
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
    /// PS1: 6-stage
    /// (-b, b^2, 4ac, 2a)
    localparam PS1_STAGES = 6;
    logic s1_valid [PS1_STAGES-1:0];
    float16 s1_neg_b [PS1_STAGES-1:0];
    float16 s1_2a [PS1_STAGES-1:0];

    float16 s1_b_sq;
    float16 s1_4ac;

    always_ff @( posedge clk ) begin
        s1_valid[0] <= valid_in;
        s1_neg_b[0] <= {~b[15], b[14:0]};
        s1_2a[0] <= a2;
        for (int i = 1; i < PS1_STAGES; i = i+1) begin
            s1_valid[i] <= s1_valid[i-1];
            s1_neg_b[i] <= s1_neg_b[i-1];
            s1_2a[i]    <= s1_2a[i-1];
        end
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

    /// Stage 2: 8-stage
    /// (-b, b^2 - 4ac, 2a)
    localparam PS2_STAGES = 8;
    logic s2_valid [PS2_STAGES-1:0];
    float16 s2_neg_b [PS2_STAGES-1:0];
    float16 s2_2a [PS2_STAGES-1:0];

    float16 s2_discrim;

    always_ff @( posedge clk ) begin 
        s2_valid[0] <= s1_valid[PS1_STAGES-1];
        s2_neg_b[0] <= s1_neg_b[PS1_STAGES-1];
        s2_2a[0] <= s1_2a[PS1_STAGES-1];
        for (int i = 1; i < PS2_STAGES; i = i + 1) begin
            s2_valid[i] <= s2_valid[i-1];
            s2_neg_b[i] <= s2_neg_b[i-1];
            s2_2a[i]    <= s2_2a[i-1];
        end
    end

    float_add_sub s2_sub_b_sq_4ac (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(s1_valid[PS1_STAGES-1]),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(s1_b_sq),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(s1_valid[PS1_STAGES-1]),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(s1_4ac),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(s1_valid[PS1_STAGES-1]),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),    // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(s2_discrim)          // output wire [15 : 0] m_axis_result_tdata
    );

    /// Stage 3: 15-stage
    /// (-b, sqrt(b^2-4ac), 2a, real_sol)
    localparam PS3_STAGES = 15;
    logic s3_valid [PS3_STAGES-1:0];
    float16 s3_neg_b [PS3_STAGES-1:0];
    float16 s3_2a [PS3_STAGES-1:0];
    logic s3_real_sol [PS3_STAGES-1:0];

    float16 s3_sqrt_discrim;

    always_ff @( posedge clk ) begin
        s3_valid[0] <= s2_valid[PS2_STAGES-1];
        s3_neg_b[0] <= s2_neg_b[PS2_STAGES-1];
        s3_2a[0] <= s2_2a[PS2_STAGES-1];
        s3_real_sol[0] <= ~s2_discrim[15]; // solution is real iff discrim is positive
        for (int i = 1; i < PS3_STAGES; i = i+1) begin
            s3_valid[i]     <= s3_valid[i-1];
            s3_neg_b[i]     <= s3_neg_b[i-1];
            s3_2a[i]        <= s3_2a[i-1];
            s3_real_sol[i]  <= s3_real_sol[i-1];
        end
    end

    float_sqrt s3_sqrt_of_discrim (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(s2_valid[PS2_STAGES-1]),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(s2_discrim),              // input wire [15 : 0] s_axis_a_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(s3_sqrt_discrim)    // output wire [15 : 0] m_axis_result_tdata
    );

    /// Stage 4: 8-stage
    /// (t1_num = -b-sqrt(b^2-4ac), t2_num = -b+sqrt(b^2-4ac), 2a, real_sol)
    localparam PS4_STAGES = 8;
    logic s4_valid [PS4_STAGES-1:0];
    float16 s4_2a [PS4_STAGES-1:0];
    logic s4_real_sol [PS4_STAGES-1:0];

    float16 s4_t1_num;
    float16 s4_t2_num;

    always_ff @( posedge clk ) begin
        s4_valid[0]     <= s3_valid[PS3_STAGES-1];
        s4_2a[0]        <= s3_2a[PS3_STAGES-1];
        s4_real_sol[0]  <= s3_real_sol[PS3_STAGES-1]; 
        for (int i = 1; i < PS4_STAGES; i = i+1) begin
            s4_valid[i]     <= s4_valid[i-1];
            s4_2a[i]        <= s4_2a[i-1];
            s4_real_sol[i]  <= s4_real_sol[i-1];
        end
    end

    float_add_sub s4_sub_t1_num (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(s3_valid[PS3_STAGES-1]),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(s3_neg_b[PS3_STAGES-1]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(s3_valid[PS3_STAGES-1]),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(s3_sqrt_discrim),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(s3_valid[PS3_STAGES-1]),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),    // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(s4_t1_num)          // output wire [15 : 0] m_axis_result_tdata
    );

    float_add_sub s4_add_t2_num (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(s3_valid[PS3_STAGES-1]),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(s3_neg_b[PS3_STAGES-1]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(s3_valid[PS3_STAGES-1]),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(s3_sqrt_discrim),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(s3_valid[PS3_STAGES-1]),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),    // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(s4_t2_num)          // output wire [15 : 0] m_axis_result_tdata
    );

    /// Stage 5: 15-stage
    /// (t1 = t1_num/2a, t2 = t2_num/2a, sign_t1, sign_t2, real_sol)
    localparam PS5_STAGES = 15;
    logic s5_valid [PS5_STAGES-1:0];
    logic s5_sign_t1 [PS5_STAGES-1:0];
    logic s5_sign_t2 [PS5_STAGES-1:0];
    logic s5_real_sol [PS5_STAGES-1:0];

    float16 s5_t1;
    float16 s5_t2;

    always_ff @( posedge clk ) begin
        s5_valid[0]     <= s4_valid[PS4_STAGES-1];
        s5_sign_t1[0]   <= s4_t1_num[15] ^ s4_2a[PS4_STAGES-1][15];
        s5_sign_t2[0]   <= s4_t2_num[15] ^ s4_2a[PS4_STAGES-1][15];
        s5_real_sol[0]  <= s4_real_sol[PS4_STAGES-1];
        for (int i = 1; i < PS5_STAGES; i = i+1) begin
            s5_valid[i]     <= s5_valid[i-1];
            s5_sign_t1[i]   <= s5_sign_t1[i-1];
            s5_sign_t2[i]   <= s5_sign_t2[i-1];
            s5_real_sol[i]  <= s5_real_sol[i-1];
        end
    end

    float_divide s5_divide_t1 (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(s4_valid[PS4_STAGES-1]),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(s4_t1_num),              // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(s4_valid[PS4_STAGES-1]),            // input wire s_axis_b_tvalid
        .s_axis_b_tdata(s4_2a[PS4_STAGES-1]),              // input wire [15 : 0] s_axis_b_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(s5_t1)    // output wire [15 : 0] m_axis_result_tdata
    );

    float_divide s5_divide_t2 (
        .aclk(clk),                                  // input wire aclk
        .s_axis_a_tvalid(s4_valid[PS4_STAGES-1]),            // input wire s_axis_a_tvalid
        .s_axis_a_tdata(s4_t2_num),              // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(s4_valid[PS4_STAGES-1]),            // input wire s_axis_b_tvalid
        .s_axis_b_tdata(s4_2a[PS4_STAGES-1]),              // input wire [15 : 0] s_axis_b_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
        .m_axis_result_tdata(s5_t2)    // output wire [15 : 0] m_axis_result_tdata
    );

    /// Stage 6: 1-stage
    /// (t = min_pos(t1, t2), real_pos_sol)
    float16 s5_s6_t;
    logic s5_s6_pos_sol;

    always_comb begin
        // Note, t1 < t2 always holds since sqrt_disrcim is positive
        if (s5_sign_t1[PS5_STAGES-1] == 1'b0) begin
            // if t1 is positive, t = t1
            s5_s6_t = s5_t1;
            s5_s6_pos_sol = 1'b1;
        end else if (s5_sign_t2[PS5_STAGES-1] == 1'b0) begin
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
        s6_valid <= s5_valid[PS5_STAGES-1];
        s6_t <= s5_s6_t;
        s6_real_pos_sol <= s5_real_sol[PS5_STAGES-1] & s5_s6_pos_sol;
    end

    /// Assign outputs
    assign sol = s6_t;
    assign real_pos_sol = s6_real_pos_sol;

endmodule

// returns 2*a, b, and 2*c for use by a quadratic solver
// 30-stage pipeline
module sphere_quadratic(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 src,
    input vec3 dir,
    input wire ShapeType shape_type,
    output logic valid_out,
    output float16 a2,
    output float16 b,
    output float16 c2
);  
    /// a2: 30-stage
    // sphere:      2*a = 2*(xD^2 + yD^2 + zD^2) = 2 * (D . D)
    // cylinder:    2*a = 2*(xD^2 + yD^2)
    // cone:        2*a = 2*(xD^2 + yD^2 - zD^2)

    float16 dir_dot_2;
    logic dir_dot_2_valid;

    vec3 a2_vec_in;
    logic [2:0] a2_sign_in;
    always @(*) begin
        a2_vec_in[0] = dir[0];
        a2_vec_in[1] = dir[1];
        a2_vec_in[2] = dir[2];

        a2_sign_in[0] = 1'b0;
        a2_sign_in[1] = 1'b0;
        a2_sign_in[2] = 1'b0;

        case (shape_type)
            stOff: begin
                a2_vec_in[0] = 16'h3C00;
                a2_vec_in[1] = 16'b0;
                a2_vec_in[2] = 16'b0;
            end
            stSphere: begin

            end
            stCylinder: begin
                a2_vec_in[2] = 16'b0;
            end
            stCone: begin
                a2_sign_in[2] = 1'b1;
            end
            default: begin

            end
        endcase
    end

    // 30-stage
    signed_double_dot_product ddp_dir (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .a(a2_vec_in),
        .b(a2_vec_in),
        .sign(a2_sign_in),
        .valid_out(dir_dot_2_valid),
        .a_dot_b_2(dir_dot_2)
    );

    assign a2 = dir_dot_2;
    assign valid_out = dir_dot_2_valid;

    /// b: 30-stage
    // sphere:      b = 2*(xS*xD + yS*yD + zS*zD) = 2 * (D . S)
    // cylinder:    b = 2*(xS*xD + yS*yD)
    // cone:        b = 2*(xS*xD + yS*yD - zS*zD)

    float16 dir_src_2;
    logic dir_src_2_valid;

    vec3 b_src_in;
    logic [2:0] b_sign_in;
    always @(*) begin
        b_src_in[0] = src[0];
        b_src_in[1] = src[1];
        b_src_in[2] = src[2];

        b_sign_in[0] = 1'b0;
        b_sign_in[1] = 1'b0;
        b_sign_in[2] = 1'b0;

        case (shape_type)
            stOff: begin
                b_src_in[0] = 16'b0;
                b_src_in[1] = 16'b0;
                b_src_in[2] = 16'b0;
            end
            stSphere: begin

            end
            stCylinder: begin
                b_src_in[2] = 16'b0;
            end
            stCone: begin
                b_sign_in[2] = 1'b1;
            end
            default: begin

            end
        endcase
    end

    signed_double_dot_product ddp_src_dir (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .a(dir),
        .b(b_src_in),
        .sign(b_sign_in),
        .valid_out(dir_src_2_valid),
        .a_dot_b_2(dir_src_2)
    );

    assign b = dir_src_2;

    /// c2: 30-stage
    // sphere:      2*c = 2*(xS^2 + yS^2 + zS^2 - 1)
    // cylinder:    2*c = 2*(xS^2 + yS^2 - 1)
    // cone:        2*c = 2*(xS^2 + yS^2 - zS^2)

    vec3 c_src_in;
    vec3 c_signed_src_in;
    logic [2:0] c_sign_in;
    logic c_include_minus_1;
    logic c_include_minus_1_piped;

    pipe#(
        .LENGTH(6),
        .WIDTH(1)
    ) (
        .clk(clk),
        .rst(rst),
        .in(c_include_minus_1),
        .out(c_include_minus_1_piped)
    );

    always @(*) begin
        c_src_in[0] = src[0];
        c_src_in[1] = src[1];
        c_src_in[2] = src[2];

        c_sign_in[0] = 1'b0;
        c_sign_in[1] = 1'b0;
        c_sign_in[2] = 1'b0;

        c_include_minus_1 = 1'b1;

        case (shape_type)
            stOff: begin
                c_src_in[0] = 16'h3C00;
                c_src_in[1] = 16'b0;
                c_src_in[2] = 16'b0;
            end
            stSphere: begin

            end
            stCylinder: begin
                c_src_in[2] = 16'b0;
            end
            stCone: begin
                c_sign_in[2] = 1'b1;
                c_include_minus_1 = 1'b0;
            end
            default: begin

            end
        endcase

        c_signed_src_in[0] = c_sign_in[0] ? {~c_src_in[0][15], c_src_in[0][14:0]} : c_src_in[0];
        c_signed_src_in[1] = c_sign_in[1] ? {~c_src_in[1][15], c_src_in[1][14:0]} : c_src_in[1];
        c_signed_src_in[2] = c_sign_in[2] ? {~c_src_in[2][15], c_src_in[2][14:0]} : c_src_in[2];
    end

    vec3 src_src;
    logic src_src_valid;

    // 6-stages: (xS^2, yS^2, +-zS^2)
    mult_elementwise mult_src_src(
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .a(c_src_in),
        .b(c_signed_src_in),
        .valid_out(src_src_valid),
        .a_times_b(src_src)
    );

    // 8 stages: (xS^2 + yS^2, zS^2 - 1)
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

    float16 src_src_z_1;
    logic src_src_z_1_valid;
    float_add_sub add_src_src_z_1 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(src_src_valid),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(src_src[2]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(src_src_valid),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(c_include_minus_1_piped ? 16'h3C00 : 16'h0000),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(src_src_valid),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),    // input wire [7 : 0] s_axis_operation_tdata
        .m_axis_result_tvalid(src_src_z_1_valid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(src_src_z_1)          // output wire [15 : 0] m_axis_result_tdata
    );
    
    // 8-stage: xS^2 + yS^2 + zS^2 - 1
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


    // 8-stage: 2*(xS^2 + yS^2 + zS^2 - 1) [uses adder]
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