`timescale 1ns / 1ps


module LinearSystemTimeStep_tb;
    logic clk = 0;
    logic rst = 1;
    
    parameter N = 5; //the number of rows
    parameter M = 5; //the number of columns
    
    logic [31:0] Gamma = 32'hc3160000; //the damping constant of -250 (absorb the negative into the damping constant;
    logic [31:0] K = 32'h4c8f0d18; //4E6, just a random big number;
    
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
    
    logic [5:0] m; //use this to keep track of which column we are on
    
    parameter IDLE = 0;
    parameter STREAM = 1;
    parameter SUM = 2;
    
    logic [1:0] state;
    
    LinearSystemTimeStep #(.N(N)) mySystem (.clk(clk), .rst(rst), .K(K), .Gamma(Gamma),.yMinus_in(yMinus), .x_in(x), .yPlus_in(yPlus), .v_in(v), .F_d(F_d), 
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
                                  
    memReadWrite #(.N(N), .width(32*N)) myMem(.clk(clk), .addrRead(addrRead), .addrWrite(addrWrite), .wea(wea), .direction(direction),
                        .x_in(xMem_in), .v_in(vMem_in), .x_out(xMem_out), .v_out(vMem_out));
    
    logic addrSet;
    logic firstReadComplete;
    logic readComplete;
    
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
        n_f = 2;
        m_f = 3;      
        F_mag = 32'h48d6d800;
        #100000;
        F_mag = 0;//32'h3a83126f;
        
    end
    
    logic outputsValidOld = 0;
    logic accumOutValidOld = 0; 
    always_ff @(posedge clk)begin
        if(!rst)begin
            for(int i = 0; i < N; i = i+1)begin
                x[i] <= 0;
                v[i] <= 0;
                
                yMinus[i] <= 0;
                yPlus[i] <= 0;
            end
            m <= 0;
            outputsValidOld <= 0;
            accumOutValidOld <= 0;
            inputsValid <= 0;
            counter <= 0;
            direction <= 1;
            addrSet <= 0;
            
            state <= IDLE;
        end else begin
            accumIDValidOld <= accumIDValid;
            accumOutValidOld <= accumOutValid;
            outputsValidOld <= outputsValid;
            
            
            case(state)
                IDLE: begin
                //in the idle state, we are waiting for the counter to exceed a certain value before we begin a calculation
                    resetAccum <= 1; //deassert accum reset
                    if(counter > 100)begin
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
                        F_d[n_f] = F_mag;
                    end else begin
                        for(int i = 0; i < N; i = i+1)begin
                            F_d[n_f] = 0;
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
                        for(int i = 0;  i < N; i = i+1)begin
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
            
            
//            if(outputsValid && (outputsValid != outputsValidOld))begin
//                inputsValid <= 0;
//                x <= x_new;
//                v <= v_new;
//                yMinus <= x_new;
//                yPlus <= x_new;
//            end else begin
//                inputsValid <= 1;
//            end
            
//            if(accumIDValid && accumIDValid != accumIDValidOld)begin
//               audioSig <= accumOut;
//               resetAccum <= 0; 
//            end else begin
//                resetAccum <= 1;
//            end
        end
    end
    
    
endmodule
