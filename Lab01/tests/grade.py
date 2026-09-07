#!/usr/bin/env python3
# BrahmaputraOS / Luit -- public grading harness (Teaching Base v1.0, Patch 02)
#
# Runs the kernel under QEMU in several configurations, drives the shell over
# stdin, and checks the transcript for required markers. Exit status 0 iff
# every test passes. CI runs exactly this script; the hidden-test harness at
# grading time is this script plus extra scenario files in tests/hidden/
# (staff repository only), so if `make grade` passes locally the public part
# of your mark is already secure.
#
# No third-party dependencies: plain subprocess + threads, so it runs inside
# the course Docker image and on bare Ubuntu equally.

import subprocess, sys, threading, time, os, re, shutil

KERNEL = "kernel.elf"
FSIMG  = "fs.img"
QEMU   = os.environ.get("QEMU", "qemu-system-riscv64")

RESULTS = []

def fresh_image(name):
    """Every test runs on a COPY of the pristine fs.img: tests must not see
    each other's files, and a corrupted image must fail only its own test."""
    shutil.copyfile(FSIMG, name)
    return name

def run_qemu(cpus, mem, script, timeout, until=None, image=None, cache="writeback"):
    """Boot Luit with a LuitFS disk, feed `script` to stdin, return transcript.
    If `until` (list of byte-strings) is given, stop as soon as any appears --
    keeps `make grade` fast without shrinking safety timeouts."""
    img = image or fresh_image("fs.grade.img")
    cmd = [QEMU, "-machine", "virt", "-bios", "default", "-kernel", KERNEL,
           "-m", mem, "-smp", str(cpus), "-nographic",
           "-drive", f"file={img},if=none,format=raw,cache={cache},id=x0",
           "-device", "virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0"]
    p = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT)
    out = bytearray()
    done = threading.Event()

    stop_markers = [u.encode() for u in (until or [])]
    def reader():
        while True:
            b = p.stdout.read(1)
            if not b:
                break
            out.extend(b)
            if stop_markers and any(m in out for m in stop_markers):
                break
        done.set()

    t = threading.Thread(target=reader, daemon=True)
    t.start()
    try:
        for delay, line in script:
            time.sleep(delay)
            try:
                p.stdin.write((line + "\n").encode())
                p.stdin.flush()
            except BrokenPipeError:
                break
        done.wait(timeout)
    finally:
        # Give QEMU a chance to flush its block backend. Fall back to SIGKILL
        # only if it does not terminate promptly.
        if p.poll() is None:
            p.terminate()
            try:
                p.wait(timeout=5)
            except subprocess.TimeoutExpired:
                p.kill()
                p.wait()
    # strip ANSI/CR noise for matching
    text = out.decode("utf-8", errors="replace").replace("\r", "")
    return text

def check(name, transcript, must_have, must_not_have=()):
    ok = True
    missing = []
    for m in must_have:
        if isinstance(m, str):
            hit = m in transcript
        else:
            hit = re.search(m, transcript) is not None
        if not hit:
            ok = False
            missing.append(m)
    bad = [m for m in must_not_have if (m in transcript)]
    if bad:
        ok = False
    RESULTS.append((name, ok))
    status = "PASS" if ok else "FAIL"
    print(f"[{status}] {name}")
    if not ok:
        for m in missing:
            print(f"       missing: {m!r}")
        for m in bad:
            print(f"       forbidden marker present: {m!r}")
        tail = "\n".join(transcript.splitlines()[-25:])
        print("       --- last 25 lines of transcript ---")
        for line in tail.splitlines():
            print("       | " + line)
    return ok

BOOT_MARKERS = [
    "BrahmaputraOS / kernel Luit",
    re.compile(r"uart\s*:\s*0x"),          # FDT discovery actually happened
    re.compile(r"palloc: RAM 0x"),
    "hart 0: online",
    re.compile(r"luitfs: \d+ blocks"),      # the disk mounted
    "init: starting BrahmaputraOS userland",
    "luit$",
]
PANIC_MARKERS = ["panic", "PANIC", "Oops"]

