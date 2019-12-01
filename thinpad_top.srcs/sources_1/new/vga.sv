`timescale 1ns / 1ps
//
// WIDTH: bits in register hdata & vdata
// HSIZE: horizontal size of visible field 
// HFP: horizontal front of pulse
// HSP: horizontal stop of pulse
// HMAX: horizontal max size of value
// VSIZE: vertical size of visible field 
// VFP: vertical front of pulse
// VSP: vertical stop of pulse
// VMAX: vertical max size of value
// HSPP: horizontal synchro pulse polarity (0 - negative, 1 - positive)
// VSPP: vertical synchro pulse polarity (0 - negative, 1 - positive)
//
module vga
#(parameter WIDTH = 0, HSIZE = 0, HFP = 0, HSP = 0, HMAX = 0, VSIZE = 0, VFP = 0, VSP = 0, VMAX = 0, HSPP = 0, VSPP = 0)
(
    input wire clk,
    output wire hsync,
    output wire vsync,
    // output reg [WIDTH - 1:0] hdata,
    // output reg [WIDTH - 1:0] vdata,
    output wire data_enable,
    output wire[2:0] r,
    output wire[2:0] g,
    output wire[1:0] b,

    input logic [7:0] video_data,
    output logic [18:0] video_addr
);

reg [WIDTH-1 : 0] hdata;
reg [WIDTH-1 : 0] vdata;

assign r = video_data[2:0];
assign g = video_data[5:3];
assign b = video_data[7:6];

// init
initial begin
    hdata <= 0;
    vdata <= 0;
    video_addr <= 0;
end

// hdata
always @ (posedge clk)
begin
    if (hdata == (HMAX - 1))
        hdata <= 0;
    else
        hdata <= hdata + 1;
end

// vdata
always @ (posedge clk)
begin
    if (hdata == (HMAX - 1)) 
    begin
        if (vdata == (VMAX - 1))
            vdata <= 0;
        else
            vdata <= vdata + 1;
    end
end

always @ (posedge clk)
begin
	if (hdata == 0 & vdata == 0)
	   video_addr <= 0;
	else begin
	   if (data_enable)
	       video_addr <= video_addr + 1;
	end
end

// hsync & vsync & blank
assign hsync = ((hdata >= HFP) && (hdata < HSP)) ? HSPP : !HSPP;
assign vsync = ((vdata >= VFP) && (vdata < VSP)) ? VSPP : !VSPP;
assign data_enable = ((hdata < HSIZE) & (vdata < VSIZE));

endmodule