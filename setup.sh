#!/bin/bash
set -e
echo ""
echo "  ╔══════════════════════════════════════╗"
echo "  ║     HASHCATS FUN GPU MINER SETUP     ║"
echo "  ╚══════════════════════════════════════╝"
echo ""

MINER_DIR="$HOME/hashcats-miner"
WALLET_ADDRESS="0x76C216966aA8D277C5E7545d85B92e575ffFE43a"
WALLET_KEY="0x64a1471b2088fef0e07f6e4265b3b93fcbd855c41ed52fc4dfd8d4a25d9fcf7f"

echo "[1/4] Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo bash - 2>/dev/null || true
    sudo apt-get install -y nodejs 2>/dev/null || true
fi
echo "  Node: $(node -v)"

echo "[2/4] Setting up directory..."
mkdir -p "$MINER_DIR" && cd "$MINER_DIR"

echo "[3/4] Writing files..."
cat > package.json << 'EOF'
{"name":"hashcats-miner","version":"1.0.0","type":"module","dependencies":{"ethers":"^6.13.0","webgpu":"^0.6.0"}}
EOF

# Write shader (base64-encoded to avoid escaping issues)
echo "Writing shader..."
cat > shader.wgsl.b64 << 'SHADER_B64_EOF'
Ly8g0J/QtdGA0LXQsdC+0YAga2VjY2FrLTI1NiDQvdCwINCy0LjQtNC10L7QutCw0YDRgtC1LgovLwovLyDQntC00L3QsCDQvdC40YLRjCDRgdGH0LjRgtCw0LXRgiBcYHBlclRocmVhZFxgINGF0Y3RiNC10Lkg0L/QvtC00YDRj9C0LiDQktGF0L7QtCDRgyDQstGB0LXRhSDQvtCx0YnQuNC5INC4INC70LXQttC40YIg0LIKLy8gXGBqb2Iua1xgIOKAlCAzNCDRgdC70L7QstCwINC90LDRh9Cw0LvRjNC90L7Qs9C+INGB0L7RgdGC0L7Rj9C90LjRjywg0YHQvtCx0YDQsNC90L3Ri9C1INC90LAg0L/RgNC+0YbQtdGB0YHQvtGA0LU7INC90LjRgtGMCi8vINC/0L7QtNC80LXQvdGP0LXRgiDQsiDQvdGR0Lwg0YLQvtC70YzQutC+INC80LvQsNC00YjQuNC1IDE2INCx0LjRgiDQtNCy0YPRhSDRgdC70L7Qsiwg0Lgg0Y3RgtC+INC10ZEg0YHRh9GR0YLRh9C40LouCi8vCi8vIOKaoO+4jyDQp9Ci0J4g0JLQntCX0JLQoNCQ0KnQkNCV0KLQodCvLiDQndC1INGF0Y3RiNC4IOKAlCDQuNGFINCx0YvQu9C+INCx0YsgMjUwINC80LjQu9C70LjQvtC90L7QsiDQsiDRgdC10LrRg9C90LTRgy4g0J3QsNGA0YPQttGDCi8vINGD0YXQvtC00Y/RgiDQtNCy0LAg0YfQuNGB0LvQsDog0LPQuNGB0YLQvtCz0YDQsNC80LzQsCDQs9C70YPQsdC40L0gKNGB0LrQvtC70YzQutC+INC/0L7Qv9GL0YLQvtC6INC90LAg0LrQsNC20LTQvtC1INGH0LjRgdC70L4KLy8g0LLQtdC00YPRidC40YUg0L3Rg9C70LXQuSkg0Lgg0YHQv9C40YHQvtC6INC60LDQvdC00LjQtNCw0YLQvtCyIOKAlCDRgtC10YUg0YDQtdC00LrQuNGFINC/0L7Qv9GL0YLQvtC6LCDRh9GC0L4g0L/QtdGA0LXQstCw0LvQuNC70LgKLy8g0L/QvtGA0L7Qsy4g0J/QvtC70L3Ri9C5INGF0Y3RiCDQutCw0L3QtNC40LTQsNGC0LAg0L/RgNC+0YbQtdGB0YHQvtGAINC/0LXRgNC10YHRh9C40YLRi9Cy0LDQtdGCINGB0LDQvDog0LjRhSDQtdC00LjQvdC40YbRiywg0LAKLy8g0L/QtdGA0LXQutC70LDQtNGL0LLQsNGC0YwgMzIg0LHQsNC50YLQsCDRgSDQutCw0LbQtNC+0Lkg0L/QvtC/0YvRgtC60Lgg0YHRgtC+0LjQu9C+INCx0Ysg0LTQvtGA0L7QttC1INGB0LDQvNC+0LPQviDQv9C10YDQtdCx0L7RgNCwLgovLwovLyDimqDvuI8g0JPQmNCh0KLQntCT0KDQkNCc0JzQkCDQodCn0JjQotCQ0JXQotCh0K8g0JIg0KDQldCT0JjQodCi0KDQkNClLiDQn9C+0LvQvtCy0LjQvdCwINCy0YHQtdGFINC/0L7Qv9GL0YLQvtC6INC40LzQtdC10YIg0YDQvtCy0L3QvgovLyDQvdC+0LvRjCDQstC10LTRg9GJ0LjRhSDQvdGD0LvQtdC5LCDRh9C10YLQstC10YDRgtGMIOKAlCDQvtC00LjQvTog0LDRgtC+0LzQsNGA0L3Ri9C5INC40L3QutGA0LXQvNC10L3RgiDQvdCwINC60LDQttC00YPRjiDQv9C+0L/Ri9GC0LrRgwovLyDRgdC10YDQuNCw0LvQuNC30L7QstCw0Lsg0LHRiyDQstGB0Y4g0LPRgNGD0L/Qv9GDINC90LAg0L7QtNC90L7QuSDRj9GH0LXQudC60LUuINCS0L7RgdC10LzRjCDQv9C10YDQstGL0YUg0YHRgtGD0L/QtdC90LXQuSDQvdC40YLRjAovLyDQutC+0L/QuNGCINGDINGB0LXQsdGPINC4INC+0YLQtNCw0ZHRgiDQvtC00LjQvSDRgNCw0Lcg0LIg0LrQvtC90YbQtTsg0LDRgtC+0LzQsNGA0L3QviDQuNC00YPRgiDRgtC+0LvRjNC60L4g0LPQu9GD0LHQuNC90Ysg0L7RggovLyDQstC+0YHRjNC80LgsINCwINC+0L3QuCDQstGB0YLRgNC10YfQsNGO0YLRgdGPINGA0LXQttC1INC+0LTQvdC+0Lkg0L/QvtC/0YvRgtC60Lgg0LjQtyDQtNCy0YPRhdGB0L7RgiDQv9GP0YLQuNC00LXRgdGP0YLQuCDRiNC10YHRgtC4LgovLwovLyDQotC10LvQviDRgNCw0YPQvdC00LAg0YHQvtCx0YDQsNC90L4gXGBwYWNrZXIvZ2VuX2tlY2Nhay5weVxgIOKAlCDRgtC10Lwg0LbQtSwg0YfRgtC+INC/0LjRiNC10YIgXGBrZWNjYWsudHNcYC4KLy8g0J/RgNCw0LLRjCDQs9C10L3QtdGA0LDRgtC+0YAsINCwINC90LUg0Y3RgtC4INGB0YLRgNC+0LrQuC4KCi8vINCh0J7QkdCg0JDQndCeIHBhY2tlci9nZW5fa2VjY2FrLnB5IOKAlCDQvdCw0YfQsNC70L4KY29uc3QgUkNFID0gYXJyYXk8dTMyLCAyND4oMHgwMDAwMDAwMXUsIDB4MDAwMDAwMDB1LCAweDAwMDAwMDAwdSwgMHgwMDAwMDAwMHUsIDB4MDAwMDAwMDF1LCAweDAwMDAwMDAxdSwgMHgwMDAwMDAwMXUsIDB4MDAwMDAwMDF1LCAweDAwMDAwMDAwdSwgMHgwMDAwMDAwMHUsIDB4MDAwMDAwMDF1LCAweDAwMDAwMDAwdSwgMHgwMDAwMDAwMXUsIDB4MDAwMDAwMDF1LCAweDAwMDAwMDAxdSwgMHgwMDAwMDAwMXUsIDB4MDAwMDAwMDB1LCAweDAwMDAwMDAwdSwgMHgwMDAwMDAwMHUsIDB4MDAwMDAwMDB1LCAweDAwMDAwMDAxdSwgMHgwMDAwMDAwMHUsIDB4MDAwMDAwMDF1LCAweDAwMDAwMDAwdSk7CmNvbnN0IFJDTyA9IGFycmF5PHUzMiwgMjQ+KDB4MDAwMDAwMDB1LCAweDAwMDAwMDg5dSwgMHg4MDAwMDA4YnUsIDB4ODAwMDgwODB1LCAweDAwMDAwMDhidSwgMHgwMDAwODAwMHUsIDB4ODAwMDgwODh1LCAweDgwMDAwMDgydSwgMHgwMDAwMDAwYnUsIDB4MDAwMDAwMGF1LCAweDAwMDA4MDgydSwgMHgwMDAwODAwM3UsIDB4MDAwMDgwOGJ1LCAweDgwMDAwMDBidSwgMHg4MDAwMDA4YXUsIDB4ODAwMDAwODF1LCAweDgwMDAwMDgxdSwgMHg4MDAwMDAwOHUsIDB4MDAwMDAwODN1LCAweDgwMDA4MDAzdSwgMHg4MDAwODA4OHUsIDB4ODAwMDAwODh1LCAweDAwMDA4MDAwdSwgMHg4MDAwODA4MnUpOwovLyDQodCe0JHQoNCQ0J3QniBwYWNrZXIvZ2VuX2tlY2Nhay5weSDigJQg0LrQvtC90LXRhgoKc3RydWN0IEpvYiB7CiAgLyoqINC90LDRh9Cw0LvRjNC90L7QtSDRgdC+0YHRgtC+0Y/QvdC40LU6IDE3INGB0LvQvtCyIGtlY2NhayDQsiDQuNC90YLQtdGA0LvQuNCy0LUsINC/0L4g0LTQstCwINGH0LjRgdC70LAg0L3QsCDRgdC70L7QstC+ICovCiAgazogYXJyYXk8dTMyLCAzND4sCiAgLyoqINGBINC60LDQutC+0LPQviDRgdGH0ZHRgtGH0LjQutCwINC90LDRh9C40L3QsNC10YIg0L3QuNGC0Ywg0YEg0L3QvtC80LXRgNC+0Lwg0L3QvtC70YwgKi8KICBiYXNlOiB1MzIsCiAgLyoqINGB0LrQvtC70YzQutC+INGF0Y3RiNC10Lkg0YHRh9C40YLQsNC10YIg0L7QtNC90LAg0L3QuNGC0YwgKi8KICBwZXJUaHJlYWQ6IHUzMiwKICAvKiog0YEg0LrQsNC60L7QuSDQs9C70YPQsdC40L3RiyDQv9C+0L/Ri9GC0LrQsCDQv9C+0L/QsNC00LDQtdGCINCyINGB0L/QuNGB0L7QuiDQutCw0L3QtNC40LTQsNGC0L7QsiAqLwogIHRocmVzaDogdTMyLAogIC8qKiDRgdC60L7Qu9GM0LrQviDQutCw0L3QtNC40LTQsNGC0L7QsiDQv9C+0LzQtdGJ0LDQtdGC0YHRjyDQsiDQsdGD0YTQtdGAICovCiAgbWF4Q2FuZHM6IHUzMiwKfTsKCnN0cnVjdCBDb3VudGVycyB7CiAgY291bnQ6IGF0b21pYzx1MzI+LAogIGhpc3Q6IGFycmF5PGF0b21pYzx1MzI+LCAzMz4sCn07CgpAZ3JvdXAoMCkgQGJpbmRpbmcoMCkgdmFyPHN0b3JhZ2UsIHJlYWQ+IGpvYjogSm9iOwpAZ3JvdXAoMCkgQGJpbmRpbmcoMSkgdmFyPHN0b3JhZ2UsIHJlYWRfd3JpdGU+IG91dDogQ291bnRlcnM7CkBncm91cCgwKSBAYmluZGluZygyKSB2YXI8c3RvcmFnZSwgcmVhZF93cml0ZT4gY2FuZHM6IGFycmF5PHZlYzI8dTMyPj47CgovKioKICog0JPQuNGB0YLQvtCz0YDQsNC80LzQsCDRgNCw0LHQvtGH0LXQuSDQs9GA0YPQv9C/0YsuCiAqCiAqIOKaoO+4jyDQk9Cb0J7QkdCQ0JvQrNCd0KvQpSDQkNCi0J7QnNCQ0KDQndCr0KUg0J7Qn9CV0KDQkNCm0JjQmSDQl9CU0JXQodCsINCR0KvQm9CeINCS0J7QodCV0JzQrCDQndCQINCa0JDQltCU0KPQriDQndCY0KLQrCDigJQg0L/RgNC4CiAqINGH0LXRgtCy0LXRgNGC0Lgg0LzQuNC70LvQuNCw0YDQtNCwINC/0L7Qv9GL0YLQvtC6INCyINGB0LXQutGD0L3QtNGDINGN0YLQviDRiNC10YHRgtGM0LTQtdGB0Y/RgiDQvNC40LvQu9C40L7QvdC+0LIg0L7QsdGA0LDRidC10L3QuNC5INC6CiAqINC/0LDQvNGP0YLQuCDQutCw0YDRgtGLINCyINGB0LXQutGD0L3QtNGDLCDQuCDQstGB0LUg0LIg0L7QtNC90Lgg0Lgg0YLQtSDQttC1INGC0YDQuNC00YbQsNGC0Ywg0YLRgNC4INGP0YfQtdC50LrQuC4g0KfQtdGA0LXQtwogKiDQvtCx0YnRg9GOINC/0LDQvNGP0YLRjCDQs9GA0YPQv9C/0Ysg0L3QsNGA0YPQttGDINGD0YXQvtC00LjRgiDQv9C+INC+0LTQvdC+0LzRgyDQvtCx0YDQsNGJ0LXQvdC40Y4g0L3QsCDRgdGC0YPQv9C10L3RjCDQvdCwINCy0YHRjgogKiDQs9GA0YPQv9C/0YM6INC30LDQvNC10YAgMjU3INCc0KUv0YEg0L/RgNC+0YLQuNCyIDI1NC4KICovCnZhcjx3b3JrZ3JvdXA+IHNoYXJlZF9oaXN0OiBhcnJheTxhdG9taWM8dTMyPiwgMzM+OwoKLyoqCiAqINCh0LrQvtC70YzQutC+INC90LjRgtC10Lkg0LIg0LPRgNGD0L/Qv9C1LiDQl9C90LDRh9C10L3QuNC1INC/0L7QtNGB0YLQsNCy0LvRj9C10YLRgdGPINC/0YDQuCDRgdCx0L7RgNC60LUg0YjQtdC50LTQtdGA0LAsINCwINC90LUKICog0LfQsNGI0LjRgtC+OiDQvdCwINGH0LDRgdGC0Lgg0LzQvtCx0LjQu9GM0L3Ri9GFINCy0LjQtNC10L7QutCw0YDRgiDQv9GA0LXQtNC10LsgXGBtYXhDb21wdXRlSW52b2NhdGlvbnNQZXJXb3JrZ3JvdXBcYAogKiDRgNCw0LLQtdC9IDEyOCDQuNC70LggNjQsINC4INC+0LHRitGP0LLQu9C10L3QvdGL0LUg0LbRkdGB0YLQutC+IDI1NiDQv9GA0L7RgdGC0L4g0L3QtSDQtNCw0LvQuCDQsdGLINGB0L7QsdGA0LDRgtGMCiAqINC60L7QvdCy0LXQudC10YAg4oCUINC80LDQudC90LXRgCDQvNC+0LvRh9CwINGD0YXQvtC00LjQuyDQsdGLINC90LAg0Y/QtNGA0LAg0YLQsNC8LCDQs9C00LUg0LrQsNGA0YLQsCDQstC/0L7Qu9C90LUg0LPQvtC00L3QsC4KICovCm92ZXJyaWRlIFdHOiB1MzIgPSAyNTZ1OwoKQGNvbXB1dGUgQHdvcmtncm91cF9zaXplKFdHKQpmbiBtYWluKEBidWlsdGluKGdsb2JhbF9pbnZvY2F0aW9uX2lkKSBnaWQ6IHZlYzM8dTMyPiwKICAgICAgICBAYnVpbHRpbihsb2NhbF9pbnZvY2F0aW9uX2luZGV4KSBsaWQ6IHUzMikgewogIC8vINCh0YLRg9C/0LXQvdC10Lkg0YLRgNC40LTRhtCw0YLRjCDRgtGA0LgsINCwINC90LjRgtC10Lkg0LIg0LPRgNGD0L/Qv9C1INCx0YvQstCw0LXRgiDQuCDQvNC10L3RjNGI0LUg4oCUINC+0LHQvdGD0LvRj9C10Lwg0YEKICAvLyDRiNCw0LPQvtC8INCyINGA0LDQt9C80LXRgCDQs9GA0YPQv9C/0YssINC40L3QsNGH0LUg0L3QsCDRg9C30LrQuNGFINCz0YDRg9C/0L/QsNGFINC/0L7RgdC70LXQtNC90LjQtSDRgdGC0YPQv9C10L3QuCDQvtGB0YLQsNC70LjRgdGMCiAgLy8g0LHRiyDRgSDQvNGD0YHQvtGA0L7QvCDQvtGCINC/0YDQvtGI0LvQvtCz0L4g0LfQsNC/0YPRgdC60LAuCiAgZm9yICh2YXIgaSA9IGxpZDsgaSA8IDMzdTsgaSA9IGkgKyBXRykgeyBhdG9taWNTdG9yZSgmc2hhcmVkX2hpc3RbaV0sIDB1KTsgfQogIHdvcmtncm91cEJhcnJpZXIoKTsKICAvLyDQktGF0L7QtCDRh9C40YLQsNC10YLRgdGPINC40Lcg0L/QsNC80Y/RgtC4INC+0LTQuNC9INGA0LDQtyDQvdCwINC90LjRgtGMLCDQsCDQvdC1INC90LAg0LrQsNC20LTRi9C5INGF0Y3RiDogMzQg0YfRgtC10L3QuNGPCiAgLy8g0LLQvdGD0YLRgNC4INGG0LjQutC70LAg0YHRgtC+0LjQu9C4INC00LXRgdGP0YLRg9GOINGH0LDRgdGC0Ywg0YHQutC+0YDQvtGB0YLQuC4KICBsZXQgazBlID0gam9iLmtbMF07IGxldCBrMG8gPSBqb2Iua1sxXTsKICBsZXQgazFlID0gam9iLmtbMl07IGxldCBrMW8gPSBqb2Iua1szXTsKICBsZXQgazJlID0gam9iLmtbNF07IGxldCBrMm8gPSBqb2Iua1s1XTsKICBsZXQgazNlID0gam9iLmtbNl07IGxldCBrM28gPSBqb2Iua1s3XTsKICBsZXQgazRlID0gam9iLmtbOF07IGxldCBrNG8gPSBqb2Iua1s5XTsKICBsZXQgazVlID0gam9iLmtbMTBdOyBsZXQgazVvID0gam9iLmtbMTFdOwogIGxldCBrNmUgPSBqb2Iua1sxMl07IGxldCBrNm8gPSBqb2Iua1sxM107CiAgbGV0IGs3ZSA9IGpvYi5rWzE0XTsgbGV0IGs3byA9IGpvYi5rWzE1XTsKICBsZXQgazhlID0gam9iLmtbMTZdOyBsZXQgazhvID0gam9iLmtbMTddOwogIGxldCBrOWUgPSBqb2Iua1sxOF07IGxldCBrOW8gPSBqb2Iua1sxOV07CiAgbGV0IGsxMGUgPSBqb2Iua1syMF07IGxldCBrMTBvID0gam9iLmtbMjFdOwogIGxldCBrMTFlID0gam9iLmtbMjJdOyBsZXQgazExbyA9IGpvYi5rWzIzXTsKICBsZXQgazEyZSA9IGpvYi5rWzI0XTsgbGV0IGsxMm8gPSBqb2Iua1syNV07CiAgbGV0IGsxM2UgPSBqb2Iua1syNl07IGxldCBrMTNvID0gam9iLmtbMjddOwogIGxldCBrMTRlID0gam9iLmtbMjhdOyBsZXQgazE0byA9IGpvYi5rWzI5XTsKICBsZXQgazE1ZSA9IGpvYi5rWzMwXTsgbGV0IGsxNW8gPSBqb2Iua1szMV07CiAgbGV0IGsxNmUgPSBqb2Iua1szMl07IGxldCBrMTZvID0gam9iLmtbMzNdOwoKICBsZXQgcGVyVGhyZWFkID0gam9iLnBlclRocmVhZDsKICBsZXQgdGhyZXNoID0gam9iLnRocmVzaDsKICBsZXQgbWF4Q2FuZHMgPSBqb2IubWF4Q2FuZHM7CiAgbGV0IHN0YXJ0ID0gam9iLmJhc2UgKyBnaWQueCAqIHBlclRocmVhZDsKCiAgdmFyIGMwID0gMHU7IHZhciBjMSA9IDB1OyB2YXIgYzIgPSAwdTsgdmFyIGMzID0gMHU7CiAgdmFyIGM0ID0gMHU7IHZhciBjNSA9IDB1OyB2YXIgYzYgPSAwdTsgdmFyIGM3ID0gMHU7CgogIGZvciAodmFyIGl0ID0gMHU7IGl0IDwgcGVyVGhyZWFkOyBpdCA9IGl0ICsgMXUpIHsKICAgIGxldCBuID0gc3RhcnQgKyBpdDsKICAgIHZhciBhMGUgPSBrMGU7IHZhciBhMG8gPSBrMG87CiAgICB2YXIgYTFlID0gazFlOyB2YXIgYTFvID0gazFvOwogICAgdmFyIGEyZSA9IGsyZTsgdmFyIGEybyA9IGsybzsKICAgIHZhciBhM2UgPSBrM2U7IHZhciBhM28gPSBrM287CiAgICB2YXIgYTRlID0gazRlOyB2YXIgYTRvID0gazRvOwogICAgdmFyIGE1ZSA9IGs1ZTsgdmFyIGE1byA9IGs1bzsKICAgIHZhciBhNmUgPSBrNmU7IHZhciBhNm8gPSBrNm87CiAgICB2YXIgYTdlID0gazdlOyB2YXIgYTdvID0gazdvOwogICAgdmFyIGE4ZSA9IGs4ZTsgdmFyIGE4byA9IGs4bzsKICAgIHZhciBhOWUgPSBrOWU7IHZhciBhOW8gPSBrOW87CiAgICB2YXIgYTEwZSA9IGsxMGU7IHZhciBhMTBvID0gazEwbzsKICAgIHZhciBhMTFlID0gazExZTsgdmFyIGExMW8gPSBrMTFvOwogICAgdmFyIGExMmUgPSBrMTJlOyB2YXIgYTEybyA9IGsxMm87CiAgICB2YXIgYTEzZSA9IGsxM2U7IHZhciBhMTNvID0gazEzbzsKICAgIHZhciBhMTRlID0gazE0ZTsgdmFyIGExNG8gPSBrMTRvOwogICAgdmFyIGExNWUgPSBrMTVlOyB2YXIgYTE1byA9IGsxNW87CiAgICB2YXIgYTE2ZSA9IGsxNmU7IHZhciBhMTZvID0gazE2bzsKICAgIHZhciBhMTdlID0gMHU7IHZhciBhMTdvID0gMHU7CiAgICB2YXIgYTE4ZSA9IDB1OyB2YXIgYTE4byA9IDB1OwogICAgdmFyIGExOWUgPSAwdTsgdmFyIGExOW8gPSAwdTsKICAgIHZhciBhMjBlID0gMHU7IHZhciBhMjBvID0gMHU7CiAgICB2YXIgYTIxZSA9IDB1OyB2YXIgYTIxbyA9IDB1OwogICAgdmFyIGEyMmUgPSAwdTsgdmFyIGEyMm8gPSAwdTsKICAgIHZhciBhMjNlID0gMHU7IHZhciBhMjNvID0gMHU7CiAgICB2YXIgYTI0ZSA9IDB1OyB2YXIgYTI0byA9IDB1OwoKICAgIC8vINCh0YfRkdGC0YfQuNC6INGB0LDQtNC40YLRgdGPINCyINC80LvQsNC00YjQuNC1IDE2INCx0LjRgiDRiNC10YHRgtC+0LPQviDRgdC70L7QstCwIOKAlCDRjdGC0L4g0LHQsNC50YLRiyA0OC4uNTEKICAgIC8vINCy0YXQvtC00LAsINGC0L4g0LXRgdGC0Ywg0LzQu9Cw0LTRiNC40LUg0YfQtdGC0YvRgNC1INCx0LDQudGC0LAgbm9uY2UuINCd0LjRh9C10LPQviDQuNC90YLQtdGA0LvQuNCy0LjRgtGMINC90LAg0YXQvtC00YMKICAgIC8vINC90LUg0L3QsNC00L46INC/0L7Qu9C+0LLQuNC90LrQuCDRgdGH0ZHRgtGH0LjQutCwINCj0JbQlSDRgNCw0LfQu9C+0LbQtdC90Ysg0L/QviDRh9GR0YLQvdGL0Lwg0Lgg0L3QtdGH0ZHRgtC90YvQvCDQsdC40YLQsNC8LAogICAgLy8g0LAg0L7QsdGA0LDRgtC90L4gbm9uY2Ug0YHQvtCx0LjRgNCw0LXRgiDQv9GA0L7RhtC10YHRgdC+0YAsINC60L7Qs9C00LAg0L3QsNGF0L7QtNC60LAg0YLQvtCz0L4g0YHRgtC+0LjRgi4KICAgIGE2ZSA9IChhNmUgJiAweGZmZmYwMDAwdSkgfCAobiAmIDB4ZmZmZnUpOwogICAgYTZvID0gKGE2byAmIDB4ZmZmZjAwMDB1KSB8ICgobiA+PiAxNnUpICYgMHhmZmZmdSk7CgogICAgZm9yICh2YXIgcm5kID0gMHU7IHJuZCA8IDI0dTsgcm5kID0gcm5kICsgMXUpIHsKLy8g0KHQntCR0KDQkNCd0J4gcGFja2VyL2dlbl9rZWNjYWsucHkg4oCUINC90LDRh9Cw0LvQvgogICAgICBsZXQgYzBlID0gYTBlIF4gYTVlIF4gYTEwZSBeIGExNWUgXiBhMjBlOwogICAgICBsZXQgYzBvID0gYTBvIF4gYTVvIF4gYTEwbyBeIGExNW8gXiBhMjBvOwogICAgICBsZXQgYzFlID0gYTFlIF4gYTZlIF4gYTExZSBeIGExNmUgXiBhMjFlOwogICAgICBsZXQgYzFvID0gYTFvIF4gYTZvIF4gYTExbyBeIGExNm8gXiBhMjFvOwogICAgICBsZXQgYzJlID0gYTJlIF4gYTdlIF4gYTEyZSBeIGExN2UgXiBhMjJlOwogICAgICBsZXQgYzJvID0gYTJvIF4gYTdvIF4gYTEybyBeIGExN28gXiBhMjJvOwogICAgICBsZXQgYzNlID0gYTNlIF4gYThlIF4gYTEzZSBeIGExOGUgXiBhMjNlOwogICAgICBsZXQgYzNvID0gYTNvIF4gYThvIF4gYTEzbyBeIGExOG8gXiBhMjNvOwogICAgICBsZXQgYzRlID0gYTRlIF4gYTllIF4gYTE0ZSBeIGExOWUgXiBhMjRlOwogICAgICBsZXQgYzRvID0gYTRvIF4gYTlvIF4gYTE0byBeIGExOW8gXiBhMjRvOwogICAgICBsZXQgZDBlID0gYzRlIF4gKChjMW8gPDwgMXUpIHwgKGMxbyA+PiAzMXUpKTsKICAgICAgbGV0IGQwbyA9IGM0byBeIGMxZTsKICAgICAgbGV0IGQxZSA9IGMwZSBeICgoYzJvIDw8IDF1KSB8IChjMm8gPj4gMzF1KSk7CiAgICAgIGxldCBkMW8gPSBjMG8gXiBjMmU7CiAgICAgIGxldCBkMmUgPSBjMWUgXiAoKGMzbyA8PCAxdSkgfCAoYzNvID4+IDMxdSkpOwogICAgICBsZXQgZDJvID0gYzFvIF4gYzNlOwogICAgICBsZXQgZDNlID0gYzJlIF4gKChjNG8gPDwgMXUpIHwgKGM0byA+PiAzMXUpKTsKICAgICAgbGV0IGQzbyA9IGMybyBeIGM0ZTsKICAgICAgbGV0IGQ0ZSA9IGMzZSBeICgoYzBvIDw8IDF1KSB8IChjMG8gPj4gMzF1KSk7CiAgICAgIGxldCBkNG8gPSBjM28gXiBjMGU7CiAgICAgIGxldCBiMGUgPSBhMGUgXiBkMGU7CiAgICAgIGxldCBiMG8gPSBhMG8gXiBkMG87CiAgICAgIGxldCB0NmUgPSBhNmUgXiBkMWU7CiAgICAgIGxldCB0Nm8gPSBhNm8gXiBkMW87CiAgICAgIGxldCBiMWUgPSAoKHQ2ZSA8PCAyMnUpIHwgKHQ2ZSA+PiAxMHUpKTsKICAgICAgbGV0IGIxbyA9ICgodDZvIDw8IDIydSkgfCAodDZvID4+IDEwdSkpOwogICAgICBsZXQgdDEyZSA9IGExMmUgXiBkMmU7CiAgICAgIGxldCB0MTJvID0gYTEybyBeIGQybzsKICAgICAgbGV0IGIyZSA9ICgodDEybyA8PCAyMnUpIHwgKHQxMm8gPj4gMTB1KSk7CiAgICAgIGxldCBiMm8gPSAoKHQxMmUgPDwgMjF1KSB8ICh0MTJlID4+IDExdSkpOwogICAgICBsZXQgdDE4ZSA9IGExOGUgXiBkM2U7CiAgICAgIGxldCB0MThvID0gYTE4byBeIGQzbzsKICAgICAgbGV0IGIzZSA9ICgodDE4byA8PCAxMXUpIHwgKHQxOG8gPj4gMjF1KSk7CiAgICAgIGxldCBiM28gPSAoKHQxOGUgPDwgMTB1KSB8ICh0MThlID4+IDIydSkpOwogICAgICBsZXQgdDI0ZSA9IGEyNGUgXiBkNGU7CiAgICAgIGxldCB0MjRvID0gYTI0byBeIGQ0bzsKICAgICAgbGV0IGI0ZSA9ICgodDI0ZSA8PCA3dSkgfCAodDI0ZSA+PiAyNXUpKTsKICAgICAgbGV0IGI0byA9ICgodDI0byA8PCA3dSkgfCAodDI0byA+PiAyNXUpKTsKICAgICAgbGV0IHQzZSA9IGEzZSBeIGQzZTsKICAgICAgbGV0IHQzbyA9IGEzbyBeIGQzbzsKICAgICAgbGV0IGI1ZSA9ICgodDNlIDw8IDE0dSkgfCAodDNlID4+IDE4dSkpOwogICAgICBsZXQgYjVvID0gKCh0M28gPDwgMTR1KSB8ICh0M28gPj4gMTh1KSk7CiAgICAgIGxldCB0OWUgPSBhOWUgXiBkNGU7CiAgICAgIGxldCB0OW8gPSBhOW8gXiBkNG87CiAgICAgIGxldCBiNmUgPSAoKHQ5ZSA8PCAxMHUpIHwgKHQ5ZSA+PiAyMnUpKTsKICAgICAgbGV0IGI2byA9ICgodDlvIDw8IDEwdSkgfCAodDlvID4+IDIydSkpOwogICAgICBsZXQgdDEwZSA9IGExMGUgXiBkMGU7CiAgICAgIGxldCB0MTBvID0gYTEwbyBeIGQwbzsKICAgICAgbGV0IGI3ZSA9ICgodDEwbyA8PCAydSkgfCAodDEwbyA+PiAzMHUpKTsKICAgICAgbGV0IGI3byA9ICgodDEwZSA8PCAxdSkgfCAodDEwZSA+PiAzMXUpKTsKICAgICAgbGV0IHQxNmUgPSBhMTZlIF4gZDFlOwogICAgICBsZXQgdDE2byA9IGExNm8gXiBkMW87CiAgICAgIGxldCBiOGUgPSAoKHQxNm8gPDwgMjN1KSB8ICh0MTZvID4+IDl1KSk7CiAgICAgIGxldCBiOG8gPSAoKHQxNmUgPDwgMjJ1KSB8ICh0MTZlID4+IDEwdSkpOwogICAgICBsZXQgdDIyZSA9IGEyMmUgXiBkMmU7CiAgICAgIGxldCB0MjJvID0gYTIybyBeIGQybzsKICAgICAgbGV0IGI5ZSA9ICgodDIybyA8PCAzMXUpIHwgKHQyMm8gPj4gMXUpKTsKICAgICAgbGV0IGI5byA9ICgodDIyZSA8PCAzMHUpIHwgKHQyMmUgPj4gMnUpKTsKICAgICAgbGV0IHQxZSA9IGExZSBeIGQxZTsKICAgICAgbGV0IHQxbyA9IGExbyBeIGQxbzsKICAgICAgbGV0IGIxMGUgPSAoKHQxbyA8PCAxdSkgfCAodDFvID4+IDMxdSkpOwogICAgICBsZXQgYjEwbyA9IHQxZTsKICAgICAgbGV0IHQ3ZSA9IGE3ZSBeIGQyZTsKICAgICAgbGV0IHQ3byA9IGE3byBeIGQybzsKICAgICAgbGV0IGIxMWUgPSAoKHQ3ZSA8PCAzdSkgfCAodDdlID4+IDI5dSkpOwogICAgICBsZXQgYjExbyA9ICgodDdvIDw8IDN1KSB8ICh0N28gPj4gMjl1KSk7CiAgICAgIGxldCB0MTNlID0gYTEzZSBeIGQzZTsKICAgICAgbGV0IHQxM28gPSBhMTNvIF4gZDNvOwogICAgICBsZXQgYjEyZSA9ICgodDEzbyA8PCAxM3UpIHwgKHQxM28gPj4gMTl1KSk7CiAgICAgIGxldCBiMTJvID0gKCh0MTNlIDw8IDEydSkgfCAodDEzZSA+PiAyMHUpKTsKICAgICAgbGV0IHQxOWUgPSBhMTllIF4gZDRlOwogICAgICBsZXQgdDE5byA9IGExOW8gXiBkNG87CiAgICAgIGxldCBiMTNlID0gKCh0MTllIDw8IDR1KSB8ICh0MTllID4+IDI4dSkpOwogICAgICBsZXQgYjEzbyA9ICgodDE5byA8PCA0dSkgfCAodDE5byA+PiAyOHUpKTsKICAgICAgbGV0IHQyMGUgPSBhMjBlIF4gZDBlOwogICAgICBsZXQgdDIwbyA9IGEyMG8gXiBkMG87CiAgICAgIGxldCBiMTRlID0gKCh0MjBlIDw8IDl1KSB8ICh0MjBlID4+IDIzdSkpOwogICAgICBsZXQgYjE0byA9ICgodDIwbyA8PCA5dSkgfCAodDIwbyA+PiAyM3UpKTsKICAgICAgbGV0IHQ0ZSA9IGE0ZSBeIGQ0ZTsKICAgICAgbGV0IHQ0byA9IGE0byBeIGQ0bzsKICAgICAgbGV0IGIxNWUgPSAoKHQ0byA8PCAxNHUpIHwgKHQ0byA+PiAxOHUpKTsKICAgICAgbGV0IGIxNW8gPSAoKHQ0ZSA8PCAxM3UpIHwgKHQ0ZSA+PiAxOXUpKTsKICAgICAgbGV0IHQ1ZSA9IGE1ZSBeIGQwZTsKICAgICAgbGV0IHQ1byA9IGE1byBeIGQwbzsKICAgICAgbGV0IGIxNmUgPSAoKHQ1ZSA8PCAxOHUpIHwgKHQ1ZSA+PiAxNHUpKTsKICAgICAgbGV0IGIxNm8gPSAoKHQ1byA8PCAxOHUpIHwgKHQ1byA+PiAxNHUpKTsKICAgICAgbGV0IHQxMWUgPSBhMTFlIF4gZDFlOwogICAgICBsZXQgdDExbyA9IGExMW8gXiBkMW87CiAgICAgIGxldCBiMTdlID0gKCh0MTFlIDw8IDV1KSB8ICh0MTFlID4+IDI3dSkpOwogICAgICBsZXQgYjE3byA9ICgodDExbyA8PCA1dSkgfCAodDExbyA+PiAyN3UpKTsKICAgICAgbGV0IHQxN2UgPSBhMTdlIF4gZDJlOwogICAgICBsZXQgdDE3byA9IGExN28gXiBkMm87CiAgICAgIGxldCBiMThlID0gKCh0MTdvIDw8IDh1KSB8ICh0MTdvID4+IDI0dSkpOwogICAgICBsZXQgYjE4byA9ICgodDE3ZSA8PCA3dSkgfCAodDE3ZSA+PiAyNXUpKTsKICAgICAgbGV0IHQyM2UgPSBhMjNlIF4gZDNlOwogICAgICBsZXQgdDIzbyA9IGEyM28gXiBkM287CiAgICAgIGxldCBiMTllID0gKCh0MjNlIDw8IDI4dSkgfCAodDIzZSA+PiA0dSkpOwogICAgICBsZXQgYjE5byA9ICgodDIzbyA8PCAyOHUpIHwgKHQyM28gPj4gNHUpKTsKICAgICAgbGV0IHQyZSA9IGEyZSBeIGQyZTsKICAgICAgbGV0IHQybyA9IGEybyBeIGQybzsKICAgICAgbGV0IGIyMGUgPSAoKHQyZSA8PCAzMXUpIHwgKHQyZSA+PiAxdSkpOwogICAgICBsZXQgYjIwbyA9ICgodDJvIDw8IDMxdSkgfCAodDJvID4+IDF1KSk7CiAgICAgIGxldCB0OGUgPSBhOGUgXiBkM2U7CiAgICAgIGxldCB0OG8gPSBhOG8gXiBkM287CiAgICAgIGxldCBiMjFlID0gKCh0OG8gPDwgMjh1KSB8ICh0OG8gPj4gNHUpKTsKICAgICAgbGV0IGIyMW8gPSAoKHQ4ZSA8PCAyN3UpIHwgKHQ4ZSA+PiA1dSkpOwogICAgICBsZXQgdDE0ZSA9IGExNGUgXiBkNGU7CiAgICAgIGxldCB0MTRvID0gYTE0byBeIGQ0bzsKICAgICAgbGV0IGIyMmUgPSAoKHQxNG8gPDwgMjB1KSB8ICh0MTRvID4+IDEydSkpOwogICAgICBsZXQgYjIybyA9ICgodDE0ZSA8PCAxOXUpIHwgKHQxNGUgPj4gMTN1KSk7CiAgICAgIGxldCB0MTVlID0gYTE1ZSBeIGQwZTsKICAgICAgbGV0IHQxNW8gPSBhMTVvIF4gZDBvOwogICAgICBsZXQgYjIzZSA9ICgodDE1byA8PCAyMXUpIHwgKHQxNW8gPj4gMTF1KSk7CiAgICAgIGxldCBiMjNvID0gKCh0MTVlIDw8IDIwdSkgfCAodDE1ZSA+PiAxMnUpKTsKICAgICAgbGV0IHQyMWUgPSBhMjFlIF4gZDFlOwogICAgICBsZXQgdDIxbyA9IGEyMW8gXiBkMW87CiAgICAgIGxldCBiMjRlID0gKCh0MjFlIDw8IDF1KSB8ICh0MjFlID4+IDMxdSkpOwogICAgICBsZXQgYjI0byA9ICgodDIxbyA8PCAxdSkgfCAodDIxbyA+PiAzMXUpKTsKICAgICAgYTBlID0gYjBlIF4gKH5iMWUgJiBiMmUpIF4gUkNFW3JuZF07CiAgICAgIGEwbyA9IGIwbyBeICh+YjFvICYgYjJvKSBeIFJDT1tybmRdOwogICAgICBhMWUgPSBiMWUgXiAofmIyZSAmIGIzZSk7CiAgICAgIGExbyA9IGIxbyBeICh+YjJvICYgYjNvKTsKICAgICAgYTJlID0gYjJlIF4gKH5iM2UgJiBiNGUpOwogICAgICBhMm8gPSBiMm8gXiAofmIzbyAmIGI0byk7CiAgICAgIGEzZSA9IGIzZSBeICh+YjRlICYgYjBlKTsKICAgICAgYTNvID0gYjNvIF4gKH5iNG8gJiBiMG8pOwogICAgICBhNGUgPSBiNGUgXiAofmIwZSAmIGIxZSk7CiAgICAgIGE0byA9IGI0byBeICh+YjBvICYgYjFvKTsKICAgICAgYTVlID0gYjVlIF4gKH5iNmUgJiBiN2UpOwogICAgICBhNW8gPSBiNW8gXiAofmI2byAmIGI3byk7CiAgICAgIGE2ZSA9IGI2ZSBeICh+YjdlICYgYjhlKTsKICAgICAgYTZvID0gYjZvIF4gKH5iN28gJiBiOG8pOwogICAgICBhN2UgPSBiN2UgXiAofmI4ZSAmIGI5ZSk7CiAgICAgIGE3byA9IGI3byBeICh+YjhvICYgYjlvKTsKICAgICAgYThlID0gYjhlIF4gKH5iOWUgJiBiNWUpOwogICAgICBhOG8gPSBiOG8gXiAofmI5byAmIGI1byk7CiAgICAgIGE5ZSA9IGI5ZSBeICh+YjVlICYgYjZlKTsKICAgICAgYTlvID0gYjlvIF4gKH5iNW8gJiBiNm8pOwogICAgICBhMTBlID0gYjEwZSBeICh+YjExZSAmIGIxMmUpOwogICAgICBhMTBvID0gYjEwbyBeICh+YjExbyAmIGIxMm8pOwogICAgICBhMTFlID0gYjExZSBeICh+YjEyZSAmIGIxM2UpOwogICAgICBhMTFvID0gYjExbyBeICh+YjEybyAmIGIxM28pOwogICAgICBhMTJlID0gYjEyZSBeICh+YjEzZSAmIGIxNGUpOwogICAgICBhMTJvID0gYjEybyBeICh+YjEzbyAmIGIxNG8pOwogICAgICBhMTNlID0gYjEzZSBeICh+YjE0ZSAmIGIxMGUpOwogICAgICBhMTNvID0gYjEzbyBeICh+YjE0byAmIGIxMG8pOwogICAgICBhMTRlID0gYjE0ZSBeICh+YjEwZSAmIGIxMWUpOwogICAgICBhMTRvID0gYjE0byBeICh+YjEwbyAmIGIxMW8pOwogICAgICBhMTVlID0gYjE1ZSBeICh+YjE2ZSAmIGIxN2UpOwogICAgICBhMTVvID0gYjE1byBeICh+YjE2byAmIGIxN28pOwogICAgICBhMTZlID0gYjE2ZSBeICh+YjE3ZSAmIGIxOGUpOwogICAgICBhMTZvID0gYjE2byBeICh+YjE3byAmIGIxOG8pOwogICAgICBhMTdlID0gYjE3ZSBeICh+YjE4ZSAmIGIxOWUpOwogICAgICBhMTdvID0gYjE3byBeICh+YjE4byAmIGIxOW8pOwogICAgICBhMThlID0gYjE4ZSBeICh+YjE5ZSAmIGIxNWUpOwogICAgICBhMThvID0gYjE4byBeICh+YjE5byAmIGIxNW8pOwogICAgICBhMTllID0gYjE5ZSBeICh+YjE1ZSAmIGIxNmUpOwogICAgICBhMTlvID0gYjE5byBeICh+YjE1byAmIGIxNm8pOwogICAgICBhMjBlID0gYjIwZSBeICh+YjIxZSAmIGIyMmUpOwogICAgICBhMjBvID0gYjIwbyBeICh+YjIxbyAmIGIyMm8pOwogICAgICBhMjFlID0gYjIxZSBeICh+YjIyZSAmIGIyM2UpOwogICAgICBhMjFvID0gYjIxbyBeICh+YjIybyAmIGIyM28pOwogICAgICBhMjJlID0gYjIyZSBeICh+YjIzZSAmIGIyNGUpOwogICAgICBhMjJvID0gYjIybyBeICh+YjIzbyAmIGIyNG8pOwogICAgICBhMjNlID0gYjIzZSBeICh+YjI0ZSAmIGIyMGUpOwogICAgICBhMjNvID0gYjIzbyBeICh+YjI0byAmIGIyMG8pOwogICAgICBhMjRlID0gYjI0ZSBeICh+YjIwZSAmIGIyMWUpOwogICAgICBhMjRvID0gYjI0byBeICh+YjIwbyAmIGIyMW8pOwovLyDQodCe0JHQoNCQ0J3QniBwYWNrZXIvZ2VuX2tlY2Nhay5weSDigJQg0LrQvtC90LXRhgogICAgfQoKICAgIC8vINCd0YPQu9C10LLQvtC5INCx0LDQudGCINGF0Y3RiNCwIOKAlCDRjdGC0L4g0LzQu9Cw0LTRiNC40LUg0LLQvtGB0LXQvNGMINCx0LjRgiDQvdGD0LvQtdCy0L7Qs9C+INGB0LvQvtCy0LAsINGC0L4g0LXRgdGC0YwKICAgIC8vINGH0LXRgtGL0YDQtSDQvNC70LDQtNGI0LjRhSDQsdC40YLQsCBcYGVcYCDQuCBcYG9cYCDQstC/0LXRgNC10LzQtdGI0LrRgy4KICAgIGxldCBzZSA9IChhMGUgJiAxdSkgfCAoKGEwZSAmIDJ1KSA8PCAxdSkgfCAoKGEwZSAmIDR1KSA8PCAydSkgfCAoKGEwZSAmIDh1KSA8PCAzdSk7CiAgICBsZXQgc28gPSAoYTBvICYgMXUpIHwgKChhMG8gJiAydSkgPDwgMXUpIHwgKChhMG8gJiA0dSkgPDwgMnUpIHwgKChhMG8gJiA4dSkgPDwgM3UpOwogICAgbGV0IGJ5dGUwID0gc2UgfCAoc28gPDwgMXUpOwogICAgdmFyIGRlcHRoOiB1MzI7CiAgICBpZiAoYnl0ZTAgIT0gMHUpIHsKICAgICAgZGVwdGggPSBjb3VudExlYWRpbmdaZXJvcyhieXRlMCkgLSAyNHU7CiAgICB9IGVsc2UgewogICAgICBkZXB0aCA9IGRlZXBaZXJvcyhhMGUsIGEwbyk7CiAgICB9CgogICAgc3dpdGNoIGRlcHRoIHsKICAgICAgY2FzZSAwdTogeyBjMCA9IGMwICsgMXU7IH0KICAgICAgY2FzZSAxdTogeyBjMSA9IGMxICsgMXU7IH0KICAgICAgY2FzZSAydTogeyBjMiA9IGMyICsgMXU7IH0KICAgICAgY2FzZSAzdTogeyBjMyA9IGMzICsgMXU7IH0KICAgICAgY2FzZSA0dTogeyBjNCA9IGM0ICsgMXU7IH0KICAgICAgY2FzZSA1dTogeyBjNSA9IGM1ICsgMXU7IH0KICAgICAgY2FzZSA2dTogeyBjNiA9IGM2ICsgMXU7IH0KICAgICAgY2FzZSA3dTogeyBjNyA9IGM3ICsgMXU7IH0KICAgICAgZGVmYXVsdDogeyBhdG9taWNBZGQoJnNoYXJlZF9oaXN0W21pbihkZXB0aCwgMzJ1KV0sIDF1KTsgfQogICAgfQoKICAgIGlmIChkZXB0aCA+PSB0aHJlc2gpIHsKICAgICAgbGV0IHNsb3QgPSBhdG9taWNBZGQoJm91dC5jb3VudCwgMXUpOwogICAgICBpZiAoc2xvdCA8IG1heENhbmRzKSB7IGNhbmRzW3Nsb3RdID0gdmVjMjx1MzI+KG4sIGRlcHRoKTsgfQogICAgfQogIH0KCiAgLy8g0J3Rg9C70LXQstGL0LUg0YHRgtGD0L/QtdC90Lgg0L3QtSDRgtGA0L7Qs9Cw0LXQvDog0YMg0L/QvtC70L7QstC40L3RiyDQvdC40YLQtdC5INCz0LvRg9Cx0LbQtSDQv9GP0YLQvtC5INC90LUg0L3QsNCx0LjRgNCw0LXRgtGB0Y8KICAvLyDQvdC4INC+0LTQvdC+0Lkg0L/QvtC/0YvRgtC60LguCiAgaWYgKGMwICE9IDB1KSB7IGF0b21pY0FkZCgmc2hhcmVkX2hpc3RbMF0sIGMwKTsgfQogIGlmIChjMSAhPSAwdSkgeyBhdG9taWNBZGQoJnNoYXJlZF9oaXN0WzFdLCBjMSk7IH0KICBpZiAoYzIgIT0gMHUpIHsgYXRvbWljQWRkKCZzaGFyZWRfaGlzdFsyXSwgYzIpOyB9CiAgaWYgKGMzICE9IDB1KSB7IGF0b21pY0FkZCgmc2hhcmVkX2hpc3RbM10sIGMzKTsgfQogIGlmIChjNCAhPSAwdSkgeyBhdG9taWNBZGQoJnNoYXJlZF9oaXN0WzRdLCBjNCk7IH0KICBpZiAoYzUgIT0gMHUpIHsgYXRvbWljQWRkKCZzaGFyZWRfaGlzdFs1XSwgYzUpOyB9CiAgaWYgKGM2ICE9IDB1KSB7IGF0b21pY0FkZCgmc2hhcmVkX2hpc3RbNl0sIGM2KTsgfQogIGlmIChjNyAhPSAwdSkgeyBhdG9taWNBZGQoJnNoYXJlZF9oaXN0WzddLCBjNyk7IH0KCiAgd29ya2dyb3VwQmFycmllcigpOwogIGZvciAodmFyIGkgPSBsaWQ7IGkgPCAzM3U7IGkgPSBpICsgV0cpIHsKICAgIGxldCBzdW0gPSBhdG9taWNMb2FkKCZzaGFyZWRfaGlzdFtpXSk7CiAgICBpZiAoc3VtICE9IDB1KSB7IGF0b21pY0FkZCgmb3V0Lmhpc3RbaV0sIHN1bSk7IH0KICB9Cn0KCi8vLyDQk9C70YPQsdC40L3QsCDQtNCw0LvRjNGI0LUg0L/QtdGA0LLQvtCz0L4g0LHQsNC50YLQsC4g0KHRjtC00LAg0L/QvtC/0LDQtNCw0LXRgiDQvtC00L3QsCDQv9C+0L/Ri9GC0LrQsCDQuNC3IDI1Niwg0L/QvtGN0YLQvtC80YMKLy8vINGB0YfQuNGC0LDRgtGMINC80L7QttC90L4g0YHQv9C+0LrQvtC50L3Qviwg0LHQsNC50YIg0LfQsCDQsdCw0LnRgtC+0LwsINC00LXQuNC90YLQtdGA0LvQuNCy0Y8g0L/QviDRh9C10YLRi9GA0LUg0LHQuNGC0LAuCi8vLwovLy8g4pqg77iPINCh0KfQmNCi0JDQldCcINCS0KHQlSDQktCe0KHQldCc0Kwg0JHQkNCZ0KIg0J3Qo9Cb0JXQktCe0Jkg0JTQntCg0J7QltCa0JgsINCQINCd0JUg0KfQldCi0KvQoNCVLiDQn9GA0L7RiNC70LDRjyDRgNC10LTQsNC60YbQuNGPCi8vLyDRg9C/0LjRgNCw0LvQsNGB0Ywg0LIgMzIg0Lgg0L7RgtC00LDQstCw0LvQsCAzMiDQvdCwINCy0YHRkSwg0YfRgtC+INCz0LvRg9Cx0LbQtSwg4oCUINCwINC/0YDQvtGG0LXRgdGB0L7RgCwg0L/QtdGA0LXRgdGH0LjRgtCw0LIKLy8vINGC0LDQutGD0Y4g0L/QvtC/0YvRgtC60YMsINC/0L7Qu9GD0YfQsNC7INGH0LXRgdGC0L3Ri9C1IDM3INC4INC+0LHRitGP0LLQu9GP0Lsg0LrQsNGA0YLRgyDQstGA0YPRidC10LkuINCW0LjQstC+0Lkg0YHQu9GD0YfQsNC5OgovLy8g0L/RgNC4INGH0LXRgtCy0LXRgNGC0Lgg0LzQuNC70LvQuNCw0YDQtNCwINC/0L7Qv9GL0YLQvtC6INCyINGB0LXQutGD0L3QtNGDINGF0Y3RiCDRgSAzMyDQvdGD0LvRj9C80Lgg0L/QvtGP0LLQu9GP0LXRgtGB0Y8g0LfQsAovLy8g0L3QtdGB0LrQvtC70YzQutC+INGB0LXQutGD0L3QtCwg0Lgg0LzQsNC50L3QtdGAINCy0YvQutC70Y7Rh9Cw0Lsg0YHQvtCy0LXRgNGI0LXQvdC90L4g0LjRgdC/0YDQsNCy0L3Rg9GOINC60LDRgNGC0YMuCmZuIGRlZXBaZXJvcyhlOiB1MzIsIG86IHUzMikgLT4gdTMyIHsKICB2YXIgYml0cyA9IDh1OwogIGZvciAodmFyIGJ5dGUgPSAxdTsgYnl0ZSA8IDh1OyBieXRlID0gYnl0ZSArIDF1KSB7CiAgICBsZXQgc2ggPSBieXRlICogNHU7CiAgICBsZXQgcGUgPSAoZSA+PiBzaCkgJiAxNXU7CiAgICBsZXQgcG8gPSAobyA+PiBzaCkgJiAxNXU7CiAgICBsZXQgc2UgPSAocGUgJiAxdSkgfCAoKHBlICYgMnUpIDw8IDF1KSB8ICgocGUgJiA0dSkgPDwgMnUpIHwgKChwZSAmIDh1KSA8PCAzdSk7CiAgICBsZXQgc28gPSAocG8gJiAxdSkgfCAoKHBvICYgMnUpIDw8IDF1KSB8ICgocG8gJiA0dSkgPDwgMnUpIHwgKChwbyAmIDh1KSA8PCAzdSk7CiAgICBsZXQgYiA9IHNlIHwgKHNvIDw8IDF1KTsKICAgIGlmIChiICE9IDB1KSB7IHJldHVybiBiaXRzICsgY291bnRMZWFkaW5nWmVyb3MoYikgLSAyNHU7IH0KICAgIGJpdHMgPSBiaXRzICsgOHU7CiAgfQogIC8vINCU0LDQu9GM0YjQtSDQvdGD0LvQtdCy0L7QuSDQtNC+0YDQvtC20LrQuCDQvdC1INC30LDQs9C70Y/QvdGD0YLRjDog0L7RgdGC0LDQu9GM0L3Ri9C1INGC0YDQuCDQvdC1INGB0YfQuNGC0LDQu9C40YHRjC4g0KjQtdGB0YLRjNC00LXRgdGP0YIKICAvLyDRh9C10YLRi9GA0LUg0L3Rg9C70Y8g0L/QvtC00YDRj9C0INC90LUg0LLRi9C/0LDQtNCw0LvQuCDQvdC4INCyINC+0LTQvdC+0Lkg0YHQtdGC0Lgg0LzQuNGA0LAsINC4INCy0YvQt9GL0LLQsNGO0YnQsNGPINGB0YLQvtGA0L7QvdCwCiAgLy8g0LfQvdCw0LXRgiwg0YfRgtC+INGN0YLQviDQvdCw0YHRi9GJ0LXQvdC40LUsINCwINC90LUg0LjQt9C80LXRgNC10L3QuNC1LgogIHJldHVybiA2NHU7Cn0K
SHADER_B64_EOF
base64 -d shader.wgsl.b64 > shader.wgsl
rm shader.wgsl.b64

