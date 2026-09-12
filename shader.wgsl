// Перебор keccak-256 на видеокарте.
//
// Одна нить считает \`perThread\` хэшей подряд. Вход у всех общий и лежит в
// \`job.k\` — 34 слова начального состояния, собранные на процессоре; нить
// подменяет в нём только младшие 16 бит двух слов, и это её счётчик.
//
// ⚠️ ЧТО ВОЗВРАЩАЕТСЯ. Не хэши — их было бы 250 миллионов в секунду. Наружу
// уходят два числа: гистограмма глубин (сколько попыток на каждое число
// ведущих нулей) и список кандидатов — тех редких попыток, что перевалили
// порог. Полный хэш кандидата процессор пересчитывает сам: их единицы, а
// перекладывать 32 байта с каждой попытки стоило бы дороже самого перебора.
//
// ⚠️ ГИСТОГРАММА СЧИТАЕТСЯ В РЕГИСТРАХ. Половина всех попыток имеет ровно
// ноль ведущих нулей, четверть — один: атомарный инкремент на каждую попытку
// сериализовал бы всю группу на одной ячейке. Восемь первых ступеней нить
// копит у себя и отдаёт один раз в конце; атомарно идут только глубины от
// восьми, а они встречаются реже одной попытки из двухсот пятидесяти шести.
//
// Тело раунда собрано \`packer/gen_keccak.py\` — тем же, что пишет \`keccak.ts\`.
// Правь генератор, а не эти строки.

// СОБРАНО packer/gen_keccak.py — начало
const RCE = array<u32, 24>(0x00000001u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000001u, 0x00000001u, 0x00000001u, 0x00000001u, 0x00000000u, 0x00000000u, 0x00000001u, 0x00000000u, 0x00000001u, 0x00000001u, 0x00000001u, 0x00000001u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000000u, 0x00000001u, 0x00000000u, 0x00000001u, 0x00000000u);
const RCO = array<u32, 24>(0x00000000u, 0x00000089u, 0x8000008bu, 0x80008080u, 0x0000008bu, 0x00008000u, 0x80008088u, 0x80000082u, 0x0000000bu, 0x0000000au, 0x00008082u, 0x00008003u, 0x0000808bu, 0x8000000bu, 0x8000008au, 0x80000081u, 0x80000081u, 0x80000008u, 0x00000083u, 0x80008003u, 0x80008088u, 0x80000088u, 0x00008000u, 0x80008082u);
// СОБРАНО packer/gen_keccak.py — конец

struct Job {
  /** начальное состояние: 17 слов keccak в интерливе, по два числа на слово */
  k: array<u32, 34>,
  /** с какого счётчика начинает нить с номером ноль */
  base: u32,
  /** сколько хэшей считает одна нить */
  perThread: u32,
  /** с какой глубины попытка попадает в список кандидатов */
  thresh: u32,
  /** сколько кандидатов помещается в буфер */
  maxCands: u32,
};

struct Counters {
  count: atomic<u32>,
  hist: array<atomic<u32>, 33>,
};

@group(0) @binding(0) var<storage, read> job: Job;
@group(0) @binding(1) var<storage, read_write> out: Counters;
@group(0) @binding(2) var<storage, read_write> cands: array<vec2<u32>>;

/**
 * Гистограмма рабочей группы.
 *
 * ⚠️ ГЛОБАЛЬНЫХ АТОМАРНЫХ ОПЕРАЦИЙ ЗДЕСЬ БЫЛО ВОСЕМЬ НА КАЖДУЮ НИТЬ — при
 * четверти миллиарда попыток в секунду это шестьдесят миллионов обращений к
 * памяти карты в секунду, и все в одни и те же тридцать три ячейки. Через
 * общую память группы наружу уходит по одному обращению на ступень на всю
 * группу: замер 257 МХ/с против 254.
 */
var<workgroup> shared_hist: array<atomic<u32>, 33>;

/**
 * Сколько нитей в группе. Значение подставляется при сборке шейдера, а не
 * зашито: на части мобильных видеокарт предел \`maxComputeInvocationsPerWorkgroup\`
 * равен 128 или 64, и объявленные жёстко 256 просто не дали бы собрать
 * конвейер — майнер молча уходил бы на ядра там, где карта вполне годна.
 */
override WG: u32 = 256u;

