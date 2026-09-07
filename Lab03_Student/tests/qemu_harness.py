#!/usr/bin/env python3
"""Small timing-stable QEMU driver used by the public Luit graders.

The important rule is event-driven synchronization: commands are sent only
*after* the guest shell prompt has actually appeared.  Timeouts are safety
limits only; they are never used as a substitute for guest readiness.
"""

import os
import re
import shutil
import subprocess
import tempfile
import threading
import time

QEMU = os.environ.get("QEMU", "qemu-system-riscv64")
BOOT_TIMEOUT = float(os.environ.get("LUIT_BOOT_TIMEOUT", "120"))


def _present(marker, text):
    if isinstance(marker, str):
        return marker in text
    return re.search(marker, text) is not None


class QemuSession:
    def __init__(self, cpus, mem, kernel="kernel.elf", fsimg="fs.img",
                 image=None, drive_cache="writeback"):
        self._owned_image = False
        if image is None:
            fd, image = tempfile.mkstemp(prefix=".fs.grade.", suffix=".img", dir=".")
            os.close(fd)
            shutil.copyfile(fsimg, image)
            self._owned_image = True
        self.image = image

        drive = (f"file={image},if=none,format=raw,cache={drive_cache},id=x0")
        cmd = [QEMU,
               "-machine", "virt",
               "-bios", "default",
               "-kernel", kernel,
               "-m", mem,
               "-smp", str(cpus),
               "-nographic",
               "-drive", drive,
               "-device", "virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0"]

        self.proc = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            bufsize=0,
        )
        self._out = bytearray()
        self._cv = threading.Condition()
        self._eof = False
        self._reader = threading.Thread(target=self._read_loop, daemon=True)
        self._reader.start()

    def _read_loop(self):
        try:
            while True:
                chunk = self.proc.stdout.read(256)
                if not chunk:
                    break
                with self._cv:
                    self._out.extend(chunk)
                    self._cv.notify_all()
        finally:
            with self._cv:
                self._eof = True
                self._cv.notify_all()

    def text(self):
        with self._cv:
            data = bytes(self._out)
        return data.decode("utf-8", errors="replace").replace("\r", "")

    def position(self):
        with self._cv:
            return len(self._out)

    def _slice_text(self, start):
        with self._cv:
            data = bytes(self._out[start:])
        return data.decode("utf-8", errors="replace").replace("\r", "")

    def wait_for_all(self, markers, timeout=BOOT_TIMEOUT, start=0,
                     abort_markers=()):
        """Wait until every marker is seen after *start*.

        Returns False on timeout, early QEMU exit, or an abort marker.
        """
        deadline = time.monotonic() + timeout
        with self._cv:
            while True:
                text = bytes(self._out[start:]).decode(
                    "utf-8", errors="replace").replace("\r", "")
                if abort_markers and any(_present(m, text) for m in abort_markers):
                    return False
                if all(_present(m, text) for m in markers):
                    return True
                if self._eof or self.proc.poll() is not None:
                    return False
                remain = deadline - time.monotonic()
                if remain <= 0:
                    return False
                self._cv.wait(min(remain, 0.25))

    def wait_for_any(self, markers, timeout, start=0, abort_markers=()):
        """Wait until any marker is seen after *start*.

        Returns the matching marker, or None on timeout/exit/abort.
        """
        deadline = time.monotonic() + timeout
        with self._cv:
            while True:
                text = bytes(self._out[start:]).decode(
                    "utf-8", errors="replace").replace("\r", "")
                if abort_markers and any(_present(m, text) for m in abort_markers):
                    return None
                for marker in markers:
                    if _present(marker, text):
                        return marker
                if self._eof or self.proc.poll() is not None:
                    return None
                remain = deadline - time.monotonic()
                if remain <= 0:
                    return None
                self._cv.wait(min(remain, 0.25))

    def wait_for_prompt(self, timeout=BOOT_TIMEOUT, start=0,
                        abort_markers=("panic", "PANIC", "Oops")):
        return self.wait_for_all(["luit$"], timeout=timeout, start=start,
                                 abort_markers=abort_markers)

    def send_line(self, line):
        if self.proc.poll() is not None:
            return False
        try:
            self.proc.stdin.write((line + "\n").encode())
            self.proc.stdin.flush()
            return True
        except (BrokenPipeError, OSError):
            return False

    def stop(self, graceful=True):
        if self.proc.poll() is not None:
            self._cleanup_image()
            return

        if graceful:
            # QEMU's -nographic monitor escape: Ctrl-A x.
            try:
                self.proc.stdin.write(b"\x01x")
                self.proc.stdin.flush()
                self.proc.wait(timeout=3)
            except (BrokenPipeError, OSError, subprocess.TimeoutExpired):
                pass

        if self.proc.poll() is None:
            try:
                self.proc.terminate()
                self.proc.wait(timeout=2)
            except subprocess.TimeoutExpired:
                self.proc.kill()
                self.proc.wait()
        self._cleanup_image()

    def power_off(self):
        """Abruptly stop QEMU (used by the persistence/power-loss test)."""
        if self.proc.poll() is None:
            self.proc.kill()
            self.proc.wait()
        self._cleanup_image()

    def _cleanup_image(self):
        if self._owned_image:
            try:
                os.unlink(self.image)
            except FileNotFoundError:
                pass
            self._owned_image = False

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        self.stop(graceful=True)
        return False
