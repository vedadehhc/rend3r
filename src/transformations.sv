`default_nettype none
`timescale 1ns / 1ps

import proctypes::*;

// See: https://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation#Advantages_of_quaternions
// 3-stage pipeline (each fpu adds 1 stage)
// (a, b, bi, bj, bk) -> (dotr, doti, dotj, dotk) -> (r1, r2, i1, i2, j1, j2, k1, k2) -> c
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

    generate
        genvar r_ind;
        for (r_ind = 0; r_ind < 4; r_ind = r_ind + 1) begin
            float_multiply multr (
                .aclk(clk),                                  // input wire aclk
                .s_axis_a_tvalid(valid_in),            // input wire s_axis_a_tvalid
                .s_axis_a_tdata(a[r_ind]),              // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(valid_in),          // input wire s_axis_b_tvalid
                .s_axis_b_tdata(b[r_ind]),              // input wire [15 : 0] s_axis_b_tdata
                .m_axis_result_tvalid(vdotr[r_ind]),  // output wire m_axis_result_tvalid
                .m_axis_result_tdata(dotr[r_ind])          // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate

    float16 r1; // = dotr[0] - dotr[1]
    float16 r2; // = dotr[2] + dotr[3]
    logic vr1r2;
    // logic vr2;

    float_add_sub add_r1 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(vdotr[0]),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(dotr[0]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(vdotr[0]),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(dotr[1]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(vdotr[0]),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),                      // input wire [7 : 0] s_axis_operation_tdata
        .m_axis_result_tvalid(vr1r2),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(r1)          // output wire [15 : 0] m_axis_result_tdata
    );
    float_add_sub add_r2 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(vdotr[0]),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(dotr[2]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(vdotr[0]),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(dotr[3]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(vdotr[0]),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(r2)          // output wire [15 : 0] m_axis_result_tdata
    );
    
    float16 cr;  // = r1 - r2
    logic vcr;

    float_add_sub add_cr (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(vr1r2),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(r1),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(vr1r2),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(r2),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(vr1r2),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(vcr)          // output wire [15 : 0] m_axis_result_tdata
    );

    // i part
    float16 doti [3:0];
    
    generate
        genvar i_ind;
        for (i_ind = 0; i_ind < 4; i_ind = i_ind + 1) begin
            float_multiply multi (
                .aclk(clk),                                  // input wire aclk
                .s_axis_a_tvalid(valid_in),            // input wire s_axis_a_tvalid
                .s_axis_a_tdata(a[i_ind]),              // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(valid_in),          // input wire s_axis_b_tvalid
                .s_axis_b_tdata(bi[i_ind]),              // input wire [15 : 0] s_axis_b_tdata
                // .m_axis_result_tvalid(a0b0_valid),  // output wire m_axis_result_tvalid
                .m_axis_result_tdata(doti[i_ind])          // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate

    float16 i1;  // = doti[0] + doti[1]
    float16 i2;  // = doti[2] - doti[3]

    float_add_sub add_i1 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(valid_in),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(doti[0]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(valid_in),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(doti[1]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(valid_in),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(i1)          // output wire [15 : 0] m_axis_result_tdata
    );
    float_add_sub add_i2 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(valid_in),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(doti[2]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(valid_in),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(doti[3]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(valid_in),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(i2)          // output wire [15 : 0] m_axis_result_tdata
    );

    float16 ci;  // = i1 + i2
    float_add_sub add_ci (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(valid_in),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(i1),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(valid_in),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(i2),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(valid_in),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(ci)          // output wire [15 : 0] m_axis_result_tdata
    );

    // j part
    float16 dotj [3:0];
    
    generate
        genvar j_ind;
        for (j_ind = 0; j_ind < 4; j_ind = j_ind + 1) begin
            float_multiply multj (
                .aclk(clk),                                  // input wire aclk
                .s_axis_a_tvalid(valid_in),            // input wire s_axis_a_tvalid
                .s_axis_a_tdata(a[j_ind]),              // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(valid_in),          // input wire s_axis_b_tvalid
                .s_axis_b_tdata(bj[j_ind]),              // input wire [15 : 0] s_axis_b_tdata
                // .m_axis_result_tvalid(a0b0_valid),  // output wire m_axis_result_tvalid
                .m_axis_result_tdata(dotj[j_ind])          // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate

    float16 j1;  // = dotj[0] - dotj[1]
    float16 j2;  // = dotj[2] + dotj[3]

    float_add_sub add_j1 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(valid_in),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(dotj[0]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(valid_in),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(dotj[1]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(valid_in),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(j1)          // output wire [15 : 0] m_axis_result_tdata
    );
    float_add_sub add_j2 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(valid_in),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(dotj[2]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(valid_in),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(dotj[3]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(valid_in),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(j2)          // output wire [15 : 0] m_axis_result_tdata
    );

    float16 cj;  // = j1 + j2
    float_add_sub add_cj (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(valid_in),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(j1),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(valid_in),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(j2),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(valid_in),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(cj)          // output wire [15 : 0] m_axis_result_tdata
    );

    
    // k part
    float16 dotk [3:0];

    generate
        genvar k_ind;
        for (k_ind = 0; k_ind < 4; k_ind = k_ind + 1) begin
            float_multiply multk (
                .aclk(clk),                                  // input wire aclk
                .s_axis_a_tvalid(valid_in),            // input wire s_axis_a_tvalid
                .s_axis_a_tdata(a[k_ind]),              // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(valid_in),          // input wire s_axis_b_tvalid
                .s_axis_b_tdata(bk[k_ind]),              // input wire [15 : 0] s_axis_b_tdata
                // .m_axis_result_tvalid(a0b0_valid),  // output wire m_axis_result_tvalid
                .m_axis_result_tdata(dotk[k_ind])          // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate

    float16 k1;  // = dotk[0] + dotk[1]
    float16 k2;  // = dotk[2] - dotk[3]

    float_add_sub add_k1 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(valid_in),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(dotk[0]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(valid_in),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(dotk[1]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(valid_in),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpAdd}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(k1)          // output wire [15 : 0] m_axis_result_tdata
    );
    float_add_sub add_k2 (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(valid_in),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(dotk[2]),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(valid_in),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(dotk[3]),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(valid_in),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(k2)          // output wire [15 : 0] m_axis_result_tdata
    );
    
    float16 ck;  // = k1 - k2
    float_add_sub add_ck (
        .aclk(clk),                                        // input wire aclk
        .s_axis_a_tvalid(valid_in),                  // input wire s_axis_a_tvalid
        .s_axis_a_tdata(k1),                    // input wire [15 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(valid_in),                  // input wire s_axis_b_tvalid
        .s_axis_b_tdata(k2),                    // input wire [15 : 0] s_axis_b_tdata
        .s_axis_operation_tvalid(valid_in),                 // input wire s_axis_operation_tvalid
        .s_axis_operation_tdata({2'b0, fpuOpSub}),                      // input wire [7 : 0] s_axis_operation_tdata
        // .m_axis_result_tvalid(m_axis_result_tvalid),        // output wire m_axis_result_tvalid
        .m_axis_result_tdata(ck)          // output wire [15 : 0] m_axis_result_tdata
    );

    // final assignments
    assign c[0] = cr;
    assign c[1] = ci;
    assign c[2] = cj;
    assign c[3] = ck;
    assign valid_out = vcr;
endmodule

// 6-stage pipeline (each quaternion_mult is 3 stage)
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

    quaternion rot_q;
    logic vmult1;

    quaternion_mult mult_rot_q (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .a(rot),
        .b(q_in),
        .valid_out(vmult1),
        .c(rot_q)
    );

    // 3 stage pipeline to stay in sync with first quaternion_mult
    quaternion rot_inv_1;
    quaternion rot_inv_2;
    quaternion rot_inv_3;
    always_ff @(posedge clk) begin
        if (rst) begin

        end else begin
            rot_inv_1[0] <= rot[0];
            rot_inv_1[1] <= {~rot[1][15], rot[1][14:0]};
            rot_inv_1[2] <= {~rot[2][15], rot[2][14:0]};
            rot_inv_1[3] <= {~rot[3][15], rot[3][14:0]};

            rot_inv_2[0] <= rot_inv_1[0];
            rot_inv_2[1] <= rot_inv_1[1];
            rot_inv_2[2] <= rot_inv_1[2];
            rot_inv_2[3] <= rot_inv_1[3];

            rot_inv_3[0] <= rot_inv_2[0];
            rot_inv_3[1] <= rot_inv_2[1];
            rot_inv_3[2] <= rot_inv_2[2];
            rot_inv_3[3] <= rot_inv_2[3];
        end
    end

    quaternion rot_q_rot_inv;
    logic vmult2;
    
    quaternion_mult mult_rot_q_rot_inv (
        .clk(clk),
        .rst(rst),
        .valid_in(vmult1),
        .a(rot_q),
        .b(rot_inv_3),
        .valid_out(vmult2),
        .c(rot_q_rot_inv)
    );

    assign out[0] = rot_q_rot_inv[1];
    assign out[1] = rot_q_rot_inv[2];
    assign out[2] = rot_q_rot_inv[3];
    assign valid_out = vmult2;
endmodule

// 6-stage pipeline (same as rotate)
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
    
    quaternion q_rot_inv;
    logic vmult1;

    quaternion_mult mult_q_rot_inv (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .a(q_in),
        .b(rot_inv),
        .valid_out(vmult1),
        .c(q_rot_inv)
    );
    
    // 3 stage pipeline to stay in sync with first quaternion_mult
    quaternion rot_1;
    quaternion rot_2;
    quaternion rot_3;
    always_ff @(posedge clk) begin
        if (rst) begin

        end else begin
            rot_1[0] <= rot_inv[0];
            rot_1[1] <= {~rot_inv[1][15], rot_inv[1][14:0]};
            rot_1[2] <= {~rot_inv[2][15], rot_inv[2][14:0]};
            rot_1[3] <= {~rot_inv[3][15], rot_inv[3][14:0]};

            rot_2[0] <= rot_1[0];
            rot_2[1] <= rot_1[1];
            rot_2[2] <= rot_1[2];
            rot_2[3] <= rot_1[3];

            rot_3[0] <= rot_2[0];
            rot_3[1] <= rot_2[1];
            rot_3[2] <= rot_2[2];
            rot_3[3] <= rot_2[3];
        end
    end

    quaternion rot_q_rot_inv;
    logic vmult2;

    quaternion_mult mult_rot_q_rot_inv (
        .clk(clk),
        .rst(rst),
        .valid_in(vmult1),
        .a(rot_3),
        .b(q_rot_inv),
        .valid_out(vmult2),
        .c(rot_q_rot_inv)
    );

    assign out[0] = rot_q_rot_inv[1];
    assign out[1] = rot_q_rot_inv[2];
    assign out[2] = rot_q_rot_inv[3];
    assign valid_out = vmult2;
endmodule

// single stage pipeline
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
                .s_axis_a_tvalid(valid_in),                  // input wire s_axis_a_tvalid
                .s_axis_a_tdata(in[coord]),                    // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(valid_in),                  // input wire s_axis_b_tvalid
                .s_axis_b_tdata(trans[coord]),                    // input wire [15 : 0] s_axis_b_tdata
                .s_axis_operation_tvalid(valid_in),                 // input wire s_axis_operation_tvalid
                .s_axis_operation_tdata({2'b0, fpuOpAdd}),                      // input wire [7 : 0] s_axis_operation_tdata
                .m_axis_result_tvalid(vout[coord]),        // output wire m_axis_result_tvalid
                .m_axis_result_tdata(sum[coord])          // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate

    assign out[0] = sum[0];
    assign out[1] = sum[1];
    assign out[2] = sum[2];
    assign valid_out = vout[0];
endmodule

// single stage pipeline
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
                .s_axis_a_tvalid(valid_in),            // input wire s_axis_a_tvalid
                .s_axis_a_tdata(in[coord]),              // input wire [15 : 0] s_axis_a_tdata
                .s_axis_b_tvalid(valid_in),          // input wire s_axis_b_tvalid
                .s_axis_b_tdata(scale[coord]),              // input wire [15 : 0] s_axis_b_tdata
                .m_axis_result_tvalid(vout[coord]),  // output wire m_axis_result_tvalid
                .m_axis_result_tdata(prod[coord])          // output wire [15 : 0] m_axis_result_tdata
            );
        end
    endgenerate

    assign out[0] = prod[0];
    assign out[1] = prod[1];
    assign out[2] = prod[2];
    assign valid_out = vout[0];
endmodule

`default_nettype wire