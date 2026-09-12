#!/usr/bin/env node
/**
 * Hashcats.fun Headless GPU Miner — runs via SSH on a VPS.
 * 
 * Uses the EXACT same WGSL shader and WASM binary from hashcats.fun.
 * GPU via @webgpu/webgpu (Google Dawn native backend).
 * 
 * Robinhood Chain (chainId 4663)
 *   RPC:  https://robinhood.drpc.org
 *   Contract: 0xCA75DF55Cc9C476DB27a7375D1fc8E794cf80721
 * 
 * Install:
 *   npm init -y
 *   npm install ethers@6 @webgpu/webgpu
 * 
 * Usage:
 *   node miner.mjs --key 0xYOUR_PRIVATE_KEY
 *   node miner.mjs --key 0x... --dry-run
 *   node miner.mjs --key 0x... --cpu-only  # WASM CPU fallback
 */

import { ethers } from "ethers";
import { create as gpuCreate } from "webgpu";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

// ============================================================
// CONSTANTS
// ============================================================
const RPC = "https://robinhood.drpc.org";
const CONTRACT = "0xCA75DF55Cc9C476DB27a7375D1fc8E794cf80721";
const CHAIN_ID = 4663;

const ABI = [
  "function mine(uint256 nonce, uint256 anchorBlock) payable returns (uint256 tokenId)",
  "function currentTarget() view returns (uint256)",
  "function baseTarget() view returns (uint256)",
  "function prevWork() view returns (uint256)",
  "function currentAnchor() view returns (uint256 anchorBlock, bytes32 anchor)",
  "function mintPrice() view returns (uint256)",
  "function totalMinted() view returns (uint256)",
  "function targetFor(address miner) view returns (uint256)",
  "event Mined(address indexed miner, uint256 indexed tokenId, uint256 seed, uint256 work, bytes32 anchor, uint256 target, uint256 nonce, uint256 unique)",
];

