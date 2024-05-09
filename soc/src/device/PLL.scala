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
    val clkout2 = Output(Clock())
    val lock = Output(Bool())
    val enclk0 = Input(Bool())
    val enclk1 = Input(Bool())
    val enclk2 = Input(Bool())
  })
}

class PLLIO(n: Int = 1) extends Bundle {
  val clkout = Vec(n, Output(Clock()))
  val enclk = Vec(n, Input(Bool()))
  val lock = Output(Bool())
}

class PLL(implicit p: Parameters) extends LazyModule{
  //val node = ClockSourceNode(Seq(ClockSourceParameters()))

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    //val (out, _) = node.out(0)
    val pll = Module(new Gowin_PLL)
    val pll_bundle = IO(new PLLIO(3))

    pll.io.clkin := clock
    pll.io.enclk0 := pll_bundle.enclk(0)
    pll.io.enclk1 := pll_bundle.enclk(1)
    pll.io.enclk2 := pll_bundle.enclk(2)

    pll_bundle.clkout(0) := pll.io.clkout0
    pll_bundle.clkout(1) := pll.io.clkout1
    pll_bundle.clkout(2) := pll.io.clkout2
    pll_bundle.lock := pll.io.lock
  }
}