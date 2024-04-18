package soc

import chisel3._
import chisel3.util._

import freechips.rocketchip.amba.apb._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._

class TimerIO extends Bundle {
  val timer = Output(UInt(32.W))
}

class TimerCtrlIO extends Bundle {
  val in = Flipped(new APBBundle(APBBundleParameters(addrBits = 32, dataBits = 32)))
  val timer = new TimerIO
}

class timer_top_apb extends Module{
  val io = IO(new TimerCtrlIO)

  io.in.pready := true.B
  io.in.prdata := 0.U
  io.in.pslverr := false.B
  io.timer.timer := 0.U

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