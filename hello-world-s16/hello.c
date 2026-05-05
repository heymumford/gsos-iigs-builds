/*
 * Hello World — ORCA/C + Toolbox (S16)
 *
 * Minimal 16-bit Apple IIGS GS/OS application using ORCA/C.
 * Calls the Toolbox QuickDraw II library to write text to screen.
 *
 * Source: https://github.com/byteworksinc/ORCA-C
 * Toolbox Reference: Apple IIGS Toolbox Reference Volume 1
 * License: MIT
 */

#include <misctool.h>

int main(void) {
    /* Initialize Toolbox environment. */
    SetIOUseBuffer(1);

    /* Write string to stdout using Toolbox console I/O. */
    puts("\nHello, GS/OS World!");
    puts("This is an ORCA/C S16 application.\n");

    return 0;
}
