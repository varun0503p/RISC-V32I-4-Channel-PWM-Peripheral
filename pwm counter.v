//-----------------------------------------------------------------
// pwmcounter.v  (REPLACED: 4-Channel PWM Generator)
//
// Replaces the original counter peripheral in the SoC.
// Same module name, same port list so NO other file needs changing.
//
// 4 independent PWM channels - fixed duty cycles:
//   CH0 = 25%   (switch V2 / LED G1 / servo M14)
//   CH1 = 50%   (switch U2 / LED G2 / servo M16)
//   CH2 = 75%   (switch U1 / LED F1 / servo L15)
//   CH3 = 100%  (switch T2 / LED F2 / servo L16)
//
// Register Map (base 0x95000000):
//   0x00  PWM_PERIOD  [15:0]  counter period (default 1000)
//   0x04  CH0_DUTY    [15:0]  duty cycle ch0 (default 250  = 25%)
//   0x08  CH1_DUTY    [15:0]  duty cycle ch1 (default 500  = 50%)
//   0x0C  CH2_DUTY    [15:0]  duty cycle ch2 (default 750  = 75%)
//   0x10  CH3_DUTY    [15:0]  duty cycle ch3 (default 1000 = 100%)
//   0x14  PWM_CTRL    [3:0]   enable bits, bit N enables channel N
//
// AXI4-Lite slave interface (identical to original counter.v).
// count_o [3:0] = {ch3_en, ch2_en, ch1_en, ch0_en} drives LEDs.
//
// Base address: 0x95000000
//-----------------------------------------------------------------

module counter
(
    // Clock and reset
     input           clk_i
    ,input           rst_i

    // AXI4-Lite slave interface (unchanged port names)
    ,input  [ 31:0]  cfg_awaddr_i
    ,input           cfg_awvalid_i
    ,output          cfg_awready_o
    ,input  [ 31:0]  cfg_wdata_i
    ,input  [  3:0]  cfg_wstrb_i
    ,input           cfg_wvalid_i
    ,output          cfg_wready_o
    ,output [  1:0]  cfg_bresp_o
    ,output          cfg_bvalid_o
    ,input           cfg_bready_i
    ,input  [ 31:0]  cfg_araddr_i
    ,input           cfg_arvalid_i
    ,output          cfg_arready_o
    ,output [ 31:0]  cfg_rdata_o
    ,output [  1:0]  cfg_rresp_o
    ,output          cfg_rvalid_o
    ,input           cfg_rready_i

    // Physical output - reused as PWM outputs + LED indicators
    // count_o[0] = CH0 PWM (25%),  count_o[1] = CH1 PWM (50%)
    // count_o[2] = CH2 PWM (75%),  count_o[3] = CH3 PWM (100%)
    ,output [  3:0]  count_o
);

`include "counter_defs.v"

//-----------------------------------------------------------------
// AXI4-Lite handshake (identical style to original counter.v)
//-----------------------------------------------------------------
wire read_en_w  = cfg_arvalid_i & cfg_arready_o;
wire write_en_w = cfg_awvalid_i & cfg_awready_o;

assign cfg_arready_o = ~cfg_rvalid_o;
assign cfg_awready_o = ~cfg_bvalid_o && ~cfg_arvalid_i;
assign cfg_wready_o  = cfg_awready_o;

//-----------------------------------------------------------------
// Register storage
//-----------------------------------------------------------------
reg [15:0] pwm_period_q;
reg [15:0] ch0_duty_q;
reg [15:0] ch1_duty_q;
reg [15:0] ch2_duty_q;
reg [15:0] ch3_duty_q;
reg [ 3:0] pwm_ctrl_q;   // enable bits [3:0]

// PWM_PERIOD
always @(posedge clk_i or posedge rst_i)
if (rst_i)
    pwm_period_q <= `PWM_PERIOD_DEFAULT;
