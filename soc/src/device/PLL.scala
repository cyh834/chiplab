package soc

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._
import freechips.rocketchip.prci._

class Gowin_PLL extends BlackBox {
  val io = IO(new Bundle {
    val clkin = Input(Clock())
    val clkout0 = Output(Clock())
    val clkout1 = Output(Clock())
  })
}

class PLLIO(n: Int = 2) extends Bundle {
  val clkout = Vec(n, Output(Clock()))
}

class PLL(implicit p: Parameters) extends LazyModule{
  //val node = ClockSourceNode(Seq(ClockSourceParameters()))

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    //val (out, _) = node.out(0)
    val pll = Module(new Gowin_PLL)
    pll.io.clkin := clock

    val pll_bundle = IO(new PLLIO(2))
    pll_bundle.clkout(0) := pll.io.clkout0
    pll_bundle.clkout(1) := pll.io.clkout1
  }
}