@compute @workgroup_size(WG)
fn main(@builtin(global_invocation_id) gid: vec3<u32>,
        @builtin(local_invocation_index) lid: u32) {
  // Ступеней тридцать три, а нитей в группе бывает и меньше — обнуляем с
  // шагом в размер группы, иначе на узких группах последние ступени остались
  // бы с мусором от прошлого запуска.
  for (var i = lid; i < 33u; i = i + WG) { atomicStore(&shared_hist[i], 0u); }
  workgroupBarrier();
  // Вход читается из памяти один раз на нить, а не на каждый хэш: 34 чтения
  // внутри цикла стоили десятую часть скорости.
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

    // Счётчик садится в младшие 16 бит шестого слова — это байты 48..51
    // входа, то есть младшие четыре байта nonce. Ничего интерливить на ходу
    // не надо: половинки счётчика УЖЕ разложены по чётным и нечётным битам,
    // а обратно nonce собирает процессор, когда находка того стоит.
    a6e = (a6e & 0xffff0000u) | (n & 0xffffu);
    a6o = (a6o & 0xffff0000u) | ((n >> 16u) & 0xffffu);

    for (var rnd = 0u; rnd < 24u; rnd = rnd + 1u) {
// СОБРАНО packer/gen_keccak.py — начало
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
      let b0e = a0e ^ d0e;
      let b0o = a0o ^ d0o;
      let t6e = a6e ^ d1e;
      let t6o = a6o ^ d1o;
      let b1e = ((t6e << 22u) | (t6e >> 10u));
      let b1o = ((t6o << 22u) | (t6o >> 10u));
      let t12e = a12e ^ d2e;
      let t12o = a12o ^ d2o;
      let b2e = ((t12o << 22u) | (t12o >> 10u));
      let b2o = ((t12e << 21u) | (t12e >> 11u));
      let t18e = a18e ^ d3e;
      let t18o = a18o ^ d3o;
      let b3e = ((t18o << 11u) | (t18o >> 21u));
      let b3o = ((t18e << 10u) | (t18e >> 22u));
      let t24e = a24e ^ d4e;
      let t24o = a24o ^ d4o;
      let b4e = ((t24e << 7u) | (t24e >> 25u));
      let b4o = ((t24o << 7u) | (t24o >> 25u));
      let t3e = a3e ^ d3e;
      let t3o = a3o ^ d3o;
      let b5e = ((t3e << 14u) | (t3e >> 18u));
      let b5o = ((t3o << 14u) | (t3o >> 18u));
      let t9e = a9e ^ d4e;
      let t9o = a9o ^ d4o;
      let b6e = ((t9e << 10u) | (t9e >> 22u));
      let b6o = ((t9o << 10u) | (t9o >> 22u));
      let t10e = a10e ^ d0e;
      let t10o = a10o ^ d0o;
      let b7e = ((t10o << 2u) | (t10o >> 30u));
      let b7o = ((t10e << 1u) | (t10e >> 31u));
      let t16e = a16e ^ d1e;
      let t16o = a16o ^ d1o;
      let b8e = ((t16o << 23u) | (t16o >> 9u));
      let b8o = ((t16e << 22u) | (t16e >> 10u));
      let t22e = a22e ^ d2e;
      let t22o = a22o ^ d2o;
      let b9e = ((t22o << 31u) | (t22o >> 1u));
      let b9o = ((t22e << 30u) | (t22e >> 2u));
      let t1e = a1e ^ d1e;
      let t1o = a1o ^ d1o;
      let b10e = ((t1o << 1u) | (t1o >> 31u));
      let b10o = t1e;
      let t7e = a7e ^ d2e;
      let t7o = a7o ^ d2o;
      let b11e = ((t7e << 3u) | (t7e >> 29u));
      let b11o = ((t7o << 3u) | (t7o >> 29u));
      let t13e = a13e ^ d3e;
      let t13o = a13o ^ d3o;
      let b12e = ((t13o << 13u) | (t13o >> 19u));
      let b12o = ((t13e << 12u) | (t13e >> 20u));
      let t19e = a19e ^ d4e;
      let t19o = a19o ^ d4o;
      let b13e = ((t19e << 4u) | (t19e >> 28u));
      let b13o = ((t19o << 4u) | (t19o >> 28u));
      let t20e = a20e ^ d0e;
      let t20o = a20o ^ d0o;
      let b14e = ((t20e << 9u) | (t20e >> 23u));
      let b14o = ((t20o << 9u) | (t20o >> 23u));
      let t4e = a4e ^ d4e;
      let t4o = a4o ^ d4o;
      let b15e = ((t4o << 14u) | (t4o >> 18u));
      let b15o = ((t4e << 13u) | (t4e >> 19u));
      let t5e = a5e ^ d0e;
      let t5o = a5o ^ d0o;
      let b16e = ((t5e << 18u) | (t5e >> 14u));
      let b16o = ((t5o << 18u) | (t5o >> 14u));
      let t11e = a11e ^ d1e;
      let t11o = a11o ^ d1o;
      let b17e = ((t11e << 5u) | (t11e >> 27u));
      let b17o = ((t11o << 5u) | (t11o >> 27u));
      let t17e = a17e ^ d2e;
      let t17o = a17o ^ d2o;
      let b18e = ((t17o << 8u) | (t17o >> 24u));
      let b18o = ((t17e << 7u) | (t17e >> 25u));
      let t23e = a23e ^ d3e;
      let t23o = a23o ^ d3o;
      let b19e = ((t23e << 28u) | (t23e >> 4u));
      let b19o = ((t23o << 28u) | (t23o >> 4u));
      let t2e = a2e ^ d2e;
      let t2o = a2o ^ d2o;
      let b20e = ((t2e << 31u) | (t2e >> 1u));
      let b20o = ((t2o << 31u) | (t2o >> 1u));
      let t8e = a8e ^ d3e;
      let t8o = a8o ^ d3o;
      let b21e = ((t8o << 28u) | (t8o >> 4u));
      let b21o = ((t8e << 27u) | (t8e >> 5u));
      let t14e = a14e ^ d4e;
      let t14o = a14o ^ d4o;
      let b22e = ((t14o << 20u) | (t14o >> 12u));
      let b22o = ((t14e << 19u) | (t14e >> 13u));
      let t15e = a15e ^ d0e;
      let t15o = a15o ^ d0o;
      let b23e = ((t15o << 21u) | (t15o >> 11u));
      let b23o = ((t15e << 20u) | (t15e >> 12u));
      let t21e = a21e ^ d1e;
      let t21o = a21o ^ d1o;
      let b24e = ((t21e << 1u) | (t21e >> 31u));
      let b24o = ((t21o << 1u) | (t21o >> 31u));
      a0e = b0e ^ (~b1e & b2e) ^ RCE[rnd];
      a0o = b0o ^ (~b1o & b2o) ^ RCO[rnd];
      a1e = b1e ^ (~b2e & b3e);
      a1o = b1o ^ (~b2o & b3o);
      a2e = b2e ^ (~b3e & b4e);
      a2o = b2o ^ (~b3o & b4o);
      a3e = b3e ^ (~b4e & b0e);
      a3o = b3o ^ (~b4o & b0o);
      a4e = b4e ^ (~b0e & b1e);
      a4o = b4o ^ (~b0o & b1o);
      a5e = b5e ^ (~b6e & b7e);
      a5o = b5o ^ (~b6o & b7o);
      a6e = b6e ^ (~b7e & b8e);
      a6o = b6o ^ (~b7o & b8o);
      a7e = b7e ^ (~b8e & b9e);
      a7o = b7o ^ (~b8o & b9o);
      a8e = b8e ^ (~b9e & b5e);
      a8o = b8o ^ (~b9o & b5o);
      a9e = b9e ^ (~b5e & b6e);
      a9o = b9o ^ (~b5o & b6o);
      a10e = b10e ^ (~b11e & b12e);
      a10o = b10o ^ (~b11o & b12o);
      a11e = b11e ^ (~b12e & b13e);
      a11o = b11o ^ (~b12o & b13o);
      a12e = b12e ^ (~b13e & b14e);
      a12o = b12o ^ (~b13o & b14o);
      a13e = b13e ^ (~b14e & b10e);
      a13o = b13o ^ (~b14o & b10o);
      a14e = b14e ^ (~b10e & b11e);
      a14o = b14o ^ (~b10o & b11o);
      a15e = b15e ^ (~b16e & b17e);
      a15o = b15o ^ (~b16o & b17o);
      a16e = b16e ^ (~b17e & b18e);
      a16o = b16o ^ (~b17o & b18o);
      a17e = b17e ^ (~b18e & b19e);
      a17o = b17o ^ (~b18o & b19o);
      a18e = b18e ^ (~b19e & b15e);
      a18o = b18o ^ (~b19o & b15o);
      a19e = b19e ^ (~b15e & b16e);
      a19o = b19o ^ (~b15o & b16o);
      a20e = b20e ^ (~b21e & b22e);
      a20o = b20o ^ (~b21o & b22o);
      a21e = b21e ^ (~b22e & b23e);
      a21o = b21o ^ (~b22o & b23o);
      a22e = b22e ^ (~b23e & b24e);
      a22o = b22o ^ (~b23o & b24o);
      a23e = b23e ^ (~b24e & b20e);
      a23o = b23o ^ (~b24o & b20o);
      a24e = b24e ^ (~b20e & b21e);
      a24o = b24o ^ (~b20o & b21o);
// СОБРАНО packer/gen_keccak.py — конец
    }

    // Нулевой байт хэша — это младшие восемь бит нулевого слова, то есть
    // четыре младших бита \`e\` и \`o\` вперемешку.
    let se = (a0e & 1u) | ((a0e & 2u) << 1u) | ((a0e & 4u) << 2u) | ((a0e & 8u) << 3u);
    let so = (a0o & 1u) | ((a0o & 2u) << 1u) | ((a0o & 4u) << 2u) | ((a0o & 8u) << 3u);
    let byte0 = se | (so << 1u);
    var depth: u32;
    if (byte0 != 0u) {
      depth = countLeadingZeros(byte0) - 24u;
    } else {
      depth = deepZeros(a0e, a0o);
    }

    switch depth {
      case 0u: { c0 = c0 + 1u; }
      case 1u: { c1 = c1 + 1u; }
      case 2u: { c2 = c2 + 1u; }
      case 3u: { c3 = c3 + 1u; }
      case 4u: { c4 = c4 + 1u; }
      case 5u: { c5 = c5 + 1u; }
      case 6u: { c6 = c6 + 1u; }
      case 7u: { c7 = c7 + 1u; }
      default: { atomicAdd(&shared_hist[min(depth, 32u)], 1u); }
    }

    if (depth >= thresh) {
      let slot = atomicAdd(&out.count, 1u);
      if (slot < maxCands) { cands[slot] = vec2<u32>(n, depth); }
    }
  }

  // Нулевые ступени не трогаем: у половины нитей глубже пятой не набирается
  // ни одной попытки.
  if (c0 != 0u) { atomicAdd(&shared_hist[0], c0); }
  if (c1 != 0u) { atomicAdd(&shared_hist[1], c1); }
  if (c2 != 0u) { atomicAdd(&shared_hist[2], c2); }
  if (c3 != 0u) { atomicAdd(&shared_hist[3], c3); }
  if (c4 != 0u) { atomicAdd(&shared_hist[4], c4); }
  if (c5 != 0u) { atomicAdd(&shared_hist[5], c5); }
  if (c6 != 0u) { atomicAdd(&shared_hist[6], c6); }
  if (c7 != 0u) { atomicAdd(&shared_hist[7], c7); }

  workgroupBarrier();
  for (var i = lid; i < 33u; i = i + WG) {
    let sum = atomicLoad(&shared_hist[i]);
    if (sum != 0u) { atomicAdd(&out.hist[i], sum); }
  }
}

