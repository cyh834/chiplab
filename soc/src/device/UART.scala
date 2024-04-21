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

class uart_top_apb extends Module{
  val io = IO(new Bundle {
    val in = Flipped(new APBBundle(APBBundleParameters(addrBits = 32, dataBits = 32)))
    val uart = new UARTIO
  })

  io.in.pready := true.B
  io.in.prdata := 0.U
  io.in.pslverr := false.B
  io.uart.tx := false.B
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
    uart_bundle <> muart.io.uart
  }
}