else if (write_en_w && (cfg_awaddr_i[7:0] == `PWM_PERIOD_REG))
    pwm_period_q <= cfg_wdata_i[15:0];

// CH0_DUTY  (default 25%)
always @(posedge clk_i or posedge rst_i)
if (rst_i)
    ch0_duty_q <= `CH0_DUTY_DEFAULT;
else if (write_en_w && (cfg_awaddr_i[7:0] == `CH0_DUTY_REG))
    ch0_duty_q <= cfg_wdata_i[15:0];

// CH1_DUTY  (default 50%)
always @(posedge clk_i or posedge rst_i)
if (rst_i)
    ch1_duty_q <= `CH1_DUTY_DEFAULT;
else if (write_en_w && (cfg_awaddr_i[7:0] == `CH1_DUTY_REG))
    ch1_duty_q <= cfg_wdata_i[15:0];

// CH2_DUTY  (default 75%)
always @(posedge clk_i or posedge rst_i)
if (rst_i)
    ch2_duty_q <= `CH2_DUTY_DEFAULT;
else if (write_en_w && (cfg_awaddr_i[7:0] == `CH2_DUTY_REG))
    ch2_duty_q <= cfg_wdata_i[15:0];

// CH3_DUTY  (default 100%)
always @(posedge clk_i or posedge rst_i)
if (rst_i)
    ch3_duty_q <= `CH3_DUTY_DEFAULT;
else if (write_en_w && (cfg_awaddr_i[7:0] == `CH3_DUTY_REG))
    ch3_duty_q <= cfg_wdata_i[15:0];

// PWM_CTRL  (all channels disabled at reset)
always @(posedge clk_i or posedge rst_i)
if (rst_i)
    pwm_ctrl_q <= 4'b0000;
else if (write_en_w && (cfg_awaddr_i[7:0] == `PWM_CTRL_REG))
    pwm_ctrl_q <= cfg_wdata_i[3:0];

//-----------------------------------------------------------------
// Read mux (combinational)
//-----------------------------------------------------------------
reg [31:0] data_r;
always @*
begin
    data_r = 32'b0;
    case (cfg_araddr_i[7:0])
    `PWM_PERIOD_REG : data_r = {16'b0, pwm_period_q};
    `CH0_DUTY_REG   : data_r = {16'b0, ch0_duty_q};
    `CH1_DUTY_REG   : data_r = {16'b0, ch1_duty_q};
    `CH2_DUTY_REG   : data_r = {16'b0, ch2_duty_q};
    `CH3_DUTY_REG   : data_r = {16'b0, ch3_duty_q};
    `PWM_CTRL_REG   : data_r = {28'b0, pwm_ctrl_q};
    default         : data_r = 32'b0;
    endcase
end

//-----------------------------------------------------------------
// RVALID (latched until master takes it)
//-----------------------------------------------------------------
reg rvalid_q;
always @(posedge clk_i or posedge rst_i)
if (rst_i)             rvalid_q <= 1'b0;
else if (read_en_w)    rvalid_q <= 1'b1;
else if (cfg_rready_i) rvalid_q <= 1'b0;
assign cfg_rvalid_o = rvalid_q;

reg [31:0] rd_data_q;
always @(posedge clk_i or posedge rst_i)
if (rst_i)
    rd_data_q <= 32'b0;
else if (!cfg_rvalid_o || cfg_rready_i)
    rd_data_q <= data_r;
assign cfg_rdata_o = rd_data_q;
assign cfg_rresp_o = 2'b00;

//-----------------------------------------------------------------
// BVALID (latched until master takes it)
//-----------------------------------------------------------------
reg bvalid_q;
always @(posedge clk_i or posedge rst_i)
if (rst_i)             bvalid_q <= 1'b0;
else if (write_en_w)   bvalid_q <= 1'b1;
else if (cfg_bready_i) bvalid_q <= 1'b0;
assign cfg_bvalid_o = bvalid_q;
assign cfg_bresp_o  = 2'b00;

//-----------------------------------------------------------------
// Shared 16-bit PWM counter (free-running, shared period)
//-----------------------------------------------------------------
reg [15:0] pwm_counter_q;

always @(posedge clk_i or posedge rst_i)
if (rst_i)
    pwm_counter_q <= 16'b0;
else if (pwm_counter_q >= pwm_period_q)
    pwm_counter_q <= 16'b0;
else
    pwm_counter_q <= pwm_counter_q + 16'd1;

//-----------------------------------------------------------------
// PWM compare: output HIGH when counter < duty register
// Channel disabled => output LOW
//-----------------------------------------------------------------
wire ch0_pwm_w = pwm_ctrl_q[0] & (pwm_counter_q < ch0_duty_q);
wire ch1_pwm_w = pwm_ctrl_q[1] & (pwm_counter_q < ch1_duty_q);
wire ch2_pwm_w = pwm_ctrl_q[2] & (pwm_counter_q < ch2_duty_q);
wire ch3_pwm_w = pwm_ctrl_q[3] & (pwm_counter_q < ch3_duty_q);

// count_o drives boolean_top.v LEDs and is also tapped for servo pins
assign count_o = {ch3_pwm_w, ch2_pwm_w, ch1_pwm_w, ch0_pwm_w};

endmodule
