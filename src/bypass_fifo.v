module bypass_fifo #(
	parameter DEPTH = 8,
	parameter WIDTH = 128
)(
	input 				clk,
	input 				rst_n,
	
	input  			    data_in_valid,
	input  [WIDTH -1:0] data_in,
    input               data_in_power,
	output 			    data_in_ready,
	
	output			    data_out_valid,
	output [WIDTH -1:0] data_out,
	input  			    data_out_ready
);

localparam DP_WD = DEPTH == 1 ? 1 : $clog2(DEPTH);
localparam BM_WD = DEPTH*2;

//==================================================================
//公用信号
//==================================================================
wire inner_data_out_valid;
wire inner_data_out_ready;

wire in_hand_en        = data_in_valid && data_in_ready;
wire out_hand_en       = data_out_valid && data_out_ready;
wire out_inner_hand_en = inner_data_out_valid && inner_data_out_ready;

reg  [DP_WD   :0]waddr;
//reg  [DP_WD   :0]raddr;
wire [DP_WD   :0]raddr;

//==================================================================
//写入计数器
//==================================================================
wire             wenc;
wire             waddr_d_h;
wire [DP_WD -1:0]waddr_d_l;
assign wenc = in_hand_en;
assign waddr_d_h = (waddr[DP_WD-1:0] == DEPTH-1) ? ~waddr[DP_WD] : waddr[DP_WD];
assign waddr_d_l = (waddr[DP_WD-1:0] == DEPTH-1) ? 0 : waddr[DP_WD-1:0] + 1;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    waddr <= 0;
	else if(wenc) waddr <= {waddr_d_h, waddr_d_l};
end

//==================================================================
//bitmap维护
//==================================================================
reg  [BM_WD -1:0]power_bitmap_q;
wire             power_bitmap_en = in_hand_en || out_inner_hand_en;
wire [BM_WD -1:0]power_bitmap_d;
wire [BM_WD -1:0]power_bitmap_in;
wire [BM_WD -1:0]power_bitmap_out;
wire [BM_WD -1:0]power_bitmap_waddr;
wire [BM_WD -1:0]power_bitmap;

assign power_bitmap_in  =  ({{(BM_WD-1){1'b0}}, (in_hand_en & data_in_power & 1'b1)} << waddr);//0010
assign power_bitmap_out = ~({{(BM_WD-1){1'b0}}, (out_inner_hand_en & 1'b1)}              << raddr);//1011
assign power_bitmap_d   = (power_bitmap_q & power_bitmap_out) | power_bitmap_in;

always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    
        power_bitmap_q <= {BM_WD{1'b0}};
	else if(power_bitmap_en) 
        power_bitmap_q <= power_bitmap_d;
end

assign power_bitmap_waddr = ({{(BM_WD-1){1'b0}}, 1'b1} << waddr);
assign power_bitmap       = power_bitmap_q | power_bitmap_waddr;

//==================================================================
//
//==================================================================
wire [BM_WD -1:0]grant;
rr_dispatch #(.WD(BM_WD), .KEEP_MODE(0))
u_rr
(
	.clk(clk),
	.rst_n(rst_n),
	.req(power_bitmap),
	.ack(out_inner_hand_en),
	.grant(grant)
);

//==================================================================
//读出计数器
//==================================================================
reg  [DP_WD   :0]raddr_d;
wire             renc;

always @* begin: RADDR_D
    integer i;
    for(i=0; i<BM_WD; i=i+1)begin
        //$display("%d, %d", i, BM_WD);
        if(grant[i] == 1'b1) begin
            raddr_d = i;
        end
    end
end

assign raddr = raddr_d;
//assign renc = out_inner_hand_en;
//always @(posedge clk or negedge rst_n)begin
//	if(~rst_n)    raddr <= {DP_WD{1'b0}};
//    else if(renc) raddr <= raddr_d;
//end

//==================================================================
//输出逻辑
//==================================================================
wire   inner_out_real  = power_bitmap[raddr];
assign inner_data_out_valid = (raddr != waddr);
assign inner_data_out_ready = data_out_ready || (~inner_out_real);
assign data_out_valid       = inner_data_out_valid && inner_out_real;
assign data_in_ready        = !((raddr[DP_WD -1:0] == waddr[DP_WD -1:0]) && (raddr[DP_WD] != waddr[DP_WD]));

//==================================================================
//数据寄存
//==================================================================
reg [WIDTH -1:0]data[DEPTH -1:0];
always @(posedge clk)begin
	if(wenc) data[waddr[DP_WD-1:0]] <= data_in;
end
assign data_out = data[raddr[DP_WD-1:0]];

endmodule
