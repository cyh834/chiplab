package soc

import chisel3._
import chisel3.util._

import freechips.rocketchip.amba.apb._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._
import javax.swing.text.html.BlockView

object INTCConfig extends SoCConfig{
  val INT_EN  : UInt = 0.U
  val INT_EDGE: UInt = 1.U
  val INT_POL : UInt = 2.U
  val INT_CLR : UInt = 3.U
  val INT_SET : UInt = 4.U
  val INT_OUT : UInt = 5.U
  val SRPROT  : UInt = 6.U
}


class INTCIO extends Bundle {
  val timer_int = Input(Bool())
  val i2c_int = Input(Bool())
  val uart1_int = Input(Bool())
  val uart0_int = Input(Bool())
  val flash_int = Input(Bool())
  val spi_int = Input(Bool())
  val vpwm_int = Input(Bool())
  val dma_int = Input(Bool())
  val int_o = Output(Bool())
}

class INTCCtrlIO extends Bundle {
  val in = Flipped(new APBBundle(APBBundleParameters(addrBits = 32, dataBits = 32)))
  val intc = new INTCIO
}

class OneIntGen extends Module {
  val io = IO(new Bundle {
    val int_en = Input(Bool())
    val int_edge = Input(Bool())
    val int_pol = Input(Bool())
    val int_in = Input(Bool())
    val int_clr = Input(Bool())
    val int_set = Input(Bool())
    val int_out = Output(Bool())
  })

  val int_delay = RegNext(io.int_in, init = false.B)
  val int_lt = RegInit(false.B)

  int_lt := MuxCase(int_lt, Array(
    ((io.int_in =/= int_delay) && (io.int_in === io.int_pol)) -> true.B,
    (io.int_set) -> true.B,
    (io.int_clr) -> false.B
  ))

  val inv_int = ~(io.int_pol ^ io.int_in)// for INTC(dma, vpwm, ..., i2c, timer), int_pol defaults to 1
  val level_int = Mux(io.int_edge, int_lt, inv_int)// for INTC, int_edge is 0, so level_int is always equal to inv_int
  io.int_out := io.int_en & level_int
}

class intc_top_apb extends Module{
  val io = IO(new INTCCtrlIO)

  val en = io.in.psel && io.in.penable
  val enw = en && io.in.pwrite
  val enr = en && !io.in.pwrite

  val int_en = RegInit(0.U(8.W))
  val int_edge = RegInit("b01000000".U(8.W))
  val int_pol = RegInit("b11111111".U(8.W))
  val int_out = Wire(Vec(8, Bool()))

  when(enw){
    switch (io.in.paddr(3,0)) {
      is (INTCConfig.INT_EN)    { int_en    := io.in.pwdata }
      is (INTCConfig.INT_EDGE)  { int_edge  := io.in.pwdata }
      is (INTCConfig.INT_POL)   { int_pol   := io.in.pwdata }
    }
  }

  io.in.prdata := MuxCase(0.U, Array(
    (enr && (io.in.paddr(3,0) === INTCConfig.INT_EN))   -> int_en,
    (enr && (io.in.paddr(3,0) === INTCConfig.INT_EDGE)) -> int_edge,
    (enr && (io.in.paddr(3,0) === INTCConfig.INT_POL))  -> int_pol,
    (enr && (io.in.paddr(3,0) === INTCConfig.INT_OUT))  -> int_out.asUInt,
    (enr && (io.in.paddr(3,0) === INTCConfig.SRPROT))   -> 0.U   //简单起见，SRPROT被忽略
  ))

  //延迟两拍
  val vpwm_int = SynchronizerShiftReg(io.intc.vpwm_int, 2)
  val int_in = Cat(io.intc.dma_int, vpwm_int, io.intc.spi_int, io.intc.flash_int, io.intc.uart0_int, io.intc.uart1_int, io.intc.i2c_int, io.intc.timer_int)

  val int_gen = Array.fill(8)(Module(new OneIntGen))
  for (i <- 0 until 8) {
    int_gen(i).io.int_en := int_en(i)
    int_gen(i).io.int_edge := int_edge(i)
    int_gen(i).io.int_pol := int_pol(i)
    int_gen(i).io.int_in := int_in(i)
    int_gen(i).io.int_clr := enw && (io.in.paddr(3,0) === INTCConfig.INT_CLR) && io.in.pwdata(i)
    int_gen(i).io.int_set := enw && (io.in.paddr(3,0) === INTCConfig.INT_SET) && io.in.pwdata(i)
    int_out(i) := int_gen(i).io.int_out
  }

  io.intc.int_o := int_out.asUInt.orR

  io.in.pready := io.in.psel && io.in.penable;
  io.in.pslverr := false.B
}

class APBINTC(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
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
    val intc_bundle = IO(new INTCIO)

    val mintc = Module(new intc_top_apb)
    mintc.io.in <> in
    intc_bundle <> mintc.io.intc
  }
}