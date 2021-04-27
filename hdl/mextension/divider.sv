import rv32i_types::*;

module us_divider(
	input clk,
	input rst,
	
	input start,
	output fin,
	input [31:0] dividend,
	input [31:0] divisor,
	output [31:0] quotient,
	output [31:0] remainder
	
);

logic [31:0] partial_q;
logic [31:0] partial_r;
logic [5:0] idx;
logic [5:0] idx2;

enum int unsigned {
    /* List of states */
	idle,
	div,
	done
	
} state, next_state;

always_comb
begin : state_actions
	
    /* Actions for each state */
	case(state)
		
		idle: begin
			fin = 1'b0;
			idx2 = 6'b011111;
			partial_q = 32'b0;
			partial_r = 32'b0;
			
		end
		
		div: begin
		
			fin = 1'b0;
		
			if(remainder < divisor) begin
				partial_q = {quotient[30:0], 1'b0}; //shift
				if(idx > 6'b011111) begin //if idx has hit 0 and overflowed
					partial_r = remainder;
				end else begin
					partial_r = {remainder[30:0], dividend[idx]};
				end
			end else begin
				partial_q = {quotient[30:0], 1'b1}; //shift
				if(idx > 6'b011111) begin //if idx has hit 0 and overflowed
					partial_r = {remainder - divisor};
				end else begin
					partial_r = {remainder - divisor, dividend[idx]};
				end
			end
			
			idx2 = idx - 1'b1;
			
		end
		
		done: begin
			idx2 = 6'b011111; //reset intermediate values
			partial_q = 0;
			partial_r = 0;
			fin = 1'b1;
		end
		
	endcase
	
end



always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	 
	 // default
	 next_state = state;
	 
	case(state)
	
		idle: begin
			if(start == 1'b1) begin
				next_state = div;
			end else begin
				next_state = idle;
			end
		end
		
		div: begin
			if(idx == 6'b100000) begin
				next_state = done;
			end else begin
				next_state = div;
			end
		end
		
		done: begin
			next_state = idle;
		end
	
	endcase
end



always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	if(rst == 1'b1) begin //reset
		state <= idle;
		quotient <= 32'b0;
		remainder <= 32'b0;
	end else begin //set quotient and remainder to their current tmp values
		state <= next_state;
		quotient <= partial_q;
		remainder <= partial_r;
		idx <= idx2;
	end
end

endmodule



module divider(

	input clk,
	input rst,
	
	input mex_funct3_t op,

	input start,
	output fin,
	input [31:0] dividend,
	input [31:0] divisor,
	output [31:0] quotient,
	output [31:0] remainder
);

logic [31:0] num;
logic [31:0] den;
logic [31:0] quo;
logic [31:0] rem;

us_divider usd(

	.clk,
	.rst,

	.start,
	.fin,
	.dividend(num),
	.divisor(den),
	.quotient(quo),
	.remainder(rem)

);

always_comb begin

	case(op) //div and rem are the same, as are divu and remu
	
		div: begin
			if(dividend[31]) begin //dividend
				num = (~dividend) + 32'b1; //2's complement
			end else begin
				num = dividend;
			end
			
			if(divisor[31]) begin //divisor
				den = (~divisor) + 32'b1; //2's complement
			end else begin
				den = divisor;
			end
			
			if(dividend[31] ^ divisor[31]) begin //quotient
				quotient = (~quo) + 32'b1; //2's complement
			end else begin
				quotient = quo;
			end
			
			if(dividend[31]) begin //remainder
				remainder = (~rem) + 32'b1; //2's complement
			end else begin
				remainder = rem;
			end
		end
		
		
		rem: begin
			if(dividend[31]) begin //dividend
				num = (~dividend) + 32'b1; //2's complement
			end else begin
				num = dividend;
			end
			
			if(divisor[31]) begin //divisor
				den = (~divisor) + 32'b1; //2's complement
			end else begin
				den = divisor;
			end
			
			if(dividend[31] ^ divisor[31]) begin //quotient
				quotient = (~quo) + 32'b1; //2's complement
			end else begin
				quotient = quo;
			end
			
			if(dividend[31]) begin //remainder
				remainder = (~rem) + 32'b1; //2's complement
			end else begin
				remainder = rem;
			end
		end
		
		
		divu: begin
			num = dividend;
			den = divisor;
			quotient = quo;
			remainder = rem;
		end
		
		
		remu: begin
			num = dividend;
			den = divisor;
			quotient = quo;
			remainder = rem;
		end
		
		default: begin //assume unsigned just in case
			num = dividend;
			den = divisor;
			quotient = quo;
			remainder = rem;
		end
	
	endcase

end

endmodule