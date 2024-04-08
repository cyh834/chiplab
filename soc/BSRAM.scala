package soc

import chisel3._
import chisel3.util._
import scala.math.ceil

import freechips.rocketchip.amba.axi4._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._

// a是写端口，b是读端口
case class SDPBBundleParameters(a_addrBits: Int, a_dataBits: Int, b_addrBits: Int, b_dataBits: Int){
  require (a_addrBits >= 1, s"SDPB addr bits must be >= 1 (got $a_addrBits)")
  require (a_dataBits >= 8, s"SDPB data bits must be >= 8 (got $a_dataBits)")
  require (b_addrBits >= 1, s"SDPB addr bits must be >= 1 (got $b_addrBits)")
  require (b_dataBits >= 8, s"SDPB data bits must be >= 8 (got $b_dataBits)")
}

object SDPBBundleParameters {
  def apply():SDPBBundleParameters = SDPBBundleParameters(a_addrBits = 7, a_dataBits = 32, b_addrBits = 7, b_dataBits = 32)
}

class BSRAM_SDPB(params: SDPBBundleParameters) extends BlackBox {
  val io = IO(new Bundle {
    val reset = Input(Bool())
    val oce = Input(Bool())
    //写端口
    val clka = Input(Clock())
    val cea = Input(Bool())
    val ada = Input(UInt(params.a_addrBits.W))
    val din = Input(UInt(params.a_dataBits.W))
    val byte_ena = Input(UInt(ceil(params.a_dataBits.toDouble / 8).toInt.W))
    //读端口
    val clkb = Input(Clock())
    val ceb = Input(Bool())
    val adb = Input(UInt(params.b_addrBits.W))
    val dout = Output(UInt(params.b_dataBits.W))
  })
}

class AXI4BSRAM(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
  val beatBytes = 4
  val node = AXI4SlaveNode(Seq(AXI4SlavePortParameters(
    Seq(AXI4SlaveParameters(
        address       = address,
        executable    = true,
        supportsWrite = TransferSizes(1, beatBytes), //范围：[1,beatBytes]
        supportsRead  = TransferSizes(1, beatBytes), //范围：[1,beatBytes]
        interleavedId = Some(0))
    ),
    beatBytes  = beatBytes)))

  private val outer = this

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val (in, _) = node.in(0)

    val bsram = Module(new BSRAM_SDPB(SDPBBundleParameters()))

    val s_idle :: s_wait_ready  :: Nil = Enum(2)

    //读通道
    val rstate = RegInit(s_idle)
    rstate := MuxLookup(rstate, s_idle, List(
      s_idle        -> Mux(ar.fire, s_wait_ready, s_idle),
      s_wait_ready  -> Mux(rlast.asBool & (~ar.fire), s_idle, s_wait_ready),
    ))
    val rid=RegEnable(ar.bits.id,0.U(4.W),ar.fire)
    val raddr=RegInit(0.U(32.W))
    val rlen=RegInit(0.U(8.W))
    val rsize=RegInit(0.U(3.W))
    val rburst=RegInit(0.U(2.W))
    val lower_bound_addr=RegEnable(ar.bits.addr & (((~ar.bits.len.asTypeOf(UInt(32.W))) << ar.bits.size )),0.U(32.W),ar.fire)
    val rcnt = RegInit(0.U(8.W))
    val beatcnt = RegInit(0.U(8.W))

    raddr := MuxCase(raddr,List(
      (ar.fire) -> ar.bits.addr,
      (rlast.asBool) -> 0.U,
      (r.fire & (beatcnt === 255.U | beatcnt === rlen)) -> lower_bound_addr,
      (r.fire) -> raddr + (1.U(32.W)<< rsize)
    ))

    rlen := Mux(io.ar.fire,io.ar.bits.len,rlen)
    rsize := Mux(io.ar.fire,io.ar.bits.size ,rsize )
    rburst:= Mux(io.ar.fire,io.ar.bits.burst,rburst)
    rcnt:=Mux(rcnt === 255.U|| rlast.asBool || io.ar.fire,0.U,
          Mux(io.r.fire,rcnt + 1.U,rcnt))
    beatcnt:=Mux(io.ar.fire,(io.ar.bits.addr >> io.ar.bits.size) & io.ar.bits.len,
             Mux(beatcnt === 255.U | beatcnt === rlen,0.U,
             Mux(rstate =/= s_idle,beatcnt+1.U,0.U)))
    //printf("%x\t%x\t%x\t%x\n",io.ar.fire,beatcnt,raddr,(io.ar.bits.addr >> io.ar.bits.size) & io.ar.bits.len)
    rlast:=(rcnt === rlen && io.r.fire)
    io.r.bits.last := rlast

    //写通道
    val wstate = RegInit(s_idle)
    wstate := MuxLookup(wstate, s_idle, List(
      s_idle        -> Mux(w.fire&w.bits.last.asBool, s_wait_ready, s_idle),
      s_wait_ready  -> Mux(b.fire, s_idle, s_wait_ready),
    ))


    w_len := MuxLookup(w_state, w_len, Seq(
      s_idle -> in.aw.bits.len,
      s_write -> w_len - in.w.bits.strb.asUInt,
    ))


    in. b.valid := w_full
    in.aw.ready := in. w.valid && (in.b.ready || !w_full)
    in. w.ready := in.aw.valid && (in.b.ready || !w_full)

    in.b.bits.id   := RegEnable(in.aw.bits.id, in.aw.fire)
    in.b.bits.resp := AXI4Parameters.RESP_OKAY

    val r_full = RegInit(false.B)

    when (in. r.fire) { r_full := false.B }
    when (in.ar.fire) { r_full := true.B }

    in. r.valid := r_full
    in.ar.ready := in.r.ready || !r_full

    in.r.bits.id   := RegEnable(in.ar.bits.id, in.ar.fire)
    in.r.bits.resp := AXI4Parameters.RESP_OKAY
    in.r.bits.data := RegEnable(bsram.io.dout,in.ar.fire)
    in.r.bits.last := true.B

    bsram.io.reset := reset.asBool
    bsram.io.oce := 1.U

    bsram.io.clka := clock
    bsram.io.cea := in.aw.fire
    bsram.io.ada := in.aw.bits.addr
    bsram.io.din := in.w.bits.data
    bsram.io.byte_ena := in.w.bits.strb

    bsram.io.clkb := clock
    bsram.io.ceb := in.ar.fire
    bsram.io.adb := in.ar.bits.addr
  }
}