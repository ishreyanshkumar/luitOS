# Lab 1 AI/LLM Use Log

Name: Shreyansh Kumar
Roll number: 240101094

For every permitted AMBER interaction, add one entry using the template below.
If no AI/LLM assistant was used, delete the template and write exactly:

**No AI/LLM assistant was used for this lab.**

## Entry 1

- Tool/model: Gemini / Agentic AI
- Question asked: Asked for debugging hypotheses regarding a compilation error in `sleep.c` where `INT_MAX` was undeclared and there was an incompatible pointer type mismatch between my functions.
- Advice used: The assistant hypothesized that I might be missing the `<limits.h>` header for `INT_MAX` and advised me to double-check that the argument types in my function signatures perfectly matched.
- Files/sections affected: `user/sleep.c` (overflow checking logic)
- How I independently verified it: I read the C standard library documentation for `INT_MAX`, verified that my variable types were indeed mismatched, and confirmed that applying the fix allowed the code to compile and pass the tests.

## Entry 2

- Tool/model: Gemini / Agentic AI
- Question asked: Asked for a review of my Python regex logic for parsing `#define` lines in `syscallmap.py`, and asked why GDB was throwing a "syntax error in expression" when I pasted my trace commands.
- Advice used: The assistant pointed out how regex capture groups can be used to isolate the syscall names, and explained that GDB was throwing syntax errors because my terminal was feeding multiple commands as a single string instead of line-by-line.
- Files/sections affected: `tools/syscallmap.py` (parsing functions) and `gdb-trace.txt`
- How I independently verified it: I tested the regex pattern on sample strings to ensure it extracted the correct components, and I manually ran the GDB trace one line at a time, which successfully produced the expected output.

## Entry 3

- Tool/model: Gemini / Agentic AI
- Question asked: Asked for help resolving LaTeX margin overflows (Overfull \hbox) and formatting list structures (`\begin{enumerate}`) in my report document.
- Advice used: The assistant helped identify that manual linebreaks (`\\`) inside paragraphs were breaking the LaTeX hyphenation and wrapping algorithm, and suggested using standard paragraph breaks instead.
- Files/sections affected: `lab01/report.tex` (presentation formatting only)
- How I independently verified it: I recompiled the LaTeX document with `pdflatex` and visually confirmed the margin overflows were fixed and the lists were cleanly rendered.

## Entry 4

- Tool/model: Gemini / Agentic AI
- Question asked: Asked for general explanations of OS architecture concepts, specifically how the `ecall` mechanism bridges user-space to kernel-space, and how process snapshots can become inconsistent.
- Advice used: The assistant explained the theory behind the RISC-V trap mechanism and race conditions during non-atomic process table scans (which falls under the permitted GREEN policy for concept explanations).
- Files/sections affected: General conceptual understanding for the lab.
- How I independently verified it: I cross-referenced the explanation with the provided Luit baseline code (`trap.c` and `syscall.c`) and course lectures, ensuring the conceptual model matched the actual implementation.
