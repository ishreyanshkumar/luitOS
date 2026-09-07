# AI/LLM Use Policy - Luit Lab 1

## Principle

AI assistants may support learning, documentation lookup, debugging, and
review, but they must not perform the graded implementation work. You must be
able to explain and modify every submitted line during evaluation or viva.

## GREEN - permitted without logging

- explanations of operating-system concepts;
- explanations of the provided Luit baseline code;
- questions about RISC-V registers, the syscall ABI, pipes, processes, and GDB;
- help interpreting compiler, linker, QEMU, or GDB error messages from your own
  work; and
- grammar or presentation improvements to text you already wrote.

## AMBER - permitted only with an entry in `lab01/LLM_LOG.md`

- discussing alternative designs before you implement them;
- asking for test-case ideas;
- asking an assistant to review code or a diff that you wrote; and
- asking for debugging hypotheses after you provide your own observations.

For every AMBER interaction, record the tool/model, what you asked, what advice
you used, where it affected your work, and how you verified it independently.

## RED - prohibited

Do not use an AI assistant to generate or complete graded solution code for:

- `user/sleep.c`;
- `user/pingpong.c`;
- `user/pstree.c`;
- `tools/syscallmap.py`;
- the required GDB observations or explanations; or
- the technical answers in the report.

Also prohibited are copying another student's code, copying a public xv6/Luit
solution, asking an agent to edit the repository, or submitting generated text
that you cannot explain.

## Submission log

Submit `lab01/LLM_LOG.md` with the assignment. An empty-use declaration is
acceptable. A false or incomplete declaration is an academic-integrity issue.
