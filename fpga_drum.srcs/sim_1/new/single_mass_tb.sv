`timescale 1ns / 1ps
`default_nettype none

module single_mass_tb;
    logic clk = 0;
    logic rst = 1;
    
    
    
    logic XREADYFLAG;
    logic VREADYFLAG;
    
    logic [31:0] addInA_XNEW;
    logic addInAValid_XNEW;
    logic addInAReady_XNEW; 
    logic [31:0] addInB_XNEW;
    logic addInBValid_XNEW = 0;
    logic addInBReady_XNEW;
    logic [31:0] addOut_XNEW;
    logic addOutReady_XNEW = 1'b1;
    logic addOutValid_XNEW;
    
    logic [31:0] addInA_XNEWInit;
    logic addInAValid_XNEWInit;
    logic addInAReady_XNEWInit; 
    logic [31:0] addInB_XNEWInit;
    logic addInBValid_XNEWInit;
    logic addInBReady_XNEWInit;
    logic [31:0] addOut_XNEWInit;
    logic addOutReady_XNEWInit;
    logic addOutValid_XNEWInit;
    
    logic [31:0] multInA_Vdt;
    logic multInAValid_Vdt;
    logic multInAReady_Vdt; 
    logic [31:0] multInB_Vdt;
    logic multInBValid_Vdt;
    logic multInBReady_Vdt;
    logic [31:0] multOut_Vdt;
    logic multOutValid_Vdt;
    logic multOutReady_Vdt;
    logic [13:0] updateID;
    
    
    logic [31:0] multInA_KX;
    logic multInAValid_KX;
    logic multInAReady_KX; 
    logic [31:0] multInB_KX;
    logic multInBValid_KX;
    logic multInBReady_KX;
    logic [31:0] multOut_KX;
    logic multOutValid_KX;
    logic multOutReady_KX;
    
    
    logic [31:0] addInA_VNEW;
    logic addInAValid_VNEW;
    logic addInAReady_VNEW; 
    logic [31:0] addInB_VNEW;
    logic addInBValid_VNEW = 0;
    logic addInBReady_VNEW;
    logic [31:0] addOut_VNEW;
    logic addOutReady_VNEW = 1'b1;
    logic addOutValid_VNEW;
    
    
    
    
    logic [31:0] multInA_Fdt;
    logic multInAValid_Fdt;
    logic multInAReady_Fdt; 
    logic [31:0] multInB_Fdt;
    logic multInBValid_Fdt;
    logic multInBReady_Fdt;
    logic [31:0] multOut_Fdt;
    logic multOutValid_Fdt;
    logic multOutReady_Fdt;
    
    
    logic [31:0] addInA_VNEW;
    logic addInAValid_VNEW;
    logic addInAReady_VNEW; 
    logic [31:0] addInB_VNEW;
    logic addInBValid_VNEW = 0;
    logic addInBReady_VNEW;
    logic [31:0] addOut_VNEW;
    logic addOutReady_VNEW = 1'b1;
    logic addOutValid_VNEW;
    
    logic [31:0] multInA_FdtSq;
    logic multInAValid_FdtSq;
    logic multInAReady_FdtSq; 
    logic [31:0] multInB_FdtSq;
    logic multInBValid_FdtSq;
    logic multInBReady_FdtSq;
    logic [31:0] multOut_FdtSq;
    logic multOutValid_FdtSq;
    logic multOutReady_FdtSq;
    
    logic [31:0] multInA_GammaV;
    logic multInAValid_GammaV;
    logic multInAReady_GammaV; 
    logic [31:0] multInB_GammaV;
    logic multInBValid_GammaV;
    logic multInBReady_GammaV;
    logic [31:0] multOut_GammaV;
    logic multOutValid_GammaV;
    logic multOutReady_GammaV;
    
    logic [31:0] addInA_F;
    logic addInAValid_F;
    logic addInAReady_F; 
    logic [31:0] addInB_F;
    logic addInBValid_F;
    logic addInBReady_F;
    logic [31:0] addOut_F;
    logic addOutReady_F;
    logic addOutValid_F;
    
    logic [31:0] addInA_FInit;
    logic addInAValid_FInit;
    logic addInAReady_FInit; 
    logic [31:0] addInB_FInit;
    logic addInBValid_FInit;
    logic addInBReady_FInit;
    logic [31:0] addOut_FInit;
    logic addOutReady_FInit;
    logic addOutValid_FInit;
    
    logic [31:0] F_d = 0; //driving force
    
    logic [31:0] x;
    logic [31:0] v;
        
        
    logic [13:0] multID;
    logic [13:0] multID_KX;   
    logic [13:0] multID_Fdt;
    logic [13:0] multID_Vdt; 
    logic [13:0] adderID_XNEW;
    logic [13:0] adderID_VNEW;
    
    //assign multInA_KX = x;
    //set multInAValid_KX in the always block when x gets updated
    assign multInB_KX = 32'hcaf42400; //-8E6, just a random big number
    assign multInBValid_KX = 1'b1; //this is a constant
    assign multOutReady_KX = addInAReady_F;// & multInAReady_FdtSq;
    
    fp_mult_s mult_KX(    .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(multInAValid_KX), .s_axis_a_tready(multInAReady_KX), .s_axis_a_tdata(multInA_KX), .s_axis_a_tuser(updateID),
                                .s_axis_b_tvalid(multInBValid_KX), .s_axis_b_tready(multInBReady_KX), .s_axis_b_tdata(multInB_KX), 
                                .m_axis_result_tdata(multOut_KX), .m_axis_result_tvalid(multOutValid_KX),.m_axis_result_tready(multOutReady_KX), .m_axis_result_tuser(multID_KX));
    

    logic [13:0] adderID_FInit;
    //assign addInA_F = multOut_KX;
    //assign addInAValid_F = multOutValid_KX;
    assign addInB_FInit = F_d; //assign the driving force
    assign addInBValid_FInit = 1; //assign this in the always block when the driving force is established
    assign addInA_FInit = multOut_GammaV;
    assign addInAValid_FInit = multOutValid_GammaV;
    
    assign addOutReady_FInit = addInBReady_F;
    
    fp_adder_s adder_FInit(   .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(addInAValid_FInit), .s_axis_a_tready(addInAReady_FInit), .s_axis_a_tdata(addInA_FInit), .s_axis_a_tuser(multID_GammaV),
                                .s_axis_b_tvalid(addInBValid_FInit),.s_axis_b_tready(addInBReady_FInit), .s_axis_b_tdata(addInB_FInit), 
                                .m_axis_result_tdata(addOut_FInit),.m_axis_result_tvalid(addOutValid_FInit),.m_axis_result_tready(addOutReady_FInit), .m_axis_result_tuser(adderID_FInit));
    


    logic [13:0] adderID_F;
    assign addInA_F = multOut_KX;
    assign addInAValid_F = multOutValid_KX;
    assign addInB_F = addOut_FInit;
    assign addInBValid_F = addOutValid_FInit;
    
    assign addOutReady_F = multInAReady_Fdt& multInAReady_FdtSq;//??
    
    fp_adder_s adder_F(   .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(addInAValid_F), .s_axis_a_tready(addInAReady_F), .s_axis_a_tdata(addInA_F), .s_axis_a_tuser(adderID_FInit),
                                .s_axis_b_tvalid(addInBValid_F),.s_axis_b_tready(addInBReady_F), .s_axis_b_tdata(addInB_F), 
                                .m_axis_result_tdata(addOut_F),.m_axis_result_tvalid(addOutValid_F),.m_axis_result_tready(addOutReady_F), .m_axis_result_tuser(adderID_F));
    
    
    //assign multInA_GammaV = v; //set this in the always block when v gets updated
    //assign multInAValid_GammaV; //set this in the always block when v gets updated
    assign multInB_GammaV = 32'hc2fa0000; //the damping constant of -125 (absorb the negative into the damping constant
    assign multInBValid_GammaV = 1;
    
    assign multOutReady_GammaV = addInBReady_F;
    logic [13:0] multID_GammaV;
    
    fp_mult_s mult_GammaV(    .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(multInAValid_GammaV), .s_axis_a_tready(multInAReady_GammaV), .s_axis_a_tdata(multInA_GammaV), .s_axis_a_tuser(updateID),
                                .s_axis_b_tvalid(multInBValid_GammaV), .s_axis_b_tready(multInBReady_GammaV), .s_axis_b_tdata(multInB_GammaV), 
                                .m_axis_result_tdata(multOut_GammaV), .m_axis_result_tvalid(multOutValid_GammaV),.m_axis_result_tready(multOutReady_GammaV), .m_axis_result_tuser(multID_GammaV));
    
    
    
    
    assign multInA_Fdt = addOut_F;
    assign multInAValid_Fdt = addOutValid_F;
    assign multInB_Fdt = 32'h37aec33c; //the dt value of 0.000020833333
    assign multInBValid_Fdt = 1'b1; //this is a constant
    assign multOutReady_Fdt = addInAReady_VNEW;
    
    fp_mult_s mult_Fdt(    .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(multInAValid_Fdt), .s_axis_a_tready(multInAReady_Fdt), .s_axis_a_tdata(multInA_Fdt), .s_axis_a_tuser(adderID_F),
                                .s_axis_b_tvalid(multInBValid_Fdt), .s_axis_b_tready(multInBReady_Fdt), .s_axis_b_tdata(multInB_Fdt), 
                                .m_axis_result_tdata(multOut_Fdt), .m_axis_result_tvalid(multOutValid_Fdt),.m_axis_result_tready(multOutReady_Fdt), .m_axis_result_tuser(multID_Fdt));
    logic [13:0] multID_FdtSq;
    logic signBit;
    assign signBit = multOut_KX[31];
    
    logic [31:0] Fdiv2;
    logic Fdiv2Valid;
    
    assign multInA_FdtSq = addOut_F;//Fdiv2;//{signBit,(multOut_KX[30:23] - 1), multOut_KX[22:0]}; //divide F by 2 by subtracting one from the exponent
    assign multInAValid_FdtSq = addOutValid_F;//multOutValid_KX;
    assign multInB_FdtSq = 32'h2f6e9bc8; //(0.0000208333)^2 / 2 in floating point format, or dt^2
    assign multInBValid_FdtSq = 1;
    assign multOutReady_FdtSq = addInBReady_XNEWInit;
    
    fp_mult_s mult_FdtSq(    .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(multInAValid_FdtSq), .s_axis_a_tready(multInAReady_FdtSq), .s_axis_a_tdata(multInA_FdtSq), .s_axis_a_tuser(adderID_F),
                                .s_axis_b_tvalid(multInBValid_FdtSq), .s_axis_b_tready(multInBReady_FdtSq), .s_axis_b_tdata(multInB_FdtSq), 
                                .m_axis_result_tdata(multOut_FdtSq), .m_axis_result_tvalid(multOutValid_FdtSq),.m_axis_result_tready(multOutReady_FdtSq), .m_axis_result_tuser(multID_FdtSq));
    
    logic [13:0] adderID_XNEWInit;
    assign addInA_XNEWInit = multOut_Vdt;
    assign addInAValid_XNEWInit = multOutValid_Vdt;
    assign addInB_XNEWInit = multOut_FdtSq;
    assign addInBValid_XNEWInit = multOutValid_FdtSq;
    
    assign addOutReady_XNEWInit = addInAReady_XNEW;
    
    fp_adder_s adder_XNEWInit(   .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(addInAValid_XNEWInit), .s_axis_a_tready(addInAReady_XNEWInit), .s_axis_a_tdata(addInA_XNEWInit), .s_axis_a_tuser(multID_FdtSq),
                                .s_axis_b_tvalid(addInBValid_XNEWInit),.s_axis_b_tready(addInBReady_XNEWInit), .s_axis_b_tdata(addInB_XNEWInit), 
                                .m_axis_result_tdata(addOut_XNEWInit),.m_axis_result_tvalid(addOutValid_XNEWInit),.m_axis_result_tready(addOutReady_XNEWInit), .m_axis_result_tuser(adderID_XNEWInit));
    
    
    assign addInA_VNEW = multOut_Fdt;
    assign addInAValid_VNEW = multOutValid_Fdt;
    //assign addInB_VNew
    fp_adder_s adder_VNEW(   .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(addInAValid_VNEW), .s_axis_a_tready(addInAReady_VNEW), .s_axis_a_tdata(addInA_VNEW), .s_axis_a_tuser(multID_Fdt), //changed updateID to multID_Fdt
                                .s_axis_b_tvalid(addInBValid_VNEW),.s_axis_b_tready(addInBReady_VNEW), .s_axis_b_tdata(addInB_VNEW), 
                                .m_axis_result_tdata(addOut_VNEW),.m_axis_result_tvalid(addOutValid_VNEW),.m_axis_result_tready(addOutReady_VNEW), .m_axis_result_tuser(adderID_VNEW));
    
    
    //input A comes from the output of the multiply
    assign addInA_XNEW = addOut_XNEWInit;
    assign addInAValid_XNEW = addOutValid_XNEWInit;
    //assign addInB_XNEW = x;
    //assign the addInBValid in the always block after it gets updated
    
    fp_adder_s adder_XNEW(   .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(addInAValid_XNEW), .s_axis_a_tready(addInAReady_XNEW), .s_axis_a_tdata(addInA_XNEW), .s_axis_a_tuser(adderID_XNEWInit),
                                .s_axis_b_tvalid(addInBValid_XNEW),.s_axis_b_tready(addInBReady_XNEW), .s_axis_b_tdata(addInB_XNEW), 
                                .m_axis_result_tdata(addOut_XNEW),.m_axis_result_tvalid(addOutValid_XNEW),.m_axis_result_tready(addOutReady_XNEW), .m_axis_result_tuser(adderID_XNEW));
    
    
    assign multOutReady_Vdt = addInAReady_XNEWInit;
    
    
    assign multInB_Vdt = 32'h37aec33c; //the dt value of 0.000020833333
    assign multInBValid_Vdt = 1'b1; //this value is a constant
    
    fp_mult_s mult_Vdt(    .aclk(clk), .aresetn(rst), .s_axis_a_tvalid(multInAValid_Vdt), .s_axis_a_tready(multInAReady_Vdt), .s_axis_a_tdata(multInA_Vdt), .s_axis_a_tuser(updateID),
                                .s_axis_b_tvalid(multInBValid_Vdt), .s_axis_b_tready(multInBReady_Vdt), .s_axis_b_tdata(multInB_Vdt), 
                                .m_axis_result_tdata(multOut_Vdt), .m_axis_result_tvalid(multOutValid_Vdt),.m_axis_result_tready(multOutReady_Vdt), .m_axis_result_tuser(multID_Vdt));
    
    always begin
        #5;
        clk = !clk;
    end
    
    initial begin
        rst = 0;
        F_d <= 0;
        #30;
        rst <= 1;        
        F_d <= 32'h47c35000;
        #10000;
        F_d = 0;
        
    end
    
    
    always_ff @(posedge clk)begin
        //Fdiv2 <= {signBit,(multOut_KX[30:23] - 1), multOut_KX[22:0]};
        if(!rst)begin
        //may need to check these values a bit...
            addInB_XNEW <= 0;//32'h41200000;//32'h0ad7233C;//{1'b0,8'd130,23'b100_0000_0000_0000_0000_0000};
            addInBValid_XNEW <= 1;
            multInA_KX <= 0;//32'h41200000;
            multInAValid_KX <= 1;
            
            multInA_Vdt <= 0;//32'h3c23d70a;//{1'b1,8'd118,23'b000_0000_0000_0000_0000_0000};//32'hACC52737;//{1'b0,8'd130,23'b100_0000_0000_0000_0000_0000};
            multInAValid_Vdt <= 1;
            multInBValid_Vdt <= 1;
            
            addInB_VNEW <= 0;
            addInBValid_VNEW <= 1;
            
            multInA_GammaV <= 0;
            multInAValid_GammaV <= 1;
            
            XREADYFLAG <= 1;
            VREADYFLAG <= 1;
           // multInA_FdtSq <= {signBit,(multOut_KX[30:23] - 1), multOut_KX[22:0]};
           // multInA_FdtSq <= 0;
            //multInAValid_FdtSq <= 1;
            Fdiv2 <= 0;
           updateID <= 1;
        end else begin
            Fdiv2[31] <= signBit;
            Fdiv2[30:23] <=(multOut_KX[30:23] - 1);
            Fdiv2[22:0] <= multOut_KX[22:0];
            Fdiv2Valid <= multOutValid_KX;
        
            if((updateID == (adderID_XNEW)) && (updateID == adderID_VNEW))begin
               //if(updateID == adderID_XNEW)begin
                    multInA_GammaV <= addOut_VNEW;
                    multInA_Vdt <= addOut_VNEW;
                    addInB_VNEW <= addOut_VNEW;
                    multInAValid_GammaV <= 1;
                    multInAValid_Vdt <= 1;
                    addInBValid_VNEW <= 1;
//               end else begin
//                   addInBValid_VNEW <= 0;
//                   multInAValid_Vdt <= 0;
                   
//               end
                
               // if(updateID == adderID_VNEW)begin
                    multInA_KX <= addOut_XNEW;
                    addInB_XNEW <= addOut_XNEW;
                    multInAValid_KX <= 1;
                    addInBValid_XNEW <= 1;
//               end else if(add) begin
//                    addInBValid_XNEW <= 0;
//                    multInAValid_KX <= 0;
//               end
               
               //if(multInAValid_KX && multInAValid_Vdt)begin
                    updateID <= updateID + 1;
              //end
            end else begin
            
               multInAValid_GammaV <= 0;
               multInAValid_KX <= 0;
               multInAValid_Vdt <= 0;
               addInBValid_XNEW <= 0;
               addInBValid_VNEW <= 0;
               
            end
        end
    end
   
endmodule
