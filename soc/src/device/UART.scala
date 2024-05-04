package soc

import chisel3._
import chisel3.util._

import freechips.rocketchip.amba.apb._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._

class UARTIO extends Bundle {
  val rx = Input(Bool())
  val tx = Output(Bool())
}

//class UARTIO_noirq extends Bundle {
//  val rx = Input(Bool())
//  val tx = Output(Bool())
//}

class uart_top_apb extends BlackBox{
  val io = IO(new Bundle {
    val clock = Input(Clock())
    val reset = Input(Reset())
    val in = Flipped(new APBBundle(APBBundleParameters(addrBits = 32, dataBits = 32)))
    val uart = new UARTIO
  })

}

class APBUart(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
  val node = APBSlaveNode(Seq(APBSlavePortParameters(
    Seq(APBSlaveParameters(
      address       = address,
      executable    = false,
      supportsRead  = true,
      supportsWrite = true)),
    beatBytes  = 4)))

  private val outer = this

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val (in, _) = node.in(0)
    val uart_bundle = IO(new UARTIO)

    val muart = Module(new uart_top_apb)
    muart.io.in <> in
    muart.io.clock := clock
    muart.io.reset := reset
    uart_bundle <> muart.io.uart

  }
}