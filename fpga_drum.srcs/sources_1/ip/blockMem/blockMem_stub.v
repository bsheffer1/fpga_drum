// Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2021.1 (win64) Build 3247384 Thu Jun 10 19:36:33 MDT 2021
// Date        : Wed Nov 30 21:32:40 2022
// Host        : DESKTOP-AHVA8MM running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/boson/OneDrive/Documents/Jobs/zeroASIC/fpga_drum_2/fpga_drum.srcs/sources_1/ip/blockMem/blockMem_stub.v
// Design      : blockMem
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-3
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2019.2" *)
module blockMem(clka, ena, wea, addra, dina, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[5:0],dina[1599:0],douta[1599:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [5:0]addra;
  input [1599:0]dina;
  output [1599:0]douta;
endmodule
