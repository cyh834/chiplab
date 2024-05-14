package soc

import chisel3._
import chisel3.util._

import freechips.rocketchip.amba.apb._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._

class SPIIO(val ssWidth: Int = 1) extends Bundle {
  val sck = Output(Bool())
  val ss = Output(UInt(ssWidth.W))
  val mosi = Output(Bool())
  val miso = Input(Bool())
}
class sd_ctrl_top extends BlackBox{
  val io = IO(new Bundle {
    val clk_ref = Input(Clock())
    val clk_ref_180deg = Input(Clock())
    val rst_n = Input(Bool())
    val sd_miso = Input(Bool())
    val sd_clk = Output(Bool())
    val sd_cs = Output(Bool())
    val sd_mosi = Output(Bool())

    val wr_start_en = Input(Bool())
    val wr_sec_addr = Input(UInt(32.W))
    val wr_data = Input(UInt(16.W))
    val wr_busy = Output(Bool())
    val wr_req = Output(Bool())

    val rd_start_en = Input(Bool())
    val rd_sec_addr = Input(UInt(32.W))
    val rd_busy = Output(Bool())
    val rd_val_en = Output(Bool())
    val rd_val_data = Output(UInt(16.W))
    val sd_init_done = Output(Bool())
  })
}

class spi_top_apb extends Module{
  val io = IO(new Bundle {
    val in = Flipped(new APBBundle(APBBundleParameters(addrBits = 32, dataBits = 32)))
    val spi = new SPIIO
    val spi_irq_out = Output(Bool())
  })

  val sd_ctrl = Module(new sd_ctrl_top)
  sd_ctrl.io.clk_ref := clock
  sd_ctrl.io.clk_ref_180deg := (~clock.asBool).asClock
  sd_ctrl.io.rst_n := ~reset.asBool
  sd_ctrl.io.sd_miso := io.spi.miso
  io.spi.sck := sd_ctrl.io.sd_clk
  io.spi.ss := sd_ctrl.io.sd_cs
  io.spi.mosi := sd_ctrl.io.sd_mosi

  sd_ctrl.io.wr_start_en := false.B
  sd_ctrl.io.wr_sec_addr := 0.U
  sd_ctrl.io.wr_data := 0.U

  val s_idle :: s_addr0 :: s_wait_data0 :: s_addr1 :: s_wait_data1 ::Nil = Enum(5)
  val state = RegInit(s_idle)
  when(state === s_idle){
    when(io.in.psel && io.in.penable && (~io.in.pwrite) && io.in.pready){
      state := s_addr0
    }
  }.elsewhen(state === s_addr0){
    state := s_wait_data0
  }.elsewhen(state === s_wait_data0){
    when(sd_ctrl.io.rd_val_en){
      state := s_addr1
    }
  }.elsewhen(state === s_addr1){
    state := s_wait_data1
  }.elsewhen(state === s_wait_data1){
    when(sd_ctrl.io.rd_val_en){
      state := s_idle
    }
  }
  sd_ctrl.io.rd_start_en := (state === s_addr0) || (state === s_addr1)
  sd_ctrl.io.rd_sec_addr := Mux(state === s_addr0, io.in.paddr,io.in.paddr + 2.U)

  val rdata = RegInit(0.U(32.W))
  when(sd_ctrl.io.rd_val_en){
    rdata := Mux(state === s_wait_data0,Cat(0.U(16.W),sd_ctrl.io.rd_val_data), Cat(sd_ctrl.io.rd_val_data, rdata(15,0)))
  }

  io.in.pready := (state === s_idle) && sd_ctrl.io.sd_init_done
  io.in.prdata := rdata
  io.in.pslverr := false.B

  io.spi_irq_out := false.B
}

//class flash extends BlackBox {
//  val io = IO(Flipped(new SPIIO(1)))
//}

class APBSPI(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
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
    val spi_bundle = IO(new SPIIO)

    val mspi = Module(new spi_top_apb)
    mspi.io.in <> in
    spi_bundle <> mspi.io.spi
  }
}