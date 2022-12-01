//`default_nettype none
/*Author:Ben Sheffer
Description: This module is a version of the singleMassTimeStep1D module that is fully pipelined.
This requires floating point modules to access inputs stored in memory...*/


module LinearSystemTimeStep #(parameter N = 3)( //this parameter is how many masses are in the string
        input clk, input rst, input [31:0] yMinus_in [N-1:0], input [31:0] x_in [N-1:0], input [31:0] yPlus_in [N-1:0],
        input [31:0] v_in [N-1:0],input [31:0] F_d [N-1:0], input inputsValid, input [31:0] Gamma,  input [31:0] K,
        input resetAccum,
        
        output logic [31:0] x_out [N-1:0], output logic [31:0] v_out [N-1:0], output logic outputsValid, output logic inputsReady,
        output logic [31:0] accumOut, output logic accumOutValid , output logic accumIDValid

    );
 /*******************state machine******************************/   
    //define states
    parameter RESET = 0;
    parameter IDLE = 1;
    parameter STREAM = 2;
    parameter SUM = 3;
    
     logic [5:0] state = 0; //use this to control what phase of the calculation we are in
     
     logic[13:0] adderID_XNEWOld;
     logic [13:0] accumIDOld;
    
    parameter resetDelay = 2;
    logic [3:0] accumResetCounter = 0;
    logic accumRst = 1;
   
    logic [13:0] n = 0; //use this to iterate through the array indices 
    
    always_ff @(posedge clk)begin
        //handle catching outputs separately from inputs
        adderID_XNEWOld <= adderID_XNEW;
        accumIDOld <= accumID;
        if(addOutValid_XNEW == 1)begin //if new data is being updated
            x_out[adderID_XNEW] <= addOut_XNEW;
            //v_out[outputID_vnewDelayed[delaySteps-1]] <= v_newDelayed[delaySteps-1]; 
        end
        
        if(addOutValid_VNEW == 1)begin
            v_out[adderID_VNEW] <= addOut_VNEW;
        end
        
        case(state)
            RESET: begin
                inputsReady <= 0;
                outputsValid <= 0;
                accumOutValid <= 0;
                
                addInAValid_XPlusMinus <= 0;
                addInBValid_XPlusMinus <= 0;
                addInAValid_YPlusMinus <= 0;
                addInBValid_YPlusMinus <= 0;
                //multInAValid_GammaV <= 0;
                
                for(int i = 0; i < N; i = i+1)begin
                    //reset all x and v values
                    //x_out[i] <= 0;
                    //v_out[i] <= 0;
                   
                end //end for loop
                
                //reset the accumulator
                if(accumResetCounter < resetDelay)begin
                    accumResetCounter <= accumResetCounter + 1;
                    accumRst <= 0; //pull accumRst low
                end else begin
                    accumRst <= 1; //restore accumRst;
                    accumResetCounter <= 0;
                    state <= IDLE; //move onto idle state
                    inputsReady <= 1; //as we move to idle state, indicate that inputs are ready to be accepted
                end
            end //end reset state
            
            IDLE: begin //this state waits for inputs to appear
                //check for a reset condition
                if(!rst || !resetAccum)begin
                    state <= RESET;
                end else begin //if not in reset
                    if(inputsValid)begin //if the inputs are valid, i.e., the top level has passed new arrays into all input positions
                        if(addInAReady_XPlusMinus && addInBReady_XPlusMinus && addInAReady_YPlusMinus && addInBReady_YPlusMinus)begin //wait for beginning of pipeline to be ready
                            state <= STREAM; //enter the state of streaming data into the pipeline
                            inputsReady <= 0; //deassert inputs ready so that the toplevel will know not to update the inputs
                            outputsValid <= 0; //the outputs are about to get updated, so they are no longer valid
                            n <= 0; //reset n so that it will be ready to begin streaming data
                            addInAValid_XPlusMinus <= 1; //begin accepting data
                            addInBValid_XPlusMinus <= 1;
                            addInAValid_YPlusMinus <= 1;
                            addInBValid_YPlusMinus <= 1;
                           // multInAValid_GammaV <= 1;
                       end //end inReady if
                    end //end inputsValid if
                end //end reset else
                
            end //end idle state
            
            STREAM: begin
                //check for a reset condition
                if(!rst || !resetAccum)begin
                    state <= RESET;
                end else begin //if not in reset, begin iterating through all the data indices
                    if(addInAReady_XPlusMinus && addInBReady_XPlusMinus && addInAReady_YPlusMinus && addInBReady_YPlusMinus)begin
                       if(n < N-1)begin
                            addInAValid_XPlusMinus <= 1; //begin accepting data
                            addInBValid_XPlusMinus <= 1;
                            addInAValid_YPlusMinus <= 1;
                            addInBValid_YPlusMinus <= 1;
                           // multInAValid_GammaV <= 1;
                            n <= n+1;
                       end else if(n == N-1) begin
                            //if the last of the data has been streamed, deassert the valid signals at the top of the pipeline
                            addInAValid_XPlusMinus <= 0; //begin accepting data
                            addInBValid_XPlusMinus <= 0;
                            addInAValid_YPlusMinus <= 0;
                            addInBValid_YPlusMinus <= 0;
                           // multInAValid_GammaV <= 0;
                            //we now wait in this state until the last of the outputs comes out the back of the pipeline
                            if((adderID_XNEW == N - 1) && (adderID_XNEW != adderID_XNEWOld))begin //if the pipeline output has just reached the end of the data burst
                                outputsValid <= 1;
                                state <= SUM; //go to the sum state (i.e. wait for the accumulator results to be valid)
                            end else begin
                                outputsValid <= 0;
                            end //end output ID = N-1 if
                       end //end n == N-1 if
                    end //end inReady if
                end //end reset else
            end //end stream state
            
            SUM: begin
                //check for a reset condition
                if(!rst || !resetAccum)begin
                    state <= RESET;
                end else begin
                    if(accumID == N - 1 && accumID != accumIDOld)begin
                        state <=  IDLE;
                        inputsReady <= 1;
                        accumIDValid <= 1;
                    end else begin
                        accumIDValid <= 0;
                    end
                end //end reset else
            end //end sum state
        
        endcase
    
    
    end //end always_ff
    
    /**************end of state machine************************/
    
    
    /**********************beginning of floating point modules********************************/
    
    //accumulator
     logic [31:0] accumInA;
    logic accumInAReady;
    logic accumInAValid;
    logic accumOutReady;
    logic [13:0] accumID;
    logic [31:0] audioSig;
    logic tlastIn = 0;
    logic tlastOut;
    
    //logic resetAccum = 1; //active low reset signal for accumulator
    assign accumOutReady = 1;
    assign accumInAValid = addOutValid_XNEW;
    assign accumInA = addOut_XNEW;
    
    fp_accumulator_s myAccumulator( .aclk(clk), .aresetn(rst & accumRst), .s_axis_a_tvalid(accumInAValid), .s_axis_a_tlast(tlastIn),
                                    .s_axis_a_tready(accumInAReady), .s_axis_a_tdata(accumInA), .s_axis_a_tuser(adderID_XNEW),
                                    .m_axis_result_tdata(accumOut), .m_axis_result_tready(accumOutReady), .m_axis_result_tvalid(accumOutValid),
                                    .m_axis_result_tuser(accumID), .m_axis_result_tlast(tlastOut));
   
    
    //first we want to find F = K*(x_inPlus + x_inMinus - 2*x_in) -Gamma*v_in + F_d
    
    //first, calculate -4*x_in
    logic [31:0] x_in4X; //multiply x_in by negative 2
    logic x_in4XValid;
    logic [31:0] temp;
    //assign input B to correspond to the data streamed from adder_XPlusMinus
    always_comb begin
        temp = x_in[adderID_XTermInit];
        x_in4X[31] = !temp[31]; //multiply by negative 1
        x_in4X[30:23] = temp[30:23] + 2; //increase exponent by 1 to multiply by two
        x_in4X[22:0] = temp[22:0]; //preserve the base
        x_in4XValid = addOutValid_XTermInit; //delay the valid signal by one clock cycle 
    end
    
    //calculate yMinus + yPlus
    logic [31:0] addInA_YPlusMinus;
    logic addInAValid_YPlusMinus;
    logic addInAReady_YPlusMinus; 
    logic [31:0] addInB_YPlusMinus;
    logic addInBValid_YPlusMinus;
    logic addInBReady_YPlusMinus;
    logic [31:0] addOut_YPlusMinus;
    logic addOutReady_YPlusMinus;
    logic addOutValid_YPlusMinus; 
    logic [13:0] adderID_YPlusMinus;
    
    assign addInA_YPlusMinus = yMinus_in[n];
    //assign addInA_YPlusMinusValid;
    assign addInB_YPlusMinus = yPlus_in[n];
    //assign addInB_YPlusMinusValid;
    assign addOutReady_YPlusMinus = addInBReady_XTermInit;
    
    fp_adder_s adder_YPlusMinus(   .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(addInAValid_YPlusMinus), .s_axis_a_tready(addInAReady_YPlusMinus), .s_axis_a_tdata(addInA_YPlusMinus), .s_axis_a_tuser(n),
                                    .s_axis_b_tvalid(addInBValid_YPlusMinus),.s_axis_b_tready(addInBReady_YPlusMinus), .s_axis_b_tdata(addInB_YPlusMinus), 
                                    .m_axis_result_tdata(addOut_YPlusMinus),.m_axis_result_tvalid(addOutValid_YPlusMinus),.m_axis_result_tready(addOutReady_YPlusMinus), .m_axis_result_tuser(adderID_YPlusMinus));
    
    
    ////calculate x_inPlus + xinMinus 
    logic [31:0] addInA_XPlusMinus;
    logic addInAValid_XPlusMinus;
    logic addInAReady_XPlusMinus; 
    logic [31:0] addInB_XPlusMinus;
    logic addInBValid_XPlusMinus;
    logic addInBReady_XPlusMinus;
    logic [31:0] addOut_XPlusMinus;
    logic addOutReady_XPlusMinus;
    logic addOutValid_XPlusMinus; 
    logic [13:0] adderID_XPlusMinus;
    
    //handle upper and lower boundary conditions
    always_comb begin
        if(n == 0) begin
            addInB_XPlusMinus = 0;
            addInA_XPlusMinus = x_in[n+1];
        end else if(n == N-1)begin
            addInB_XPlusMinus = x_in[n-1];
            addInA_XPlusMinus = 0;
        end else begin
            addInB_XPlusMinus = x_in[n-1];
            addInA_XPlusMinus = x_in[n+1];
        end
    end

    assign addOutReady_XPlusMinus = addInAReady_XTermInit;
    
    fp_adder_s adder_XPlusMinus(   .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(addInAValid_XPlusMinus), .s_axis_a_tready(addInAReady_XPlusMinus), .s_axis_a_tdata(addInA_XPlusMinus), .s_axis_a_tuser(n),
                                .s_axis_b_tvalid(addInBValid_XPlusMinus),.s_axis_b_tready(addInBReady_XPlusMinus), .s_axis_b_tdata(addInB_XPlusMinus), 
                                .m_axis_result_tdata(addOut_XPlusMinus),.m_axis_result_tvalid(addOutValid_XPlusMinus),.m_axis_result_tready(addOutReady_XPlusMinus), .m_axis_result_tuser(adderID_XPlusMinus));
    
    //calculate XTermInit = (yPlus + yMinus) + (x_inPlus + x_inMinus)

    logic [31:0] addInA_XTermInit;
    logic addInAValid_XTermInit;
    logic addInAReady_XTermInit; 
    logic [31:0] addInB_XTermInit;
    logic addInBValid_XTermInit;
    logic addInBReady_XTermInit;
    logic [31:0] addOut_XTermInit;
    logic addOutReady_XTermInit;
    logic addOutValid_XTermInit; 
    logic [13:0] adderID_XTermInit;
    
    assign addInA_XTermInit = addOut_XPlusMinus; //assign this in the always block
    assign addInAValid_XTermInit = addOutValid_XPlusMinus;
    assign addInB_XTermInit = addOut_YPlusMinus; //assign this in the always block
    assign addInBValid_XTermInit = addOutValid_YPlusMinus; //assign this in the always block when the driving force is established
    assign addOutReady_XTermInit = addInAReady_XTerm & addInBReady_XTerm; //this feeds into INA of the KX multiplier
    
    fp_adder_s adder_XTermInit(   .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(addInAValid_XTermInit), .s_axis_a_tready(addInAReady_XTermInit), .s_axis_a_tdata(addInA_XTermInit), .s_axis_a_tuser(adderID_XPlusMinus),
                                .s_axis_b_tvalid(addInBValid_XTermInit),.s_axis_b_tready(addInBReady_XTermInit), .s_axis_b_tdata(addInB_XTermInit), 
                                .m_axis_result_tdata(addOut_XTermInit),.m_axis_result_tvalid(addOutValid_XTermInit),.m_axis_result_tready(addOutReady_XTermInit), .m_axis_result_tuser(adderID_XTermInit));

    
    ////calculate XTerm = XTermInit - 4*x_in = (yPlus + yMinus) + (x_inPlus + x_inMinus) - 4*x_in  
    logic [31:0] addInA_XTerm;
    logic addInAValid_XTerm;
    logic addInAReady_XTerm; 
    logic [31:0] addInB_XTerm;
    logic addInBValid_XTerm;
    logic addInBReady_XTerm;
    logic [31:0] addOut_XTerm;
    logic addOutReady_XTerm;
    logic addOutValid_XTerm; 
    logic [13:0] adderID_XTerm;
    
    assign addInA_XTerm = addOut_XTermInit; //assign this in the always block
    assign addInAValid_XTerm = addOutValid_XTermInit;
    assign addInB_XTerm = x_in4X; //assign this in the always block
    assign addInBValid_XTerm = x_in4XValid; //assign this in the always block when the driving force is established
    assign addOutReady_XTerm = multInAReady_KX; //this feeds into INA of the KX multiplier
    
    fp_adder_s adder_XTerm(   .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(addInAValid_XTerm), .s_axis_a_tready(addInAReady_XTerm), .s_axis_a_tdata(addInA_XTerm), .s_axis_a_tuser(adderID_XTermInit),
                                .s_axis_b_tvalid(addInBValid_XTerm),.s_axis_b_tready(addInBReady_XTerm), .s_axis_b_tdata(addInB_XTerm), 
                                .m_axis_result_tdata(addOut_XTerm),.m_axis_result_tvalid(addOutValid_XTerm),.m_axis_result_tready(addOutReady_XTerm), .m_axis_result_tuser(adderID_XTerm));
    
    
    //calculate -K*x_in   
    logic [31:0] multInA_KX;
    logic multInAValid_KX;
    logic multInAReady_KX; 
    logic [31:0] multInB_KX;
    logic multInBValid_KX;
    logic multInBReady_KX;
    logic [31:0] multOut_KX;
    logic multOutValid_KX;
    logic multOutReady_KX;
    logic [13:0] multID_KX; 
    
    assign multInA_KX = addOut_XTerm;
    assign multInAValid_KX = addOutValid_XTerm;
    assign multInB_KX = K;
    assign multInBValid_KX = multInAValid_KX; //this is a constant
    assign multOutReady_KX = addInAReady_F;// & multInAReady_FdtSq;
    
    fp_mult_s mult_KX(    .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(multInAValid_KX), .s_axis_a_tready(multInAReady_KX), .s_axis_a_tdata(multInA_KX), .s_axis_a_tuser(adderID_XTerm),
                                .s_axis_b_tvalid(multInBValid_KX), .s_axis_b_tready(multInBReady_KX), .s_axis_b_tdata(multInB_KX), 
                                .m_axis_result_tdata(multOut_KX), .m_axis_result_tvalid(multOutValid_KX),.m_axis_result_tready(multOutReady_KX), .m_axis_result_tuser(multID_KX));
    
    
    //calculate -Gamma*v_in
    logic [31:0] multInA_GammaV;
    logic multInAValid_GammaV;
    logic multInAReady_GammaV; 
    logic [31:0] multInB_GammaV;
    logic multInBValid_GammaV;
    logic multInBReady_GammaV;
    logic [31:0] multOut_GammaV;
    logic multOutValid_GammaV;
    logic multOutReady_GammaV;
    logic [13:0] multID_GammaV;
    
    assign multInA_GammaV = v_in[adderID_XPlusMinus]; //assign this to the velocity corresponding to mass n
    assign multInAValid_GammaV = addOutValid_XPlusMinus; //syncronize inputs to adder F by starting this stage after adder_XPlusMinus
    assign multInB_GammaV = Gamma;
    assign multInBValid_GammaV = multInAValid_GammaV; //this is a constant
    assign multOutReady_GammaV = addInAReady_FInit;
    
    fp_mult_s mult_GammaV(    .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(multInAValid_GammaV), .s_axis_a_tready(multInAReady_GammaV), .s_axis_a_tdata(multInA_GammaV), .s_axis_a_tuser(adderID_XPlusMinus),
                                .s_axis_b_tvalid(multInBValid_GammaV), .s_axis_b_tready(multInBReady_GammaV), .s_axis_b_tdata(multInB_GammaV), 
                                .m_axis_result_tdata(multOut_GammaV), .m_axis_result_tvalid(multOutValid_GammaV),.m_axis_result_tready(multOutReady_GammaV), .m_axis_result_tuser(multID_GammaV));
    
    
    //calculate F_d -Gamma*V_in 
    logic [31:0] addInA_FInit;
    logic addInAValid_FInit;
    logic addInAReady_FInit; 
    logic [31:0] addInB_FInit;
    logic addInBValid_FInit;
    logic addInBReady_FInit;
    logic [31:0] addOut_FInit;
    logic addOutReady_FInit;
    logic addOutValid_FInit; 
    logic [13:0] adderID_FInit;
    
    //assign addInA_F = multOut_KX;
    //assign addInAValid_F = multOutValid_KX;
    assign addInB_FInit = F_d[multID_GammaV]; //assign the driving force
    assign addInBValid_FInit = multOutValid_GammaV; //assign this in the always block when the driving force is established
    assign addInA_FInit = multOut_GammaV;
    assign addInAValid_FInit = multOutValid_GammaV;
    assign addOutReady_FInit = 1;//addInBReady_F;
    
    fp_adder_s adder_FInit(   .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(addInAValid_FInit), .s_axis_a_tready(addInAReady_FInit), .s_axis_a_tdata(addInA_FInit), .s_axis_a_tuser(multID_GammaV),
                                .s_axis_b_tvalid(addInBValid_FInit),.s_axis_b_tready(addInBReady_FInit), .s_axis_b_tdata(addInB_FInit), 
                                .m_axis_result_tdata(addOut_FInit),.m_axis_result_tvalid(addOutValid_FInit),.m_axis_result_tready(addOutReady_FInit), .m_axis_result_tuser(adderID_FInit));

    //calculate F = K*XTerm + (F_d - Gamma*V_in)
    logic [31:0] addInA_F;
    logic addInAValid_F;
    logic addInAReady_F; 
    logic [31:0] addInB_F;
    logic addInBValid_F;
    logic addInBReady_F;
    logic [31:0] addOut_F;
    logic addOutReady_F;
    logic addOutValid_F;
    logic [13:0] adderID_F;
    
    assign addInA_F = multOut_KX;
    assign addInAValid_F = multOutValid_KX;
    assign addInB_F = addOut_FInitDelayed[delaySteps-1];
    assign addInBValid_F = addOutValid_FInitDelayed[delaySteps-1];//addOutValid_FInit;
    assign addOutReady_F = multInAReady_Fdt;//& multInAReady_FdtSq;//??
    
    fp_adder_s adder_F(   .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(addInAValid_F), .s_axis_a_tready(addInAReady_F), .s_axis_a_tdata(addInA_F), .s_axis_a_tuser(multID_KX),
                                .s_axis_b_tvalid(addInBValid_F),.s_axis_b_tready(addInBReady_F), .s_axis_b_tdata(addInB_F), 
                                .m_axis_result_tdata(addOut_F),.m_axis_result_tvalid(addOutValid_F),.m_axis_result_tready(addOutReady_F), .m_axis_result_tuser(adderID_F));

    
    //Next,  we want to find x_new = x_in + v_in*dt + 1/2 * F * dt^2calculate 
    
    //calculate v_in*dt
    logic [31:0] multInA_Vdt;
    logic multInAValid_Vdt;
    logic multInAReady_Vdt; 
    logic [31:0] multInB_Vdt;
    logic multInBValid_Vdt;
    logic multInBReady_Vdt;
    logic [31:0] multOut_Vdt;
    logic multOutValid_Vdt;
    logic multOutReady_Vdt;
    logic [13:0] multID_Vdt;
    
    assign multInA_Vdt = addOut_VNEW;
    assign multInAValid_Vdt = addOutValid_VNEW;
    assign multOutReady_Vdt = addInAReady_XNEW;
    assign multInB_Vdt = 32'h37aec33c; //the dt value of 0.000020833333
    assign multInBValid_Vdt = multInAValid_Vdt; //this value is a constant
    
    fp_mult_s mult_Vdt(    .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(multInAValid_Vdt), .s_axis_a_tready(multInAReady_Vdt), .s_axis_a_tdata(multInA_Vdt), .s_axis_a_tuser(adderID_VNEW),
                                .s_axis_b_tvalid(multInBValid_Vdt), .s_axis_b_tready(multInBReady_Vdt), .s_axis_b_tdata(multInB_Vdt), 
                                .m_axis_result_tdata(multOut_Vdt), .m_axis_result_tvalid(multOutValid_Vdt),.m_axis_result_tready(multOutReady_Vdt), .m_axis_result_tuser(multID_Vdt));
    
    //calculate x_new = x_in + x_newInit = x_in + (v_in*dt + v_in*dt)
    logic [31:0] addInA_XNEW;
    logic addInAValid_XNEW;
    logic addInAReady_XNEW; 
    logic [31:0] addInB_XNEW;
    logic addInBValid_XNEW;
    logic addInBReady_XNEW;
    logic [31:0] addOut_XNEW;
    logic addOutReady_XNEW = 1'b1;
    logic addOutValid_XNEW;
    logic [13:0] adderID_XNEW;

    //input A comes from the output of the multiply
    assign addInA_XNEW = multOut_Vdt;
    assign addInAValid_XNEW = multOutValid_Vdt;
    assign addInB_XNEW = x_in[multID_Vdt];
    assign addInBValid_XNEW = addInAValid_XNEW; //in the always block after it gets updated
    
    fp_adder_s adder_XNEW(   .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(addInAValid_XNEW), .s_axis_a_tready(addInAReady_XNEW), .s_axis_a_tdata(addInA_XNEW), .s_axis_a_tuser(multID_Vdt),
                                .s_axis_b_tvalid(addInBValid_XNEW),.s_axis_b_tready(addInBReady_XNEW), .s_axis_b_tdata(addInB_XNEW), 
                                .m_axis_result_tdata(addOut_XNEW),.m_axis_result_tvalid(addOutValid_XNEW),.m_axis_result_tready(addOutReady_XNEW), .m_axis_result_tuser(adderID_XNEW));
    
    //now we want to find v_new = v_in + F*dt
    
    //calculate F*dt
    
    logic [31:0] multInA_Fdt;
    logic multInAValid_Fdt;
    logic multInAReady_Fdt; 
    logic [31:0] multInB_Fdt;
    logic multInBValid_Fdt;
    logic multInBReady_Fdt;
    logic [31:0] multOut_Fdt;
    logic multOutValid_Fdt;
    logic multOutReady_Fdt;
    logic [13:0] multID_Fdt;
    
    assign multInA_Fdt = addOut_F;
    assign multInAValid_Fdt = addOutValid_F;
    assign multInB_Fdt = 32'h37aec33c; //the dt value of 0.000020833333
    assign multInBValid_Fdt = multInAValid_Fdt; //this is a constant
    assign multOutReady_Fdt = addInAReady_VNEW;
    
    fp_mult_s mult_Fdt(    .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(multInAValid_Fdt), .s_axis_a_tready(multInAReady_Fdt), .s_axis_a_tdata(multInA_Fdt), .s_axis_a_tuser(adderID_F),
                                .s_axis_b_tvalid(multInBValid_Fdt), .s_axis_b_tready(multInBReady_Fdt), .s_axis_b_tdata(multInB_Fdt), 
                                .m_axis_result_tdata(multOut_Fdt), .m_axis_result_tvalid(multOutValid_Fdt),.m_axis_result_tready(multOutReady_Fdt), .m_axis_result_tuser(multID_Fdt));
       
     
    //calculate v_new = v_new + F*dt
    logic [31:0] addInA_VNEW;
    logic addInAValid_VNEW;
    logic addInAReady_VNEW; 
    logic [31:0] addInB_VNEW;
    logic addInBValid_VNEW;
    logic addInBReady_VNEW;
    logic [31:0] addOut_VNEW;
    logic addOutReady_VNEW;
    logic addOutValid_VNEW;
    logic [13:0] adderID_VNEW;
    
    assign addInA_VNEW = multOut_Fdt;
    assign addInAValid_VNEW = multOutValid_Fdt;
    assign addInB_VNEW = v_in[multID_Fdt];
    assign addInBValid_VNEW = addInAValid_VNEW;
    assign addOutReady_VNEW = multInAReady_Vdt;
    
    //assign addInB_VNew
    fp_adder_s adder_VNEW(   .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(addInAValid_VNEW), .s_axis_a_tready(addInAReady_VNEW), .s_axis_a_tdata(addInA_VNEW), .s_axis_a_tuser(multID_Fdt), //changed updateID to multID_Fdt
                                .s_axis_b_tvalid(addInBValid_VNEW),.s_axis_b_tready(addInBReady_VNEW), .s_axis_b_tdata(addInB_VNEW), 
                                .m_axis_result_tdata(addOut_VNEW),.m_axis_result_tvalid(addOutValid_VNEW),.m_axis_result_tready(addOutReady_VNEW), .m_axis_result_tuser(adderID_VNEW));
    


    //delay the v output to match the x output (give both variables the same latency)
    parameter delaySteps = 13;
    logic [31:0] v_newDelayed [delaySteps-1:0];
    logic [13:0] outputID_vnewDelayed [delaySteps-1:0];
    logic v_newDelayedValid [delaySteps-1:0];
    
    assign v_newDelayed[0] = addOut_VNEW;
    assign outputID_vnewDelayed[0] = adderID_VNEW; 
    assign v_newDelayedValid[0] = addOutValid_VNEW;
    
    logic [31:0] addOut_FInitDelayed [delaySteps-1:0];
    logic [13:0] adderID_FInitDelayed [delaySteps-1:0];
    logic addOutValid_FInitDelayed [delaySteps-1:0];
    logic [13:0] adderID_FInitDelayedFinal;
    assign adderID_FInitDelayedFinal = adderID_FInitDelayed[delaySteps-1];
    
    assign addOut_FInitDelayed[0] = addOut_FInit;
    assign adderID_FInitDelayed[0] = adderID_FInit;
    assign addOutValid_FInitDelayed[0] = addOutValid_FInit;
    
    always_ff @(posedge clk)begin
    
        if(!rst)begin
            for(int i = 1; i < delaySteps; i = i+1)begin
                v_newDelayed[i] <= 0;
                outputID_vnewDelayed[i] <= 0;
                v_newDelayedValid[i] <= 0; 
                
                addOut_FInitDelayed[i] <= 0;
                adderID_FInitDelayed[i] <= 0;
                addOutValid_FInitDelayed[i] <= 0;
            end
        end else begin    
            for(int i = 1; i < delaySteps; i = i+1)begin
                v_newDelayed[i] <= v_newDelayed[i-1];
                outputID_vnewDelayed[i] <= outputID_vnewDelayed[i-1];
                v_newDelayedValid[i] <= v_newDelayedValid[i-1]; 
                
                addOut_FInitDelayed[i] <= addOut_FInitDelayed[i-1];
                adderID_FInitDelayed[i] <= adderID_FInitDelayed[i-1];
                addOutValid_FInitDelayed[i] <= addOutValid_FInitDelayed[i-1];
            end
        end
    end
    
    /*******************end of floating point modules********************/
    
    
endmodule