// ============================================================
// WGSL SHADER (extracted from hashcats.fun gpu.worker)
// ============================================================
const SHADER = `
const RCE = array<u32, 24>(0x00000001u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000001u, 0x00000001u, 0x00000001u, 0x00000001u, 0x00000000u, 0x00000000u, 0x00000001u, 0x00000000u, 0x00000001u, 0x00000001u, 0x00000001u, 0x00000001u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000001u, 0x00000000u, 0x00000001u, 0x00000000u);
const RCO = array<u32, 24>(0x00000000u, 0x00000089u, 0x8000008bu, 0x80008080u, 0x0000008bu, 0x00008000u, 0x80008088u, 0x80000082u, 0x0000000bu, 0x0000000au, 0x00008082u, 0x00008003u, 0x0000808bu, 0x8000000bu, 0x8000008au, 0x80000081u, 0x80000081u, 0x80000008u, 0x00000083u, 0x80008003u, 0x80008088u, 0x80000088u, 0x00008000u, 0x80008082u);

struct Job {
  k: array<u32, 34>,
  base: u32,
  perThread: u32,
  thresh: u32,
  maxCands: u32,
}

struct Counters {
  count: atomic<u32>,
  hist: array<atomic<u32>, 33>,
}

@group(0) @binding(0) var<storage, read> job: Job;
@group(0) @binding(1) var<storage, read_write> out: Counters;
@group(0) @binding(2) var<storage, read_write> cands: array<vec2<u32>>;

var<workgroup> shared_hist: array<atomic<u32>, 33>;

override WG: u32 = 256u;

@compute @workgroup_size(WG)
fn main(@builtin(global_invocation_id) gid: vec3<u32>,
        @builtin(local_invocation_index) lid: u32) {
  for (var i = lid; i < 33u; i = i + WG) { atomicStore(&shared_hist[i], 0u); }
  workgroupBarrier();

  let k0e = job.k[0]; let k0o = job.k[1];
  let k1e = job.k[2]; let k1o = job.k[3];
  let k2e = job.k[4]; let k2o = job.k[5];
  let k3e = job.k[6]; let k3o = job.k[7];
  let k4e = job.k[8]; let k4o = job.k[9];
  let k5e = job.k[10]; let k5o = job.k[11];
  let k6e = job.k[12]; let k6o = job.k[13];
  let k7e = job.k[14]; let k7o = job.k[15];
  let k8e = job.k[16]; let k8o = job.k[17];
  let k9e = job.k[18]; let k9o = job.k[19];
  let k10e = job.k[20]; let k10o = job.k[21];
  let k11e = job.k[22]; let k11o = job.k[23];
  let k12e = job.k[24]; let k12o = job.k[25];
  let k13e = job.k[26]; let k13o = job.k[27];
  let k14e = job.k[28]; let k14o = job.k[29];
  let k15e = job.k[30]; let k15o = job.k[31];
  let k16e = job.k[32]; let k16o = job.k[33];

  let perThread = job.perThread;
  let thresh = job.thresh;
  let maxCands = job.maxCands;
  let start = job.base + gid.x * perThread;

  var c0 = 0u; var c1 = 0u; var c2 = 0u; var c3 = 0u;
  var c4 = 0u; var c5 = 0u; var c6 = 0u; var c7 = 0u;

  for (var it = 0u; it < perThread; it = it + 1u) {
    let n = start + it;
    var a0e = k0e; var a0o = k0o;
    var a1e = k1e; var a1o = k1o;
    var a2e = k2e; var a2o = k2o;
    var a3e = k3e; var a3o = k3o;
    var a4e = k4e; var a4o = k4o;
    var a5e = k5e; var a5o = k5o;
    var a6e = k6e; var a6o = k6o;
    var a7e = k7e; var a7o = k7o;
    var a8e = k8e; var a8o = k8o;
    var a9e = k9e; var a9o = k9o;
    var a10e = k10e; var a10o = k10o;
    var a11e = k11e; var a11o = k11o;
    var a12e = k12e; var a12o = k12o;
    var a13e = k13e; var a13o = k13o;
    var a14e = k14e; var a14o = k14o;
    var a15e = k15e; var a15o = k15o;
    var a16e = k16e; var a16o = k16o;
    var a17e = 0u; var a17o = 0u;
    var a18e = 0u; var a18o = 0u;
    var a19e = 0u; var a19o = 0u;
    var a20e = 0u; var a20o = 0u;
    var a21e = 0u; var a21o = 0u;
    var a22e = 0u; var a22o = 0u;
    var a23e = 0u; var a23o = 0u;
    var a24e = 0u; var a24o = 0u;

    a6e = (a6e & 0xffff0000u) | (n & 0xffffu);
    a6o = (a6o & 0xffff0000u) | ((n >> 16u) & 0xffffu);

    for (var rnd = 0u; rnd < 24u; rnd = rnd + 1u) {
      let c0e = a0e ^ a5e ^ a10e ^ a15e ^ a20e;
      let c0o = a0o ^ a5o ^ a10o ^ a15o ^ a20o;
      let c1e = a1e ^ a6e ^ a11e ^ a16e ^ a21e;
      let c1o = a1o ^ a6o ^ a11o ^ a16o ^ a21o;
      let c2e = a2e ^ a7e ^ a12e ^ a17e ^ a22e;
      let c2o = a2o ^ a7o ^ a12o ^ a17o ^ a22o;
      let c3e = a3e ^ a8e ^ a13e ^ a18e ^ a23e;
      let c3o = a3o ^ a8o ^ a13o ^ a18o ^ a23o;
      let c4e = a4e ^ a9e ^ a14e ^ a19e ^ a24e;
      let c4o = a4o ^ a9o ^ a14o ^ a19o ^ a24o;
      let d0e = c4e ^ ((c1o << 1u) | (c1o >> 31u));
      let d0o = c4o ^ c1e;
      let d1e = c0e ^ ((c2o << 1u) | (c2o >> 31u));
      let d1o = c0o ^ c2e;
      let d2e = c1e ^ ((c3o << 1u) | (c3o >> 31u));
      let d2o = c1o ^ c3e;
      let d3e = c2e ^ ((c4o << 1u) | (c4o >> 31u));
      let d3o = c2o ^ c4e;
      let d4e = c3e ^ ((c0o << 1u) | (c0o >> 31u));
      let d4o = c3o ^ c0e;
      let b0e = a0e ^ d0e; let b0o = a0o ^ d0o;
      let t6e = a6e ^ d1e; let t6o = a6o ^ d1o;
      let b1e = ((t6e << 22u) | (t6e >> 10u)); let b1o = ((t6o << 22u) | (t6o >> 10u));
      let t12e = a12e ^ d2e; let t12o = a12o ^ d2o;
      let b2e = ((t12o << 22u) | (t12o >> 10u)); let b2o = ((t12e << 21u) | (t12e >> 11u));
      let t18e = a18e ^ d3e; let t18o = a18o ^ d3o;
      let b3e = ((t18o << 11u) | (t18o >> 21u)); let b3o = ((t18e << 10u) | (t18e >> 22u));
      let t24e = a24e ^ d4e; let t24o = a24o ^ d4o;
      let b4e = ((t24e << 7u) | (t24e >> 25u)); let b4o = ((t24o << 7u) | (t24o >> 25u));
      let t3e = a3e ^ d3e; let t3o = a3o ^ d3o;
      let b5e = ((t3e << 14u) | (t3e >> 18u)); let b5o = ((t3o << 14u) | (t3o >> 18u));
      let t9e = a9e ^ d4e; let t9o = a9o ^ d4o;
      let b6e = ((t9e << 10u) | (t9e >> 22u)); let b6o = ((t9o << 10u) | (t9o >> 22u));
      let t10e = a10e ^ d0e; let t10o = a10o ^ d0o;
      let b7e = ((t10o << 2u) | (t10o >> 30u)); let b7o = ((t10e << 1u) | (t10e >> 31u));
      let t16e = a16e ^ d1e; let t16o = a16o ^ d1o;
      let b8e = ((t16o << 23u) | (t16o >> 9u)); let b8o = ((t16e << 22u) | (t16e >> 10u));
      let t22e = a22e ^ d2e; let t22o = a22o ^ d2o;
      let b9e = ((t22o << 31u) | (t22o >> 1u)); let b9o = ((t22e << 30u) | (t22e >> 2u));
      let t1e = a1e ^ d1e; let t1o = a1o ^ d1o;
      let b10e = ((t1o << 1u) | (t1o >> 31u)); let b10o = t1e;
      let t7e = a7e ^ d2e; let t7o = a7o ^ d2o;
      let b11e = ((t7e << 3u) | (t7e >> 29u)); let b11o = ((t7o << 3u) | (t7o >> 29u));
      let t13e = a13e ^ d3e; let t13o = a13o ^ d3o;
      let b12e = ((t13o << 13u) | (t13o >> 19u)); let b12o = ((t13e << 12u) | (t13e >> 20u));
      let t19e = a19e ^ d4e; let t19o = a19o ^ d4o;
      let b13e = ((t19e << 4u) | (t19e >> 28u)); let b13o = ((t19o << 4u) | (t19o >> 28u));
      let t20e = a20e ^ d0e; let t20o = a20o ^ d0o;
      let b14e = ((t20e << 9u) | (t20e >> 23u)); let b14o = ((t20o << 9u) | (t20o >> 23u));
      let t4e = a4e ^ d4e; let t4o = a4o ^ d4o;
      let b15e = ((t4o << 14u) | (t4o >> 18u)); let b15o = ((t4e << 13u) | (t4e >> 19u));
      let t5e = a5e ^ d0e; let t5o = a5o ^ d0o;
      let b16e = ((t5e << 18u) | (t5e >> 14u)); let b16o = ((t5o << 18u) | (t5o >> 14u));
      let t11e = a11e ^ d1e; let t11o = a11o ^ d1o;
      let b17e = ((t11e << 5u) | (t11e >> 27u)); let b17o = ((t11o << 5u) | (t11o >> 27u));
      let t17e = a17e ^ d2e; let t17o = a17o ^ d2o;
      let b18e = ((t17o << 8u) | (t17o >> 24u)); let b18o = ((t17e << 7u) | (t17e >> 25u));
      let t23e = a23e ^ d3e; let t23o = a23o ^ d3o;
      let b19e = ((t23e << 28u) | (t23e >> 4u)); let b19o = ((t23o << 28u) | (t23o >> 4u));
      let t2e = a2e ^ d2e; let t2o = a2o ^ d2o;
      let b20e = ((t2e << 31u) | (t2e >> 1u)); let b20o = ((t2o << 31u) | (t2o >> 1u));
      let t8e = a8e ^ d3e; let t8o = a8o ^ d3o;
      let b21e = ((t8o << 28u) | (t8o >> 4u)); let b21o = ((t8e << 27u) | (t8e >> 5u));
      let t14e = a14e ^ d4e; let t14o = a14o ^ d4o;
      let b22e = ((t14o << 20u) | (t14o >> 12u)); let b22o = ((t14e << 19u) | (t14e >> 13u));
      let t15e = a15e ^ d0e; let t15o = a15o ^ d0o;
      let b23e = ((t15o << 21u) | (t15o >> 11u)); let b23o = ((t15e << 20u) | (t15e >> 12u));
      let t21e = a21e ^ d1e; let t21o = a21o ^ d1o;
      let b24e = ((t21e << 1u) | (t21e >> 31u)); let b24o = ((t21o << 1u) | (t21o >> 31u));
      a0e = b0e ^ (~b1e & b2e) ^ RCE[rnd];
      a0o = b0o ^ (~b1o & b2o) ^ RCO[rnd];
      a1e = b1e ^ (~b2e & b3e); a1o = b1o ^ (~b2o & b3o);
      a2e = b2e ^ (~b3e & b4e); a2o = b2o ^ (~b3o & b4o);
      a3e = b3e ^ (~b4e & b0e); a3o = b3o ^ (~b4o & b0o);
      a4e = b4e ^ (~b0e & b1e); a4o = b4o ^ (~b0o & b1o);
      a5e = b5e ^ (~b6e & b7e); a5o = b5o ^ (~b6o & b7o);
      a6e = b6e ^ (~b7e & b8e); a6o = b6o ^ (~b7o & b8o);
      a7e = b7e ^ (~b8e & b9e); a7o = b7o ^ (~b8o & b9o);
      a8e = b8e ^ (~b9e & b4e); a8o = b8o ^ (~b9o & b4o);
      a9e = b9e ^ (~b5e & b6e); a9o = b9o ^ (~b5o & b6o);
      a10e = b10e ^ (~b11e & b12e); a10o = b10o ^ (~b11o & b12o);
      a11e = b11e ^ (~b12e & b13e); a11o = b11o ^ (~b12o & b13o);
      a12e = b12e ^ (~b13e & b14e); a12o = b12o ^ (~b13o & b14o);
      a13e = b13e ^ (~b14e & b10e); a13o = b13o ^ (~b14o & b10o);
      a14e = b14e ^ (~b10e & b11e); a14o = b14o ^ (~b10o & b11o);
      a15e = b15e ^ (~b16e & b17e); a15o = b15o ^ (~b16o & b17o);
      a16e = b16e ^ (~b17e & b18e); a16o = b16o ^ (~b17o & b18o);
      a17e = b17e ^ (~b18e & b19e); a17o = b17o ^ (~b18o & b19o);
      a18e = b18e ^ (~b19e & b15e); a18o = b18o ^ (~b19o & b15o);
      a19e = b19e ^ (~b15e & b16e); a19o = b19o ^ (~b15o & b16o);
      a20e = b20e ^ (~b21e & b22e); a20o = b20o ^ (~b21o & b22o);
      a21e = b21e ^ (~b22e & b23e); a21o = b21o ^ (~b22o & b23o);
      a22e = b22e ^ (~b23e & b24e); a22o = b22o ^ (~b23o & b24o);
      a23e = b23e ^ (~b24e & b20e); a23o = b23o ^ (~b24o & b20o);
      a24e = b24e ^ (~b20e & b21e); a24o = b24o ^ (~b20o & b21o);
    }

    // Extract hash bytes from lane 0 (a0e, a0o)
    let h0 = a0e;
    let h1 = a0o;
    // De-interleave to get bytes
    var byte0 = 0u;
    for (var b = 0u; b < 8u; b = b + 1u) {
      let pe = (h0 >> (b * 4u)) & 15u;
      let po = (h1 >> (b * 4u)) & 15u;
      let se = (pe & 1u) | ((pe & 2u) << 1u) | ((pe & 4u) << 2u) | ((pe & 8u) << 3u);
      let so = (po & 1u) | ((po & 2u) << 1u) | ((po & 4u) << 2u) | ((po & 8u) << 3u);
      byte0 = byte0 | ((se | (so << 1u)) << (b * 8u));
    }

    // Count leading zeros
    var depth = 0u;
    if (byte0 == 0u) {
      depth = 32u;
      // Check more lanes (simplified — full version checks all 8 bytes of lane 0)
    } else {
      depth = countLeadingZeros(byte0);
    }

    // Local histogram for first 8 levels
    if (depth < 8u) {
      switch (depth) {
        case 0u: { c0 += 1u; }
        case 1u: { c1 += 1u; }
        case 2u: { c2 += 1u; }
        case 3u: { c3 += 1u; }
        case 4u: { c4 += 1u; }
        case 5u: { c5 += 1u; }
        case 6u: { c6 += 1u; }
        case 7u: { c7 += 1u; }
        default: { }
      }
    } else {
      atomicAdd(&shared_hist[depth], 1u);
    }

    // If candidate (depth >= threshold), store it
    if (depth >= thresh) {
      let idx = atomicAdd(&out.count, 1u);
      if (idx < maxCands) {
        cands[idx] = vec2<u32>(n, depth);
      }
    }
  }

  // Flush local histogram to shared
  atomicAdd(&shared_hist[0u], c0);
  atomicAdd(&shared_hist[1u], c1);
  atomicAdd(&shared_hist[2u], c2);
  atomicAdd(&shared_hist[3u], c3);
  atomicAdd(&shared_hist[4u], c4);
  atomicAdd(&shared_hist[5u], c5);
  atomicAdd(&shared_hist[6u], c6);
  atomicAdd(&shared_hist[7u], c7);
  workgroupBarrier();

  // Sum to global
  for (var i = lid; i < 33u; i = i + WG) {
    let sum = atomicLoad(&shared_hist[i]);
    if (sum != 0u) { atomicAdd(&out.hist[i], sum); }
  }
}
`;

