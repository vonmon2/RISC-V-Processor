import rv32i_types::*;

module id_ex_regs
(
    input clk,
    input rst,
    input load,
    input logic [31:0] pc_i,
	input rv32i_word instruction_i,
	input instruction_decoded_t instruction_decoded_i,
	input rv32i_control_word control_word_i,
	input rv32i_word rs1_out_i,
	input rv32i_word rs2_out_i,
	input logic bubble_control,
    output logic [31:0] pc_o,
	output rv32i_word instruction_o,
	output instruction_decoded_t instruction_decoded_o,
	output rv32i_control_word control_word_o,
	output rv32i_word rs1_out_o,
	output rv32i_word rs2_out_o,
	
	input logic halt_i,
	output logic halt_o
);

// internal registers
logic [31:0] pc;
rv32i_word instruction;
instruction_decoded_t instruction_decoded;
rv32i_control_word control_word;
rv32i_word rs1_out;
rv32i_word rs2_out;

logic halt;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        pc <= '0;
		instruction <= '0;
		instruction_decoded <= '0;
		control_word <= '0;
		rs1_out <= '0;
		rs2_out <= '0;
		halt <= halt_i; //dont squah halt
    end
    else if (load)
    begin
        pc <= pc_i;
		instruction <= instruction_i;
		instruction_decoded <= instruction_decoded_i;
		rs1_out <= rs1_out_i;
		rs2_out <= rs2_out_i;
		halt <= halt_i;
		//if we are adding a bubble, zero out control word
		if(bubble_control) begin
			control_word <= '0;
			instruction <= '0;
			instruction_decoded <= '0;
			rs1_out <= '0;
			rs2_out <= '0;
		end
		else begin
			control_word <= control_word_i;
			instruction <= instruction_i;
			instruction_decoded <= instruction_decoded_i;
			rs1_out <= rs1_out_i;
			rs2_out <= rs2_out_i;
		end
		//control_word <= control_word_i;
    end
    else
    begin
        pc <= pc;
		instruction <= instruction;
		instruction_decoded <= instruction_decoded;
		control_word <= control_word;
		rs1_out <= rs1_out;
		rs2_out <= rs2_out;
		halt <= halt;
    end
end

always_comb
begin
    pc_o = pc;
	instruction_o = instruction;
	instruction_decoded_o = instruction_decoded;
	control_word_o = control_word;
	rs1_out_o = rs1_out;
	rs2_out_o = rs2_out;
	halt_o = halt;
end

endmodule : id_ex_regs
