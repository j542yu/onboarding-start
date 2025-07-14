/*
 * Copyright (c) 2024 Judy Yu
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module spi_peripheral (
    input  wire       clk,      // clock
    input  wire       rst_n,    // active low asynch reset

    input wire ncs,
    input wire copi,       
    input wire sclk,

    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

    localparam MAX_ADDRESS = 7'h04;

    reg [15:0] received_message; // [15] = r/w, [14:8] = register to write to, [7:0] = data bits
    reg [4:0]  bit_count; // count up to 16 SCLK edges to know when transaction is complete

    // value-sensitive signals have N = 2 samples
    reg ncs_synch;
    reg copi_synch;

    // edge-sensitive signals have N + 1 = 3 samples; sclk_synch[1] = old, sclk_synch[0] = new
    reg [1:0] sclk_synch;

    wire transaction_ready = (bit_count == 5'd16) ? 1 : 0;
    wire posedge_sclk = ~sclk_synch[1] && sclk_synch[0];
    wire negedge_sclk = sclk_synch[1] && ~sclk_synch[0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            received_message <= '0;
            bit_count <= '0;
            ncs_synch <= '0;
            copi_synch <= '0;
            sclk_synch <= '0;
            en_reg_out_7_0 <= '0;
            en_reg_out_15_8 <= '0;
            en_reg_pwm_7_0 <= '0;
            en_reg_pwm_15_8 <= '0;
            pwm_duty_cycle <= '0;
        end

        else begin
            // synchronizer FF chain to avoid metastability
            ncs_synch <= ncs;
            copi_synch <= copi;
            sclk_synch[1] <= sclk;
            sclk_synch[0] <= sclk_synch[1];


            // SPI Mode 0: shift in data on rising SCLK, shift out data on falling SCLK
            
            if (!ncs_synch && !transaction_ready) begin
                // shift in data on rising SCLK edge
                if (posedge_sclk) begin
                    received_message <= {received_message[14:0], copi_synch};
                    bit_count <= bit_count + 1;
                end
            end
            else if (transaction_ready) begin
                // shift out data on falling SCLK edge if register address is valid
                if (ncs_synch && negedge_sclk && (received_message[14:8] <= MAX_ADDRESS)) begin
                    case (received_message[14:8])
                        7'h00   : en_reg_out_7_0 <= received_message[7:0];
                        7'h01   : en_reg_out_15_8 <= received_message[7:0];
                        7'h02   : en_reg_pwm_7_0 <= received_message[7:0];
                        7'h03   : en_reg_pwm_15_8 <= received_message[7:0];
                        7'h04   : pwm_duty_cycle <= received_message[7:0];
                        default :;
                    endcase
                end

                received_message <= '0;
                bit_count <= '0;
            end
        end
    end
endmodule