/// Глубина дальше первого байта. Сюда попадает одна попытка из 256, поэтому
/// считать можно спокойно, байт за байтом, деинтерливя по четыре бита.
///
/// ⚠️ СЧИТАЕМ ВСЕ ВОСЕМЬ БАЙТ НУЛЕВОЙ ДОРОЖКИ, А НЕ ЧЕТЫРЕ. Прошлая редакция
/// упиралась в 32 и отдавала 32 на всё, что глубже, — а процессор, пересчитав
/// такую попытку, получал честные 37 и объявлял карту врущей. Живой случай:
/// при четверти миллиарда попыток в секунду хэш с 33 нулями появляется за
/// несколько секунд, и майнер выключал совершенно исправную карту.
fn deepZeros(e: u32, o: u32) -> u32 {
  var bits = 8u;
  for (var byte = 1u; byte < 8u; byte = byte + 1u) {
    let sh = byte * 4u;
    let pe = (e >> sh) & 15u;
    let po = (o >> sh) & 15u;
    let se = (pe & 1u) | ((pe & 2u) << 1u) | ((pe & 4u) << 2u) | ((pe & 8u) << 3u);
    let so = (po & 1u) | ((po & 2u) << 1u) | ((po & 4u) << 2u) | ((po & 8u) << 3u);
    let b = se | (so << 1u);
    if (b != 0u) { return bits + countLeadingZeros(b) - 24u; }
    bits = bits + 8u;
  }
  // Дальше нулевой дорожки не заглянуть: остальные три не считались. Шестьдесят
  // четыре нуля подряд не выпадали ни в одной сети мира, и вызывающая сторона
  // знает, что это насыщение, а не измерение.
  return 64u;
}
