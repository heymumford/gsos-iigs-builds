/* hello.c — Minimal 16-bit GS/OS Hello World application.
 * Target: Apple IIGS (cc65 apple2enh or APW)
 * License: MIT
 *
 * This is a smoke-test binary that exercises the full cc65 toolchain:
 * compiler (cc65), assembler (ca65), linker (ld65), and utilities.
 * On successful compile+link, a 16-bit S16 (Application) file is produced.
 */

#include <stdio.h>

int main(void) {
    printf("Hello, GS/OS World!\n");
    return 0;
}