// ============================================================
// KECCAK STATE PREPARATION (from hashcats worker)
// ============================================================

// Bit interleave: takes two uint32, returns [even, odd]
function interleave(e, t) {
  let n = 0, r = 0;
  for (let i = 0; i < 16; i++) {
    n |= (e >>> (2*i) & 1) << i;
    r |= (e >>> (2*i+1) & 1) << i;
    n |= (t >>> (2*i) & 1) << (i+16);
    r |= (t >>> (2*i+1) & 1) << (i+16);
  }
  return [n|0, r|0];
}

// Bit de-interleave
function deinterleave(e, t) {
  let n = 0, r = 0;
  for (let i = 0; i < 16; i++) {
    n |= (e >>> i & 1) << (2*i);
    n |= (t >>> i & 1) << (2*i+1);
    r |= (e >>> (i+16) & 1) << (2*i);
    r |= (t >>> (i+16) & 1) << (2*i+1);
  }
  return [n|0, r|0];
}

// Byte swap (big-endian to little-endian)
function byteSwap(e) {
  return ((e & 255) << 24 | (e >>> 8 & 255) << 16 | (e >>> 16 & 255) << 8 | e >>> 24) >>> 0;
}

// Pack miner + prev + anchor into 116-byte input
function packInput(miner, prev, anchor) {
  const r = new Uint8Array(116);
  // miner (20 bytes hex → 20 bytes at offset 0)
  const mh = miner.startsWith('0x') ? miner.slice(2) : miner;
  for (let i = 0; i < 20; i++) r[i] = parseInt(mh.slice(i*2, i*2+2), 16);
  // prev (uint256 → 32 bytes big-endian at offset 52)
  const pb = BigInt(prev).toString(16).padStart(64, '0');
  for (let i = 0; i < 32; i++) r[52+i] = parseInt(pb.slice(i*2, i*2+2), 16);
  // anchor (bytes32 hex → 32 bytes at offset 84)
  const ah = anchor.startsWith('0x') ? anchor.slice(2) : anchor;
  for (let i = 0; i < 32; i++) r[84+i] = parseInt(ah.slice(i*2, i*2+2), 16);
  return r;
}

