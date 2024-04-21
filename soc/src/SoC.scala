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
  val xbar2 = AXI4Xbar()
  val apbxbar = LazyModule(new APBFanout).node
  
  val cpu = LazyModule(new CPU(idBits = 4))
  
  val luart = LazyModule(new APBUart(AddressSet.misaligned(0x1FE00000, 0x10000)))
  val lgpio = LazyModule(new APBGPIO(AddressSet.misaligned(0x1FD10000, 0x10)))
  val lsdram = LazyModule(new AXI4SDRAM(AddressSet.misaligned(0x1C000000, 0x40000)))
  //val lvga = LazyModule(new APBVGA(AddressSet.misaligned(0x21000000, 0x200000)))
  val lspi  = LazyModule(new APBSPI(
    AddressSet.misaligned(0x00000000, 0x100000) ++  // XIP flash 
    AddressSet.misaligned(0x1FE80000, 0x100000)     // SPI 控制器
  ))
  val lconf = LazyModule(new APBConfig(AddressSet.misaligned(0x1FD00000, 0x10000)))
  val ltimer = LazyModule(new APBTimer(AddressSet.misaligned(0x1FD20000, 0x10)))
  val lint = LazyModule(new APBInt(AddressSet.misaligned(0x10005000, 0x10)))
  val lsram = LazyModule(new AXI4SRAM(AddressSet.misaligned(0x1C000000, 0x40000)))
  val lsdram = LazyModule(new AXI4SDRAM(AddressSet.misaligned(0x2C000000, 0x40000)))

  List(lspi.node, luart.node, ltimer.node,  lgpio.node, lconf.node, lint.node).map(_ := apbxbar)
  List(apbxbar := AXI4ToAPB(), sramNode).map(_ := xbar2)
  List(xbar2 := AXI4UserYanker(Some(1)) := AXI4Fragmenter(), lsdram.get.node ):= xbar

  xbar := cpu.masterNode

  override lazy val module = new Impl
  class Impl extends LazyModuleImp(this) with DontTouch {
    // 为 CPU 生成延迟的复位信号
    cpu.module.reset := SynchronizerShiftReg(reset.asBool, 10) || reset.asBool

    // 连接中断信号到 CPU
    val intr_from_chipSlave = IO(Input(UInt(8.W)))
    //TODO:连接到lint
    cpu.module.interrupt := 0.U(8.W)

    // 暴露外设的接口作为端口
    val spi = IO(chiselTypeOf(lspi.module.spi_bundle))
    val uart = IO(chiselTypeOf(luart.module.uart_bundle))
    val sdram = IO(chiselTypeOf(sdram.get.module.sdram_bundle))
    val gpio = IO(chiselTypeOf(lgpio.module.gpio_bundle))
    //val vga = IO(chiselTypeOf(lvga.module.vga_bundle))
    val sram = IO(chiselTypeOf(lsram.module.sram_bundle))

    uart <> luart.module.uart_bundle
    spi <> lspi.module.spi_bundle
    sdram <> lsdram.get.module.sdram_bundle
    gpio <> lgpio.module.gpio_bundle
    //vga <> lvga.module.vga_bundle
    sram <> lsram.module.sram_bundle
  }
}

class SoCFull(implicit p: Parameters) extends LazyModule {
  val asic = LazyModule(new SoCASIC)
  ElaborationArtefacts.add("graphml", graphML)

  val pll = LazyModule(new PLL)

  override lazy val module = new Impl
  class Impl extends LazyModuleImp(this) with DontTouch {
    val masic = asic.module
    val mpll = pll.module

    //val vga = IO(chiselTypeOf(masic.vga))
    val uart = IO(chiselTypeOf(masic.uart))
    val gpio = IO(chiselTypeOf(masic.gpio))

    val flash = Module(new flash)
    flash.io <> masic.spi
    flash.io.ss := masic.spi.ss(0)

    val sram = Module(new sram)
    sram.io <> masic.sram

    val sdram = Module(new sdram)
    sdram.io <> masic.sdram

    val externalPins = IO(new Bundle{
      val gpio = chiselTypeOf(masic.gpio)
      //val vga = chiselTypeOf(masic.vga)
      val uart = chiselTypeOf(masic.uart)
    })
    externalPins.gpio <> masic.gpio
    //externalPins.vga <> masic.vga
    externalPins.uart <> masic.uart

    //处理时钟信号
    pll.module.clock := clock
    masic.clock := mpll.pll_bundle.clkout(0)

    //处理复位信号
    val reset_btn = gpio.in(0)
    List(masic, sram).map(_.reset := reset_btn)
  }
}