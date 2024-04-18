package soc

import chisel3._
import chisel3.util._

import freechips.rocketchip.amba.apb._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._
import javax.swing.text.html.BlockView

class ConfigIO extends Bundle {
  val config = Output(UInt(32.W))
}

class ConfigCtrlIO extends Bundle {
  val in = Flipped(new APBBundle(APBBundleParameters(addrBits = 32, dataBits = 32)))
  val config = new ConfigIO
}

class config_top_apb extends Module{
  val io = IO(new ConfigCtrlIO)

  io.in.pready := true.B
  io.in.prdata := 0.U
  io.in.pslverr := false.B
  io.config.config := 0.U

}

class APBConfig(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
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
    val config_bundle = IO(new ConfigIO)

    val mconfig = Module(new config_top_apb)
    mconfig.io.in <> in
    config_bundle <> mconfig.io.config
  }
}