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

class SDPBIO(params: SDPBBundleParameters = MySDPBBundleParameters) extends Bundle{
    val reset = Input(Bool())
    val oce = Input(Bool())
    //写端口
    val clka = Input(Clock())
    val cea = Input(Bool())
    val ada = Input(UInt(params.a_addrBits.W))
    val din = Input(UInt(params.a_dataBits.W))
    val byte_ena = Input(UInt(params.a_strbBits.W))
    //读端口
    val clkb = Input(Clock())
    val ceb = Input(Bool())
    val adb = Input(UInt(params.b_addrBits.W))
    val dout = Output(UInt(params.b_dataBits.W))
}

class sram(params: SDPBBundleParameters = MySDPBBundleParameters) extends BlackBox {
  val io = IO(new SDPBIO(params))
}

class AXI4SRAM extends Module {
  val io=IO(Flipped(new AXI4Bundle(CPUAXI4BundleParameters())))

  val bsram = IO(new SDPBIO(params))
  bsram.io.reset := reset.asBool
  bsram.io.oce := 1.U

  // burst is not supported
  assert(!(io.ar.valid && io.ar.bits.len =/= 0.U))
  assert(!(io.aw.valid && io.aw.bits.len =/= 0.U))
  // size > 4 is not supported
  assert(!(io.ar.valid && io.ar.bits.size > "b10".U))
  assert(!(io.aw.valid && io.aw.bits.size > "b10".U))


  val s_idle :: s_wait :: Nil = Enum(2)

  //read channel
  val rstate = RegInit(s_idle)
  rstate := MuxLookup(rstate, s_idle, Seq(
    s_idle -> Mux(io.ar.fire , s_wait, s_idle),
    s_wait -> Mux(io.r.fire || io.ar.fire, s_idle, s_wait)
  ))
  io. r.valid := rstate === s_wait
  io.ar.ready := true.B
  io. r.bits.resp := AXI4Parameters.RESP_OKAY
  io. r.bits.data := RegEnable(bsram.io.dout, io.ar.fire)
  io. r.bits.last := true.B
  io .r.bits.id := RegEnable(io.ar.bits.id, io.ar.fire)

  bsram.io.clkb := clock
  bsram.io.ceb := io.ar.fire
  bsram.io.adb := io.ar.bits.addr

  //write channel
  val wstate = RegInit(s_idle)
  wstate := MuxLookup(wstate, s_idle, Seq(
    s_idle -> Mux(io.aw.fire && io.w.fire, s_wait, s_idle),
    s_wait -> Mux(io.b.fire || (io.aw.fire && io.w.fire), s_idle, s_wait)
  ))
  io.aw.ready := true.B
  io. w.ready := true.B
  io.b.valid := wstate === s_wait
  io.b.bits.resp := AXI4Parameters.RESP_OKAY
  io.b.bits.id := RegEnable(io.aw.bits.id, io.aw.fire)

  bsram.io.clka := clock
  bsram.io.cea := io.aw.fire
  bsram.io.ada := io.aw.bits.addr
  bsram.io.din := io.w.bits.data
  bsram.io.byte_ena := io.w.bits.strb
}