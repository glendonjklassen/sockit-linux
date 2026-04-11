// bridge_ledkey_probe_bridge_0_fixed.v
//
// Quartus 25.1 generates a recursive self-instantiation for the
// hps_bridge_avalon wrapper in tiny bridge-only Platform Designer systems.
// This checked-in replacement keeps only the bridge paths used by this demo:
//   - h2f_reset
//   - h2f_lw
// Everything else is tied off so the generated system remains buildable.

`timescale 1 ps / 1 ps
module bridge_ledkey_probe_bridge_0 #(
        parameter F2S_Width = 2,
        parameter S2F_Width = 2
    ) (
        output wire        h2f_rst_n,
        input  wire        new_signal_13,
        input  wire        new_signal_14,

        input  wire        h2f_axi_clk,
        output wire [11:0] h2f_AWID,
        output wire [29:0] h2f_AWADDR,
        output wire [3:0]  h2f_AWLEN,
        output wire [2:0]  h2f_AWSIZE,
        output wire [1:0]  h2f_AWBURST,
        output wire [1:0]  h2f_AWLOCK,
        output wire [3:0]  h2f_AWCACHE,
        output wire [2:0]  h2f_AWPROT,
        output wire        h2f_AWVALID,
        input  wire        h2f_AWREADY,
        output wire [11:0] h2f_WID,
        output wire [127:0] h2f_WDATA,
        output wire [15:0] h2f_WSTRB,
        output wire        h2f_WLAST,
        output wire        h2f_WVALID,
        input  wire        h2f_WREADY,
        input  wire [11:0] h2f_BID,
        input  wire [1:0]  h2f_BRESP,
        input  wire        h2f_BVALID,
        output wire        h2f_BREADY,
        output wire [11:0] h2f_ARID,
        output wire [29:0] h2f_ARADDR,
        output wire [3:0]  h2f_ARLEN,
        output wire [2:0]  h2f_ARSIZE,
        output wire [1:0]  h2f_ARBURST,
        output wire [1:0]  h2f_ARLOCK,
        output wire [3:0]  h2f_ARCACHE,
        output wire [2:0]  h2f_ARPROT,
        output wire        h2f_ARVALID,
        input  wire        h2f_ARREADY,
        input  wire [11:0] h2f_RID,
        input  wire [127:0] h2f_RDATA,
        input  wire [1:0]  h2f_RRESP,
        input  wire        h2f_RLAST,
        input  wire        h2f_RVALID,
        output wire        h2f_RREADY,

        input  wire        h2f_lw_axi_clk,
        output wire [11:0] h2f_lw_AWID,
        output wire [20:0] h2f_lw_AWADDR,
        output wire [3:0]  h2f_lw_AWLEN,
        output wire [2:0]  h2f_lw_AWSIZE,
        output wire [1:0]  h2f_lw_AWBURST,
        output wire [1:0]  h2f_lw_AWLOCK,
        output wire [3:0]  h2f_lw_AWCACHE,
        output wire [2:0]  h2f_lw_AWPROT,
        output wire        h2f_lw_AWVALID,
        input  wire        h2f_lw_AWREADY,
        output wire [11:0] h2f_lw_WID,
        output wire [31:0] h2f_lw_WDATA,
        output wire [3:0]  h2f_lw_WSTRB,
        output wire        h2f_lw_WLAST,
        output wire        h2f_lw_WVALID,
        input  wire        h2f_lw_WREADY,
        input  wire [11:0] h2f_lw_BID,
        input  wire [1:0]  h2f_lw_BRESP,
        input  wire        h2f_lw_BVALID,
        output wire        h2f_lw_BREADY,
        output wire [11:0] h2f_lw_ARID,
        output wire [20:0] h2f_lw_ARADDR,
        output wire [3:0]  h2f_lw_ARLEN,
        output wire [2:0]  h2f_lw_ARSIZE,
        output wire [1:0]  h2f_lw_ARBURST,
        output wire [1:0]  h2f_lw_ARLOCK,
        output wire [3:0]  h2f_lw_ARCACHE,
        output wire [2:0]  h2f_lw_ARPROT,
        output wire        h2f_lw_ARVALID,
        input  wire        h2f_lw_ARREADY,
        input  wire [11:0] h2f_lw_RID,
        input  wire [31:0] h2f_lw_RDATA,
        input  wire [1:0]  h2f_lw_RRESP,
        input  wire        h2f_lw_RLAST,
        input  wire        h2f_lw_RVALID,
        output wire        h2f_lw_RREADY,

        input  wire        f2h_axi_clk,
        output wire [7:0]  f2h_AWID,
        output wire [31:0] f2h_AWADDR,
        output wire [3:0]  f2h_AWLEN,
        output wire [2:0]  f2h_AWSIZE,
        output wire [1:0]  f2h_AWBURST,
        output wire [1:0]  f2h_AWLOCK,
        output wire [3:0]  f2h_AWCACHE,
        output wire [2:0]  f2h_AWPROT,
        output wire        f2h_AWVALID,
        input  wire        f2h_AWREADY,
        output wire [4:0]  f2h_AWUSER,
        output wire [7:0]  f2h_WID,
        output wire [127:0] f2h_WDATA,
        output wire [15:0] f2h_WSTRB,
        output wire        f2h_WLAST,
        output wire        f2h_WVALID,
        input  wire        f2h_WREADY,
        input  wire [7:0]  f2h_BID,
        input  wire [1:0]  f2h_BRESP,
        input  wire        f2h_BVALID,
        output wire        f2h_BREADY,
        output wire [7:0]  f2h_ARID,
        output wire [31:0] f2h_ARADDR,
        output wire [3:0]  f2h_ARLEN,
        output wire [2:0]  f2h_ARSIZE,
        output wire [1:0]  f2h_ARBURST,
        output wire [1:0]  f2h_ARLOCK,
        output wire [3:0]  f2h_ARCACHE,
        output wire [2:0]  f2h_ARPROT,
        output wire        f2h_ARVALID,
        input  wire        f2h_ARREADY,
        output wire [4:0]  f2h_ARUSER,
        input  wire [7:0]  f2h_RID,
        input  wire [127:0] f2h_RDATA,
        input  wire [1:0]  f2h_RRESP,
        input  wire        f2h_RLAST,
        input  wire        f2h_RVALID,
        output wire        f2h_RREADY,

        output wire [31:0] f2h_sdram0_ARADDR,
        output wire [3:0]  f2h_sdram0_ARLEN,
        output wire [7:0]  f2h_sdram0_ARID,
        output wire [2:0]  f2h_sdram0_ARSIZE,
        output wire [1:0]  f2h_sdram0_ARBURST,
        output wire [1:0]  f2h_sdram0_ARLOCK,
        output wire [2:0]  f2h_sdram0_ARPROT,
        output wire        f2h_sdram0_ARVALID,
        output wire [3:0]  f2h_sdram0_ARCACHE,
        output wire [31:0] f2h_sdram0_AWADDR,
        output wire [3:0]  f2h_sdram0_AWLEN,
        output wire [7:0]  f2h_sdram0_AWID,
        output wire [2:0]  f2h_sdram0_AWSIZE,
        output wire [1:0]  f2h_sdram0_AWBURST,
        output wire [1:0]  f2h_sdram0_AWLOCK,
        output wire [2:0]  f2h_sdram0_AWPROT,
        output wire        f2h_sdram0_AWVALID,
        output wire [3:0]  f2h_sdram0_AWCACHE,
        input  wire [1:0]  f2h_sdram0_BRESP,
        input  wire [7:0]  f2h_sdram0_BID,
        input  wire        f2h_sdram0_BVALID,
        output wire        f2h_sdram0_BREADY,
        input  wire        f2h_sdram0_ARREADY,
        input  wire        f2h_sdram0_AWREADY,
        output wire        f2h_sdram0_RREADY,
        input  wire [63:0] f2h_sdram0_RDATA,
        input  wire [1:0]  f2h_sdram0_RRESP,
        input  wire        f2h_sdram0_RLAST,
        input  wire [7:0]  f2h_sdram0_RID,
        input  wire        f2h_sdram0_RVALID,
        output wire        f2h_sdram0_WLAST,
        output wire        f2h_sdram0_WVALID,
        output wire [63:0] f2h_sdram0_WDATA,
        output wire [7:0]  f2h_sdram0_WSTRB,
        input  wire        f2h_sdram0_WREADY,
        output wire [7:0]  f2h_sdram0_WID,
        input  wire        f2h_sdram0_clk
    );

    assign h2f_rst_n = ~new_signal_13;

    /* Full H2F bridge is unused in this design. */
    assign h2f_AWID    = 12'b0;
    assign h2f_AWADDR  = 30'b0;
    assign h2f_AWLEN   = 4'b0;
    assign h2f_AWSIZE  = 3'b0;
    assign h2f_AWBURST = 2'b0;
    assign h2f_AWLOCK  = 2'b0;
    assign h2f_AWCACHE = 4'b0;
    assign h2f_AWPROT  = 3'b0;
    assign h2f_AWVALID = 1'b0;
    assign h2f_WID     = 12'b0;
    assign h2f_WDATA   = 128'b0;
    assign h2f_WSTRB   = 16'b0;
    assign h2f_WLAST   = 1'b0;
    assign h2f_WVALID  = 1'b0;
    assign h2f_BREADY  = 1'b0;
    assign h2f_ARID    = 12'b0;
    assign h2f_ARADDR  = 30'b0;
    assign h2f_ARLEN   = 4'b0;
    assign h2f_ARSIZE  = 3'b0;
    assign h2f_ARBURST = 2'b0;
    assign h2f_ARLOCK  = 2'b0;
    assign h2f_ARCACHE = 4'b0;
    assign h2f_ARPROT  = 3'b0;
    assign h2f_ARVALID = 1'b0;
    assign h2f_RREADY  = 1'b0;

    cyclonev_hps_interface_hps2fpga_light_weight hps2fpga_light_weight (
        .clk    (h2f_lw_axi_clk),
        .awid   (h2f_lw_AWID),
        .awaddr (h2f_lw_AWADDR),
        .awlen  (h2f_lw_AWLEN),
        .awsize (h2f_lw_AWSIZE),
        .awburst(h2f_lw_AWBURST),
        .awlock (h2f_lw_AWLOCK),
        .awcache(h2f_lw_AWCACHE),
        .awprot (h2f_lw_AWPROT),
        .awvalid(h2f_lw_AWVALID),
        .awready(h2f_lw_AWREADY),
        .wid    (h2f_lw_WID),
        .wdata  (h2f_lw_WDATA),
        .wstrb  (h2f_lw_WSTRB),
        .wlast  (h2f_lw_WLAST),
        .wvalid (h2f_lw_WVALID),
        .wready (h2f_lw_WREADY),
        .bid    (h2f_lw_BID),
        .bresp  (h2f_lw_BRESP),
        .bvalid (h2f_lw_BVALID),
        .bready (h2f_lw_BREADY),
        .arid   (h2f_lw_ARID),
        .araddr (h2f_lw_ARADDR),
        .arlen  (h2f_lw_ARLEN),
        .arsize (h2f_lw_ARSIZE),
        .arburst(h2f_lw_ARBURST),
        .arlock (h2f_lw_ARLOCK),
        .arcache(h2f_lw_ARCACHE),
        .arprot (h2f_lw_ARPROT),
        .arvalid(h2f_lw_ARVALID),
        .arready(h2f_lw_ARREADY),
        .rid    (h2f_lw_RID),
        .rdata  (h2f_lw_RDATA),
        .rresp  (h2f_lw_RRESP),
        .rlast  (h2f_lw_RLAST),
        .rvalid (h2f_lw_RVALID),
        .rready (h2f_lw_RREADY)
    );

    /* FPGA-to-HPS and FPGA-to-SDRAM paths are unused in this design. */
    assign f2h_AWID    = 8'b0;
    assign f2h_AWADDR  = 32'b0;
    assign f2h_AWLEN   = 4'b0;
    assign f2h_AWSIZE  = 3'b0;
    assign f2h_AWBURST = 2'b0;
    assign f2h_AWLOCK  = 2'b0;
    assign f2h_AWCACHE = 4'b0;
    assign f2h_AWPROT  = 3'b0;
    assign f2h_AWVALID = 1'b0;
    assign f2h_AWUSER  = 5'b0;
    assign f2h_WID     = 8'b0;
    assign f2h_WDATA   = 128'b0;
    assign f2h_WSTRB   = 16'b0;
    assign f2h_WLAST   = 1'b0;
    assign f2h_WVALID  = 1'b0;
    assign f2h_BREADY  = 1'b0;
    assign f2h_ARID    = 8'b0;
    assign f2h_ARADDR  = 32'b0;
    assign f2h_ARLEN   = 4'b0;
    assign f2h_ARSIZE  = 3'b0;
    assign f2h_ARBURST = 2'b0;
    assign f2h_ARLOCK  = 2'b0;
    assign f2h_ARCACHE = 4'b0;
    assign f2h_ARPROT  = 3'b0;
    assign f2h_ARVALID = 1'b0;
    assign f2h_ARUSER  = 5'b0;
    assign f2h_RREADY  = 1'b0;

    assign f2h_sdram0_ARADDR  = 32'b0;
    assign f2h_sdram0_ARLEN   = 4'b0;
    assign f2h_sdram0_ARID    = 8'b0;
    assign f2h_sdram0_ARSIZE  = 3'b0;
    assign f2h_sdram0_ARBURST = 2'b0;
    assign f2h_sdram0_ARLOCK  = 2'b0;
    assign f2h_sdram0_ARPROT  = 3'b0;
    assign f2h_sdram0_ARVALID = 1'b0;
    assign f2h_sdram0_ARCACHE = 4'b0;
    assign f2h_sdram0_AWADDR  = 32'b0;
    assign f2h_sdram0_AWLEN   = 4'b0;
    assign f2h_sdram0_AWID    = 8'b0;
    assign f2h_sdram0_AWSIZE  = 3'b0;
    assign f2h_sdram0_AWBURST = 2'b0;
    assign f2h_sdram0_AWLOCK  = 2'b0;
    assign f2h_sdram0_AWPROT  = 3'b0;
    assign f2h_sdram0_AWVALID = 1'b0;
    assign f2h_sdram0_AWCACHE = 4'b0;
    assign f2h_sdram0_BREADY  = 1'b0;
    assign f2h_sdram0_RREADY  = 1'b0;
    assign f2h_sdram0_WLAST   = 1'b0;
    assign f2h_sdram0_WVALID  = 1'b0;
    assign f2h_sdram0_WDATA   = 64'b0;
    assign f2h_sdram0_WSTRB   = 8'b0;
    assign f2h_sdram0_WID     = 8'b0;
endmodule
