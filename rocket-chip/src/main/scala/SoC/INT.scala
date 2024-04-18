package soc

import chisel3._
import chisel3.util._

import freechips.rocketchip.amba.apb._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._

class IntIO extends Bundle {
  val int = Output(UInt(32.W))
}

class IntCtrlIO extends Bundle {
  val in = Flipped(new APBBundle(APBBundleParameters(addrBits = 32, dataBits = 32)))
  val int = new IntIO
}

class int_top_apb extends Module{
  val io = IO(new IntCtrlIO)

  io.in.pready := true.B
  io.in.prdata := 0.U
  io.in.pslverr := false.B
  io.int.int := 0.U

}

class APBInt(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
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
    val int_bundle = IO(new IntIO)

    val mint = Module(new int_top_apb)
    mint.io.in <> in
    int_bundle <> mint.io.int
  }
}