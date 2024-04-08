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
  // 创建 AXI4 Xbar
  val xbar = AXI4Xbar()
  
  // 创建 APB Xbar
  val apbxbar = LazyModule(new APBFanout).node
  
  // 创建 CPU 模块
  val cpu = LazyModule(new CPU(idBits = 4))
  
  // 创建其他外设模块，如 UART、GPIO、键盘、VGA、SPI、PSRAM、BSRAM、SDRAM 等
  //val luart = LazyModule(new APBUart16550(AddressSet.misaligned(0x10000000, 0x1000)))
  val lgpio = LazyModule(new APBGPIO(AddressSet.misaligned(0x10002000, 0x10)))
  //val lkeyboard = LazyModule(new APBKeyboard(AddressSet.misaligned(0x10011000, 0x8)))
  //val lvga = LazyModule(new APBVGA(AddressSet.misaligned(0x21000000, 0x200000)))
  val lspi  = LazyModule(new APBSPI(
    AddressSet.misaligned(0x10001000, 0x1000) ++    // SPI 控制器
    AddressSet.misaligned(0x30000000, 0x10000000)   // XIP flash
  ))
  //val lpsram = LazyModule(new APBPSRAM(AddressSet.misaligned(0x80000000L, 0x400000)))
  val lbsram = LazyModule(new AXI4BSRAM(AddressSet.misaligned(0x20000000, 0x1000)))
  //val sramNode = AXI4RAM(AddressSet.misaligned(0x0f000000, 0x2000).head, false, true, 8, None, Nil, false)
  //val lsdram = LazyModule(new APBSDRAM(AddressSet.misaligned(0xa0000000L, 0x2000000)))

  // 将外设模块连接到 APB Xbar
  //List(lspi.node, luart.node, lpsram.node, lsdram.node, lgpio.node, lkeyboard.node, lvga.node).map(_ := apbxbar)
  List(lspi.node, lgpio.node).map(_ := apbxbar)

  // 将 APB Xbar、bsram 连接到 AXI4 Xbar
  List(apbxbar := AXI4ToAPB(), lbsram.node).map(_ := xbar)

  // 将 CPU 的主节点连接到 AXI4 Xbar
  xbar := cpu.masterNode

  // SoC 的具体实现逻辑
  override lazy val module = new Impl
  class Impl extends LazyModuleImp(this) with DontTouch {
    // 为 CPU 生成延迟的复位信号
    cpu.module.reset := SynchronizerShiftReg(reset.asBool, 10) || reset.asBool

    //cpu.module.slave := DontCare

    // 连接中断信号到 CPU
    val intr_from_chipSlave = IO(Input(UInt(8.W)))
    cpu.module.interrupt := intr_from_chipSlave

    // 暴露外设的接口作为端口
    val spi = IO(chiselTypeOf(lspi.module.spi_bundle))
    //val uart = IO(chiselTypeOf(luart.module.uart))
    //val psram = IO(chiselTypeOf(lpsram.module.qspi_bundle))
    //val sdram = IO(chiselTypeOf(lsdram.module.sdram_bundle))
    //val bsram = IO(chiselTypeOf(lbsram.module.bram_bundle))
    val gpio = IO(chiselTypeOf(lgpio.module.gpio_bundle))
    //val ps2 = IO(chiselTypeOf(lkeyboard.module.ps2_bundle))
    //val vga = IO(chiselTypeOf(lvga.module.vga_bundle))
    //uart <> luart.module.uart
    spi <> lspi.module.spi_bundle
    //psram <> lpsram.module.qspi_bundle
    //sdram <> lsdram.module.sdram_bundle
    gpio <> lgpio.module.gpio_bundle
    //bsram <> lbsram.module.bram_bundle
    //ps2 <> lkeyboard.module.ps2_bundle
    //vga <> lvga.module.vga_bundle
  }
}

class soc_top(implicit p: Parameters) extends LazyModule {
  val asic = LazyModule(new SoCASIC)

  override lazy val module = new Impl
  class Impl extends LazyModuleImp(this) with DontTouch {
    val masic = asic.module

    masic.intr_from_chipSlave := 0.U(8.W)

    //val bsram = Module(new AXI4BSRAM)
    //bsram.io <> masic.bsram

    val externalPins = IO(new Bundle{
      val gpio = chiselTypeOf(masic.gpio)
      val spi = chiselTypeOf(masic.spi)
      //val vga = chiselTypeOf(masic.vga)
      //val uart = chiselTypeOf(masic.uart)
    })
    externalPins.spi <> masic.spi
    externalPins.gpio <> masic.gpio
    //externalPins.uart <> masic.uart
  }
}