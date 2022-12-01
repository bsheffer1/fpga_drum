`timescale 1ns / 1ps
`default_nettype none

module singleMassTimeStep_tb;
    logic clk = 0;
    logic rst = 1;
    
    logic [31:0] Gamma = 32'hc2fa0000; //the damping constant of -125 (absorb the negative into the damping constant;
    logic [31:0] K = 32'h4a742400; //-8E6, just a random big number;
    
    logic [31:0] F_d;
    logic [31:0] x;
    logic [31:0] v;
    logic [13:0] updateID;
    logic inputsValid;
    
    logic [31:0] x_new;
    logic [31:0] v_new;
    logic [13:0] outputID_xnew;
    logic [13:0] outputID_vnew;
    logic x_newValid;
    logic v_newValid;
    
    SingleMassTimeStep myTimeStep(  .clk(clk), .rst(rst), .x_in(x), .F_d(F_d), .v_in(v), .inputsValid(inputsValid), .updateID(updateID), .Gamma(Gamma), .K(K),
                                    .x_new(x_new), .v_new(v_new), .outputID_xnew(outputID_xnew), .x_newValid(x_newValid),.outputID_vnew(outputID_vnew), .v_newValid(v_newValid));
    
    logic [31:0] floatToFixedInA;
    logic floatToFixedInAValid;
    logic floatToFixedInAReady;
    logic [31:0] floatToFixedOut;
    logic floatToFixedOutReady;
    logic floatToFixedOutValid;
    logic [13:0] floatToFixedID;
    
    fp_floatToFixed_s myFloatToFixed(   .aclk(clk), .aresetn(rst), .s_axis_a_tdata(floatToFixedInA), .s_axis_a_tvalid(floatToFixedInAValid),
                                        .s_axis_a_tready(floatToFixedInAReady), .s_axis_a_tuser(outputID_xnew),
                                        .m_axis_result_tdata(floatToFixedOut), .m_axis_result_tvalid(floatToFixedOutValid),
                                        .m_axis_result_tready(floatToFixedOutReady), .m_axis_result_tuser(floatToFixedID));
                                        
    assign floatToFixedInAValid = inputsValid;
    assign floatToFixedOutReady = 1; 
    
    logic [7:0] aud_out;
    logic [31:0] aud_outTemp;
    assign aud_outTemp = floatToFixedOut + 127;        
    assign aud_out = aud_outTemp[7:0];     
    
    logic aud_pwm;
    logic [13:0] counter;
    pwm myPwm(.clk_in(clk), .rst_in(!rst), .level_in(aud_out), .pwm_out(aud_pwm));
    
                              
    
    always begin
        #5;
        clk = !clk;
    end
    
    initial begin
        rst = 0;
        F_d = 0;
        #30;
        rst = 1;        
        F_d = 32'h47761020;
        #100000;
        F_d = 0;
        
    end
    
    always_ff @(posedge clk) begin
        if(!rst)begin
            x <= 0;
            v <= 0;
            
            floatToFixedInA <= 0;
            //F_d <= 0;
            inputsValid <= 1;   
            updateID <= 1;
            counter <= 0;
        end else begin
    
             if(counter > 2083)begin
                if((updateID == outputID_vnew) && (updateID == outputID_xnew))begin
                    x <= x_new;
                    v <= v_new;
                    floatToFixedInA <= x_new;
                    inputsValid <= 1;
                    updateID <= updateID + 1;
                    counter <= 0;
                end else begin
                    inputsValid <= 0;
                end
                
             end else begin
                counter <= counter + 1;
             end
        
            end
        end
        
    endmodule
    
    
    ////PWM generator for audio generation!
//module pwm (input clk_in, input rst_in, input [7:0] level_in, output logic pwm_out);
//  logic [7:0] count;
//  assign pwm_out = count<level_in;
//  always_ff @(posedge clk_in)begin
//    if (rst_in) count <= 8'b0;
//    else count <= count+8'b1;
//  end
//endmodule