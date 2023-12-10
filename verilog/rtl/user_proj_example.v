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

module user_proj_example (
`ifdef USE_POWER_PINS
    inout vdd,	// User area 1 1.8V supply
    inout vss,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
  
    // Logic Analyzer Signals
    input  [63:0] la_data_in,
    output [63:0] la_data_out,
    input  [63:0] la_oenb

    // IOs
    // input io_in,
    // output [2:0] io_out
);
    reg [2:0] reg_num1, reg_num2;

    //wire [BITS-1:0] count;
    wire [2:0] sum, status;
    wire done;
    //wire done;
    wire wena;
    //wire valid;
    // wire [3:0] wstrb;
    wire [31:0] la_write;
    // LA
    assign la_data_out = {{(63-3){1'b0}}, sum};

    // Assuming LA probes [63:32] are for controlling the count register  
    assign la_write = ~la_oenb[63:32];

    // Assuming LA probes [65:64] are for controlling the count clk & reset  
    assign clk = wb_clk_i;
    assign rst = wb_rst_i;
    // Assuming LA probes [36] controls the wena;
    assign wena = la_data_in[36];

    // Assign the IO output to observe the status of BEC's FSM 
    assign io_out = status;

    always @(posedge clk) begin
        if (rst) begin
            reg_num1 <= 0;
            reg_num2 <= 0;
        end
        else begin
            if (|la_write && ~wena)  begin
                case (la_data_in[35])
                    1'b0: begin
                        reg_num1 <= la_data_in[34:32];
                    end
                    1'b1:begin
                        reg_num2 <= la_data_in[34:32];
                    end
                endcase;
            end       
        end
    end




    add #(
    ) add(
        .clk(clk),
        .reset(rst),
        .num1(reg_num1),
        .num2(reg_num2),
        // .la_write(la_write),
        // .la_input(la_data_in[36:32]),
        .status(status),
        .wena(wena),
        .done(done),
        .sum(sum)
    );

endmodule

module add(
    input clk,
    input reset,
    // input [31:0] la_write,
    input [2:0] num1,
    input [2:0] num2,
    // input [4:0] la_input,
    input wena,
    output [2:0] status,
    output done,
    output [2:0] sum
    
);
reg [2:0] sum;
reg done;
reg data_ready;
reg [2:0] count;
reg busy;
parameter IDLE = 2'b00, READY = 2'b01, BUSY = 2'b10, DONE = 2'b11;
// assign busy = (current_state == BUSY) ? 1 : 0;

reg current_state;
wire next_state;
assign status = data_ready << 2 | busy << 1 | done ;

always @(posedge clk )
    begin
        if(reset)
            current_state <= IDLE;
        else 
            current_state <= next_state;
    end

always@(wena, done) begin
    case(current_state)
        IDLE: begin
            if (wena) begin
                next_state <= READY;
            end else begin
                next_state <= IDLE;
            end
        end

        READY: begin
            next_state <= BUSY;
        end

        BUSY: begin
            if (done) begin
                next_state <= DONE;
            end else begin
                next_state <= BUSY;
            end
        end

        DONE: begin
            next_state <= IDLE;
        end
    endcase
end


always @(posedge clk) begin
    if (reset) begin
        done        <= 1'b0;
        busy        <= 1'b0;
        data_ready  <= 1'b0;
        count       <= 3'b0;
    end
    else begin
        case (current_state)
            IDLE: begin
                done        <= 1'b0;
                busy        <= 1'b0;
                data_ready  <= 1'b0;
                count       <= 3'b0;
            end    

            READY: begin
                data_ready <= 1'b1;
            end

            BUSY: begin
                busy <= 1'b1;
                data_ready <= 1'b0;

                count <= count + 1; 
                if (count == 4) begin
                    done <= 1'b1;
                end else begin
                    done <= 1'b0;
                end
            end

            DONE: begin
                sum <= num1 + num2;
            end
        endcase   
    end
end
endmodule
`default_nettype wire
