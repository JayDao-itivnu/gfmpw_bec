// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */
`include "add.v"
module user_proj_example (
`ifdef USE_POWER_PINS
    inout vdd,	// User area 1 1.8V supply
    inout vss,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
  
    // Logic Analyzer Signals
    input  [36:32] la_data_in,
    output [63:0] la_data_out,
    input  [63:32] la_oenb,

    // IOs
    // input io_in,
    output [2:0] io_out
);
    reg [2:0] reg_num1, reg_num2;
	reg [2:0] num_2, num_1;

    //wire [BITS-1:0] count;
    wire [2:0] sum;
	reg [2:0] status;
    wire done, wena, busy;
	wire clk, rst;

    wire [31:0] la_write;
    // LA
    assign la_data_out = {{(63-2){1'b0}}, sum};

    // Assuming LA probes [63:32] are for controlling the count register  
    assign la_write = ~la_oenb[63:32];

    // Assuming LA probes [65:64] are for controlling the count clk & reset  
    assign clk = wb_clk_i;
    assign rst = wb_rst_i;
    // Assuming LA probes [36] controls the wena;
    assign wena = |la_write && ~ la_data_in[36];
	assign busy = la_data_in[36];
    // Assign the IO output to observe the status of BEC's FSM 
    assign io_out = status;
	reg [1:0] current_state;
	reg [1:0] next_state;
	parameter IDLE = 2'b00, WRITE = 2'b01, BUSY = 2'b10, DONE = 2'b11;	

	always @(wena, busy, done) begin
		case (current_state) 
			IDLE: begin
				status <= 3'b000;
				if (wena) begin
					next_state <= WRITE;
				end else begin
					next_state <= IDLE;
				end
			end

			WRITE: begin
				status <= 3'b100;

				if (busy) begin
					next_state <= BUSY;
				end else begin
					next_state <= WRITE;
					case (la_data_in[35])
						1'b0: begin
							num_1 <= la_data_in[34:32];
						end
						1'b1:begin
							num_2 <= la_data_in[34:32];
						end
					endcase; 
				end
				
			end

			BUSY: begin
				status <= 3'b010;
				if (done) begin
					next_state <= DONE;
				end else begin
					next_state <= BUSY;
				end
			end

			DONE: begin
				status <= 3'b001;
				next_state <= IDLE;
			end
		endcase
	end
	
    always @(posedge clk) begin
        if (rst) begin
            reg_num1 <= 0;
            reg_num2 <= 0;
			current_state <= IDLE;
        end else begin
            reg_num1 <= num_1;
            reg_num2 <= num_2;
			current_state <= next_state;
		end
    end




    add #(
    ) add(
        .clk(clk),
        .reset(rst),
        .num1(reg_num1),
        .num2(reg_num2),
        .enable(busy),
        .done(done),
        .sum(sum)
    );

endmodule

// module add(
//     input clk,
//     input reset,
//     input [2:0] num1,
//     input [2:0] num2,
//     input enable,
//     output done,
//     output reg [2:0] sum
    
// );
// reg reg_done;
// reg [9:0] count;

// parameter IDLE = 2'b00, BUSY = 2'b10, DONE = 2'b11;
// // assign busy = (current_state == BUSY) ? 1 : 0;

// assign done = reg_done;

// reg [1:0] current_state;
// reg [1:0] next_state;

// always @(posedge clk )
//     begin
//         if(reset)
//             current_state <= IDLE;
//         else 
//             current_state <= next_state;
//     end

// always@(enable, reg_done) begin
//     case(current_state)
//         IDLE: begin
//             if (enable) begin
//                 next_state <= BUSY;
//             end else begin
//                 next_state <= IDLE;
//             end
//         end

//         BUSY: begin
//             if (reg_done) begin
//                 next_state <= DONE;
//             end else begin
//                 next_state <= BUSY;
//             end
//         end

//         DONE: begin
//             next_state <= IDLE;
//         end
// 		default: next_state <= IDLE;
//     endcase
// end


// always @(posedge clk) begin
//     if (reset) begin
//         reg_done    <= 1'b0;
//         count       <= 10'h000;
//     end
//     else begin
//         case (current_state)
//             IDLE: begin
//                 reg_done    <= 1'b0;
// 				count       <= 10'h000;
//             end    

//             BUSY: begin
//                 count <= count + 1; 
//                 if (count == 10'h3FF) begin
//                     reg_done <= 1'b1;
//                 end else begin
//                     reg_done <= 1'b0;
//                 end
//             end

//             DONE: begin
//                 sum <= num1 + num2;
//             end
// 			default: begin
// 				reg_done    <= 1'b0;
// 				count       <= 10'h000;
// 			end
//         endcase   
//     end
// end
// endmodule
`default_nettype wire
