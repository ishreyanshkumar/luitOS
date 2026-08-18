#!/bin/sh
# Unified public grader. `make grade LAB=3` always runs the complete baseline
# regression first, then the Lab 3 public test.
set -u
LAB="$1"
if [ -z "$LAB" ]; then
    echo "usage: make grade LAB=N"
    exit 2
fi
LN=$(printf "%02d" "$LAB")
SCRIPT=$(ls tests/lab${LN}_*.sh 2>/dev/null | head -1)

echo "=== CS3106L grade: Lab $LAB ==="
total=0
pass=0

echo "--- baseline regression ---"
if python3 tests/grade.py >/tmp/luit_base_$$.txt 2>&1; then
    if grep -q "9/9 passed" /tmp/luit_base_$$.txt; then
        echo "[PASS] baseline 9/9 preserved"
        pass=$((pass+1))
    else
        echo "[FAIL] baseline summary missing"
        cat /tmp/luit_base_$$.txt
    fi
else
    echo "[FAIL] baseline regressed"
    cat /tmp/luit_base_$$.txt
fi
total=$((total+1))
rm -f /tmp/luit_base_$$.txt

echo "--- lab $LAB public test ---"
if [ -z "$SCRIPT" ]; then
    echo "[FAIL] no public test for Lab $LAB"
    total=$((total+1))
else
    total=$((total+1))
    if sh "$SCRIPT"; then
        pass=$((pass+1))
    fi
fi

echo "=== Lab $LAB: $pass/$total checks passed ==="
[ "$pass" -eq "$total" ]
