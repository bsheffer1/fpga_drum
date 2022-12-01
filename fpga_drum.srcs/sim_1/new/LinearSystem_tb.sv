`timescale 1ns / 1ps
`default_nettype none

module LinearSystem_tb;
    logic clk = 0;
    logic rst = 1;
    
    parameter N = 5;
    
    logic [31:0] Gamma = 32'hc2fa0000; //the damping constant of -125 (absorb the negative into the damping constant;
    logic [31:0] K = 32'h4a742400; //4E6, just a random big number;
    
    logic [31:0] F_d [N-1:0];
    logic [31:0] x [N-1:0];
    logic [31:0] xTemp [N-1:0];
    logic [31:0] xPlus;
    logic [31:0] xMinus;
    logic [31:0] v [N-1:0];
    
    logic [31:0] x_in;
    logic [31:0] v_in;
    logic [31:0] F_din;
    
    logic [13:0] updateID;
    logic inputsValid;
    
    logic [31:0] x_new;
    logic [31:0] v_new;
    logic [13:0] outputID_xnew;
    logic [13:0] outputID_vnew;
    logic [13:0] outputID_xold;
    logic [13:0] outputID_vold;
    
    logic inputsReady;
    
    logic x_newValid;
    logic v_newValid;
    logic inputsValid_in;
    assign inputsValid_in = inputsValid & inputsReady;
    
    SingleMassTimeStep1D myTimeStep(  .clk(clk), .rst(rst), .x_in(x_in), .x_inPlus(xPlus), .x_inMinus(xMinus), .F_d(F_din), .v_in(v_in), .inputsValid(inputsValid_in), .updateID(updateID), .Gamma(Gamma), .K(K),
                                    .x_new(x_new), .v_new(v_new), .outputID_xnew(outputID_xnew), .x_newValid(x_newValid),.outputID_vnew(outputID_vnew), .v_newValid(v_newValid), .inputsReady(inputsReady));
    
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
    
    logic [31:0] accumInA;
    logic accumInAReady;
    logic accumInAValid;
    logic [31:0] accumOut;
    logic accumOutReady;
    logic accumOutValid;
    logic [13:0] accumID;
    logic [31:0] audioSig;
    
    logic resetAccum = 1; //active low reset signal for accumulator
    assign accumOutReady = 1;
    assign accumInAValid = x_newValid;
    assign accumInA = x_new;
    
    fp_accumulator_s myAccumulator( .aclk(clk), .aresetn(rst & resetAccum), .s_axis_a_tvalid(accumInAValid),
                                    .s_axis_a_tready(accumInAReady), .s_axis_a_tdata(accumInA), .s_axis_a_tuser(outputID_xnew),
                                    .m_axis_result_tdata(accumOut), .m_axis_result_tready(accumOutReady), .m_axis_result_tvalid(accumOutValid),
                                    .m_axis_result_tuser(accumID));
                                    
   
    
    logic [7:0] aud_out;
    logic [31:0] aud_outTemp;
    assign aud_outTemp = floatToFixedOut + 127;        
    assign aud_out = aud_outTemp[7:0];     
    
    logic aud_pwm;
    logic [13:0] counter;
    pwm myPwm(.clk_in(clk), .rst_in(!rst), .level_in(aud_out), .pwm_out(aud_pwm));
    
    logic [6:0] n; //which mass are we on in the string?                          
    
    always begin
        #5;
        clk = !clk;
    end
    
    initial begin
        rst = 0;
        //F_d = 0;
        for(int i = 0; i < N; i=i+1)begin
            F_d[i] = 0;
        end
        #30;
        rst = 1;        
        F_d[1] = 32'h4dd1cef0;
        #100000;
        F_d[1] = 0;
        
    end
    parameter delay = 0;
    logic [5:0] delayCounter;
    
    always_ff @(posedge clk) begin
        if(!rst)begin
            for(int i = 0; i < N; i = i+1)begin
                x[i] <= 0;
                v[i] <= 0;
            end
            x_in <= 0;
            xMinus <= 0;
            xPlus <= 0;
            v_in <= 0;
            F_din <= 0;
            n <= 0;
            floatToFixedInA <= 0;
            //F_d <= 0;
            inputsValid <= 0;   
            updateID <= 0;
            outputID_vold <= 0;
            outputID_xold <= 0;
            inputsValid <= 0;
            
            
            delayCounter <= 0;
            counter <= 0;
        end else begin//if not in reset...
        
                
        
                 outputID_xold <= outputID_xnew;
                //inputsValid <= 0;
                if((outputID_xnew == N) && (outputID_xold != outputID_xnew))begin //if the final data has just arrived
                    x[outputID_xnew-1] <= x_new;
                    v[outputID_vnew-1] <= v_new;
                    
                    audioSig <= accumOut;
                    resetAccum <= 0;
                    n <= 0;
                   
                end else if((outputID_xold != outputID_xnew)) begin
                    if(outputID_xnew > 0)begin
                        x[outputID_xnew-1] <= x_new;
                        v[outputID_vnew-1] <= v_new;
                    end
                end
        
        
            if(n == N)begin
                if(delayCounter >= delay)begin
                   // n <= n+1;
                   // updateID <= n+1;
                    delayCounter <= 0;
                    inputsValid <= 0;
                end else begin
                    delayCounter <=  delayCounter + 1;
                    inputsValid <= 0;
                end
            end else if (n == N-1)begin
                if(inputsReady)begin                    
                    xMinus <= x[n-1];
                    x_in <= x[n];
                    xPlus <= 0;
                    v_in <= v[n];
                    F_din <= F_d[n];
                    updateID <= n+1;
                    
                    if(delayCounter >= delay)begin
                        n <= n+1;
                        inputsValid <= 1;
                        delayCounter <= 0;
                    end else begin
                        delayCounter <=  delayCounter + 1;
                        inputsValid <= 1;
                    end
                end
    
            end else if (n == 0) begin
                if(inputsReady)begin
                    xMinus <= 0;
                    x_in <= x[n];
                    xPlus <= x[n+1];
                    v_in <= v[n];
                    F_din <= F_d[n];
                    inputsValid <= 1;
                    updateID <= n+1;
                    resetAccum <= 1;
                    
                    if(delayCounter >= delay)begin
                        n <= n+1;
                        inputsValid <= 1;
                        delayCounter <= 0;
                    end else begin
                        delayCounter <=  delayCounter + 1;
                        inputsValid <= 1;
                    end
                 end
            end else if(n < N-1) begin
              if(inputsReady)begin  
                    xMinus <= x[n-1];
                    x_in <= x[n];
                    xPlus <= x[n+1];
                    v_in <= v[n];
                    F_din <= F_d[n];
                    updateID <= n+1;
                    
                    if(delayCounter >= delay)begin
                        n <= n+1;
                        inputsValid <= 1;
                        delayCounter <= 0;
                    end else begin
                        delayCounter <=  delayCounter + 1;
                        inputsValid <= 1;
                    end
                end
            end           
        end
    end
        
endmodule    