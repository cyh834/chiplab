package soc

import chisel3._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.system.DefaultConfig
import freechips.rocketchip.diplomacy.LazyModule

trait SoCConfig {
  def debug: Boolean = false
  def sim: Boolean = true
}

object Config extends SoCConfig

class SoCTop extends Module {
  implicit val config: Parameters = new DefaultConfig

  val dut = LazyModule(new SoCFull)
  val mdut = Module(dut.module)
  val externalPins = IO(chiselTypeOf(mdut.externalPins))

  mdut.dontTouchPorts()
  mdut.externalPins <> externalPins

  val flash = Module(new flash)
  flash.io <> mdut.spi
  flash.io.ss := mdut.spi.ss(0)

  //val sdram = Module(new sdram)
  //sdram.io <> mdut.sdram
  val sdram = IO(chiselTypeOf(mdut.sdram))
  sdram <> mdut.sdram

  //val cmos_hdmi = IO(chiselTypeOf(mdut.ch))
  //cmos_hdmi <> mdut.ch

}

object Elaborate extends App {
  val firtoolOptions = Array("--disable-annotation-unknown")
  circt.stage.ChiselStage.emitSystemVerilogFile(new SoCTop, args, firtoolOptions)
}
