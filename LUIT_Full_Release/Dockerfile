# BrahmaputraOS / Luit -- reproducible build & grade environment.
# Every student, TA and CI runner uses THIS image. "Works on my machine"
# is not a defence in this course; this file is why.
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc-riscv64-unknown-elf \
        binutils-riscv64-unknown-elf \
        qemu-system-misc \
        gdb-multiarch \
        python3 \
        make \
        git \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /luit
COPY . /luit

# Sanity: image must be able to build and grade the baseline out of the box.
RUN make clean && make -j"$(nproc)"

CMD ["make", "grade"]
