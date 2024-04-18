package soc

import chisel3._
import chisel3.util._

import freechips.rocketchip.amba._
import freechips.rocketchip.amba.axi4._
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.diplomacy._
import freechips.rocketchip.util._

class AXI4MEM(address: Seq[AddressSet])(implicit p: Parameters) extends LazyModule {
  val beatBytes = 4

  //val node = AXI4MEMNode()
  val node = AXI4SlaveNode(Seq(AXI4SlavePortParameters(
    Seq(AXI4SlaveParameters(
        address       = address,
        executable    = true,
        supportsWrite = TransferSizes(1, beatBytes), //范围：[1,beatBytes]
        supportsRead  = TransferSizes(1, beatBytes), //范围：[1,beatBytes]
        interleavedId = Some(0))),
    beatBytes  = beatBytes
    )))

  private val outer = this

  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val (in, _) = node.in(0)

    val mem_bundle = IO(new AXI4Bundle(CPUAXI4BundleParameters()))

    mem_bundle.aw.valid <> in.aw.valid
    mem_bundle.aw.ready <> in.aw.ready
    mem_bundle.aw.bits.addr <> in.aw.bits.addr
    mem_bundle.aw.bits.len <> in.aw.bits.len
    mem_bundle.aw.bits.size <> in.aw.bits.size
    mem_bundle.aw.bits.burst <> in.aw.bits.burst
    mem_bundle.aw.bits.lock <> in.aw.bits.lock
    mem_bundle.aw.bits.cache <> in.aw.bits.cache
    mem_bundle.aw.bits.prot <> in.aw.bits.prot
    mem_bundle.aw.bits.qos <> in.aw.bits.qos
    mem_bundle.aw.bits.id <> in.aw.bits.id
    mem_bundle.aw.bits.user <> in.aw.bits.user

    mem_bundle.w.valid <> in.w.valid
    mem_bundle.w.ready <> in.w.ready
    mem_bundle.w.bits.data <> in.w.bits.data
    mem_bundle.w.bits.strb <> in.w.bits.strb
    mem_bundle.w.bits.last <> in.w.bits.last
    mem_bundle.w.bits.user <> in.w.bits.user

    mem_bundle.b.valid <> in.b.valid
    mem_bundle.b.ready <> in.b.ready
    mem_bundle.b.bits.resp <> in.b.bits.resp
    mem_bundle.b.bits.id <> in.b.bits.id
    mem_bundle.b.bits.user <> in.b.bits.user
    mem_bundle.b.bits.resp <> in.b.bits.resp

    mem_bundle.ar.valid <> in.ar.valid
    mem_bundle.ar.ready <> in.ar.ready
    mem_bundle.ar.bits.addr <> in.ar.bits.addr
    mem_bundle.ar.bits.len <> in.ar.bits.len
    mem_bundle.ar.bits.size <> in.ar.bits.size
    mem_bundle.ar.bits.burst <> in.ar.bits.burst
    mem_bundle.ar.bits.lock <> in.ar.bits.lock
    mem_bundle.ar.bits.cache <> in.ar.bits.cache
    mem_bundle.ar.bits.prot <> in.ar.bits.prot
    mem_bundle.ar.bits.qos <> in.ar.bits.qos
    mem_bundle.ar.bits.id <> in.ar.bits.id
    mem_bundle.ar.bits.user <> in.ar.bits.user

    mem_bundle.r.valid <> in.r.valid
    mem_bundle.r.ready <> in.r.ready
    mem_bundle.r.bits.data <> in.r.bits.data
    mem_bundle.r.bits.resp <> in.r.bits.resp
    mem_bundle.r.bits.last <> in.r.bits.last
    mem_bundle.r.bits.id <> in.r.bits.id
    mem_bundle.r.bits.user <> in.r.bits.user

  }
}

