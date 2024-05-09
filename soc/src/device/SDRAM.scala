package soc

import chisel3._
import chisel3.util._
import chisel3.experimental.Analog

import freechips.rocketchip.amba._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.amba.apb._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._

class o_ddr extends Bundle {
  val addr = Output(UInt(15.W))
  val ba = Output(UInt(3.W))
  val cs_n = Output(Bool())
  val ras_n = Output(Bool())
  val cas_n = Output(Bool())
  val we_n = Output(Bool())
  val clk = Output(Bool())
  val clk_n = Output(Bool())
  val cke = Output(Bool())
  val odt = Output(Bool())
  val reset_n = Output(Bool())
  val dqm = Output(UInt(4.W))
}

class DDR3IO extends Bundle {
  val O_ddr = new o_ddr
  val dq = Analog(32.W)
  val dqs = Analog(4.W)
  val dqs_n = Analog(4.W)
}

class DMIIO extends Bundle {
  val clk = Input(Clock())
  val memory_clk = Input(Clock())
  val pll_lock = Input(Bool())
  val rst_n = Input(Bool())
  val cmd = Input(UInt(3.W))
  val cmd_en = Input(Bool())
  val addr = Input(UInt(29.W))
  val wr_data = Input(UInt(256.W))
  val wr_data_en = Input(Bool())
  val wr_data_end = Input(Bool())
  val wr_data_mask = Input(UInt(32.W))
  val sr_req = Input(Bool())
  val ref_req = Input(Bool())
  val burst = Input(Bool())
  val pll_stop = Output(Bool())
  val clk_out = Output(Bool())
  val ddr_rst = Output(Bool())
  val init_calib_complete = Output(Bool())
  val cmd_ready = Output(Bool())
  val wr_data_rdy = Output(Bool())
  val rd_data = Output(UInt(256.W))
  val rd_data_valid = Output(Bool())
  val rd_data_end = Output(Bool())
  val sr_ack = Output(Bool())
  val ref_ack = Output(Bool())
}

class DDR3_Memory_Interface_Top_IO extends DMIIO{
  val O_ddr = new o_ddr
  val IO_ddr_dq = Analog(32.W)
  val IO_ddr_dqs = Analog(4.W)
  val IO_ddr_dqs_n = Analog(4.W)
}

class DDR3_Memory_Interface_Top extends BlackBox{
  val io = IO(new DDR3_Memory_Interface_Top_IO)
}

class sdram_top_axi extends BlackBox{
  val io = IO(new Bundle{
    val clock = Input(Clock())
    val reset = Input(Bool())
    val in = Flipped(new AXI4Bundle(AXI4BundleParameters(addrBits = 32, dataBits = 32, idBits = 4)))
    val dmi = Flipped(new DMIIO)
  })
}

class AXI4SDRAM(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
  val beatBytes = 4
  val node = AXI4SlaveNode(Seq(AXI4SlavePortParameters(
    Seq(AXI4SlaveParameters(
        address       = address,
        executable    = true,
        supportsWrite = TransferSizes(1, beatBytes),
        supportsRead  = TransferSizes(1, beatBytes),
        interleavedId = Some(0))
    ),
    beatBytes  = beatBytes)))
  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val (in, _) = node.in(0)
    val sdram_bundle = IO(Flipped(new DMIIO))

    val msdram = Module(new sdram_top_axi)
    msdram.io.clock := clock
    msdram.io.reset := reset
    msdram.io.in <> in
    sdram_bundle <> msdram.io.dmi
  }
}





















//class sdram extends BlackBox {
//  val io = IO(Flipped(new DDR3IO))
//}

//class AXI4SDRAM(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
//  val beatBytes = 4
//
//  val node = AXI4SlaveNode(Seq(AXI4SlavePortParameters(
//    Seq(AXI4SlaveParameters(
//        address       = address,
//        executable    = true,
//        supportsWrite = TransferSizes(1, beatBytes), //范围：[1,beatBytes]
//        supportsRead  = TransferSizes(1, beatBytes), //范围：[1,beatBytes]
//        interleavedId = Some(0))),
//    beatBytes  = beatBytes)))
//
//  lazy val module = new Impl
//  class Impl extends LazyModuleImp(this) {
//    val (in, _) = node.in(0)
//
//    val sdram_bundle = IO(new SDRAMIO)
//    val msdram = Module(new Paski_GowinDDR_AXI4_Compatible)
//
//    msdram.io.sys_clk_resetn := sdram_bundle.sig.sys_clk_resetn
//    msdram.io.sys_clk_clk := sdram_bundle.sig.sys_clk_clk
//    msdram.io.mem_clk_clk := sdram_bundle.sig.mem_clk_clk
//    msdram.io.io_pll_lock := sdram_bundle.sig.io_pll_lock
//
//    msdram.io.axi <> in
//
//    msdram.io.io_ddr_iface_O_ddr <> sdram_bundle.o_ddr
//    msdram.io.io_ddr_iface_IO_ddr_dq <> sdram_bundle.dq
//    msdram.io.io_ddr_iface_IO_ddr_dqs <> sdram_bundle.dqs
//    msdram.io.io_ddr_iface_IO_ddr_dqs_n <> sdram_bundle.dqs_n
//  }
//}