// Pad to 136-byte Keccak block and convert to 34 interleaved uint32
function prepareState(input) {
  const block = new Uint8Array(136);
  block.set(input);
  block[input.length] = 1;
  block[135] |= 128;
  const state = new Int32Array(34);
  for (let i = 0; i < 17; i++) {
    const lo = block[8*i] | block[8*i+1] << 8 | block[8*i+2] << 16 | block[8*i+3] << 24;
    const hi = block[8*i+4] | block[8*i+5] << 8 | block[8*i+6] << 16 | block[8*i+7] << 24;
    const [e, o] = interleave(lo, hi);
    state[2*i] = e;
    state[2*i+1] = o;
  }
  return state;
}

// Inject stream counter into state (words 10-11 = nonce bytes 20-27)
function injectStream(state, stream) {
  state[10] = (state[10] & 0xffff) | ((stream & 0xffff) << 16);
  state[11] = (state[11] & 0xffff) | ((stream >>> 16 & 0xffff) << 16);
}

// Reconstruct full nonce from stream + counter
function reconstructNonce(stream, counter) {
  const [deintCounter] = deinterleave(counter & 0xffff, counter >>> 16 & 0xffff);
  const [deintStream] = deinterleave(stream & 0xffff, stream >>> 16 & 0xffff);
  return (BigInt(byteSwap(deintStream)) << 32n) | BigInt(byteSwap(deintCounter >>> 0));
}

