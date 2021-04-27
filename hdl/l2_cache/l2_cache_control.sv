/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module l2_cache_control (

	input clk,
	input rst,
	
	// port to cpu
    input logic mem_read,
    input logic mem_write,
	output logic mem_resp,

	//signals between datapath and control
	output logic source_sel,
	output logic [2:0] way_sel,
	output logic tag_sel,
	output logic load_cache,
	output logic load_lru,
	output logic read_cache_data,
	output logic load_dirty_arr,
	output logic [2:0] dirty_sel,
	input logic cache_hit,
	input logic dirty_o,
	input logic [2:0] hit_idx,
	input logic [2:0] plru_idx,
	
	//port to memory
	input logic resp_from_mem,
	output logic read_from_mem,
	output logic write_to_mem
);


enum int unsigned {
    /* List of states */
	s_idle,
	s_write_back,
	s_load_data_from_mem,
	s_load_data_into_cache,
	s_respond_to_cpu
	
} state, next_state;

function void set_defaults();
	
	way_sel = hit_idx; // on a hit (idle), want to select the way which has the hit
	tag_sel = 1'b1; //make default to mem addr tag
	read_from_mem = 1'b0;
	write_to_mem = 1'b0;
	load_cache = 1'b0;
	load_lru = 1'b0;
	source_sel = 1'b0;
	read_cache_data = 1'b1; // always want to read cache data
	mem_resp = 1'b0;
	load_dirty_arr = 1'b0;
	dirty_sel = plru_idx; // dirty output is only important for checking if we need to write back when evicting.
endfunction

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
	
    /* Actions for each state */
	case(state)
		
		s_idle: begin
			//all signals are default
		end
		
		s_write_back: begin
			write_to_mem = 1'b1;
			way_sel = plru_idx; //should this be changed since data from cacheline is delayed a cycle? (set this in prev state)
			tag_sel = 1'b0; //choose mem address from tag (concat with set)
		end
		
		s_load_data_from_mem: begin
			read_from_mem = 1'b1;
			way_sel = plru_idx;
			tag_sel = 1'b1; //select mem addr tag
		end
		
		s_load_data_into_cache: begin
			load_cache = 1'b1;
			source_sel = 1'b1; // memory
			way_sel = plru_idx; //replace least recently used
			load_dirty_arr = 1'b1; // load a 0 if reading (and evicting), load 1 if writing. 
		end
		
		s_respond_to_cpu: begin
			mem_resp = 1'b1;
			way_sel = hit_idx; // redundant since this is default; keeping it here anyway for now
			load_lru = 1'b1; // lru will load way_sel into the respective index
			// not sure if mem_write signal will persist here, so additional logic/signals may be needed
			load_cache = mem_write; // want to load cache if we are writing;
			if(mem_write) load_dirty_arr = 1'b1;
		end
	endcase
	
end



always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	 
	 // default
	 next_state = state;
	 
	 if(rst == 1'b1) begin
		next_state = s_idle;
	 end
	 
	 else begin
	 
		 case(state)
		
			s_idle: begin
				if( (mem_read | mem_write) & ~cache_hit & dirty_o) begin
					next_state = s_write_back;
				end
				
				else if( (mem_read | mem_write) & ~cache_hit & ~dirty_o) begin
					next_state = s_load_data_from_mem;
				end
				
				if( (mem_read | mem_write) & cache_hit) begin
					next_state = s_respond_to_cpu;
				end
			end
			
			s_write_back: begin
				if(resp_from_mem == 1'b1) begin
					next_state = s_load_data_from_mem;
				end
			end
			
			s_load_data_from_mem: begin
				if(resp_from_mem == 1'b1) begin
					next_state = s_load_data_into_cache;
				end
			end
			
			s_load_data_into_cache: begin
				next_state = s_respond_to_cpu;
			end
			
			s_respond_to_cpu: begin
				next_state = s_idle;
			end
		endcase
	end
end



always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	state <= next_state;
end


endmodule : l2_cache_control
