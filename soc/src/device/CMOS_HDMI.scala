package soc

import chisel3._
import chisel3.util._

import freechips.rocketchip.amba.apb._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._
import chisel3.experimental.Analog

class cmos_hdmi extends BlackBox {
  val io = IO(new Bundle {
    val clk = Input(Clock())
    val rst_n = Input(Bool())
    // DDR3 PHY
    val ddr3_dq = Analog(32.W)
    val ddr3_dqs_n = Analog(4.W)
    val ddr3_dqs_p = Analog(4.W)
    val ddr3_addr = Output(UInt(14.W))
    val ddr3_ba = Output(UInt(3.W))
    val ddr3_ras_n = Output(Bool())
    val ddr3_cas_n = Output(Bool())
    val ddr3_we_n = Output(Bool())
    val ddr3_reset_n = Output(Bool())
    val ddr3_ck_p = Output(Bool())
    val ddr3_ck_n = Output(Bool())
    val ddr3_cke = Output(Bool())
    val ddr3_cs_n = Output(Bool())
    val ddr3_dm = Output(UInt(4.W))
    val ddr3_odt = Output(Bool())
    // LEDs
    val led = Output(UInt(4.W))
    // HDMI
    val tmds_clk_n_0 = Output(Bool())
    val tmds_clk_p_0 = Output(Bool())
    val tmds_d_n_0 = Output(UInt(3.W))
    val tmds_d_p_0 = Output(UInt(3.W))
    // CMOS1 interface
    val iic_mux = Output(UInt(3.W))
    val cmos_xclk = Output(Bool())
    val cmos_pwdn = Output(Bool())
    val cmos_scl = Output(Bool())
    val cmos_sda = Analog(1.W)
    val cmos_vsync = Input(Bool())
    val cmos_href = Input(Bool())
    val cmos_pclk = Input(Bool())
    val cmos_db = Input(UInt(8.W))
    val cmos_rst_n = Output(Bool())
  })
}