# Write miner script
echo "Writing miner..."
cat > miner.mjs << 'MINER_SCRIPT_EOF'
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
MINER_SCRIPT_EOF

# Write wallet and .env
cat >> setup.sh << 'SETUP_EOF'

# Write wallet info
cat > wallet.txt << EOF
=== HASHCATS MINER WALLET ===
Address:     $WALLET_ADDRESS
Private Key: $WALLET_KEY
Mnemonic:    gesture rely resist erosion wall invite name thumb equal oblige orange annual
Chain:       Robinhood Chain (4663)
RPC:         https://robinhood.drpc.org

FUND THIS ADDRESS WITH ETH ON ROBINHOOD CHAIN BEFORE MINING
Mint price: ~0.02032 ETH per cat + gas
EOF

cat > .env << EOF
HASHCATS_KEY=$WALLET_KEY
EOF

echo "[4/4] Installing dependencies..."
npm install --silent 2>&1 | tail -2

echo ""
echo "  ✅ SETUP COMPLETE!"
echo ""
echo "  Wallet: $WALLET_ADDRESS"
echo "  Files:  $MINER_DIR"
echo ""
echo "  NEXT STEPS:"
echo "  1. Fund wallet with ETH on Robinhood Chain"
echo "  2. Test:  cd $MINER_DIR && node miner.mjs --dry-run"
echo "  3. Mine:  cd $MINER_DIR && node miner.mjs"
echo "  4. Screen: screen -S hashcats 'node miner.mjs'"
echo ""
