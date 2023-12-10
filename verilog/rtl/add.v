module add(
    input clk,
    input reset,
    input [2:0] num1,
    input [2:0] num2,
    input enable,
    output done,
    output reg [2:0] sum
    
);
reg reg_done;
reg [9:0] count;

localparam IDLE = 2'b00;
localparam BUSY = 2'b10;
localparam DONE = 2'b11;
// assign busy = (current_state == BUSY) ? 1 : 0;

assign done = reg_done;

reg [1:0] current_state;
reg [1:0] next_state;

always @(posedge clk )
    begin
        if(reset)
            current_state <= IDLE;
        else 
            current_state <= next_state;
    end

always @(enable, reg_done) begin
    case(current_state)
        IDLE: begin
            if (enable) begin
                next_state <= BUSY;
            end else begin
                next_state <= IDLE;
            end
        end

        BUSY: begin
            if (reg_done) begin
                next_state <= DONE;
            end else begin
                next_state <= BUSY;
            end
        end

        DONE: begin
            next_state <= IDLE;
        end
		default: next_state <= IDLE;
    endcase
end


always @(posedge clk) begin
    if (reset) begin
        reg_done    <= 1'b0;
        count       <= 10'h000;
    end
    else begin
        case (current_state)
            IDLE: begin
                reg_done    <= 1'b0;
				count       <= 10'h000;
            end    

            BUSY: begin
                count <= count + 1; 
                if (count == 10'h3FF) begin
                    reg_done <= 1'b1;
                end else begin
                    reg_done <= 1'b0;
                end
            end

            DONE: begin
                sum <= num1 + num2;
            end
			default: begin
				reg_done    <= 1'b0;
				count       <= 10'h000;
			end
        endcase   
    end
end
endmodule
/* verilator lint_off EOFNEWLINE */
// `default_nettype wire
