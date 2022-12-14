`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

// 6 stage
module mult_elementwise(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 a,
    input vec3 b,
    output logic valid_out,
    output vec3 a_times_b
);
    vec3 a_b;
    logic a_b_valid [2:0];

    generate
        genvar a_b_ind;
        for (a_b_ind = 0; a_b_ind < 3; a_b_ind = a_b_ind + 1) begin
            float_multiply mult_a_b (
                .aclk(clk),                                         // input wire aclk
                .s_axis_a_tvalid(valid_in),                         // input wire s_axis_a_tvalid
                .s_axis_a_tdata(a[a_b_ind]),                   // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(valid_in),                         // input wire s_axis_b_tvalid
                .s_axis_b_tdata(b[a_b_ind]),                   // input wire [15 : 0] s_axis_b_tdata
                .m_axis_result_tvalid(a_b_valid[a_b_ind]),    // output wire m_axis_result_tvalid
                .m_axis_result_tdata(a_b[a_b_ind])            // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate

    assign a_times_b[0] = a_b[0];
    assign a_times_b[1] = a_b[1];
    assign a_times_b[2] = a_b[2];
    assign valid_out = a_b_valid[0];
endmodule

// 22-stage pipeline
// (a, b) --[6]--> (ax * bx, ay * by, az * bz) --[8]-->  (ax * bx + ay * by, az * bz)  --[8]--> (ax * bx + ay * by + az * bz) 
module dot_product(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 a,
    input vec3 b,
    output logic valid_out,
    output float16 a_dot_b
);
    vec3 a_b;
    logic a_b_valid [2:0];

    // PS1: 6 stages
    generate
        genvar a_b_ind;
        for (a_b_ind = 0; a_b_ind < 3; a_b_ind = a_b_ind + 1) begin
            float_multiply mult_a_b (
                .aclk(clk),                                         // input wire aclk
                .s_axis_a_tvalid(valid_in),                         // input wire s_axis_a_tvalid
                .s_axis_a_tdata(a[a_b_ind]),                   // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(valid_in),                         // input wire s_axis_b_tvalid
                .s_axis_b_tdata(b[a_b_ind]),                   // input wire [15 : 0] s_axis_b_tdata
                .m_axis_result_tvalid(a_b_valid[a_b_ind]),    // output wire m_axis_result_tvalid
                .m_axis_result_tdata(a_b[a_b_ind])            // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate

    float16 a_b_x_y;
    logic a_b_x_y_valid;

    // PS2: 8 stages
    float_add_sub add_a_b_x_y (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(a_b_valid[0]),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(a_b[0]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(a_b_valid[1]),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(a_b[1]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(a_b_valid[0]),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),    // input wire [7 : 0] s_axis_operation_tdata
        .m_axis_result_tvalid(a_b_x_y_valid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(a_b_x_y)          // output wire [15 : 0] m_axis_result_tdata
    );

    // Pipeline stage
    localparam PS2_STAGES = 8;
    float16 a_b_z [PS2_STAGES-1:0];
    always_ff @( posedge clk ) begin
        a_b_z[0] <= a_b[2];
        for (int i = 1; i < PS2_STAGES; i = i+1) begin
            a_b_z[i] <= a_b_z[i-1];
        end
    end


    // PS3: 8 stages
    float16 a_b_x_y_z;
    logic a_b_x_y_z_valid;

    float_add_sub add_dir_sq_x_y_z (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(a_b_x_y_valid),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(a_b_x_y),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(a_b_x_y_valid),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(a_b_z[PS2_STAGES-1]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(a_b_x_y_valid),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),    // input wire [7 : 0] s_axis_operation_tdata
        .m_axis_result_tvalid(a_b_x_y_z_valid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(a_b_x_y_z)          // output wire [15 : 0] m_axis_result_tdata
    );

    assign a_dot_b = a_b_x_y_z;
    assign valid_out = a_b_x_y_z_valid;

endmodule

// 30-stage pipeline
// (a, b) --[22]--> (a.b) --[8]--> (a.b + a.b)
module double_dot_product(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 a,
    input vec3 b,
    output logic valid_out,
    output float16 a_dot_b_2
);

    float16 a_dot_b;
    logic a_dot_b_valid;

    // 22-stages
    dot_product dp(
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .a(a),
        .b(b),
        .valid_out(a_dot_b_valid),
        .a_dot_b(a_dot_b)
    );

    // 8 stages
    float16 a_dot_b_double;
    logic a_dot_b_double_valid;
    float_add_sub add_dir_sq_x_y_z (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(a_dot_b_valid),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(a_dot_b),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(a_dot_b_valid),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(a_dot_b),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(a_dot_b_valid),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),    // input wire [7 : 0] s_axis_operation_tdata
        .m_axis_result_tvalid(a_dot_b_double_valid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(a_dot_b_double)          // output wire [15 : 0] m_axis_result_tdata
    );

    assign a_dot_b_2 = a_dot_b_double;
    assign valid_out = a_dot_b_double_valid;
endmodule



// 22-stage pipeline
// (a, b) --[6]--> (ax * bx, ay * by, az * bz) --[8]-->  (ax * bx + ay * by, az * bz)  --[8]--> (ax * bx + ay * by + az * bz) 
module signed_dot_product(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 a,
    input vec3 b,
    input wire [2:0] sign,
    output logic valid_out,
    output float16 a_dot_b
);
    vec3 a_b;
    logic a_b_valid [2:0];

    // PS1: 6 stages
    generate
        genvar a_b_ind;
        for (a_b_ind = 0; a_b_ind < 3; a_b_ind = a_b_ind + 1) begin
            float_multiply mult_a_b (
                .aclk(clk),                                         // input wire aclk
                .s_axis_a_tvalid(valid_in),                         // input wire s_axis_a_tvalid
                .s_axis_a_tdata(a[a_b_ind]),                   // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(valid_in),                         // input wire s_axis_b_tvalid
                .s_axis_b_tdata(sign[a_b_ind] ? {~b[a_b_ind][15], b[a_b_ind][14:0]} : b[a_b_ind]),                   // input wire [15 : 0] s_axis_b_tdata
                .m_axis_result_tvalid(a_b_valid[a_b_ind]),    // output wire m_axis_result_tvalid
                .m_axis_result_tdata(a_b[a_b_ind])            // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate

    float16 a_b_x_y;
    logic a_b_x_y_valid;

    // PS2: 8 stages
    float_add_sub add_a_b_x_y (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(a_b_valid[0]),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(a_b[0]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(a_b_valid[1]),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(a_b[1]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(a_b_valid[0]),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),    // input wire [7 : 0] s_axis_operation_tdata
        .m_axis_result_tvalid(a_b_x_y_valid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(a_b_x_y)          // output wire [15 : 0] m_axis_result_tdata
    );

    // Pipeline stage
    localparam PS2_STAGES = 8;
    float16 a_b_z [PS2_STAGES-1:0];
    always_ff @( posedge clk ) begin
        a_b_z[0] <= a_b[2];
        for (int i = 1; i < PS2_STAGES; i = i+1) begin
            a_b_z[i] <= a_b_z[i-1];
        end
    end


    // PS3: 8 stages
    float16 a_b_x_y_z;
    logic a_b_x_y_z_valid;

    float_add_sub add_dir_sq_x_y_z (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(a_b_x_y_valid),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(a_b_x_y),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(a_b_x_y_valid),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(a_b_z[PS2_STAGES-1]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(a_b_x_y_valid),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),    // input wire [7 : 0] s_axis_operation_tdata
        .m_axis_result_tvalid(a_b_x_y_z_valid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(a_b_x_y_z)          // output wire [15 : 0] m_axis_result_tdata
    );

    assign a_dot_b = a_b_x_y_z;
    assign valid_out = a_b_x_y_z_valid;

endmodule


// 30-stage pipeline
// (a, b) --[22]--> (a.b) --[8]--> (a.b + a.b)
module signed_double_dot_product(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 a,
    input vec3 b,
    input wire [2:0] sign,
    output logic valid_out,
    output float16 a_dot_b_2
);

    float16 a_dot_b;
    logic a_dot_b_valid;

    // 22-stages
    signed_dot_product dp(
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .a(a),
        .b(b),
        .sign(sign),
        .valid_out(a_dot_b_valid),
        .a_dot_b(a_dot_b)
    );

    // 8 stages
    float16 a_dot_b_double;
    logic a_dot_b_double_valid;
    float_add_sub add_dir_sq_x_y_z (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(a_dot_b_valid),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(a_dot_b),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(a_dot_b_valid),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(a_dot_b),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(a_dot_b_valid),  // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),    // input wire [7 : 0] s_axis_operation_tdata
        .m_axis_result_tvalid(a_dot_b_double_valid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(a_dot_b_double)          // output wire [15 : 0] m_axis_result_tdata
    );

    assign a_dot_b_2 = a_dot_b_double;
    assign valid_out = a_dot_b_double_valid;
endmodule

// See: https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation#Advantages_of_quaternions
// 22-stage pipeline 
// (a, b, bi, bj, bk) --[6]--> (dotr, doti, dotj, dotk) --[8]--> (r1, r2, i1, i2, j1, j2, k1, k2) --[8]--> c
module quaternion_mult(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input quaternion a,
    input quaternion b,
    output logic valid_out,
    output quaternion c
);

    quaternion bi;
    assign bi[0] = b[1];
    assign bi[1] = b[0];
    assign bi[2] = b[3];
    assign bi[3] = b[2];

    quaternion bj;
    assign bj[0] = b[2];
    assign bj[1] = b[3];
    assign bj[2] = b[0];
    assign bj[3] = b[1];

    quaternion bk;
    assign bk[0] = b[3];
    assign bk[1] = b[2];
    assign bk[2] = b[1];
    assign bk[3] = b[0];
    
    // real part
    float16 dotr [3:0];
    logic vdotr [3:0];   


    /// PS1: 6-stage
    generate
        genvar r_ind;
        for (r_ind = 0; r_ind < 4; r_ind = r_ind + 1) begin
            float_multiply multr (
                .aclk(clk),                                  // input wire aclk
                .s_axis_a_tvalid(1'b1),            // input wire s_axis_a_tvalid
                .s_axis_a_tdata(a[r_ind]),              // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(1'b1),          // input wire s_axis_b_tvalid
                .s_axis_b_tdata(b[r_ind]),              // input wire [15 : 0] s_axis_b_tdata
                // .m_axis_result_tvalid(vdotr[r_ind]),  // output wire m_axis_result_tvalid
                .m_axis_result_tdata(dotr[r_ind])          // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate

    float16 r1; // = dotr[0] - dotr[1]
    float16 r2; // = dotr[2] + dotr[3]
    logic vr1r2;
    // logic vr2;

    /// PS2: 8-stage
    float_add_sub add_r1 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(1'b1),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(dotr[0]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(dotr[1]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(vdotr[0]),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(vr1r2),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(r1)          // output wire [15 : 0] m_axis_result_tdata
    );
    float_add_sub add_r2 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(1'b1),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(dotr[2]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(dotr[3]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(vdotr[0]),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(r2)          // output wire [15 : 0] m_axis_result_tdata
    );
    
    /// PS3: 8-stage
    float16 cr;  // = r1 - r2
    logic vcr;

    float_add_sub add_cr (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(1'b1),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(r1),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(r2),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(1'b1),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(cr)          // output wire [15 : 0] m_axis_result_tdata
    );

    // i part
    float16 doti [3:0];

    /// PS1: 6-stage
    generate
        genvar i_ind;
        for (i_ind = 0; i_ind < 4; i_ind = i_ind + 1) begin
            float_multiply multi (
                .aclk(clk),                                  // input wire aclk
                .s_axis_a_tvalid(1'b1),            // input wire s_axis_a_tvalid
                .s_axis_a_tdata(a[i_ind]),              // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(1'b1),          // input wire s_axis_b_tvalid
                .s_axis_b_tdata(bi[i_ind]),              // input wire [15 : 0] s_axis_b_tdata
                // .m_axis_result_tvalid(a0b0_valid),  // output wire m_axis_result_tvalid
                .m_axis_result_tdata(doti[i_ind])          // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate

    /// PS2: 8-stage
    float16 i1;  // = doti[0] + doti[1]
    float16 i2;  // = doti[2] - doti[3]

    float_add_sub add_i1 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(1'b1),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(doti[0]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(doti[1]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(1'b1),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(i1)          // output wire [15 : 0] m_axis_result_tdata
    );
    float_add_sub add_i2 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(1'b1),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(doti[2]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(doti[3]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(1'b1),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(i2)          // output wire [15 : 0] m_axis_result_tdata
    );


    /// PS3: 8-stage
    float16 ci;  // = i1 + i2
    float_add_sub add_ci (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(1'b1),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(i1),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(i2),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(1'b1),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(ci)          // output wire [15 : 0] m_axis_result_tdata
    );

    // j part
    float16 dotj [3:0];
    
    /// PS1: 6-stage
    generate
        genvar j_ind;
        for (j_ind = 0; j_ind < 4; j_ind = j_ind + 1) begin
            float_multiply multj (
                .aclk(clk),                                  // input wire aclk
                .s_axis_a_tvalid(1'b1),            // input wire s_axis_a_tvalid
                .s_axis_a_tdata(a[j_ind]),              // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(1'b1),          // input wire s_axis_b_tvalid
                .s_axis_b_tdata(bj[j_ind]),              // input wire [15 : 0] s_axis_b_tdata
                // .m_axis_result_tvalid(a0b0_valid),  // output wire m_axis_result_tvalid
                .m_axis_result_tdata(dotj[j_ind])          // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate


    /// PS2: 8-stage
    float16 j1;  // = dotj[0] - dotj[1]
    float16 j2;  // = dotj[2] + dotj[3]

    float_add_sub add_j1 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(1'b1),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(dotj[0]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(dotj[1]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(1'b1),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(j1)          // output wire [15 : 0] m_axis_result_tdata
    );
    float_add_sub add_j2 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(1'b1),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(dotj[2]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(dotj[3]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(1'b1),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(j2)          // output wire [15 : 0] m_axis_result_tdata
    );


    /// PS3: 8-stage
    float16 cj;  // = j1 + j2
    float_add_sub add_cj (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(1'b1),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(j1),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(j2),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(1'b1),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(cj)          // output wire [15 : 0] m_axis_result_tdata
    );

    
    // k part
    float16 dotk [3:0];

    /// PS1: 6-stage
    generate
        genvar k_ind;
        for (k_ind = 0; k_ind < 4; k_ind = k_ind + 1) begin
            float_multiply multk (
                .aclk(clk),                                  // input wire aclk
                .s_axis_a_tvalid(1'b1),            // input wire s_axis_a_tvalid
                .s_axis_a_tdata(a[k_ind]),              // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(1'b1),          // input wire s_axis_b_tvalid
                .s_axis_b_tdata(bk[k_ind]),              // input wire [15 : 0] s_axis_b_tdata
                // .m_axis_result_tvalid(a0b0_valid),  // output wire m_axis_result_tvalid
                .m_axis_result_tdata(dotk[k_ind])          // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate


    /// PS2: 8-stage
    float16 k1;  // = dotk[0] + dotk[1]
    float16 k2;  // = dotk[2] - dotk[3]

    float_add_sub add_k1 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(1'b1),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(dotk[0]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(dotk[1]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(1'b1),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(k1)          // output wire [15 : 0] m_axis_result_tdata
    );
    float_add_sub add_k2 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(1'b1),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(dotk[2]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(dotk[3]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(1'b1),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(k2)          // output wire [15 : 0] m_axis_result_tdata
    );
    
    /// PS3: 8-stage
    float16 ck;  // = k1 - k2
    float_add_sub add_ck (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(1'b1),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(k1),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(k2),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(1'b1),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(ck)          // output wire [15 : 0] m_axis_result_tdata
    );

    // final assignments
    assign c[0] = cr;
    assign c[1] = ci;
    assign c[2] = cj;
    assign c[3] = ck;
    assign valid_out = 1'b1;
endmodule

// 44-stage pipeline (each quaternion_mult is 22-stage)
module rotate(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 in,
    input quaternion rot,
    output logic valid_out,
    output vec3 out
);
    quaternion q_in;
    assign q_in[0] = 16'b0;
    assign q_in[1] = in[0];
    assign q_in[2] = in[1];
    assign q_in[3] = in[2];

    /// PS1: 22-stage
    quaternion rot_q;
    logic vmult1;

    quaternion_mult mult_rot_q (
        .clk(clk),
        .rst(rst),
        .valid_in(1'b1),
        .a(rot),
        .b(q_in),
        // .valid_out(vmult1),
        .c(rot_q)
    );

    localparam PS1_STAGES = 22;
    quaternion rot_inv [PS1_STAGES-1:0];

    // 22-stage pipeline to stay in sync with first quaternion_mult
    always_ff @(posedge clk) begin
        rot_inv[0][0] <= rot[0];
        rot_inv[0][1] <= {~rot[1][15], rot[1][14:0]};
        rot_inv[0][2] <= {~rot[2][15], rot[2][14:0]};
        rot_inv[0][3] <= {~rot[3][15], rot[3][14:0]};
        for (int i = 1; i < PS1_STAGES; i = i + 1) begin
            rot_inv[i][0] <= rot_inv[i-1][0];
            rot_inv[i][1] <= rot_inv[i-1][1];
            rot_inv[i][2] <= rot_inv[i-1][2];
            rot_inv[i][3] <= rot_inv[i-1][3];
        end
    end

    // PS2: 22-stage
    quaternion rot_q_rot_inv;
    logic vmult2;
    
    quaternion_mult mult_rot_q_rot_inv (
        .clk(clk),
        .rst(rst),
        .valid_in(1'b1),
        .a(rot_q),
        .b(rot_inv[PS1_STAGES-1]),
        // .valid_out(vmult2),
        .c(rot_q_rot_inv)
    );

    assign out[0] = rot_q_rot_inv[1];
    assign out[1] = rot_q_rot_inv[2];
    assign out[2] = rot_q_rot_inv[3];
    assign valid_out = 1'b1;
endmodule

// 44-stage pipeline (same as rotate)
module rotate_inv(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 in,
    input quaternion rot_inv,
    output logic valid_out,
    output vec3 out
);
    quaternion q_in;
    assign q_in[0] = 16'b0;
    assign q_in[1] = in[0];
    assign q_in[2] = in[1];
    assign q_in[3] = in[2];
    
    /// PS1: 22-stage
    quaternion q_rot_inv;
    logic vmult1;

    quaternion_mult mult_q_rot_inv (
        .clk(clk),
        .rst(rst),
        .valid_in(1'b1),
        .a(q_in),
        .b(rot_inv),
        // .valid_out(vmult1),
        .c(q_rot_inv)
    );
    
    // 22-stage pipeline to stay in sync with first quaternion_mult
    localparam PS1_STAGES = 22;
    quaternion rot [PS1_STAGES-1:0];
    always_ff @(posedge clk) begin
        rot[0][0] <= rot_inv[0];
        rot[0][1] <= {~rot_inv[1][15], rot_inv[1][14:0]};
        rot[0][2] <= {~rot_inv[2][15], rot_inv[2][14:0]};
        rot[0][3] <= {~rot_inv[3][15], rot_inv[3][14:0]};
        for (int i = 1; i < PS1_STAGES; i = i+1) begin
            rot[i][0] <= rot[i-1][0];
            rot[i][1] <= rot[i-1][1];
            rot[i][2] <= rot[i-1][2];
            rot[i][3] <= rot[i-1][3];
        end
    end

    /// PS2: 22-stage
    quaternion rot_q_rot_inv;
    logic vmult2;

    quaternion_mult mult_rot_q_rot_inv (
        .clk(clk),
        .rst(rst),
        .valid_in(1'b1),
        .a(rot[PS1_STAGES-1]),
        .b(q_rot_inv),
        // .valid_out(vmult2),
        .c(rot_q_rot_inv)
    );

    assign out[0] = rot_q_rot_inv[1];
    assign out[1] = rot_q_rot_inv[2];
    assign out[2] = rot_q_rot_inv[3];
    assign valid_out = 1'b1;
endmodule

// 8-stage pipeline
module translate(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 in,
    input vec3 trans,
    output logic valid_out,
    output vec3 out
);
    logic vout [2:0];
    vec3 sum;

    generate
        for (genvar coord = 0; coord < 3; coord = coord + 1) begin
            float_add_sub add_x (
                .aclk(clk),                                        // input wire aclk
                .s_axis_a_tvalid(1'b1),                  // input wire s_axis_a_tvalid
                .s_axis_a_tdata(in[coord]),                    // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(1'b1),                  // input wire s_axis_b_tvalid
                .s_axis_b_tdata(trans[coord]),                    // input wire [15 : 0] s_axis_b_tdata
                .s_axis_operation_tvalid(1'b1),                 // input wire s_axis_operation_tvalid
                .s_axis_operation_tdata({2'b0, fpuOpAdd}),                      // input wire [7 : 0] s_axis_operation_tdata
                // .m_axis_result_tvalid(vout[coord]),        // output wire m_axis_result_tvalid
                .m_axis_result_tdata(sum[coord])          // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate

    assign out[0] = sum[0];
    assign out[1] = sum[1];
    assign out[2] = sum[2];
    assign valid_out = 1'b1;
endmodule

// 6-stage pipeline
module scale(
    input wire clk,
    input wire rst,
    input wire valid_in,
    input vec3 in,
    input vec3 scale,
    output logic valid_out,
    output vec3 out
);
    logic vout [2:0];
    vec3 prod;

    generate
        for (genvar coord = 0; coord < 3; coord = coord + 1) begin
            float_multiply mult (
                .aclk(clk),                                  // input wire aclk
                .s_axis_a_tvalid(1'b1),            // input wire s_axis_a_tvalid
                .s_axis_a_tdata(in[coord]),              // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(1'b1),          // input wire s_axis_b_tvalid
                .s_axis_b_tdata(scale[coord]),              // input wire [15 : 0] s_axis_b_tdata
                // .m_axis_result_tvalid(vout[coord]),  // output wire m_axis_result_tvalid
                .m_axis_result_tdata(prod[coord])          // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate

    assign out[0] = prod[0];
    assign out[1] = prod[1];
    assign out[2] = prod[2];
    assign valid_out = 1'b1;
endmodule



module unit_float_to_fixed (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire float16 flt,
    output logic valid_out,
    output logic [15:0] fx
);

    float16 abs_flt;
    assign abs_flt = {1'b0, flt[14:0]};

    // 2-stage for comparator (if > 1, cap to 1)

    // 6-stage for mul


    // 5-stage
    // float_to_fixed13 z_to_fx13 (
    //     .aclk                (clk),          // input wire aclk
    //     .s_axis_a_tvalid     (input_valid),  // input wire s_axis_a_tvalid
    //     .s_axis_a_tdata      ({~z_dist[15], z_dist[14:0]}),       // input wire [15 : 0] s_axis_a_tdata
    //     .m_axis_result_tvalid(fx13_valid),   // output wire m_axis_result_tvalid
    //     .m_axis_result_tdata (fx13_out)      // output wire [15 : 0] m_axis_result_tdata
    // );

endmodule

`default_nettype wire