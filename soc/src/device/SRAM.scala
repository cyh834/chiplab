package soc

import chisel3._
import chisel3.util._
import scala.math.ceil

import freechips.rocketchip.amba.axi4._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._

// a是写端口，b是读端口
case class SDPBBundleParameters(a_depth: Int, a_dataBits: Int, b_depth: Int, b_dataBits: Int){

  val a_addrBits = log2Ceil(a_depth)
  val b_addrBits = log2Ceil(b_depth)
  val a_strbBits = (a_dataBits + 7) / 8
  require (a_addrBits >= 1, s"SDPB addr bits must be >= 1 (got $a_addrBits)")
  require (a_dataBits >= 8, s"SDPB data bits must be >= 8 (got $a_dataBits)")
  require (b_addrBits >= 1, s"SDPB addr bits must be >= 1 (got $b_addrBits)")
  require (b_dataBits >= 8, s"SDPB data bits must be >= 8 (got $b_dataBits)")
}

object MySDPBBundleParameters {
  def apply():SDPBBundleParameters = SDPBBundleParameters(a_depth = 65536, a_dataBits = 32, b_depth = 65536, b_dataBits = 32)
}

class SDPBIO(params: SDPBBundleParameters = MySDPBBundleParameters()) extends Bundle{
    val reset     = Output(Bool())
    val oce       = Output(Bool())
    //写端口
    val clka      = Output(Bool())
    val cea       = Output(Bool())
    val ada       = Output(UInt(params.a_addrBits.W))
    val din       = Output(UInt(params.a_dataBits.W))
    val byte_ena  = Output(UInt(params.a_strbBits.W))
    //读端口
    val clkb      = Output(Bool())
    val ceb       = Output(Bool())
    val adb       = Output(UInt(params.b_addrBits.W))
    val dout      = Input(UInt(params.b_dataBits.W))
}

class sdpb_top extends Module {
  val io = IO(new Bundle {
    val clock = Input(Clock())
    val reset = Input(Bool())
    val in = Flipped(new AXI4Bundle(AXI4BundleParameters(addrBits = 32, dataBits = 32, idBits = 4)))
    val sdpb = new SDPBIO
  })
    io.sdpb.reset := io.reset
    io.sdpb.oce := 1.U

    // burst is not supported
    assert(!(io.in.ar.valid && io.in.ar.bits.len =/= 0.U))
    assert(!(io.in.aw.valid && io.in.aw.bits.len =/= 0.U))
    // size > 4 is not supported
    assert(!(io.in.ar.valid && io.in.ar.bits.size > "b10".U))
    assert(!(io.in.aw.valid && io.in.aw.bits.size > "b10".U))


    val s_idle :: s_wait :: Nil = Enum(2)

    //read channel
    val rstate = RegInit(s_idle)
    rstate := MuxLookup(rstate, s_idle)(Seq(
      s_idle -> Mux(io.in.ar.fire , s_wait, s_idle),
      s_wait -> Mux(io.in.r.fire || io.in.ar.fire, s_idle, s_wait)
    ))

    io.in. r.valid := rstate === s_wait
    io.in.ar.ready := true.B
    io.in. r.bits.resp := AXI4Parameters.RESP_OKAY
    io.in. r.bits.data := Mux(io.in.r.fire, io.sdpb.dout, x"deadbeef".U)
    io.in. r.bits.last := true.B
    io.in. r.bits.id := RegEnable(io.in.ar.bits.id, io.in.ar.fire)

    io.sdpb.clkb := clock.asBool
    io.sdpb.ceb := io.in.ar.fire
    io.sdpb.adb := io.in.ar.bits.addr >> 2.U

    //write channel
    val wstate = RegInit(s_idle)
    wstate := MuxLookup(wstate, s_idle)(Seq(
      s_idle -> Mux(io.in.aw.fire && io.in.w.fire, s_wait, s_idle),
      s_wait -> Mux(io.in.b.fire || (io.in.aw.fire && io.in.w.fire), s_idle, s_wait)
    ))
    io.in.aw.ready := true.B
    io.in. w.ready := true.B
    io.in.b.valid := wstate === s_wait
    io.in.b.bits.resp := AXI4Parameters.RESP_OKAY
    io.in.b.bits.id := RegEnable(io.in.aw.bits.id, io.in.aw.fire)

    io.sdpb.clka := clock.asBool
    io.sdpb.cea := io.in.aw.fire
    io.sdpb.ada := io.in.aw.bits.addr >> 2.U
    io.sdpb.din := io.in.w.bits.data
    io.sdpb.byte_ena := io.in.w.bits.strb
}

class SRAM_SDPB(params: SDPBBundleParameters = MySDPBBundleParameters()) extends BlackBox {
  val io = IO(Flipped(new SDPBIO(params)))
}

class AXI4SRAM(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
  val beatBytes = 4

  val node = AXI4SlaveNode(Seq(AXI4SlavePortParameters(
    Seq(AXI4SlaveParameters(
        address       = address,
        executable    = true,
        supportsWrite = TransferSizes(1, beatBytes), //范围：[1,beatBytes]
        supportsRead  = TransferSizes(1, beatBytes), //范围：[1,beatBytes]
        interleavedId = Some(0))),
    beatBytes  = beatBytes)))

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val (in, _) = node.in(0)

    val sram_bundle = IO(new SDPBIO)
    val msram = Module(new sdpb_top)
    msram.io.clock := clock
    msram.io.reset := reset.asBool
    msram.io.in <> in
    sram_bundle <> msram.io.sdpb
  }
}