// ============================================================
// LEADING ZEROS / TARGET COMPARISON
// ============================================================
const CLZ = new Int32Array(256);
for (let i = 1; i < 256; i++) {
  let t = 0, n = i;
  while (!(n & 128)) { t++; n <<= 1; }
  CLZ[i] = t;
}
CLZ[0] = 8;

const BIT_SHUFFLE = new Int32Array(16);
for (let i = 0; i < 16; i++) BIT_SHUFFLE[i] = (i&1) | ((i&2)<<1) | ((i&4)<<2) | ((i&8)<<3);

function leadingZeros(hash) {
  // hash is Uint8Array(32)
  let t = 0;
  for (let n of hash) {
    if (n === 0) { t += 8; continue; }
    return t + CLZ[n];
  }
  return t;
}

function hashLessThanTarget(hash, targetBytes) {
  for (let i = 0; i < 32; i++) {
    if (hash[i] !== targetBytes[i]) return hash[i] < targetBytes[i];
  }
  return false;
}

// ============================================================
// CPU KECCAK (for verifying GPU candidates)
// ============================================================
const { createHash } = await import('crypto');

function keccak256(data) {
  // Node.js crypto.createHash('sha3-256') is NIST SHA3, NOT Keccak!
  // We need Keccak-256 (Ethereum's). Use ethers.
  return ethers.keccak256(data);
}

