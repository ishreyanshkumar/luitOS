#!/bin/sh
# Unified per-lab grader: `make grade LAB=N` runs the public test(s) for lab N
# plus the baseline regression, and reports individual results.
# Usage: sh tests/run_lab.sh N
LAB="$1"
if [ -z "$LAB" ]; then echo "usage: make grade LAB=N (1..12)"; exit 2; fi

# zero-pad
LN=$(printf "%02d" "$LAB")
SCRIPT=$(ls tests/lab${LN}_*.sh 2>/dev/null | head -1)

echo "=== CS3106L grade: Lab $LAB ==="
total=0; pass=0

# 1) baseline must always still pass (no regression)
echo "--- baseline regression ---"
if python3 tests/grade.py >/tmp/base_$LAB.txt 2>&1; then
    grep -q "9/9 passed" /tmp/base_$LAB.txt && { echo "[PASS] baseline 9/9 preserved"; pass=$((pass+1)); } || echo "[FAIL] baseline regressed"
else
    echo "[FAIL] baseline regressed"; cat /tmp/base_$LAB.txt
fi
total=$((total+1))
rm -f /tmp/base_$LAB.txt

# 2) the lab's own public test
echo "--- lab $LAB public test ---"
if [ -z "$SCRIPT" ]; then
    echo "[N/A ] no public test for lab $LAB yet (spec-only lab)"
else
    total=$((total+1))
    if sh "$SCRIPT"; then pass=$((pass+1)); fi
fi

echo "=== Lab $LAB: $pass/$total checks passed ==="
[ "$pass" -eq "$total" ]
