/****************************************************/
//	Module name: stage.v
//	Authority @ yangxiangrui (yangxiangrui11@nudt.edu.cn)
//	Last edited time: 2020/09/26
//	Function outline: a stage wrapper for RMT pipeline
/****************************************************/

`timescale 1ns / 1ps

module stage #(
    parameter STAGE = 0,  //valid: 0-4
    parameter PHV_LEN = 48*8+32*8+16*8+5*20+256,
    parameter KEY_LEN = 48*2+32*2+16*2+5,
    parameter ACT_LEN = 25,
    parameter KEY_OFF = 3*6
)
(
    input                        axis_clk,
    input                        aresetn,

    input  [PHV_LEN-1:0]         phv_in,
    input                        phv_in_valid,
    output [PHV_LEN-1:0]         phv_out,
    output                       phv_out_valid,

    //input for the key extractor RAM
    input  [KEY_OFF-1:0]         key_offset_in,
    input                        key_offset_valid_in

    //TODO need control channel
);

//key_extract to lookup_engine
wire [KEY_LEN-1:0]           key2lookup_key;
wire                         key2lookup_key_valid;
wire [PHV_LEN-1:0]           key2lookup_phv;

//lookup_engine to action_engine
wire [ACT_LEN*25-1:0]        lookup2action_action;
wire                         lookup2action_action_valid;
wire [PHV_LEN-1:0]           lookup2action_phv;

//

key_extract #(
	.STAGE(STAGE),
    .PHV_LEN(),
    .KEY_LEN(),
    .KEY_OFF()
) key_extract(
    .clk(axis_clk),
    .rst_n(aresetn),

    //output from parser
    .phv_in(phv_in),
    .phv_valid_in(phv_in_valid),
    //key for lookup table
    .key_offset_in(key_offset_in),
    .key_offset_valid_in(key_offset_valid_in),
    .phv_out(key2lookup_phv),
    .phv_valid_out(key2lookup_key_valid),
    .key_out(key2lookup_key),
    .key_valid_out(key2lookup_key_valid)
);

lookup_engine #(
    .STAGE(STAGE),
    .PHV_LEN(),
    .KEY_LEN(),
    .ACT_LEN()
) lookup_engine(
    .clk(axis_clk),
    .rst_n(aresetn),

    //output from key extractor
    .extract_key(key2lookup_key),
    .key_valid(key2lookup_key_valid),
    .phv_in(key2lookup_phv),

    //output to the action engine
    .action(lookup2action_action),
    .action_valid(lookup2action_action_valid),
    .pkt_hdr_vec_out(lookup2action_phv),

    //control channel
    .lookup_din(),
    .lookup_din_mask(),
    .lookup_din_addr(),
    .lookup_din_en(),

    //control channel (action ram)
    .action_data_in(),
    .action_en(),
    .action_addr()
);

action_engine #(
    .STAGE(STAGE),
    .PHV_LEN(),
    .ACT_LEN()
)action_engine(
    .clk(axis_clk),
    .rst_n(aresetn),

    //signals from lookup to ALUs
    .phv_in(lookup2action_phv),
    .phv_valid_in(lookup2action_action_valid),
    .action_in(lookup2action_action),
    .action_valid_in(lookup2action_action_valid),

    //signals output from ALUs
    .phv_out(phv_out),
    .phv_valid_out(phv_out_valid)
);


endmodule