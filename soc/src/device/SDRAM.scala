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
import freechips.rocketchip.subsystem._

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

class DMIIO_LITE extends Bundle {
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
  val clk_out = Output(Clock())
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

class DMIIO extends DMIIO_LITE{
  val clk = Input(Clock())
  val memory_clk = Input(Clock())
  val pll_lock = Input(Bool())
  val rst_n = Input(Bool())
}

class DDR3_Memory_Interface_Top_IO extends DMIIO{
  val O_ddr = new o_ddr
  val IO_ddr_dq = Analog(32.W)
  val IO_ddr_dqs = Analog(4.W)
  val IO_ddr_dqs_n = Analog(4.W)
}

class ddr_fifo_io extends Bundle{
  val Data = Input(UInt(32.W))
  val Reset = Input(Bool())
  val WrClk = Input(Clock())
  val RdClk = Input(Clock())
  val WrEn = Input(Bool())
  val RdEn = Input(Bool())
  val Wnum = Input(UInt(2.W))
  val Rnum = Input(UInt(2.W))
  val Q = Output(UInt(32.W))
  val Empty = Output(Bool())
  val Full = Output(Bool())
}

class ddr_fifo extends BlackBox{
  val io = IO(new ddr_fifo_io)
}

class DDR3_Memory_Interface_Top extends BlackBox{
  val io = IO(new DDR3_Memory_Interface_Top_IO)
}

class sdram_top_axi extends Module{
  val io = IO(new Bundle{
    val clk_out = Output(Clock())
    val in = Flipped(new AXI4Bundle(AXI4BundleParameters(addrBits = 32, dataBits = 32, idBits = 4)))
    val dmi = Flipped(new DMIIO_LITE)
})

  val (ar, r, aw, w, b) = (io.in.ar, io.in.r, io.in.aw, io.in.w, io.in.b)

  val s_idle :: s_inflight :: s_wait_rready_bready :: Nil = Enum(3)
  val state = RegInit(s_idle)
  val accept_read = (state === s_idle) && ar.valid
  val accept_write = !accept_read && (state === s_idle) && aw.valid && w.valid
  val is_write = accept_write holdUnless (state === s_idle)

  val done = Mux(is_write, io.dmi.wr_data_rdy & io.dmi.cmd_ready, io.dmi.rd_data_valid)
  switch (state) {
    is (s_idle)     { state := Mux((ar.valid || (aw.valid && w.valid)) & io.dmi.init_calib_complete, s_inflight, s_idle) }
    is (s_inflight) { state := Mux(done, Mux(r.fire || b.fire, s_idle, s_wait_rready_bready), s_inflight) }
    is (s_wait_rready_bready) { state := Mux(r.fire || b.fire, s_idle, s_wait_rready_bready) }
  }

  // burst is not supported
  assert(!(ar.valid && ar.bits.len =/= 0.U))
  assert(!(aw.valid && aw.bits.len =/= 0.U))
  // size > 4 is not supported
  assert(!(ar.valid && ar.bits.size > "b10".U))
  assert(!(aw.valid && aw.bits.size > "b10".U))

  val rid_reg    = RegEnable(ar.bits.id, accept_read)
  val bid_reg    = RegEnable(aw.bits.id, accept_write)
  val araddr_reg = ar.bits.addr holdUnless accept_read
  val awaddr_reg = aw.bits.addr holdUnless accept_write
  val wdata_reg  =  w.bits.data holdUnless accept_write
  val wstrb_reg  =  w.bits.strb holdUnless accept_write

  val addr = Mux(is_write, awaddr_reg, araddr_reg)
  io.dmi.cmd := Mux(is_write, 0.U, 1.U)
  io.dmi.cmd_en := state === s_inflight
  io.dmi.addr := addr & "xffffffe0".U
  io.dmi.wr_data := (Cat(0.U(224.W),wdata_reg) << Cat(addr(4,0),0.U(3.W)))
  io.dmi.wr_data_en := (state === s_inflight) & is_write  & io.dmi.wr_data_rdy & io.dmi.cmd_ready
  io.dmi.wr_data_end := (state === s_inflight) & is_write  & io.dmi.wr_data_rdy & io.dmi.cmd_ready
  io.dmi.wr_data_mask :=  Mux(is_write,(Cat(0.U(28.W),wstrb_reg(3,0)) << addr(4,0)), 0.U)
  io.dmi.sr_req := false.B
  io.dmi.ref_req := false.B
  io.dmi.burst := 0.U
  io.clk_out := io.dmi.clk_out

  ar.ready := accept_read & io.dmi.init_calib_complete
  w.ready  := accept_write & io.dmi.init_calib_complete
  aw.ready := accept_write & io.dmi.init_calib_complete

  val resp = AXI4Parameters.RESP_OKAY
  val resp_hold = resp holdUnless (state === s_inflight)
  r.valid  := !is_write && (((state === s_inflight) && io.dmi.rd_data_valid) || (state === s_wait_rready_bready))
  r.bits.data := (io.dmi.rd_data >> Cat(addr(4,0),0.U(3.W))) holdUnless (state === s_inflight)
  r.bits.id   := rid_reg
  r.bits.resp := resp_hold
  r.bits.last := true.B

  b.valid  := is_write && (((state === s_inflight) && io.dmi.wr_data_rdy) || (state === s_wait_rready_bready))
  b.bits.resp := resp_hold
  b.bits.id   := bid_reg
}

class AXI4SDRAM(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule with HasCrossing{
  val crossing = AsynchronousCrossing(8)

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
    val sdram_bundle = IO(Flipped(new DMIIO_LITE))
    val clk_out = IO(Output(Clock()))

    val msdram = Module(new sdram_top_axi)
    msdram.io.in <> in
    sdram_bundle <> msdram.io.dmi
    clk_out <> msdram.io.clk_out
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

