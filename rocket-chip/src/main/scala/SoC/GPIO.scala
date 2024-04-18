package soc

import chisel3._
import chisel3.util._

import freechips.rocketchip.amba.apb._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._


class GPIOIO extends Bundle {
  val out = Output(UInt(6.W)) //led addr:0x0
  val in = Input(UInt(4.W))   //btn addr:0x4
}

class GPIOCtrlIO extends Bundle {
  val in = Flipped(new APBBundle(APBBundleParameters(addrBits = 32, dataBits = 32)))
  val gpio = new GPIOIO
}


class gpio_top_apb extends Module{
  val io = IO(new GPIOCtrlIO)

  val mask = (0 until 4).map(i => Fill(8, io.in.pstrb(i).asUInt) << (i*8)).reduce(_ | _)

  val en = io.in.psel && io.in.penable
  val enw = en && io.in.pwrite && (io.in.paddr(3,0) === 0.U)
  val enr = en && !io.in.pwrite && (io.in.paddr(3,0) === 4.U)

  val gpio = RegEnable((io.in.pwdata & mask)(5,0), 0.U(6.W), enw)
  io.gpio.out := gpio(5,0)

  io.in.pready := true.B
  io.in.prdata := Mux(enr,Cat(0.U(28.W),io.gpio.in),x"deadbeef".U(32.W))
  io.in.pslverr := false.B
}


class APBGPIO(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
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
    val gpio_bundle = IO(new GPIOIO)

    val mgpio = Module(new gpio_top_apb)
    mgpio.io.in <> in
    gpio_bundle <> mgpio.io.gpio
  }
}