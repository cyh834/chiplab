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
import freechips.rocketchip.jtag.JTAGIO
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
  
  val lsram   = LazyModule(new AXI4SRAM (AddressSet.misaligned(0x1c000000 , 0x40000)))  //65536 * 32
  val lgpio   = LazyModule(new APBGPIO  (AddressSet.misaligned(0xa0000000L, 0x10)))
  val ltimer  = LazyModule(new APBTimer (AddressSet.misaligned(0xa0010000L, 0x10)))
  val lintc   = LazyModule(new APBINTC  (AddressSet.misaligned(0xa0020000L, 0x10)))
  val luart   = LazyModule(new APBUart  (AddressSet.misaligned(0xa0030000L, 0x10)))
  val lsdram  = LazyModule(new AXI4SDRAM(AddressSet.misaligned(0x00000000 , 0x20000000))) // 512MB

  //val lvga = LazyModule(new APBVGA(AddressSet.misaligned(0x21000000, 0x200000)))
  val lspi  = LazyModule(new APBSPI(
    AddressSet.misaligned(0x00000000, 0x100000) ++  // XIP flash 
    AddressSet.misaligned(0x1fe80000, 0x100000)     // SPI 控制器
  ))

  List(lspi.node, luart.node, ltimer.node,  lgpio.node, lintc.node).map(_ := apbxbar)
  List(apbxbar := AXI4ToAPB(), lsram.node).map(_ := xbar2)
  List(xbar2 := AXI4UserYanker(Some(1)) := AXI4Fragmenter(), lsdram.node ).map( _ := xbar)

  xbar := cpu.masterNode

  override lazy val module = new Impl
  class Impl extends LazyModuleImp(this) with DontTouch {
    // 为 CPU 生成延迟的复位信号
    cpu.module.reset := SynchronizerShiftReg(reset.asBool, 10) || reset.asBool

    val intr_from_SoC = IO(Input(UInt(8.W)))
    cpu.module.interrupt := intr_from_SoC

    // 暴露外设的接口作为端口
    val intc = IO(chiselTypeOf(lintc.module.intc_bundle))
    val timer = IO(chiselTypeOf(ltimer.module.timer_bundle))
    val spi = IO(chiselTypeOf(lspi.module.spi_bundle))
    val uart = IO(chiselTypeOf(luart.module.uart_bundle))
    val sdram = IO(chiselTypeOf(lsdram.module.sdram_bundle))
    val gpio = IO(chiselTypeOf(lgpio.module.gpio_bundle))
    //val vga = IO(chiselTypeOf(lvga.module.vga_bundle))
    val sram = IO(chiselTypeOf(lsram.module.sram_bundle))

    timer <> ltimer.module.timer_bundle
    intc <> lintc.module.intc_bundle
    uart <> luart.module.uart_bundle
    spi <> lspi.module.spi_bundle
    sdram <> lsdram.module.sdram_bundle
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

    val sram = Module(new SRAM_SDPB)
    sram.io <> masic.sram

    val spi = IO(chiselTypeOf(masic.spi))
    spi <> masic.spi

    val sdram = IO(chiselTypeOf(masic.sdram))
    sdram <> masic.sdram

    val externalPins = IO(new Bundle{
      val gpio = chiselTypeOf(masic.gpio)
      //val vga = chiselTypeOf(masic.vga)
      val uart = (chiselTypeOf(masic.uart))
    })
    externalPins.gpio <> masic.gpio
    //externalPins.vga <> masic.vga
    externalPins.uart.rx <> masic.uart.rx
    externalPins.uart.tx <> masic.uart.tx

    //处理时钟信号
    pll.module.clock := clock
    masic.clock := mpll.pll_bundle.clkout(0)
    val test = withClock(mpll.pll_bundle.clkout(1))(RegInit(0.U(32.W)))

    //处理复位信号
    
    val reset_time = 40000
    val cnt = withReset(~externalPins.gpio.in(0)){Counter(reset_time)}
    when(cnt.value < (reset_time - 1).U ) {
      cnt.inc()
    }
    val rst = (cnt.value < (reset_time - 1).U) && (cnt.value > 10.U)
    
    List(masic).map(_.reset := rst)

    //处理中断信号
    masic.intr_from_SoC := masic.intc.int_o
    masic.intc.timer_int := masic.timer.int
    masic.intc.i2c_int := 0.U
    masic.intc.uart1_int := 0.U
    masic.intc.uart0_int := 0.U//masic.uart.irq
    masic.intc.flash_int := 0.U
    masic.intc.spi_int := 0.U
    masic.intc.vpwm_int := 0.U
    masic.intc.dma_int := 0.U

  }
}