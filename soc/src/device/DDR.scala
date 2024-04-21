package soc

import chisel3._
import chisel3.util._

import freechips.rocketchip.amba.axi4._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._

class DDRIO extends Bundle {
  val ddr = Output(UInt(32.W))
}

class DDRCtrlIO extends Bundle {
  val ddr = new DDRIO
}

class AXI4DDR(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
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
  }
}
