package soc

import chisel3._
import chisel3.util._
import chisel3.experimental.Analog

import freechips.rocketchip.amba._
import freechips.rocketchip.amba.axi4._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._

class SDRAMIO extends Bundle {
  val MEMORY_CLK = Input(Bool())
  val CLK_IN = Input(Bool())
  val RSTN = Input(Bool())
  val LOCK = Input(Bool())
  val STOP = Output(Bool())
  val INIT = Output(Bool())
  val BANK = Output(UInt(3.W))
  val CS_N = Output(Bool())
  val RAS_N = Output(Bool())
  val CAS_N = Output(Bool())
  val WE_N = Output(Bool())
  val CK = Output(Bool())
  val CK_N = Output(Bool())
  val CKE = Output(Bool())
  val RESET_N = Output(Bool())
  val ODT = Output(Bool())
  val ADDR = Output(UInt(14.W))
  val DM = Output(UInt(2.W))
  val DQ = Analog(16.W)
  val DQS = Analog(2.W)
  val DQS_N = Analog(2.W)
}

class sdram_top_axi extends BlackBox {
  val io = IO(new Bundle {
    val clock_25M = Input(Clock())
    val clock_50M = Input(Clock())
    val reset = Input(Bool())
    val in = Flipped(new AXI4Bundle(AXI4BundleParameters(addrBits = 32, dataBits = 32, idBits = 4)))
    val sdram = new SDRAMIO
  })
}


class sdram extends BlackBox {
  val io = IO(Flipped(new SDRAMIO))
}

class AXI4SDRAM(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
  val beatBytes = 4

  val node = AXI4SlaveNode(Seq(AXI4SlavePortParameters(
    Seq(AXI4SlaveParameters(
        address       = address,
        executable    = true,
        supportsWrite = TransferSizes(1, beatBytes), //范围：[1,beatBytes]
        supportsRead  = TransferSizes(1, beatBytes), //范围：[1,beatBytes]
        interleavedId = Some(0))),
    beatBytes  = beatBytes)))

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val (in, _) = node.in(0)

    val sdram_bundle = IO(new SDRAMIO)
    val msdram = Module(new sdram_top_axi)

    val pll = Module(new Gowin_PLL_DDR3)
    pll.io.clkin := clock

    msdram.io.clock_25M := clock
    msdram.io.clock_50M := pll.io.clkout0
    msdram.io.reset := reset.asBool
    msdram.io.in <> in
    sdram_bundle <> msdram.io.sdram
  }
}

