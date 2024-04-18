package soc

import chisel3._
import chisel3.util._

import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.subsystem._
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._

object CPUAXI4BundleParameters {
  def apply() = AXI4BundleParameters(addrBits = 32, dataBits = 32, idBits = 4)
}

trait FixBundle extends Bundle {
  val break_point = Input(Bool())
  val infor_flag = Input(Bool())
  val reg_num = Input(UInt(5.W))
  val ws_valid = Output(Bool())
  val rf_rdata = Output(UInt(32.W))
  val debug0_wb_pc = Output(UInt(32.W))
  val debug0_wb_rf_wen = Output(UInt(4.W))
  val debug0_wb_rf_wnum = Output(UInt(5.W))
  val debug0_wb_rf_wdata = Output(UInt(32.W))
  val debug0_wb_inst = Output(UInt(32.W))

  val master_wid = Output(UInt(4.W))
}

class core_top extends BlackBox {
  val io = IO(new Bundle with FixBundle{
    val aclk = Input(Clock())
    val aresetn = Input(Bool())
    val intrpt = Input(UInt(8.W))
    val master = AXI4Bundle(CPUAXI4BundleParameters())
    //val slave = Flipped(AXI4Bundle(CPUAXI4BundleParameters()))
  })
}

class CPU(idBits: Int)(implicit p: Parameters) extends LazyModule {
  val masterNode = AXI4MasterNode(p(ExtIn).map(params =>
    AXI4MasterPortParameters(
      masters = Seq(AXI4MasterParameters(
        name = "cpu",
        id   = IdRange(0, 1 << idBits))))).toSeq)
  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val (master, _) = masterNode.out(0)
    val interrupt = IO(Input(UInt(8.W)))
    //val slave = IO(Flipped(AXI4Bundle(CPUAXI4BundleParameters())))

    
    val cpu = Module(new core_top)
    //fix
    cpu.io.aclk := clock
    cpu.io.aresetn := (~reset.asUInt).asBool
    cpu.io.intrpt := interrupt

    cpu.io.break_point := false.B
    cpu.io.infor_flag := false.B
    cpu.io.reg_num := 0.U

    master <> cpu.io.master

  }
}