def boot_test(cpus, mem, timeout=35):
    tr = run_qemu(cpus, mem, [(6, "meminfo")], timeout, until=["free pages:"])
    extra = []
    if cpus >= 2:
        extra = [f"hart {i}: online" for i in range(1, cpus)]
    return check(f"boot smoke: CPUS={cpus} MEM={mem}",
                 tr, BOOT_MARKERS + extra + ["free pages:"], PANIC_MARKERS)

def shell_test(cpus, mem, timeout=45):
    """Redirection, pipes, directories, relative paths -- the pre-Lab-1 shell
    contract, exercised exactly the way the course document promises it."""
    script = [(6,  "echo hello > a"),
              (1,  "cat a"),
              (1,  "cat a | wc"),
              (1,  "mkdir d; echo nested > d/f"),
              (1,  "cat d/f"),
              (1,  "grep hel a"),
              (1,  "rm a; cat a")]
    tr = run_qemu(cpus, mem, script, timeout, until=["cannot open a"])
    return check(f"shell: redirection/pipes/dirs CPUS={cpus}",
                 tr, ["hello", "1 1 6", "nested",
                      "cat: cannot open a"],       # rm actually removed it
                 PANIC_MARKERS)

def persistence_test(cpus, mem, timeout=40):
    """Write a file, stop QEMU, boot again on the same image, and read it.

    The explicit marker proves that the shell completed the redirection before
    QEMU is stopped. directsync prevents a host-side QEMU write-back cache from
    making this test depend on process-termination timing.
    """
    img = fresh_image("fs.persist.img")
    try:
        first = run_qemu(
            cpus, mem,
            [(6, "echo survives > p.txt"),
             (1, "echo __PERSIST_WRITTEN__")],
            timeout,
            until=["__PERSIST_WRITTEN__", "panic"],
            image=img,
            cache="directsync",
        )
        if "__PERSIST_WRITTEN__" not in first or any(
            marker in first for marker in PANIC_MARKERS
        ):
            return check(
                "persistence: file survives reboot",
                first,
                ["__PERSIST_WRITTEN__"],
                PANIC_MARKERS,
            )

        tr = run_qemu(
            cpus, mem,
            [(6, "cat p.txt"),
             (1, "echo __PERSIST_READ__")],
            timeout,
            until=["__PERSIST_READ__", "cannot open", "panic"],
            image=img,
            cache="directsync",
        )
        return check("persistence: file survives reboot",
                     tr, ["survives", "__PERSIST_READ__"],
                     PANIC_MARKERS + ["cannot open"])
    finally:
        try:
            os.remove(img)
        except FileNotFoundError:
            pass

def usertests(cpus, mem, timeout=90):
    tr = run_qemu(cpus, mem, [(6, "usertests")], timeout,
                  until=["=== ALL TESTS PASSED ===", "] FAIL", "panic"])
    return check(f"usertests: CPUS={cpus} MEM={mem}",
                 tr, ["=== ALL TESTS PASSED ==="], ["FAIL"] + PANIC_MARKERS)

def forktest(cpus, mem, timeout=60):
    tr = run_qemu(cpus, mem, [(6, "forktest")], timeout,
                  until=["forktest: OK", "panic"])
    return check(f"forktest: CPUS={cpus} MEM={mem}",
                 tr, ["forktest: OK"], PANIC_MARKERS)

def main():
    if not os.path.exists(KERNEL):
        print("kernel.elf not found -- run `make` first", file=sys.stderr)
        sys.exit(2)
    print("=== Luit public grade run ===")
    boot_test(1, "64M")
    boot_test(2, "128M")
    boot_test(4, "128M")
    boot_test(4, "512M")
    shell_test(2, "128M")
    persistence_test(2, "128M")
    usertests(1, "128M")
    usertests(4, "128M")
    forktest(2, "128M")
    npass = sum(1 for _, ok in RESULTS if ok)
    print(f"=== {npass}/{len(RESULTS)} passed ===")
    sys.exit(0 if npass == len(RESULTS) else 1)

if __name__ == "__main__":
    main()