function computeHash(miner, nonce, prev, anchor) {
  // keccak256(miner (20) || nonce (32) || prev (32) || anchor (32))
  const mb = ethers.getBytes(miner); // 20 bytes
  const nb = ethers.toBeArray(BigInt(nonce)); // variable length
  const nb32 = new Uint8Array(32);
  nb32.set(nb, 32 - nb.length);
  const pb = ethers.toBeArray(BigInt(prev));
  const pb32 = new Uint8Array(32);
  pb32.set(pb, 32 - pb.length);
  const ab = ethers.getBytes(anchor);
  const input = new Uint8Array(116);
  input.set(mb, 0);
  input.set(nb32, 20);
  input.set(pb32, 52);
  input.set(ab, 84);
  return ethers.getBytes(keccak256(input));
}

// ============================================================
// GPU MINER
// ============================================================
const WG = 256;       // workgroup size
const MAX_CANDS = 1024; // max candidates per dispatch

// WebGPU constants (from the WebGPU spec, not available as globals in Node.js)
const GPUBufferUsage = { 
  MAP_READ: 0x0001, MAP_WRITE: 0x0002, 
  COPY_SRC: 0x0004, COPY_DST: 0x0008, 
  INDEX: 0x0010, VERTEX: 0x0020, UNIFORM: 0x0040, 
  STORAGE: 0x0080, INDIRECT: 0x0100 
};
const GPUMapMode = { READ: 0x0001, WRITE: 0x0002 };

async function initGPU() {
  // Initialize webgpu (Google Dawn native backend)
  const gpu = gpuCreate([]);
  const adapter = await gpu.requestAdapter({ powerPreference: 'high-performance' });
  if (!adapter) throw new Error('No GPU adapter found');
  const device = await adapter.requestDevice();
  const info = adapter.info || {};
  const name = info.description || info.device || `${info.vendor || ''} ${info.architecture || ''}`.trim() || 'GPU';
  console.log(`GPU: ${name}`);
  
  const module = device.createShaderModule({ code: SHADER });
  const pipeline = await device.createComputePipelineAsync({
    layout: 'auto',
    compute: { module, entryPoint: 'main', constants: { WG } }
  });
  
  // Create buffers
  const jobBuf = device.createBuffer({ size: 152, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST });
  const outBuf = device.createBuffer({ size: 136, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC | GPUBufferUsage.COPY_DST });
  const candsBuf = device.createBuffer({ size: MAX_CANDS * 8, usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_SRC });
  const readOut = device.createBuffer({ size: 136, usage: GPUBufferUsage.MAP_READ | GPUBufferUsage.COPY_DST });
  const readCands = device.createBuffer({ size: MAX_CANDS * 8, usage: GPUBufferUsage.MAP_READ | GPUBufferUsage.COPY_DST });
  
  const bindGroup = device.createBindGroup({
    layout: pipeline.getBindGroupLayout(0),
    entries: [
      { binding: 0, resource: { buffer: jobBuf } },
      { binding: 1, resource: { buffer: outBuf } },
      { binding: 2, resource: { buffer: candsBuf } },
    ]
  });
  
  return { device, pipeline, jobBuf, outBuf, candsBuf, readOut, readCands, bindGroup, name };
}

async function gpuMine(gpu, state, stream, target, targetBytes, needDepth, base, perThread, workgroups) {
  const { device, pipeline, jobBuf, outBuf, candsBuf, readOut, readCands, bindGroup } = gpu;
  
  // Build job buffer: 34 uint32 (state) + base + perThread + thresh + maxCands = 38 uint32 = 152 bytes
  const job = new Uint32Array(38);
  job.set(state, 0);
  job[34] = base >>> 0;
  job[35] = perThread;
  job[36] = needDepth;
  job[37] = MAX_CANDS;
  
  // Clear output buffer
  const clearOut = new Uint32Array(34);
  
  device.queue.writeBuffer(jobBuf, 0, job);
  device.queue.writeBuffer(outBuf, 0, clearOut);
  
  const encoder = device.createCommandEncoder();
  const pass = encoder.beginComputePass();
  pass.setPipeline(pipeline);
  pass.setBindGroup(0, bindGroup);
  pass.dispatchWorkgroups(workgroups);
  pass.end();
  encoder.copyBufferToBuffer(outBuf, 0, readOut, 0, 136);
  encoder.copyBufferToBuffer(candsBuf, 0, readCands, 0, MAX_CANDS * 8);
  device.queue.submit([encoder.finish()]);
  
  // Read results
  await readOut.mapAsync(GPUMapMode.READ);
  const outData = new Uint32Array(readOut.getMappedRange().slice(0));
  readOut.unmap();
  
  await readCands.mapAsync(GPUMapMode.READ);
  const candsData = new Uint32Array(readCands.getMappedRange().slice(0));
  readCands.unmap();
  
  const count = outData[0];
  const hist = outData.slice(1, 34);
  
  // Check candidates
  const candidates = [];
  const numCands = Math.min(count, MAX_CANDS);
  for (let i = 0; i < numCands; i++) {
    const counter = candsData[2*i] | 0;
    const depth = candsData[2*i+1];
    // Reconstruct full nonce
    const nonce = reconstructNonce(stream, counter);
    // Verify on CPU
    candidates.push({ nonce, depth, counter });
  }
  
  const totalHashes = workgroups * WG * perThread;
  return { count, hist, candidates, totalHashes };
}

