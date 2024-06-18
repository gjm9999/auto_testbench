`define DELAY(N, clk) begin \
	repeat(N) @(posedge clk);\
	#1ps;\
end

import bypass_fifo_pkg::*;

module testbench();

//-------------------------------------{{{common cfg
timeunit 1ns;
timeprecision 1ps;
initial $timeformat(-9,3,"ns",6);

string tc_name;
int tc_seed;

initial begin
    if(!$value$plusargs("tc_name=%s", tc_name)) $error("no tc_name!");
    else $display("tc name = %0s", tc_name);
    if(!$value$plusargs("ntb_random_seed=%0d", tc_seed)) $error("no tc_seed");
    else $display("tc seed = %0d", tc_seed);
end
//-------------------------------------}}}

//-------------------------------------{{{parameter declare
parameter DEPTH = 8;
parameter WIDTH = 128;
//-------------------------------------}}}

//-------------------------------------{{{signal declare
logic  clk;
logic  rst_n;
logic  data_in_valid;
logic [WIDTH -1:0] data_in;
logic  data_in_power;
logic  data_in_ready;
logic  data_out_valid;
logic [WIDTH -1:0] data_out;
logic  data_out_ready;
//-------------------------------------}}}

//-------------------------------------{{{clk/rst cfg
initial forever #5ns clk = ~clk;
initial begin
    rst_n = 1'b0;
	`DELAY(30, clk);
	rst_n = 1'b1;
end
initial begin
    #100000ns $finish;
end
//-------------------------------------}}}

//-------------------------------------{{{valid sig assign
always @(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        data_in_valid <= 0;
    end
    else if(data_in_ready || ~data_in_valid)begin
        data_in_valid <= $urandom;
    end
end

//-------------------------------------}}}

//-------------------------------------{{{ready sig assign
always @(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        data_out_ready <= 0;
    end
    else begin
        data_out_ready <= $urandom;
    end
end

//-------------------------------------}}}

//-------------------------------------{{{data  sig assign
always @(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        data_in <= 'x;
    end
    else if(data_in_valid && data_in_ready)begin
        data_in <= $urandom;
    end
    else if(data_in_valid == 0)begin
        data_in <= $urandom;
    end
end

always @(posedge clk or negedge rst_n)begin
    if(~rst_n)begin
        data_in_power <= 'x;
    end
    else if(data_in_valid && data_in_ready)begin
        data_in_power <= $urandom;
    end
    else if(data_in_valid == 0)begin
        data_in_power <= $urandom;
    end
end

//-------------------------------------}}}

//-------------------------------------{{{other sig assign
initial begin
    `DELAY(50, clk);
end

//-------------------------------------}}}

//-------------------------------------{{{rtl inst
bypass_fifo #(
    .DEPTH(DEPTH),
    .WIDTH(WIDTH)) 
u_bypass_fifo(
    .clk(clk),
    .rst_n(rst_n),
    .data_in_valid(data_in_valid),
    .data_in(data_in),
    .data_in_power(data_in_power),
    .data_in_ready(data_in_ready),
    .data_out_valid(data_out_valid),
    .data_out(data_out),
    .data_out_ready(data_out_ready)
);
//-------------------------------------}}}

//-------------------------------------{{{auto_verification
task in_queue_gain();
  while(1)begin
    @(negedge clk);
    if(data_in_valid && data_in_ready)begin
      data_in_valid_struct data_in_valid_dat;
      data_in_valid_dat.data_in = data_in;
      data_in_valid_dat.data_in_power = data_in_power;
      data_in_valid_bus_q.push_back(data_in_valid_dat);
    end//if-end 
  end//while-end 
endtask: in_queue_gain

task out_queue_gain();
  while(1)begin
    @(negedge clk);
    if(data_out_valid && data_out_ready)begin
      data_out_valid_struct data_out_valid_dat;
      data_out_valid_dat.data_out = data_out;
      data_out_valid_bus_q.push_back(data_out_valid_dat);
    end//if-end 
  end//while-end 
endtask: out_queue_gain

task rm_queue_gain();
  data_in_valid_struct data_in_valid_dat;
  data_out_valid_struct data_out_valid_dat;
  while(1)begin
    wait(data_in_valid_bus_q.size > 0);
    data_in_valid_dat = data_in_valid_bus_q.pop_front();
    if(data_in_valid_dat.data_in_power === 1'b1)begin
        data_out_valid_dat.data_out = data_in_valid_dat.data_in;
        rm_q.push_back(data_out_valid_dat);
    end
  end
endtask: rm_queue_gain

task queue_check();
  while(1)begin
    data_out_valid_struct rm_data;
    data_out_valid_struct dual_data;
    wait(data_out_valid_bus_q.size() > 0);
    dual_data = data_out_valid_bus_q.pop_front();
    if(rm_q.size() == 0) begin
      $display("dual_data = %0p, rm_queue.size = 0", dual_data);
      error_cnt += 1;
    end
    else begin
      rm_data = rm_q.pop_front();
      if(dual_data != rm_data)begin
        error_cnt += 1;
        $display("dual_data(%0p) != rm_data(%0p) at %t", dual_data, rm_data, $realtime);
      end
      else begin
        //$display("dual_data(%0p) == rm_data(%0p) at %t", dual_data, rm_data, $realtime);
      end
    end
    if(error_cnt >= ERROR_DEBUG_CNT) begin
      $display("Check Error!!!");
      $finish;
    end
  end
endtask: queue_check

initial begin
  fork
    in_queue_gain();
    out_queue_gain();
    rm_queue_gain();
    if(check_en == 1) queue_check();
  join_none
end

//-------------------------------------}}}
endmodule
