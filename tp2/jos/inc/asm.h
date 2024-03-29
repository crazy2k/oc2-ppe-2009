/* See COPYRIGHT for copyright information. */

#ifndef JOS_INC_ASM_H
#define JOS_INC_ASM_H

/*
 * Entry point for a procedure called from C
 */
#define ASENTRY(proc)	.align 2; .globl proc; .type proc,@function; proc:
#define ENTRY(proc)	ASENTRY(proc)

/*
 * Align a branch target and fill the gap with NOP's
 */
#define ALIGN_TEXT	.align 2,0x90
#define SUPERALIGN_TEXT	.p2align 4,0x90 /* 16-byte alignment, nop filled */


/*
 * gas won't do logical shifts in computed immediates!
 */
#define SRL(val, shamt)	(((val) >> (shamt)) & ~(-1 << (32 - (shamt))))

#define DEF_SYM(symbol, addr)              \
	asm(".globl _" #symbol "\n"        \
	    "\t.set _" #symbol ",%P0"      \
	    : : "i" (addr))

#endif /* !INC_JOS_ASM_H */
