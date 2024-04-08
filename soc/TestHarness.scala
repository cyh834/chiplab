package freechips.rocketchip.system

import chisel3._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy.LazyModule
import soc._

class TestHarness()(implicit p: Parameters) extends Module {
  val io = IO(new Bundle { })
  val ldut = LazyModule(new soc_top)
  val dut = Module(ldut.module)
  dut.dontTouchPorts()
  dut.externalPins := DontCare
}