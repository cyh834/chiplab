package soc

import chisel3._
import chisel3.util._

import freechips.rocketchip.diplomacy._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.subsystem._
import freechips.rocketchip.util._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.amba.apb._
import freechips.rocketchip.system.SimAXIMem
import scala.runtime.LazyInt

object AXI4SlaveNodeGenerator {
  def apply(params: Option[MasterPortParams], address: Seq[AddressSet])(implicit valName: ValName) =
    AXI4SlaveNode(params.map(p => AXI4SlavePortParameters(
        slaves = Seq(AXI4SlaveParameters(
          address       = address,
          executable    = p.executable,
          supportsWrite = TransferSizes(1, p.maxXferBytes),
          supportsRead  = TransferSizes(1, p.maxXferBytes))),
        beatBytes = p.beatBytes
      )).toSeq)
}

class SoCASIC(implicit p: Parameters) extends LazyModule {
  val xbar = AXI4Xbar()
  val ddrxbar = AXI4Xbar()
  val apbxbar = LazyModule(new APBFanout).node
  
  val cpu = LazyModule(new CPU(idBits = 4))
  
  //外设
  val lmem = LazyModule(new AXI4MEM(AddressSet.misaligned(0x1C000000, 0x40000))) //ddr3
  val lspi  = LazyModule(new APBSPI(
    AddressSet.misaligned(0x00000000, 0x100000) ++  // XIP flash 
    AddressSet.misaligned(0x1FE80000, 0x100000)       // SPI 控制器
  ))
  val lconf = LazyModule(new APBConfig(AddressSet.misaligned(0x1FD00000, 0x10000)))
  val lgpio = LazyModule(new APBGPIO(AddressSet.misaligned(0x1FD10000, 0x10)))
  val ltimer = LazyModule(new APBTimer(AddressSet.misaligned(0x1FD20000, 0x10)))
  val luart = LazyModule(new APBUart(AddressSet.misaligned(0x1FE00000, 0x10000)))
  val lint = LazyModule(new APBInt(AddressSet.misaligned(0x10005000, 0x10)))

  List(luart.node, ltimer.node,  lgpio.node, lconf.node, lint.node, lspi.node).map(_ := apbxbar)
  List(apbxbar := AXI4ToAPB() := AXI4Fragmenter(), ddrxbar := AXI4Fragmenter()).map(_ := xbar)
  xbar := cpu.masterNode

  List(lmem.node).map(_ := ddrxbar)

  override lazy val module = new Impl
  class Impl extends LazyModuleImp(this) with DontTouch {
    // 为 CPU 生成延迟的复位信号
    cpu.module.reset := SynchronizerShiftReg(reset.asBool, 10) || reset.asBool

    // 连接中断信号到 CPU
    val intr_from_chipSlave = IO(Input(UInt(8.W)))
    cpu.module.interrupt := intr_from_chipSlave

    // 暴露外设的接口作为端口
    val uart = IO(chiselTypeOf(luart.module.uart_bundle))
    val gpio = IO(chiselTypeOf(lgpio.module.gpio_bundle))
    val spi = IO(chiselTypeOf(lspi.module.spi_bundle))
    val mem = IO(chiselTypeOf(lmem.module.mem_bundle))

    uart <> luart.module.uart_bundle
    gpio <> lgpio.module.gpio_bundle
    spi <> lspi.module.spi_bundle
    mem <> lmem.module.mem_bundle
  }
}

class soc_top(implicit p: Parameters) extends LazyModule {
  val asic = LazyModule(new SoCASIC)
  val pll = LazyModule(new PLL)


  override lazy val module = new Impl
  class Impl extends LazyModuleImp(this) with DontTouch {
    val mpll = pll.module
    val masic = asic.module

    val sram = Module(new AXI4SRAM)
    val gpio = IO(chiselTypeOf(masic.gpio))
    val uart = IO(chiselTypeOf(masic.uart))
    val flash = IO(chiselTypeOf(masic.spi))


    val reset_btn = gpio.in(0)

    pll.module.clock := clock

    masic.clock := mpll.pll_bundle.clkout(0)
    masic.reset := reset_btn
    masic.intr_from_chipSlave := 0.U(8.W)

    gpio <> masic.gpio
    uart <> masic.uart
    flash <> masic.spi
    sram.in <> masic.mem
    sram.reset := reset_btn
  }
}