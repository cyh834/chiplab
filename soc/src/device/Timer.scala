package soc

import chisel3._
import chisel3.util._

import freechips.rocketchip.amba.apb._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._

object TimerConfig extends SoCConfig{
  val cfg : UInt = x"0".U; 
  val cnt : UInt = x"4".U;
  val cmp : UInt = x"8".U;
  val step: UInt = x"c".U;
}

class TimerIO extends Bundle {
  val int = Output(Bool())
}

class TimerCtrlIO extends Bundle {
  val in = Flipped(new APBBundle(APBBundleParameters(addrBits = 32, dataBits = 32)))
  val timer = new TimerIO
}

class timer_top_apb extends Module{
  val io = IO(new TimerCtrlIO)

  val en = io.in.psel && io.in.penable
  val enw = en && io.in.pwrite
  val enr = en && !io.in.pwrite

  val start     = RegEnable(io.in.pwdata(0), false.B , enw && (io.in.paddr(3,0) === TimerConfig.cfg))
  val int_en    = RegEnable(io.in.pwdata(1), false.B , enw && (io.in.paddr(3,0) === TimerConfig.cfg))
  val periodic  = RegEnable(io.in.pwdata(2), false.B , enw && (io.in.paddr(3,0) === TimerConfig.cfg))

  val count     = RegInit(0.U(32.W))
  val compare   = RegInit(x"ffffffff".U(32.W))
  val step      = RegInit(0.U(32.W))
  
  val int_trigger = (count === compare) && start;

  when(enw && (io.in.paddr(3,0) === TimerConfig.cnt) && ~start){
    count := io.in.pwdata
  }.elsewhen(start){
    count := count + 1.U
  }.otherwise{
    count := 0.U
  }

  when(enw && (io.in.paddr(3,0) === TimerConfig.cmp) && ~start) {
    compare := io.in.pwdata
  }.elsewhen (periodic && int_trigger) {
    compare := count + step
  }

  when (enw && (io.in.paddr(3,0) === TimerConfig.step) && ~start) {
    step := io.in.pwdata
  }

  val int_r = RegInit(0.U(1.W))
  when (enw && (io.in.paddr(3,0) === TimerConfig.cfg) && io.in.pwdata(8)) {
    int_r := 0.U // write 1 to clear the interrupt flag bit
  }.elsewhen (int_trigger) {
    int_r := 1.U
  }

  io.timer.int := int_r & int_en

  val rdata = RegInit(0.U(32.W))
  when(~io.in.psel | io.in.pwrite){
    rdata := 0.U
  }.otherwise{
    when(enr){
      rdata := MuxLookup(io.in.paddr(3,0), rdata)(Seq(
        TimerConfig.cfg -> Cat(0.U(23.W), int_r, 0.U(5.W), periodic, int_en, start),
        TimerConfig.cnt -> count,
        TimerConfig.cmp -> compare,
        TimerConfig.step-> step
      ))
    }
  }

  io.in.pready := RegNext(io.in.psel && io.in.penable);
  io.in.prdata := rdata
  io.in.pslverr := false.B
}

class APBTimer(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
  val node = APBSlaveNode(Seq(APBSlavePortParameters(
    Seq(APBSlaveParameters(
      address       = address,
      executable    = true,
      supportsRead  = true,
      supportsWrite = true)),
    beatBytes  = 4)))

  private val outer = this

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val (in, _) = node.in(0)
    val timer_bundle = IO(new TimerIO)

    val mtimer = Module(new timer_top_apb)
    mtimer.io.in <> in
    timer_bundle <> mtimer.io.timer
  }
}