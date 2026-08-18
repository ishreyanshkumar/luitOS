#!/usr/bin/env python3
# BrahmaputraOS / Luit -- public grading harness
# Timing-stable release: commands are synchronized to guest output, never to
# fixed sleep intervals.  This keeps grading deterministic across fast/slow
# hosts, WSL, VMs, and different QEMU scheduling behavior.

import os
import re
import shutil
import sys
import tempfile

from qemu_harness import BOOT_TIMEOUT, QemuSession

KERNEL = "kernel.elf"
FSIMG = "fs.img"
RESULTS = []
PANIC_MARKERS = ["panic", "PANIC", "Oops"]

BOOT_MARKERS = [
    "BrahmaputraOS / kernel Luit",
    re.compile(r"uart\s*:\s*0x"),
    re.compile(r"palloc: RAM 0x"),
    "hart 0: online",
    re.compile(r"luitfs: \d+ blocks"),
    "init: starting BrahmaputraOS userland",
    "luit$",
]


def _present(marker, text):
    if isinstance(marker, str):
        return marker in text
    return re.search(marker, text) is not None


def check(name, transcript, must_have, must_not_have=(), harness_note=None):
    missing = [m for m in must_have if not _present(m, transcript)]
    bad = [m for m in must_not_have if _present(m, transcript)]
    ok = not missing and not bad and harness_note is None
    RESULTS.append((name, ok))

    print(f"[{'PASS' if ok else 'FAIL'}] {name}")
    if not ok:
        if harness_note:
            print(f"       harness: {harness_note}")
        for m in missing:
            print(f"       missing: {m!r}")
        for m in bad:
            print(f"       forbidden marker present: {m!r}")
        tail = "\n".join(transcript.splitlines()[-25:])
        print("       --- last 25 lines of transcript ---")
        for line in tail.splitlines():
            print("       | " + line)
    return ok


def boot_test(cpus, mem, timeout=45):
    extra = [f"hart {i}: online" for i in range(1, cpus)]
    required_ready = BOOT_MARKERS + extra
    note = None

    with QemuSession(cpus, mem) as q:
        if not q.wait_for_all(required_ready, timeout=BOOT_TIMEOUT,
                              abort_markers=PANIC_MARKERS):
            note = "guest did not reach a complete boot state before the safety timeout"
        else:
            start = q.position()
            q.send_line("meminfo")
            if q.wait_for_any(["free pages:"], timeout=timeout, start=start,
                              abort_markers=PANIC_MARKERS) is None:
                note = "meminfo did not complete before the safety timeout"
        tr = q.text()

    return check(f"boot smoke: CPUS={cpus} MEM={mem}", tr,
                 required_ready + ["free pages:"], PANIC_MARKERS, note)


def shell_test(cpus, mem, timeout=60):
    note = None
    commands = [
        "echo hello > a",
        "cat a",
        "cat a | wc",
        "mkdir d; echo nested > d/f",
        "cat d/f",
        "grep hel a",
        "rm a; cat a",
    ]

    with QemuSession(cpus, mem) as q:
        if not q.wait_for_prompt(timeout=BOOT_TIMEOUT):
            note = "guest shell prompt did not appear before the safety timeout"
        else:
            start = q.position()
            for cmd in commands:
                if not q.send_line(cmd):
                    note = "QEMU exited while shell commands were being sent"
                    break
            if note is None and q.wait_for_any(["cat: cannot open a"], timeout=timeout,
                                                start=start,
                                                abort_markers=PANIC_MARKERS) is None:
                note = "shell command sequence did not complete before the safety timeout"
        tr = q.text()

    return check(f"shell: redirection/pipes/dirs CPUS={cpus}", tr,
                 ["hello", "1 1 6", "nested", "cat: cannot open a"],
                 PANIC_MARKERS, note)


def persistence_test(cpus, mem, timeout=60):
    """A completed guest write must survive an abrupt QEMU restart.

    The old grader slept for six seconds and could send the write before the
    shell existed.  Here we wait for the first prompt, then wait for the *next*
    prompt after the write command, which proves that the shell completed it.
    Writethrough is used so QEMU host caching cannot create a host-dependent
    false failure when QEMU is then killed to model power loss.
    """
    fd, img = tempfile.mkstemp(prefix=".fs.persist.", suffix=".img", dir=".")
    os.close(fd)
    shutil.copyfile(FSIMG, img)
    note = None

    try:
        q = QemuSession(cpus, mem, image=img, drive_cache="writethrough")
        try:
            if not q.wait_for_prompt(timeout=BOOT_TIMEOUT):
                note = "first boot did not reach the shell prompt"
            else:
                start = q.position()
                q.send_line("echo survives > p.txt")
                if not q.wait_for_prompt(timeout=timeout, start=start):
                    note = "file-creation command did not return to the shell"
            first_tr = q.text()
        finally:
            # Keep the original test's power-loss semantics: no graceful guest
            # shutdown after the completed write.
            q.power_off()

        if note is None:
            with QemuSession(cpus, mem, image=img, drive_cache="writethrough") as q2:
                if not q2.wait_for_prompt(timeout=BOOT_TIMEOUT):
                    note = "reboot did not reach the shell prompt"
                else:
                    start = q2.position()
                    q2.send_line("cat p.txt")
                    if q2.wait_for_any(["survives", "cat: cannot open"],
                                       timeout=timeout, start=start,
                                       abort_markers=PANIC_MARKERS) is None:
                        note = "reboot read did not complete before the safety timeout"
                tr = q2.text()
        else:
            tr = first_tr
    finally:
        try:
            os.unlink(img)
        except FileNotFoundError:
            pass

    return check("persistence: file survives reboot", tr,
                 ["survives"], PANIC_MARKERS + ["cat: cannot open"], note)


def usertests(cpus, mem, timeout=150):
    note = None
    with QemuSession(cpus, mem) as q:
        if not q.wait_for_prompt(timeout=BOOT_TIMEOUT):
            note = "guest shell prompt did not appear before the safety timeout"
        else:
            start = q.position()
            q.send_line("usertests")
            marker = q.wait_for_any(["=== ALL TESTS PASSED ===", "] FAIL", "panic", "PANIC"],
                                    timeout=timeout, start=start)
            if marker is None:
                note = "usertests did not finish before the safety timeout"
        tr = q.text()
    return check(f"usertests: CPUS={cpus} MEM={mem}", tr,
                 ["=== ALL TESTS PASSED ==="], ["FAIL"] + PANIC_MARKERS, note)


def forktest(cpus, mem, timeout=90):
    note = None
    with QemuSession(cpus, mem) as q:
        if not q.wait_for_prompt(timeout=BOOT_TIMEOUT):
            note = "guest shell prompt did not appear before the safety timeout"
        else:
            start = q.position()
            q.send_line("forktest")
            if q.wait_for_any(["forktest: OK", "panic", "PANIC"], timeout=timeout,
                              start=start) is None:
                note = "forktest did not finish before the safety timeout"
        tr = q.text()
    return check(f"forktest: CPUS={cpus} MEM={mem}", tr,
                 ["forktest: OK"], PANIC_MARKERS, note)


def main():
    if not os.path.exists(KERNEL):
        print("kernel.elf not found -- run `make` first", file=sys.stderr)
        return 2
    if not os.path.exists(FSIMG):
        print("fs.img not found -- run `make` first", file=sys.stderr)
        return 2

    print("=== Luit public grade run (timing-stable) ===")
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
    return 0 if npass == len(RESULTS) else 1


if __name__ == "__main__":
    raise SystemExit(main())
