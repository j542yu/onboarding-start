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

reg [15:0] received_message; // [15] = r/w, [14:8] = register to write to, [7:0] = data bits
reg [3:0]  bit_count; // 4-bit (hex) count from 0 to 15 to know when message is complete

// value-sensitive signals have N = 2 samples
reg ncs_synch;
reg copi_synch;

// edge-sensitive signals have N + 1 = 3 samples; sclk_synch[0] = old, sclk_synch[1] = new
reg [1:0] sclk_synch;