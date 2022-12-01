`timescale 1ns / 1ps

module add_mult_tb;
    logic clk = 0;
    
    logic multOutReady;
    logic addOutReady;
    logic inputValid = 0;
    
    logic [31:0] addInA;
    logic [31:0] addInB;
    logic [31:0] addOut;
    
    fp_adder_s myAdder(   .aclk(clk), .s_axis_a_tvalid(inputValid), .s_axis_a_tdata(addInA), 
                                .s_axis_b_tvalid(inputValid), .s_axis_b_tdata(addInB), .m_axis_result_tready(1'b1), 
                                .m_axis_result_tdata(addOut),.m_axis_result_tvalid(addOutReady));
    
    logic [31:0] multInA;
    logic [31:0] multInB;
    logic [31:0] multOut;
    
    fp_mult_s myMult(    .aclk(clk), .s_axis_a_tvalid(inputValid), .s_axis_a_tdata(multInA), 
                                .s_axis_b_tvalid(inputValid), .s_axis_b_tdata(multInB), .m_axis_result_tready(1'b1), 
                                .m_axis_result_tdata(multOut), .m_axis_result_tvalid(multOutReady));
    
    always begin
        #5;
        clk = !clk;
    end
    
    initial begin
        #10;
        //add 12 to 12
        addInA = {1'b0,8'd130,23'b100_0000_0000_0000_0000_0000};
        addInB = {1'b0,8'd130,23'b100_0000_0000_0000_0000_0000};
        
        //multiply 12 by 12
        multInA = {1'b0,8'd130,23'b100_0000_0000_0000_0000_0000};
        multInB = {1'b0,8'd130,23'b100_0000_0000_0000_0000_0000};
        inputValid = 1;
        #10
        inputValid = 0;
        
        #30;
         //multiply 12 by -12
        multInA = {1'b0,8'd130,23'b100_0000_0000_0000_0000_0000};
        multInB = {1'b1,8'd130,23'b100_0000_0000_0000_0000_0000};
        inputValid = 1;
    end
    
    
endmodule