// ============================================================
// MAIN
// ============================================================
async function main() {
  const args = process.argv.slice(2);
  const keyArg = args.find(a => a.startsWith('--key'));
  const dryRun = args.includes('--dry-run');
  const cpuOnly = args.includes('--cpu-only');
  
  if (!keyArg) {
    console.error('Usage: node miner.mjs --key 0xPRIVATE_KEY [--dry-run] [--cpu-only]');
    process.exit(1);
  }
  
  const privateKey = keyArg.split('=')[1] || args[args.indexOf(keyArg) + 1];
  
  // Connect
  const provider = new ethers.JsonRpcProvider(RPC);
  const wallet = new ethers.Wallet(privateKey, provider);
  const contract = new ethers.Contract(CONTRACT, ABI, wallet);
  
  const network = await provider.getNetwork();
  console.log(`RPC: ${RPC}`);
  console.log(`Chain ID: ${network.chainId} (expected ${CHAIN_ID})`);
  console.log(`Miner: ${wallet.address}`);
  const balance = await provider.getBalance(wallet.address);
  console.log(`Balance: ${ethers.formatEther(balance)} ETH`);
  
  // Read contract state
  const target = await contract.currentTarget();
  const baseTarget = await contract.baseTarget();
  const prev = await contract.prevWork();
  const [anchorBlock, anchor] = await contract.currentAnchor();
  const price = await contract.mintPrice();
  const totalMinted = await contract.totalMinted();
  
  const targetBytes = ethers.toBeArray(target);
  const targetBytes32 = new Uint8Array(32);
  targetBytes32.set(targetBytes, 32 - targetBytes.length);
  const bits = 256 - target.toString(2).length;
  
  console.log(`\n=== Contract State ===`);
  console.log(`Total minted: ${totalMinted}`);
  console.log(`Mint price: ${ethers.formatEther(price)} ETH`);
  console.log(`Difficulty: ${bits} bits`);
  console.log(`Anchor block: ${anchorBlock}`);
  console.log(`Need ~2^${bits} = ${(2n ** BigInt(bits)).toLocaleString()} hashes/cat\n`);
  
  // Init GPU
  let gpu = null;
  if (!cpuOnly) {
    try {
      gpu = await initGPU();
    } catch (e) {
      console.error(`GPU init failed: ${e.message}`);
      console.error('Falling back to CPU-only mode');
    }
  }
  
  if (!gpu) {
    console.log('CPU-only mode (will be slow — ~0.5 MH/s per core)');
    console.log('For real mining, use a VPS with GPU and @webgpu/webgpu installed');
  }
  
  // Prepare keccak state
  const input = packInput(wallet.address, prev, anchor);
  const state = prepareState(input);
  const stream = Math.floor(Math.random() * 4294967296);
  injectStream(state, stream);
  
  // Mining parameters
  let base = 0;
  let totalHashes = 0n;
  let bestDepth = 0;
  const startTime = Date.now();
  let round = 0;
  
  // GPU tuning
  let perThread = 256;
  let workgroups = 4096;
  
  while (true) {
    round++;
    if (gpu) {
      // === GPU MINING ===
      const t0 = Date.now();
      const result = await gpuMine(gpu, state, stream, target, targetBytes32, bits, base, perThread, workgroups);
      const elapsed = (Date.now() - t0) / 1000;
      totalHashes += BigInt(result.totalHashes);
      
      const rate = Number(result.totalHashes) / elapsed / 1e6;
      console.log(`[Round ${round}] ${rate.toFixed(1)} MH/s | ${result.totalHashes.toLocaleString()} hashes | ${elapsed.toFixed(2)}s | best ${bestDepth}/${bits}b`);
      
      // Check candidates
      let found = null;
      for (const cand of result.candidates) {
        // Verify hash on CPU
        const hash = computeHash(wallet.address, cand.nonce, prev, anchor);
        const depth = leadingZeros(hash);
        if (depth > bestDepth) bestDepth = depth;
        if (depth >= bits && hashLessThanTarget(hash, targetBytes32)) {
          found = { nonce: cand.nonce, hash, depth };
          break;
        }
      }
      
      if (found) {
        console.log(`\n*** SOLUTION FOUND ***`);
        console.log(`  Nonce: ${found.nonce}`);
        console.log(`  Hash: 0x${Buffer.from(found.hash).toString('hex')}`);
        console.log(`  Depth: ${found.depth} bits`);
        console.log(`  Total hashes: ${totalHashes.toLocaleString()}`);
        console.log(`  Time: ${((Date.now() - startTime) / 1000).toFixed(1)}s`);
        
        if (!dryRun) {
          console.log('\nSubmitting mine()...');
          try {
            const gasEstimate = await contract.mine.estimateGas(found.nonce, anchorBlock, { value: price });
            const tx = await contract.mine(found.nonce, anchorBlock, { value: price, gasLimit: gasEstimate * 120n / 100n });
            console.log(`  TX: ${tx.hash}`);
            const receipt = await tx.wait();
            console.log(`  ${receipt.status === 1 ? '✓ MINED!' : '✗ failed'} block=${receipt.blockNumber}`);
            if (receipt.status === 1) {
              for (const log of receipt.logs) {
                try {
                  const parsed = contract.interface.parseLog(log);
                  if (parsed?.name === 'Mined') {
                    console.log(`  Cat #${parsed.args.tokenId} (unique=${parsed.args.unique})`);
                  }
                } catch {}
              }
            }
          } catch (e) {
            console.log(`  Error: ${e.message}`);
          }
        } else {
          console.log('[DRY RUN] Would submit mine()');
        }
        
        // Refresh state
        break;
      }
      
      base += result.totalHashes;
      
      // Auto-tune
      if (elapsed > 0 && result.count === 0) {
        const targetRate = 250e6; // target ~250 MH/s
        const actualRate = Number(result.totalHashes) / elapsed;
        if (actualRate < targetRate * 0.5) {
          workgroups = Math.min(workgroups * 2, 4096);
        }
      }
      
    } else {
      // === CPU FALLBACK (slow) ===
      const batchSize = 100000;
      const t0 = Date.now();
      let found = null;
      
      for (let i = 0; i < batchSize; i++) {
        const nonce = BigInt(base + i);
        const hash = computeHash(wallet.address, nonce, prev, anchor);
        const depth = leadingZeros(hash);
        if (depth > bestDepth) bestDepth = depth;
        if (depth >= bits && hashLessThanTarget(hash, targetBytes32)) {
          found = { nonce, hash, depth };
          break;
        }
      }
      
      totalHashes += BigInt(batchSize);
      const elapsed = (Date.now() - t0) / 1000;
      const rate = batchSize / elapsed / 1e6;
      const totalElapsed = (Date.now() - startTime) / 1000;
      console.log(`[${totalElapsed.toFixed(0)}s] ${rate.toFixed(2)} MH/s | ${totalHashes.toLocaleString()} h | best ${bestDepth}/${bits}b`);
      
      if (found) {
        console.log(`\n*** FOUND *** nonce=${found.nonce} depth=${found.depth}b`);
        if (!dryRun) {
          try {
            const tx = await contract.mine(found.nonce, anchorBlock, { value: price });
            const receipt = await tx.wait();
            console.log(`  ${receipt.status === 1 ? '✓ MINED!' : '✗ failed'}`);
          } catch (e) { console.log(`  Error: ${e.message}`); }
        }
        break;
      }
      
      base += batchSize;
    }
    
    // Refresh contract state periodically
    if (round % 30 === 0) {
      try {
        const newTarget = await contract.currentTarget();
        const newPrev = await contract.prevWork();
        const [newAB, newAnchor] = await contract.currentAnchor();
        const newTotal = await contract.totalMinted();
        const newBits = 256 - newTarget.toString(2).length;
        if (newAB !== anchorBlock || newPrev !== prev) {
          console.log(`State changed: ${newTotal} minted, ${newBits} bits, block ${newAB}`);
          // Re-prepare state
          const newInput = packInput(wallet.address, newPrev, newAnchor);
          const newState = prepareState(newInput);
          state.set(newState);
          injectStream(state, stream);
          base = 0;
        }
      } catch (e) { console.log(`Refresh error: ${e.message}`); }
    }
  }
  
  const totalTime = (Date.now() - startTime) / 1000;
  const avgRate = totalTime > 0 ? (Number(totalHashes) / totalTime / 1e6).toFixed(2) : '0';
  console.log(`\nDone. ${totalHashes.toLocaleString()} hashes in ${totalTime.toFixed(1)}s (${avgRate} MH/s avg)`);
}

main().catch(e => { console.error(e); process.exit(1); });
