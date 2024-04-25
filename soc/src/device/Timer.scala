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

  val start     = RegEnable(apb_pwdata(0), 0.U(1.W), enw && (apb_paddr === TimerConfig.cfg))
  val int_en    = RegEnable(apb_pwdata(1), 0.U(1.W), enw && (apb_paddr === TimerConfig.cfg))
  val periodic  = RegEnable(apb_pwdata(2), 0.U(1.W), enw && (apb_paddr === TimerConfig.cfg))

  val count     = RegInit(0.U(32.W))
  val compare   = RegInit(x"ffffffff".U(32.W))
  val step      = RegInit(0.U(32.W))
  
  val int_trigger = (count === compare) && start;

  count := MuxCase(count, Array(
    enw && (apb_paddr === TimerConfig.cnt)&& ~start  -> apb_pwdata,
    start                                           -> count + 1.U,
    ~start                                          -> 0.U
  ))

  compare := MuxCase(compare, Array(
    enw && (apb_paddr === TimerConfig.cmp) && ~start -> apb_pwdata
    periodic & int_trigger                          -> count + step
  ))

  step := MuxCase(step, Array(
    enw && (apb_paddr === TimerConfig.step) && ~start-> apb_pwdata
  ))

  val int_r = RegInit(0.U(1.W))
  int_r := MuxCase(int_r, Array(
    enw && (apb_paddr === TimerConfig.cfg) && apb_pwdata(8) -> 0.U,// write 1 to clear the interrupt flag bit
    int_trigger -> 1.U
  ))  

  io.timer.int := int_r & int_en

  val rdata = RegInit(0.U(32.W))
  rdata := MuxCase(rdata, Array(
    ~io.in.psel | io.in.pwrite -> 0.U,
    enr && (apb_paddr(3,0) === TimerConfig.cfg) -> Cat(0.U(23.W), int_r, 0.U(5.W), periodic, int_en, start),
    enr && (apb_paddr(3,0) === TimerConfig.cnt) -> count,
    enr && (apb_paddr(3,0) === TimerConfig.cmp) -> compare,
    enr && (apb_paddr(3,0) === TimerConfig.step)-> step
  ))

  io.in.pready := true.B
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