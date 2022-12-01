`timescale 1ns / 1ps
/*
Author: Ben Sheffer
Description: This is meant to juggle using two different BRAMS to act as inputs and outputs for the simulation. it also helps to 
interface inputs and outputs that are arrays and 
*/

module memReadWrite #(parameter N = 3, width = 32*N)(   input clk, input [5:0] addrRead, input [5:0] addrWrite, input wea, input direction, 
                                          input [31:0] x_in [N-1:0], input [31:0] v_in [N-1:0], 
                                          output logic [31:0] x_out [N-1:0], output logic [31:0] v_out [N-1:0]
    );
    
    logic [5:0] addrA;
    logic [5:0] addrB;
    
    logic [width-1:0] x_inA;
    logic [width-1:0] v_inA;
    logic [width-1:0] x_outA;
    logic [width-1:0] v_outA;
    logic [width-1:0] x_inB;
    logic [width-1:0] v_inB;
    logic [width-1:0] x_outB;
    logic [width-1:0] v_outB;
    
    logic weaA;
    logic weaB;
    
    blockMem xMemA(.clka(clk), .ena(1'b1), .wea(weaA), .addra(addrA), .dina(x_inA), .douta(x_outA));
    blockMem vMemA(.clka(clk), .ena(1'b1), .wea(weaA), .addra(addrA), .dina(v_inA), .douta(v_outA));
    blockMem xMemB(.clka(clk), .ena(1'b1), .wea(weaB),.addra(addrB), .dina(x_inB), .douta(x_outB));
    blockMem vMemB(.clka(clk), .ena(1'b1), .wea(weaB), .addra(addrB), .dina(v_inB), .douta(v_outB));
    
    //use this generate block to pack arrays into single bytes and vice versa to interface array inputs and outputs of module
    //with the single byte inputs and outputs of the BRAMs
    always_comb begin
        if(direction)begin
            addrA = addrRead;
            addrB = addrWrite;
            //clear memA's write enable, and route the wea to memB
            weaA = 0;
            weaB = wea;
            
            //x_inA = 0;
            //v_inA = 0;
        end else begin
            addrB = addrRead;
            addrA = addrWrite;
            //clear memA's write enable, and route the wea to memB
            weaB = 0;
            weaA = wea;
            
            //x_inB = 0;
            //v_inB = 0;
        end
    end
    
    
    genvar i;
    generate
        for(i = 0; i < N; i = i+1)begin
            //route the inputs and outputs according to the direction input
            always_comb begin
                if(direction)begin
                //if direction is set, use memA as inputs and memB to catch outputs
                    //assign memA to the read address, and memory B to the write address
                    //Genvar i = 0;
                    
                      
                    x_out[i] = x_outA[32*(i+1)-1:32*i];
                    v_out[i] = v_outA[32*(i+1)-1:32*i];
                    
                    x_inB[32*(i+1)-1:32*i] = x_in[i];
                    v_inB[32*(i+1)-1:32*i] = v_in[i];
                    
                    x_inA[32*(i+1)-1:32*i] = 0;
                    v_inA[32*(i+1)-1:32*i] = 0;
                    
              
                end else begin
                //if direction is cleared, use memB as inputs and memA to catch outputs
                    //assign memB to the read address, and memory A to the write address
                    x_out[i] = x_outB[32*(i+1)-1:32*i];
                    v_out[i] = v_outB[32*(i+1)-1:32*i];
                    
                    x_inA[32*(i+1)-1:32*i] = x_in[i];
                    v_inA[32*(i+1)-1:32*i] = v_in[i];
                    
                    x_inB[32*(i+1)-1:32*i] = 0;
                    v_inB[32*(i+1)-1:32*i] = 0;
                    
                end //end direction = 0 case
            end //end always comb
        end //end for loop
    endgenerate
endmodule
