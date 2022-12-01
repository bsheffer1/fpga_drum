//`timescale 1ns / 1ps
//`default_nettype none

module top_level(   input clk_100mhz,
                    input vauxp2 , vauxn2,
                    input vauxp3 , vauxn3,
                    input vauxp10, vauxn10,
                    input btnc, btnu, btnl, btnr,
                    input [15:0] sw,
                    output logic [1:0] jb,
                    output aud_pwm, aud_sd
    );
    parameter N = 50; //the number of rows
    parameter M = 25; //the number of columns
     
    //active low reset
    logic rst;
    assign rst = !btnc;
    
    assign aud_sd = 1'b1; //enable pwm amplifier
    
    
    
    logic [31:0] Gamma;// = 32'hc2fa0000; //the damping constant of -125 (absorb the negative into the damping constant;
    logic [31:0] K;// = 32'hca742400; //-8E6, just a random big number;
    logic [31:0] scaleFactor; //scale the output from the accumulator to between -127 and 127
    
     logic [31:0] F_mag;
    logic [5:0] n_f;
    logic [5:0] m_f;
    
    logic [31:0] x [N-1:0];
    logic [31:0] v [N-1:0];
    logic [31:0] yPlus[N-1:0];
    logic [31:0] yMinus[N-1:0];
    logic [31:0] F_d [N-1:0];
    logic inputsValid;
    logic inputsReady;
    
    logic resetAccum;
    
    
    logic [31:0] x_new [N-1:0];
    logic [31:0] v_new [N-1:0];
    logic outputsValid;
    logic [31:0] accumOut; 
    logic [31:0] audioSig;
    logic accumOutValid;
    logic accumIDValid;
    logic accumIDValidOld;
    
    logic [13:0] counter;
    logic [13:0] sampleDelay;
    
    logic [5:0] m; //use this to keep track of which column we are on
    
    logic outputsValidOld = 0;
    logic accumOutValidOld = 0; 
    
    parameter IDLE = 0;
    parameter STREAM = 1;
    parameter SUM = 2;
    
    logic [1:0] state;
    
    LinearSystemTimeStep #(.N(N)) mySystem (.clk(clk_100mhz), .rst(rst), .K(K), .Gamma(Gamma),.yMinus_in(yMinus), .x_in(x), .yPlus_in(yPlus), .v_in(v), .F_d(F_d), 
                                            .inputsValid(inputsValid), .resetAccum(resetAccum),
                                            .x_out(x_new), .v_out(v_new), .outputsValid(outputsValid), .inputsReady(inputsReady),
                                            .accumOut(accumOut), .accumOutValid(accumOutValid), .accumIDValid(accumIDValid)
                                  );
                                  
    logic [5:0] addrRead;
    logic [5:0] addrWrite;
    logic wea;
    logic direction;
    logic [31:0] xMem_in [N-1:0];
    logic [31:0] vMem_in [N-1:0]; 
    logic [31:0] xMem_out [N-1:0]; 
    logic [31:0] vMem_out [N-1:0];
                                  
    memReadWrite #(.N(N), .width(32*N)) myMem(.clk(clk_100mhz), .addrRead(addrRead), .addrWrite(addrWrite), .wea(wea), .direction(direction),
                        .x_in(xMem_in), .v_in(vMem_in), .x_out(xMem_out), .v_out(vMem_out));
    
    logic addrSet;
    logic firstReadComplete;
    logic readComplete;
    
    //calculate audioSig * scaleFactor 
    logic [31:0] multInA_scaleFactor;
    logic multInAValid_scaleFactor;
    logic multInAReady_scaleFactor; 
    logic [31:0] multInB_scaleFactor;
    logic multInBValid_scaleFactor;
    logic multInBReady_scaleFactor;
    logic [31:0] multOut_scaleFactor;
    logic multOutValid_scaleFactor;
    logic multOutReady_scaleFactor;
    logic [13:0] multID_scaleFactor;
    logic floatToFixedInAReady;
    
    assign multInA_scaleFactor = audioSig; //
    assign multInAValid_scaleFactor = 1; //
    assign multInB_scaleFactor = scaleFactor;
    assign multInBValid_scaleFactor = 1; //this is a constant
    assign multOutReady_scaleFactor = floatToFixedInAReady;
    
    fp_mult_s mult_scaleFactor( .aclk(clk_100mhz), .aresetn(rst), .s_axis_a_tvalid(multInAValid_scaleFactor), .s_axis_a_tready(multInAReady_scaleFactor), .s_axis_a_tdata(multInA_scaleFactor), .s_axis_a_tuser(14'b0),
                                .s_axis_b_tvalid(multInBValid_scaleFactor), .s_axis_b_tready(multInBReady_scaleFactor), .s_axis_b_tdata(multInB_scaleFactor), 
                                .m_axis_result_tdata(multOut_scaleFactor), .m_axis_result_tvalid(multOutValid_scaleFactor),.m_axis_result_tready(multOutReady_scaleFactor), .m_axis_result_tuser(multID_scaleFactor));
    
    
    
  //this is to convert the floating point position output (or eventually the accumulator ouptut)
  //into something the pwm module can handle.
  //for now, it's just a float to int converter, so the position/ sum of position needs to be tuned to be between -127. and 127.    
    logic [31:0] floatToFixedInA;
    logic floatToFixedInAValid;
    logic [31:0] floatToFixedOut;
    logic floatToFixedOutReady;
    logic floatToFixedOutValid;
    logic [13:0] floatToFixedID;
    
    fp_floatToFixed_s myFloatToFixed(   .aclk(clk_100mhz), .aresetn(rst), .s_axis_a_tdata(floatToFixedInA), .s_axis_a_tvalid(floatToFixedInAValid),
                                        .s_axis_a_tready(floatToFixedInAReady), .s_axis_a_tuser(multID_scaleFactor),
                                        .m_axis_result_tdata(floatToFixedOut), .m_axis_result_tvalid(floatToFixedOutValid),
                                        .m_axis_result_tready(floatToFixedOutReady), .m_axis_result_tuser(floatToFixedID));
                                        
    assign floatToFixedInAValid = multOutValid_scaleFactor;
    assign floatToFixedOutReady = 1;
   // assign floatToFixedInA = multOut_scaleFactor;
    assign floatToFixedInAValid = multOutValid_scaleFactor;
    always_comb begin
        floatToFixedInA = multOut_scaleFactor;
    end
    
    
    logic [7:0] aud_out;
    logic [31:0] aud_outTemp;
    
    assign aud_outTemp = floatToFixedOut + 127; 
    always_comb begin
        if(aud_outTemp > 255) begin
            aud_out =  255;
        end else if(aud_outTemp < 0) begin
            aud_out = 0;
        end else begin
            aud_out = aud_outTemp[7:0];
        end
    end       
                         
    pwm myPwm(.clk_in(clk_100mhz), .rst_in(!rst), .level_in(aud_out), .pwm_out(aud_pwm));
    
    logic newDataFlag;
    
    vio_0 myVio(.clk(clk_100mhz), .probe_out0(K), .probe_out1(Gamma), .probe_out2(scaleFactor), .probe_out3(sampleDelay), .probe_out4(switch_axis_hold));
    always_ff @(posedge clk_100mhz)begin
        if(!rst)begin
            for(int i = 0;  i < N; i = i+1)begin    
                x[i] <= 0;
                yMinus[i] <= 0;
                yPlus[i] <= 0;
                v[i] <= 0;
                F_d[i] <= 0;
             end
    //        floatToFixedInA <= 0;
            outputsValidOld <= 0;
            accumOutValidOld <= 0;
            inputsValid <= 1;  
            newDataFlag <= 0; 
            m <= 0;
            outputsValidOld <= 0;
            accumOutValidOld <= 0;
            inputsValid <= 0;
            counter <= 0;
            direction <= 1;
            addrSet <= 0;
            newDataFlag <= 0;
            state <= IDLE;

        end else begin //end in reset if
        
            //keep track of the old states where edges are relevant
            accumIDValidOld <= accumIDValid;
            accumOutValidOld <= accumOutValid;
            outputsValidOld <= outputsValid;
              
            //set the driving force based on the state of the buttons  
            if(btnu == 1)begin
                F_mag <= 32'h48d6d800;
                n_f <= 25;
                m_f <= 12;
            end else if(btnl == 1)begin
                F_mag <= 32'h48d6d800;
                n_f <= 12;
                m_f <= 12;
            end else if(btnr == 1)begin
                F_mag <= 32'h48d6d800;
                n_f <= 3;
                m_f <= 5;
            /* 11-30-2022 - commenting out force inputs from pad since they weren't working */
           /* end else if (f_out) begin
                F_mag <= f_out;
                n_f <= x_out;
                m_f <= y_out;*/
            end else begin
                F_mag <= 0;
                n_f <= 0;
                m_f <= 0;
            end
        
            case(state)
                IDLE: begin
                //in the idle state, we are waiting for the counter to exceed a certain value before we begin a calculation
                    resetAccum <= 1; //deassert accum reset
                    if(counter > sampleDelay)begin
                        state <= STREAM; //if the counter has overflowed, move onto the stream state
                        counter <= 0;
                        m <= 0; //set m to zero to start the streaming process
                        firstReadComplete <= 0;
                        readComplete <= 0;
                        addrSet <= 0;
                        direction <= !direction;
                    end else begin
                        counter <= counter + 1;
                    end
                end
                
                STREAM: begin
                //in the stream state, iterate through all of the m values, read appropriate values from ram, and assign appropriate inputs, and catch outputs
                    //set the force
                    if(m == m_f)begin
                        F_d[n_f] <= F_mag;
                    end else begin
                        for(int i = 0; i < N; i = i+1)begin
                            F_d[n_f] <= 0;
                        end
                    end
                    //read in and set the positions
                    if(m == 0)begin //if on the left boundary
                        //set the left boundary to zero
                        for(int i = 0; i < N; i = i+1)begin
                            yMinus[i] <= 0;
                        end
                        if(!readComplete)begin
                            //read in the n+1 position
                            if(!firstReadComplete) begin//read in the n+1 position
                                if(!addrSet)begin
                                    addrRead <= m + 1;
                                    addrSet <= 1;
                                end else begin
                                    yPlus <= xMem_out;
                                    firstReadComplete <= 1;
                                    addrSet <= 0;
                                end
                            end else begin  //read in the n position and velocity //if first read complete
                                if(!addrSet)begin
                                    addrRead <= m;
                                    addrSet <= 1;
                                end else begin
                                    x <= xMem_out;
                                    v <= vMem_out;
                                    addrSet <= 0;
                                    readComplete <= 1;
                                end
                            end
                        end else begin //if both reads are complete
                            if(outputsValid && (outputsValid != outputsValidOld))begin //if outputs are recieved
                                xMem_in <= x_new; //pass the new outputs to the inputs of the memory
                                vMem_in <= v_new;
                                addrWrite <= m; //pass the correct address to the memory
                                addrSet <= 1; //assert that we have set everything for the adresses
                            end else begin
                                if(addrSet)begin //if we have just gotten an output, and passed it to the memory module,
                                    inputsValid <= 0; //deassert input values since we just got their output
                                    if(wea == 0)begin //if the data hasn't been written to the memory, assert the wea signal
                                        wea <= 1;
                                    end else begin //if the wea has been asserted
                                        wea <= 0; //deassert wea
                                        addrSet <= 0; // deassert addr set
                                        m <= m + 1; //increment to the next address location
                                        readComplete <= 0; //reset the read complete values
                                        firstReadComplete <= 0;
                                        yMinus <= x; //the x value is the yMinus in the next address
                                    end
                                end else begin //if the reads are complete, but the output address hasn't been set, validate inputs
                                    inputsValid <= 1; //if the reads are complete, but the outputs aren't ready, that must mean we need to validate the inputs
                                end    
                            end
                        end
                       
                    end else if( m == M-1)begin //if on the right boundary
                        //read in x[n] and v[n]
                        if(!readComplete)begin
                            if(!addrSet)begin
                                addrRead <= m;
                                addrSet <= 1;
                            end else begin
                                x <= xMem_out;
                                v <= vMem_out;
                                addrSet <= 0;
                                readComplete <= 1;
                            end
                        end else begin //if both reads are complete
                            if(outputsValid && (outputsValid != outputsValidOld))begin //if outputs are recieved
                                xMem_in <= x_new; //pass the new outputs to the inputs of the memory
                                vMem_in <= v_new;
                                addrWrite <= m; //pass the correct address to the memory
                                addrSet <= 1; //assert that we have set everything for the adresses
                            end else begin
                                if(addrSet)begin //if we have just gotten an output, and passed it to the memory module,
                                    inputsValid <= 0; //deassert input values since we just got their output
                                    if(wea == 0)begin //if the data hasn't been written to the memory, assert the wea signal
                                        wea <= 1;
                                    end else begin //if the wea has been asserted
                                        wea <= 0; //deassert wea
                                        addrSet <= 0; // deassert addr set
                                        readComplete <= 0; //reset the read complete values
                                        state <= SUM; //since we are at the end of the calculation now, we should move on to sum
                                    end
                                end else begin //if the reads are complete, but the output address hasn't been set, validate inputs
                                    inputsValid <= 1; //if the reads are complete, but the outputs aren't ready, that must mean we need to validate the inputs
                                end    
                            end
                        end
                        
                        //read in the n position and velocity
                        //set right boundary to zero
                        for(int i = 0;  i < N; i=i+1)begin
                            yPlus[i] <= 0;
                        end
                    end else begin //if we are on a middle column
                        //read in the n+1 position
                        
                        //read in the n position and velocity
                        if(!readComplete)begin
                            //read in the n+1 position
                            if(!firstReadComplete) begin//read in the n+1 position
                                if(!addrSet)begin
                                    addrRead <= m + 1;
                                    addrSet <= 1;
                                end else begin
                                    yPlus <= xMem_out;
                                    firstReadComplete <= 1;
                                    addrSet <= 0;
                                end
                            end else begin  //read in the n position and velocity //if first read complete
                                if(!addrSet)begin
                                    addrRead <= m;
                                    addrSet <= 1;
                                end else begin
                                    x <= xMem_out;
                                    v <= vMem_out;
                                    addrSet <= 0;
                                    readComplete <= 1;
                                end
                            end
                        end else begin //if both reads are complete
                            if(outputsValid && (outputsValid != outputsValidOld))begin //if outputs are recieved
                                xMem_in <= x_new; //pass the new outputs to the inputs of the memory
                                vMem_in <= v_new;
                                addrWrite <= m; //pass the correct address to the memory
                                addrSet <= 1; //assert that we have set everything for the adresses
                            end else begin
                                if(addrSet)begin //if we have just gotten an output, and passed it to the memory module,
                                    inputsValid <= 0; //deassert input values since we just got their output
                                    if(wea == 0)begin //if the data hasn't been written to the memory, assert the wea signal
                                        wea <= 1;
                                    end else begin //if the wea has been asserted
                                        wea <= 0; //deassert wea
                                        addrSet <= 0; // deassert addr set
                                        m <= m + 1; //increment to the next address location
                                        readComplete <= 0; //reset the read complete values
                                        
                                        yMinus <= x; //the x value is the yMinus in the next address
                                    end
                                end else begin //if the reads are complete, but the output address hasn't been set, validate inputs
                                    inputsValid <= 1; //if the reads are complete, but the outputs aren't ready, that must mean we need to validate the inputs
                                end    
                            end
                        end
                    end
                end
                
                SUM: begin
                        //wait for the next valid accumulator result
                    if(accumIDValid && accumIDValid != accumIDValidOld)begin //once the new (and last) result is available...
                       audioSig <= accumOut; //store the accumulator
                       resetAccum <= 0; //reset the accumulator
                       state <= IDLE; //return to the idle state;
                    end else begin
                        resetAccum <= 1;
                    end
                    
                end
            endcase   
            
        end //end not in reset if
    end //end always
    
    
endmodule


//PWM generator for audio generation!
module pwm (input clk_in, input rst_in, input [7:0] level_in, output logic pwm_out);
  logic [7:0] count;
  assign pwm_out = count<level_in;
  always_ff @(posedge clk_in)begin
    if (rst_in) count <= 8'b0;
    else count <= count+8'b1;
  end
  
endmodule