
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		_start
_start:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fb                   	sti    
f0100009:	4f                   	dec    %edi
f010000a:	52                   	push   %edx
f010000b:	e4 66                	in     $0x66,%al

f010000c <_start>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 

	# Establish our own GDT in place of the boot loader's temporary GDT.
	lgdt	RELOC(mygdtdesc)		# load descriptor table
f0100015:	0f 01 15 18 30 11 00 	lgdtl  0x113018

	# Immediately reload all segment registers (including CS!)
	# with segment selectors from the new GDT.
	movl	$DATA_SEL,%eax			# Data segment selector
f010001c:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax,%ds				# -> DS: Data Segment
f0100021:	8e d8                	mov    %eax,%ds
	movw	%ax,%es				# -> ES: Extra Segment
f0100023:	8e c0                	mov    %eax,%es
	movw	%ax,%ss				# -> SS: Stack Segment
f0100025:	8e d0                	mov    %eax,%ss
	ljmp	$CODE_SEL,$relocated		# reload CS by jumping
f0100027:	ea 2e 00 10 f0 08 00 	ljmp   $0x8,$0xf010002e

f010002e <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002e:	bd 00 00 00 00       	mov    $0x0,%ebp

        # Set the stack pointer
	movl	$(bootstacktop),%esp
f0100033:	bc 00 30 11 f0       	mov    $0xf0113000,%esp

	# now to C code
	call	i386_init
f0100038:	e8 63 00 00 00       	call   f01000a0 <i386_init>

f010003d <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003d:	eb fe                	jmp    f010003d <spin>
	...

f0100040 <test_backtrace>:
#include <kern/pmap.h>
#include <kern/kclock.h>

void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
        cprintf("entering test_backtrace %d\n", x);
f0100046:	8b 45 08             	mov    0x8(%ebp),%eax
f0100049:	89 44 24 04          	mov    %eax,0x4(%esp)
f010004d:	c7 04 24 c0 36 10 f0 	movl   $0xf01036c0,(%esp)
f0100054:	e8 be 22 00 00       	call   f0102317 <cprintf>
        if (x > 0)
f0100059:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010005d:	7e 10                	jle    f010006f <test_backtrace+0x2f>
                test_backtrace(x-1);
f010005f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100062:	83 e8 01             	sub    $0x1,%eax
f0100065:	89 04 24             	mov    %eax,(%esp)
f0100068:	e8 d3 ff ff ff       	call   f0100040 <test_backtrace>
f010006d:	eb 1c                	jmp    f010008b <test_backtrace+0x4b>
        else
                mon_backtrace(0, 0, 0);
f010006f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100076:	00 
f0100077:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007e:	00 
f010007f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100086:	e8 08 0a 00 00       	call   f0100a93 <mon_backtrace>
        cprintf("leaving test_backtrace %d\n", x);
f010008b:	8b 45 08             	mov    0x8(%ebp),%eax
f010008e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100092:	c7 04 24 dc 36 10 f0 	movl   $0xf01036dc,(%esp)
f0100099:	e8 79 22 00 00       	call   f0102317 <cprintf>
}
f010009e:	c9                   	leave  
f010009f:	c3                   	ret    

f01000a0 <i386_init>:

void
i386_init(void)
{
f01000a0:	55                   	push   %ebp
f01000a1:	89 e5                	mov    %esp,%ebp
f01000a3:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else,
	// clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a6:	ba 30 3c 11 f0       	mov    $0xf0113c30,%edx
f01000ab:	b8 b8 35 11 f0       	mov    $0xf01135b8,%eax
f01000b0:	89 d1                	mov    %edx,%ecx
f01000b2:	29 c1                	sub    %eax,%ecx
f01000b4:	89 c8                	mov    %ecx,%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000c1:	00 
f01000c2:	c7 04 24 b8 35 11 f0 	movl   $0xf01135b8,(%esp)
f01000c9:	e8 72 30 00 00       	call   f0103140 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000ce:	e8 49 08 00 00       	call   f010091c <cons_init>

	cprintf("240 decimal is %o octal!\n", 240);
f01000d3:	c7 44 24 04 f0 00 00 	movl   $0xf0,0x4(%esp)
f01000da:	00 
f01000db:	c7 04 24 f7 36 10 f0 	movl   $0xf01036f7,(%esp)
f01000e2:	e8 30 22 00 00       	call   f0102317 <cprintf>

        test_backtrace(5);
f01000e7:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000ee:	e8 4d ff ff ff       	call   f0100040 <test_backtrace>

	// Lab 2 memory management initialization functions
	i386_detect_memory();
f01000f3:	e8 85 0b 00 00       	call   f0100c7d <i386_detect_memory>
	i386_vm_init();
f01000f8:	e8 35 0e 00 00       	call   f0100f32 <i386_vm_init>
	page_init();
f01000fd:	e8 a2 14 00 00       	call   f01015a4 <page_init>
	page_check();
f0100102:	e8 11 17 00 00       	call   f0101818 <page_check>



	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100107:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010010e:	e8 e6 0a 00 00       	call   f0100bf9 <monitor>
f0100113:	eb f2                	jmp    f0100107 <i386_init+0x67>

f0100115 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100115:	55                   	push   %ebp
f0100116:	89 e5                	mov    %esp,%ebp
f0100118:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	if (panicstr)
f010011b:	a1 c0 35 11 f0       	mov    0xf01135c0,%eax
f0100120:	85 c0                	test   %eax,%eax
f0100122:	75 49                	jne    f010016d <_panic+0x58>
		goto dead;
	panicstr = fmt;
f0100124:	8b 45 10             	mov    0x10(%ebp),%eax
f0100127:	a3 c0 35 11 f0       	mov    %eax,0xf01135c0

	va_start(ap, fmt);
f010012c:	8d 45 10             	lea    0x10(%ebp),%eax
f010012f:	83 c0 04             	add    $0x4,%eax
f0100132:	89 45 fc             	mov    %eax,-0x4(%ebp)
	cprintf("kernel panic at %s:%d: ", file, line);
f0100135:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100138:	89 44 24 08          	mov    %eax,0x8(%esp)
f010013c:	8b 45 08             	mov    0x8(%ebp),%eax
f010013f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100143:	c7 04 24 11 37 10 f0 	movl   $0xf0103711,(%esp)
f010014a:	e8 c8 21 00 00       	call   f0102317 <cprintf>
	vcprintf(fmt, ap);
f010014f:	8b 55 10             	mov    0x10(%ebp),%edx
f0100152:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100155:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100159:	89 14 24             	mov    %edx,(%esp)
f010015c:	e8 82 21 00 00       	call   f01022e3 <vcprintf>
	cprintf("\n");
f0100161:	c7 04 24 29 37 10 f0 	movl   $0xf0103729,(%esp)
f0100168:	e8 aa 21 00 00       	call   f0102317 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010016d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100174:	e8 80 0a 00 00       	call   f0100bf9 <monitor>
f0100179:	eb f2                	jmp    f010016d <_panic+0x58>

f010017b <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010017b:	55                   	push   %ebp
f010017c:	89 e5                	mov    %esp,%ebp
f010017e:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
f0100181:	8d 45 10             	lea    0x10(%ebp),%eax
f0100184:	83 c0 04             	add    $0x4,%eax
f0100187:	89 45 fc             	mov    %eax,-0x4(%ebp)
	cprintf("kernel warning at %s:%d: ", file, line);
f010018a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010018d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100191:	8b 45 08             	mov    0x8(%ebp),%eax
f0100194:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100198:	c7 04 24 2b 37 10 f0 	movl   $0xf010372b,(%esp)
f010019f:	e8 73 21 00 00       	call   f0102317 <cprintf>
	vcprintf(fmt, ap);
f01001a4:	8b 55 10             	mov    0x10(%ebp),%edx
f01001a7:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01001aa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01001ae:	89 14 24             	mov    %edx,(%esp)
f01001b1:	e8 2d 21 00 00       	call   f01022e3 <vcprintf>
	cprintf("\n");
f01001b6:	c7 04 24 29 37 10 f0 	movl   $0xf0103729,(%esp)
f01001bd:	e8 55 21 00 00       	call   f0102317 <cprintf>
	va_end(ap);
}
f01001c2:	c9                   	leave  
f01001c3:	c3                   	ret    

f01001c4 <serial_proc_data>:

static bool serial_exists;

int
serial_proc_data(void)
{
f01001c4:	55                   	push   %ebp
f01001c5:	89 e5                	mov    %esp,%ebp
f01001c7:	83 ec 14             	sub    $0x14,%esp
f01001ca:	c7 45 f8 fd 03 00 00 	movl   $0x3fd,-0x8(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001d1:	8b 55 f8             	mov    -0x8(%ebp),%edx
f01001d4:	ec                   	in     (%dx),%al
f01001d5:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
f01001d8:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001dc:	0f b6 c0             	movzbl %al,%eax
f01001df:	83 e0 01             	and    $0x1,%eax
f01001e2:	85 c0                	test   %eax,%eax
f01001e4:	75 09                	jne    f01001ef <serial_proc_data+0x2b>
		return -1;
f01001e6:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
f01001ed:	eb 18                	jmp    f0100207 <serial_proc_data+0x43>
f01001ef:	c7 45 f4 f8 03 00 00 	movl   $0x3f8,-0xc(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001f6:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01001f9:	ec                   	in     (%dx),%al
f01001fa:	88 45 fe             	mov    %al,-0x2(%ebp)
	return data;
f01001fd:	0f b6 45 fe          	movzbl -0x2(%ebp),%eax
	return inb(COM1+COM_RX);
f0100201:	0f b6 c0             	movzbl %al,%eax
f0100204:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100207:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
f010020a:	c9                   	leave  
f010020b:	c3                   	ret    

f010020c <serial_intr>:

void
serial_intr(void)
{
f010020c:	55                   	push   %ebp
f010020d:	89 e5                	mov    %esp,%ebp
f010020f:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100212:	a1 e4 35 11 f0       	mov    0xf01135e4,%eax
f0100217:	85 c0                	test   %eax,%eax
f0100219:	74 0c                	je     f0100227 <serial_intr+0x1b>
		cons_intr(serial_proc_data);
f010021b:	c7 04 24 c4 01 10 f0 	movl   $0xf01001c4,(%esp)
f0100222:	e8 28 06 00 00       	call   f010084f <cons_intr>
}
f0100227:	c9                   	leave  
f0100228:	c3                   	ret    

f0100229 <serial_init>:

void
serial_init(void)
{
f0100229:	55                   	push   %ebp
f010022a:	89 e5                	mov    %esp,%ebp
f010022c:	83 ec 40             	sub    $0x40,%esp
f010022f:	c7 45 f0 fa 03 00 00 	movl   $0x3fa,-0x10(%ebp)
f0100236:	c6 45 ff 00          	movb   $0x0,-0x1(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010023a:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
f010023e:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100241:	ee                   	out    %al,(%dx)
f0100242:	c7 45 ec fb 03 00 00 	movl   $0x3fb,-0x14(%ebp)
f0100249:	c6 45 fe 80          	movb   $0x80,-0x2(%ebp)
f010024d:	0f b6 45 fe          	movzbl -0x2(%ebp),%eax
f0100251:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0100254:	ee                   	out    %al,(%dx)
f0100255:	c7 45 e8 f8 03 00 00 	movl   $0x3f8,-0x18(%ebp)
f010025c:	c6 45 fd 0c          	movb   $0xc,-0x3(%ebp)
f0100260:	0f b6 45 fd          	movzbl -0x3(%ebp),%eax
f0100264:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100267:	ee                   	out    %al,(%dx)
f0100268:	c7 45 e4 f9 03 00 00 	movl   $0x3f9,-0x1c(%ebp)
f010026f:	c6 45 fc 00          	movb   $0x0,-0x4(%ebp)
f0100273:	0f b6 45 fc          	movzbl -0x4(%ebp),%eax
f0100277:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010027a:	ee                   	out    %al,(%dx)
f010027b:	c7 45 e0 fb 03 00 00 	movl   $0x3fb,-0x20(%ebp)
f0100282:	c6 45 fb 03          	movb   $0x3,-0x5(%ebp)
f0100286:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
f010028a:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010028d:	ee                   	out    %al,(%dx)
f010028e:	c7 45 dc fc 03 00 00 	movl   $0x3fc,-0x24(%ebp)
f0100295:	c6 45 fa 00          	movb   $0x0,-0x6(%ebp)
f0100299:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
f010029d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01002a0:	ee                   	out    %al,(%dx)
f01002a1:	c7 45 d8 f9 03 00 00 	movl   $0x3f9,-0x28(%ebp)
f01002a8:	c6 45 f9 01          	movb   $0x1,-0x7(%ebp)
f01002ac:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
f01002b0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01002b3:	ee                   	out    %al,(%dx)
f01002b4:	c7 45 d4 fd 03 00 00 	movl   $0x3fd,-0x2c(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002bb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01002be:	ec                   	in     (%dx),%al
f01002bf:	88 45 f8             	mov    %al,-0x8(%ebp)
	return data;
f01002c2:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01002c6:	3c ff                	cmp    $0xff,%al
f01002c8:	0f 95 c0             	setne  %al
f01002cb:	0f b6 c0             	movzbl %al,%eax
f01002ce:	a3 e4 35 11 f0       	mov    %eax,0xf01135e4
f01002d3:	c7 45 d0 fa 03 00 00 	movl   $0x3fa,-0x30(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002da:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01002dd:	ec                   	in     (%dx),%al
f01002de:	88 45 f7             	mov    %al,-0x9(%ebp)
	return data;
f01002e1:	c7 45 cc f8 03 00 00 	movl   $0x3f8,-0x34(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e8:	8b 55 cc             	mov    -0x34(%ebp),%edx
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	88 45 f6             	mov    %al,-0xa(%ebp)
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
f01002ef:	c9                   	leave  
f01002f0:	c3                   	ret    

f01002f1 <delay>:
// page.

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01002f1:	55                   	push   %ebp
f01002f2:	89 e5                	mov    %esp,%ebp
f01002f4:	83 ec 20             	sub    $0x20,%esp
f01002f7:	c7 45 f8 84 00 00 00 	movl   $0x84,-0x8(%ebp)
f01002fe:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0100301:	ec                   	in     (%dx),%al
f0100302:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
f0100305:	c7 45 f4 84 00 00 00 	movl   $0x84,-0xc(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030c:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010030f:	ec                   	in     (%dx),%al
f0100310:	88 45 fe             	mov    %al,-0x2(%ebp)
	return data;
f0100313:	c7 45 f0 84 00 00 00 	movl   $0x84,-0x10(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010031a:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010031d:	ec                   	in     (%dx),%al
f010031e:	88 45 fd             	mov    %al,-0x3(%ebp)
	return data;
f0100321:	c7 45 ec 84 00 00 00 	movl   $0x84,-0x14(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100328:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010032b:	ec                   	in     (%dx),%al
f010032c:	88 45 fc             	mov    %al,-0x4(%ebp)
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010032f:	c9                   	leave  
f0100330:	c3                   	ret    

f0100331 <lpt_putc>:

static void
lpt_putc(int c)
{
f0100331:	55                   	push   %ebp
f0100332:	89 e5                	mov    %esp,%ebp
f0100334:	83 ec 20             	sub    $0x20,%esp
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100337:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
f010033e:	eb 09                	jmp    f0100349 <lpt_putc+0x18>
		delay();
f0100340:	e8 ac ff ff ff       	call   f01002f1 <delay>
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100345:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
f0100349:	c7 45 f4 79 03 00 00 	movl   $0x379,-0xc(%ebp)
f0100350:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100353:	ec                   	in     (%dx),%al
f0100354:	88 45 ff             	mov    %al,-0x1(%ebp)
	return data;
f0100357:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
f010035b:	84 c0                	test   %al,%al
f010035d:	78 09                	js     f0100368 <lpt_putc+0x37>
f010035f:	81 7d f8 ff 31 00 00 	cmpl   $0x31ff,-0x8(%ebp)
f0100366:	7e d8                	jle    f0100340 <lpt_putc+0xf>
		delay();
	outb(0x378+0, c);
f0100368:	8b 45 08             	mov    0x8(%ebp),%eax
f010036b:	0f b6 c0             	movzbl %al,%eax
f010036e:	c7 45 f0 78 03 00 00 	movl   $0x378,-0x10(%ebp)
f0100375:	88 45 fe             	mov    %al,-0x2(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100378:	0f b6 45 fe          	movzbl -0x2(%ebp),%eax
f010037c:	8b 55 f0             	mov    -0x10(%ebp),%edx
f010037f:	ee                   	out    %al,(%dx)
f0100380:	c7 45 ec 7a 03 00 00 	movl   $0x37a,-0x14(%ebp)
f0100387:	c6 45 fd 0d          	movb   $0xd,-0x3(%ebp)
f010038b:	0f b6 45 fd          	movzbl -0x3(%ebp),%eax
f010038f:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0100392:	ee                   	out    %al,(%dx)
f0100393:	c7 45 e8 7a 03 00 00 	movl   $0x37a,-0x18(%ebp)
f010039a:	c6 45 fc 08          	movb   $0x8,-0x4(%ebp)
f010039e:	0f b6 45 fc          	movzbl -0x4(%ebp),%eax
f01003a2:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01003a5:	ee                   	out    %al,(%dx)
	outb(0x378+2, 0x08|0x04|0x01);
	outb(0x378+2, 0x08);
}
f01003a6:	c9                   	leave  
f01003a7:	c3                   	ret    

f01003a8 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
cga_init(void)
{
f01003a8:	55                   	push   %ebp
f01003a9:	89 e5                	mov    %esp,%ebp
f01003ab:	83 ec 20             	sub    $0x20,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01003ae:	c7 45 f4 00 80 0b f0 	movl   $0xf00b8000,-0xc(%ebp)
	was = *cp;
f01003b5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01003b8:	0f b7 00             	movzwl (%eax),%eax
f01003bb:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
	*cp = (uint16_t) 0xA55A;
f01003bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01003c2:	66 c7 00 5a a5       	movw   $0xa55a,(%eax)
	if (*cp != 0xA55A) {
f01003c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01003ca:	0f b7 00             	movzwl (%eax),%eax
f01003cd:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01003d1:	74 13                	je     f01003e6 <cga_init+0x3e>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01003d3:	c7 45 f4 00 00 0b f0 	movl   $0xf00b0000,-0xc(%ebp)
		addr_6845 = MONO_BASE;
f01003da:	c7 05 e8 35 11 f0 b4 	movl   $0x3b4,0xf01135e8
f01003e1:	03 00 00 
f01003e4:	eb 14                	jmp    f01003fa <cga_init+0x52>
	} else {
		*cp = was;
f01003e6:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01003e9:	0f b7 45 fa          	movzwl -0x6(%ebp),%eax
f01003ed:	66 89 02             	mov    %ax,(%edx)
		addr_6845 = CGA_BASE;
f01003f0:	c7 05 e8 35 11 f0 d4 	movl   $0x3d4,0xf01135e8
f01003f7:	03 00 00 
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01003fa:	a1 e8 35 11 f0       	mov    0xf01135e8,%eax
f01003ff:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100402:	c6 45 ff 0e          	movb   $0xe,-0x1(%ebp)
f0100406:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
f010040a:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010040d:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010040e:	a1 e8 35 11 f0       	mov    0xf01135e8,%eax
f0100413:	83 c0 01             	add    $0x1,%eax
f0100416:	89 45 e8             	mov    %eax,-0x18(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100419:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010041c:	ec                   	in     (%dx),%al
f010041d:	88 45 fe             	mov    %al,-0x2(%ebp)
	return data;
f0100420:	0f b6 45 fe          	movzbl -0x2(%ebp),%eax
f0100424:	0f b6 c0             	movzbl %al,%eax
f0100427:	c1 e0 08             	shl    $0x8,%eax
f010042a:	89 45 f0             	mov    %eax,-0x10(%ebp)
	outb(addr_6845, 15);
f010042d:	a1 e8 35 11 f0       	mov    0xf01135e8,%eax
f0100432:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100435:	c6 45 fd 0f          	movb   $0xf,-0x3(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100439:	0f b6 45 fd          	movzbl -0x3(%ebp),%eax
f010043d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100440:	ee                   	out    %al,(%dx)
	pos |= inb(addr_6845 + 1);
f0100441:	a1 e8 35 11 f0       	mov    0xf01135e8,%eax
f0100446:	83 c0 01             	add    $0x1,%eax
f0100449:	89 45 e0             	mov    %eax,-0x20(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010044c:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010044f:	ec                   	in     (%dx),%al
f0100450:	88 45 fc             	mov    %al,-0x4(%ebp)
	return data;
f0100453:	0f b6 45 fc          	movzbl -0x4(%ebp),%eax
f0100457:	0f b6 c0             	movzbl %al,%eax
f010045a:	09 45 f0             	or     %eax,-0x10(%ebp)

	crt_buf = (uint16_t*) cp;
f010045d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100460:	a3 ec 35 11 f0       	mov    %eax,0xf01135ec
	crt_pos = pos;
f0100465:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100468:	66 a3 f0 35 11 f0    	mov    %ax,0xf01135f0
}
f010046e:	c9                   	leave  
f010046f:	c3                   	ret    

f0100470 <cga_putc>:



void
cga_putc(int c)
{
f0100470:	55                   	push   %ebp
f0100471:	89 e5                	mov    %esp,%ebp
f0100473:	53                   	push   %ebx
f0100474:	83 ec 34             	sub    $0x34,%esp
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100477:	8b 45 08             	mov    0x8(%ebp),%eax
f010047a:	b0 00                	mov    $0x0,%al
f010047c:	85 c0                	test   %eax,%eax
f010047e:	75 07                	jne    f0100487 <cga_putc+0x17>
		c |= 0x0700;
f0100480:	81 4d 08 00 07 00 00 	orl    $0x700,0x8(%ebp)

	switch (c & 0xff) {
f0100487:	8b 45 08             	mov    0x8(%ebp),%eax
f010048a:	25 ff 00 00 00       	and    $0xff,%eax
f010048f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100492:	83 7d d4 09          	cmpl   $0x9,-0x2c(%ebp)
f0100496:	0f 84 bf 00 00 00    	je     f010055b <cga_putc+0xeb>
f010049c:	83 7d d4 09          	cmpl   $0x9,-0x2c(%ebp)
f01004a0:	7f 0b                	jg     f01004ad <cga_putc+0x3d>
f01004a2:	83 7d d4 08          	cmpl   $0x8,-0x2c(%ebp)
f01004a6:	74 16                	je     f01004be <cga_putc+0x4e>
f01004a8:	e9 ec 00 00 00       	jmp    f0100599 <cga_putc+0x129>
f01004ad:	83 7d d4 0a          	cmpl   $0xa,-0x2c(%ebp)
f01004b1:	74 4f                	je     f0100502 <cga_putc+0x92>
f01004b3:	83 7d d4 0d          	cmpl   $0xd,-0x2c(%ebp)
f01004b7:	74 59                	je     f0100512 <cga_putc+0xa2>
f01004b9:	e9 db 00 00 00       	jmp    f0100599 <cga_putc+0x129>
	case '\b':
		if (crt_pos > 0) {
f01004be:	0f b7 05 f0 35 11 f0 	movzwl 0xf01135f0,%eax
f01004c5:	66 85 c0             	test   %ax,%ax
f01004c8:	0f 84 ee 00 00 00    	je     f01005bc <cga_putc+0x14c>
			crt_pos--;
f01004ce:	0f b7 05 f0 35 11 f0 	movzwl 0xf01135f0,%eax
f01004d5:	83 e8 01             	sub    $0x1,%eax
f01004d8:	66 a3 f0 35 11 f0    	mov    %ax,0xf01135f0
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004de:	8b 15 ec 35 11 f0    	mov    0xf01135ec,%edx
f01004e4:	0f b7 05 f0 35 11 f0 	movzwl 0xf01135f0,%eax
f01004eb:	0f b7 c0             	movzwl %ax,%eax
f01004ee:	01 c0                	add    %eax,%eax
f01004f0:	01 c2                	add    %eax,%edx
f01004f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01004f5:	b0 00                	mov    $0x0,%al
f01004f7:	83 c8 20             	or     $0x20,%eax
f01004fa:	66 89 02             	mov    %ax,(%edx)
f01004fd:	e9 ba 00 00 00       	jmp    f01005bc <cga_putc+0x14c>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100502:	0f b7 05 f0 35 11 f0 	movzwl 0xf01135f0,%eax
f0100509:	83 c0 50             	add    $0x50,%eax
f010050c:	66 a3 f0 35 11 f0    	mov    %ax,0xf01135f0
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100512:	0f b7 0d f0 35 11 f0 	movzwl 0xf01135f0,%ecx
f0100519:	0f b7 15 f0 35 11 f0 	movzwl 0xf01135f0,%edx
f0100520:	0f b7 c2             	movzwl %dx,%eax
f0100523:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100529:	c1 e8 10             	shr    $0x10,%eax
f010052c:	89 c3                	mov    %eax,%ebx
f010052e:	66 c1 eb 06          	shr    $0x6,%bx
f0100532:	66 89 5d da          	mov    %bx,-0x26(%ebp)
f0100536:	0f b7 45 da          	movzwl -0x26(%ebp),%eax
f010053a:	c1 e0 02             	shl    $0x2,%eax
f010053d:	66 03 45 da          	add    -0x26(%ebp),%ax
f0100541:	c1 e0 04             	shl    $0x4,%eax
f0100544:	89 d3                	mov    %edx,%ebx
f0100546:	66 29 c3             	sub    %ax,%bx
f0100549:	66 89 5d da          	mov    %bx,-0x26(%ebp)
f010054d:	89 c8                	mov    %ecx,%eax
f010054f:	66 2b 45 da          	sub    -0x26(%ebp),%ax
f0100553:	66 a3 f0 35 11 f0    	mov    %ax,0xf01135f0
f0100559:	eb 61                	jmp    f01005bc <cga_putc+0x14c>
		break;
	case '\t':
		cons_putc(' ');
f010055b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100562:	e8 97 03 00 00       	call   f01008fe <cons_putc>
		cons_putc(' ');
f0100567:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010056e:	e8 8b 03 00 00       	call   f01008fe <cons_putc>
		cons_putc(' ');
f0100573:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010057a:	e8 7f 03 00 00       	call   f01008fe <cons_putc>
		cons_putc(' ');
f010057f:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100586:	e8 73 03 00 00       	call   f01008fe <cons_putc>
		cons_putc(' ');
f010058b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100592:	e8 67 03 00 00       	call   f01008fe <cons_putc>
f0100597:	eb 23                	jmp    f01005bc <cga_putc+0x14c>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100599:	8b 15 ec 35 11 f0    	mov    0xf01135ec,%edx
f010059f:	0f b7 0d f0 35 11 f0 	movzwl 0xf01135f0,%ecx
f01005a6:	0f b7 c1             	movzwl %cx,%eax
f01005a9:	01 c0                	add    %eax,%eax
f01005ab:	01 c2                	add    %eax,%edx
f01005ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01005b0:	66 89 02             	mov    %ax,(%edx)
f01005b3:	8d 41 01             	lea    0x1(%ecx),%eax
f01005b6:	66 a3 f0 35 11 f0    	mov    %ax,0xf01135f0
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005bc:	0f b7 05 f0 35 11 f0 	movzwl 0xf01135f0,%eax
f01005c3:	66 3d cf 07          	cmp    $0x7cf,%ax
f01005c7:	76 5d                	jbe    f0100626 <cga_putc+0x1b6>
		int i;

		memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005c9:	a1 ec 35 11 f0       	mov    0xf01135ec,%eax
f01005ce:	05 a0 00 00 00       	add    $0xa0,%eax
f01005d3:	8b 15 ec 35 11 f0    	mov    0xf01135ec,%edx
f01005d9:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01005e0:	00 
f01005e1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01005e5:	89 14 24             	mov    %edx,(%esp)
f01005e8:	e8 84 2b 00 00       	call   f0103171 <memcpy>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005ed:	c7 45 f4 80 07 00 00 	movl   $0x780,-0xc(%ebp)
f01005f4:	eb 17                	jmp    f010060d <cga_putc+0x19d>
			crt_buf[i] = 0x0700 | ' ';
f01005f6:	8b 15 ec 35 11 f0    	mov    0xf01135ec,%edx
f01005fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01005ff:	01 c0                	add    %eax,%eax
f0100601:	8d 04 02             	lea    (%edx,%eax,1),%eax
f0100604:	66 c7 00 20 07       	movw   $0x720,(%eax)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memcpy(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100609:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
f010060d:	81 7d f4 cf 07 00 00 	cmpl   $0x7cf,-0xc(%ebp)
f0100614:	7e e0                	jle    f01005f6 <cga_putc+0x186>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100616:	0f b7 05 f0 35 11 f0 	movzwl 0xf01135f0,%eax
f010061d:	83 e8 50             	sub    $0x50,%eax
f0100620:	66 a3 f0 35 11 f0    	mov    %ax,0xf01135f0
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100626:	a1 e8 35 11 f0       	mov    0xf01135e8,%eax
f010062b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010062e:	c6 45 fb 0e          	movb   $0xe,-0x5(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100632:	0f b6 45 fb          	movzbl -0x5(%ebp),%eax
f0100636:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100639:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010063a:	0f b7 05 f0 35 11 f0 	movzwl 0xf01135f0,%eax
f0100641:	66 c1 e8 08          	shr    $0x8,%ax
f0100645:	0f b6 d0             	movzbl %al,%edx
f0100648:	a1 e8 35 11 f0       	mov    0xf01135e8,%eax
f010064d:	83 c0 01             	add    $0x1,%eax
f0100650:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100653:	88 55 fa             	mov    %dl,-0x6(%ebp)
f0100656:	0f b6 45 fa          	movzbl -0x6(%ebp),%eax
f010065a:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010065d:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
f010065e:	a1 e8 35 11 f0       	mov    0xf01135e8,%eax
f0100663:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0100666:	c6 45 f9 0f          	movb   $0xf,-0x7(%ebp)
f010066a:	0f b6 45 f9          	movzbl -0x7(%ebp),%eax
f010066e:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100671:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos);
f0100672:	0f b7 05 f0 35 11 f0 	movzwl 0xf01135f0,%eax
f0100679:	0f b6 d0             	movzbl %al,%edx
f010067c:	a1 e8 35 11 f0       	mov    0xf01135e8,%eax
f0100681:	83 c0 01             	add    $0x1,%eax
f0100684:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100687:	88 55 f8             	mov    %dl,-0x8(%ebp)
f010068a:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
f010068e:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100691:	ee                   	out    %al,(%dx)
}
f0100692:	83 c4 34             	add    $0x34,%esp
f0100695:	5b                   	pop    %ebx
f0100696:	5d                   	pop    %ebp
f0100697:	c3                   	ret    

f0100698 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100698:	55                   	push   %ebp
f0100699:	89 e5                	mov    %esp,%ebp
f010069b:	83 ec 38             	sub    $0x38,%esp
f010069e:	c7 45 f4 64 00 00 00 	movl   $0x64,-0xc(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01006a8:	ec                   	in     (%dx),%al
f01006a9:	88 45 fe             	mov    %al,-0x2(%ebp)
	return data;
f01006ac:	0f b6 45 fe          	movzbl -0x2(%ebp),%eax
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01006b0:	0f b6 c0             	movzbl %al,%eax
f01006b3:	83 e0 01             	and    $0x1,%eax
f01006b6:	85 c0                	test   %eax,%eax
f01006b8:	75 0c                	jne    f01006c6 <kbd_proc_data+0x2e>
		return -1;
f01006ba:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f01006c1:	e9 6b 01 00 00       	jmp    f0100831 <kbd_proc_data+0x199>
f01006c6:	c7 45 f0 60 00 00 00 	movl   $0x60,-0x10(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006cd:	8b 55 f0             	mov    -0x10(%ebp),%edx
f01006d0:	ec                   	in     (%dx),%al
f01006d1:	88 45 fd             	mov    %al,-0x3(%ebp)
	return data;
f01006d4:	0f b6 45 fd          	movzbl -0x3(%ebp),%eax

	data = inb(KBDATAP);
f01006d8:	88 45 ff             	mov    %al,-0x1(%ebp)

	if (data == 0xE0) {
f01006db:	80 7d ff e0          	cmpb   $0xe0,-0x1(%ebp)
f01006df:	75 19                	jne    f01006fa <kbd_proc_data+0x62>
		// E0 escape character
		shift |= E0ESC;
f01006e1:	a1 e0 35 11 f0       	mov    0xf01135e0,%eax
f01006e6:	83 c8 40             	or     $0x40,%eax
f01006e9:	a3 e0 35 11 f0       	mov    %eax,0xf01135e0
		return 0;
f01006ee:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01006f5:	e9 37 01 00 00       	jmp    f0100831 <kbd_proc_data+0x199>
	} else if (data & 0x80) {
f01006fa:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
f01006fe:	84 c0                	test   %al,%al
f0100700:	79 55                	jns    f0100757 <kbd_proc_data+0xbf>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100702:	a1 e0 35 11 f0       	mov    0xf01135e0,%eax
f0100707:	83 e0 40             	and    $0x40,%eax
f010070a:	85 c0                	test   %eax,%eax
f010070c:	75 0e                	jne    f010071c <kbd_proc_data+0x84>
f010070e:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
f0100712:	89 c2                	mov    %eax,%edx
f0100714:	83 e2 7f             	and    $0x7f,%edx
f0100717:	88 55 df             	mov    %dl,-0x21(%ebp)
f010071a:	eb 07                	jmp    f0100723 <kbd_proc_data+0x8b>
f010071c:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
f0100720:	88 45 df             	mov    %al,-0x21(%ebp)
f0100723:	0f b6 55 df          	movzbl -0x21(%ebp),%edx
f0100727:	88 55 ff             	mov    %dl,-0x1(%ebp)
		shift &= ~(shiftcode[data] | E0ESC);
f010072a:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
f010072e:	0f b6 80 20 30 11 f0 	movzbl -0xfeecfe0(%eax),%eax
f0100735:	83 c8 40             	or     $0x40,%eax
f0100738:	0f b6 c0             	movzbl %al,%eax
f010073b:	f7 d0                	not    %eax
f010073d:	89 c2                	mov    %eax,%edx
f010073f:	a1 e0 35 11 f0       	mov    0xf01135e0,%eax
f0100744:	21 d0                	and    %edx,%eax
f0100746:	a3 e0 35 11 f0       	mov    %eax,0xf01135e0
		return 0;
f010074b:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100752:	e9 da 00 00 00       	jmp    f0100831 <kbd_proc_data+0x199>
	} else if (shift & E0ESC) {
f0100757:	a1 e0 35 11 f0       	mov    0xf01135e0,%eax
f010075c:	83 e0 40             	and    $0x40,%eax
f010075f:	85 c0                	test   %eax,%eax
f0100761:	74 11                	je     f0100774 <kbd_proc_data+0xdc>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100763:	80 4d ff 80          	orb    $0x80,-0x1(%ebp)
		shift &= ~E0ESC;
f0100767:	a1 e0 35 11 f0       	mov    0xf01135e0,%eax
f010076c:	83 e0 bf             	and    $0xffffffbf,%eax
f010076f:	a3 e0 35 11 f0       	mov    %eax,0xf01135e0
	}

	shift |= shiftcode[data];
f0100774:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
f0100778:	0f b6 80 20 30 11 f0 	movzbl -0xfeecfe0(%eax),%eax
f010077f:	0f b6 d0             	movzbl %al,%edx
f0100782:	a1 e0 35 11 f0       	mov    0xf01135e0,%eax
f0100787:	09 d0                	or     %edx,%eax
f0100789:	a3 e0 35 11 f0       	mov    %eax,0xf01135e0
	shift ^= togglecode[data];
f010078e:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
f0100792:	0f b6 80 20 31 11 f0 	movzbl -0xfeecee0(%eax),%eax
f0100799:	0f b6 d0             	movzbl %al,%edx
f010079c:	a1 e0 35 11 f0       	mov    0xf01135e0,%eax
f01007a1:	31 d0                	xor    %edx,%eax
f01007a3:	a3 e0 35 11 f0       	mov    %eax,0xf01135e0

	c = charcode[shift & (CTL | SHIFT)][data];
f01007a8:	a1 e0 35 11 f0       	mov    0xf01135e0,%eax
f01007ad:	83 e0 03             	and    $0x3,%eax
f01007b0:	8b 14 85 20 35 11 f0 	mov    -0xfeecae0(,%eax,4),%edx
f01007b7:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
f01007bb:	8d 04 02             	lea    (%edx,%eax,1),%eax
f01007be:	0f b6 00             	movzbl (%eax),%eax
f01007c1:	0f b6 c0             	movzbl %al,%eax
f01007c4:	89 45 f8             	mov    %eax,-0x8(%ebp)
	if (shift & CAPSLOCK) {
f01007c7:	a1 e0 35 11 f0       	mov    0xf01135e0,%eax
f01007cc:	83 e0 08             	and    $0x8,%eax
f01007cf:	85 c0                	test   %eax,%eax
f01007d1:	74 22                	je     f01007f5 <kbd_proc_data+0x15d>
		if ('a' <= c && c <= 'z')
f01007d3:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
f01007d7:	7e 0c                	jle    f01007e5 <kbd_proc_data+0x14d>
f01007d9:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
f01007dd:	7f 06                	jg     f01007e5 <kbd_proc_data+0x14d>
			c += 'A' - 'a';
f01007df:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
f01007e3:	eb 10                	jmp    f01007f5 <kbd_proc_data+0x15d>
		else if ('A' <= c && c <= 'Z')
f01007e5:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
f01007e9:	7e 0a                	jle    f01007f5 <kbd_proc_data+0x15d>
f01007eb:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
f01007ef:	7f 04                	jg     f01007f5 <kbd_proc_data+0x15d>
			c += 'a' - 'A';
f01007f1:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01007f5:	a1 e0 35 11 f0       	mov    0xf01135e0,%eax
f01007fa:	f7 d0                	not    %eax
f01007fc:	83 e0 06             	and    $0x6,%eax
f01007ff:	85 c0                	test   %eax,%eax
f0100801:	75 28                	jne    f010082b <kbd_proc_data+0x193>
f0100803:	81 7d f8 e9 00 00 00 	cmpl   $0xe9,-0x8(%ebp)
f010080a:	75 1f                	jne    f010082b <kbd_proc_data+0x193>
		cprintf("Rebooting!\n");
f010080c:	c7 04 24 45 37 10 f0 	movl   $0xf0103745,(%esp)
f0100813:	e8 ff 1a 00 00       	call   f0102317 <cprintf>
f0100818:	c7 45 ec 92 00 00 00 	movl   $0x92,-0x14(%ebp)
f010081f:	c6 45 fc 03          	movb   $0x3,-0x4(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100823:	0f b6 45 fc          	movzbl -0x4(%ebp),%eax
f0100827:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010082a:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010082b:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010082e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100831:	8b 45 d8             	mov    -0x28(%ebp),%eax
}
f0100834:	c9                   	leave  
f0100835:	c3                   	ret    

f0100836 <kbd_intr>:

void
kbd_intr(void)
{
f0100836:	55                   	push   %ebp
f0100837:	89 e5                	mov    %esp,%ebp
f0100839:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010083c:	c7 04 24 98 06 10 f0 	movl   $0xf0100698,(%esp)
f0100843:	e8 07 00 00 00       	call   f010084f <cons_intr>
}
f0100848:	c9                   	leave  
f0100849:	c3                   	ret    

f010084a <kbd_init>:

void
kbd_init(void)
{
f010084a:	55                   	push   %ebp
f010084b:	89 e5                	mov    %esp,%ebp
}
f010084d:	5d                   	pop    %ebp
f010084e:	c3                   	ret    

f010084f <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
f010084f:	55                   	push   %ebp
f0100850:	89 e5                	mov    %esp,%ebp
f0100852:	83 ec 18             	sub    $0x18,%esp
f0100855:	eb 33                	jmp    f010088a <cons_intr+0x3b>
	int c;

	while ((c = (*proc)()) != -1) {
		if (c == 0)
f0100857:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f010085b:	74 2d                	je     f010088a <cons_intr+0x3b>
			continue;
		cons.buf[cons.wpos++] = c;
f010085d:	8b 15 04 38 11 f0    	mov    0xf0113804,%edx
f0100863:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100866:	88 82 00 36 11 f0    	mov    %al,-0xfeeca00(%edx)
f010086c:	8d 42 01             	lea    0x1(%edx),%eax
f010086f:	a3 04 38 11 f0       	mov    %eax,0xf0113804
		if (cons.wpos == CONSBUFSIZE)
f0100874:	a1 04 38 11 f0       	mov    0xf0113804,%eax
f0100879:	3d 00 02 00 00       	cmp    $0x200,%eax
f010087e:	75 0a                	jne    f010088a <cons_intr+0x3b>
			cons.wpos = 0;
f0100880:	c7 05 04 38 11 f0 00 	movl   $0x0,0xf0113804
f0100887:	00 00 00 
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010088a:	8b 45 08             	mov    0x8(%ebp),%eax
f010088d:	ff d0                	call   *%eax
f010088f:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0100892:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
f0100896:	75 bf                	jne    f0100857 <cons_intr+0x8>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100898:	c9                   	leave  
f0100899:	c3                   	ret    

f010089a <cons_getc>:

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f010089a:	55                   	push   %ebp
f010089b:	89 e5                	mov    %esp,%ebp
f010089d:	83 ec 18             	sub    $0x18,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01008a0:	e8 67 f9 ff ff       	call   f010020c <serial_intr>
	kbd_intr();
f01008a5:	e8 8c ff ff ff       	call   f0100836 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01008aa:	8b 15 00 38 11 f0    	mov    0xf0113800,%edx
f01008b0:	a1 04 38 11 f0       	mov    0xf0113804,%eax
f01008b5:	39 c2                	cmp    %eax,%edx
f01008b7:	74 39                	je     f01008f2 <cons_getc+0x58>
		c = cons.buf[cons.rpos++];
f01008b9:	8b 15 00 38 11 f0    	mov    0xf0113800,%edx
f01008bf:	0f b6 82 00 36 11 f0 	movzbl -0xfeeca00(%edx),%eax
f01008c6:	0f b6 c0             	movzbl %al,%eax
f01008c9:	89 45 fc             	mov    %eax,-0x4(%ebp)
f01008cc:	8d 42 01             	lea    0x1(%edx),%eax
f01008cf:	a3 00 38 11 f0       	mov    %eax,0xf0113800
		if (cons.rpos == CONSBUFSIZE)
f01008d4:	a1 00 38 11 f0       	mov    0xf0113800,%eax
f01008d9:	3d 00 02 00 00       	cmp    $0x200,%eax
f01008de:	75 0a                	jne    f01008ea <cons_getc+0x50>
			cons.rpos = 0;
f01008e0:	c7 05 00 38 11 f0 00 	movl   $0x0,0xf0113800
f01008e7:	00 00 00 
		return c;
f01008ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01008ed:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01008f0:	eb 07                	jmp    f01008f9 <cons_getc+0x5f>
	}
	return 0;
f01008f2:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
f01008f9:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
f01008fc:	c9                   	leave  
f01008fd:	c3                   	ret    

f01008fe <cons_putc>:

// output a character to the console
void
cons_putc(int c)
{
f01008fe:	55                   	push   %ebp
f01008ff:	89 e5                	mov    %esp,%ebp
f0100901:	83 ec 08             	sub    $0x8,%esp
	lpt_putc(c);
f0100904:	8b 45 08             	mov    0x8(%ebp),%eax
f0100907:	89 04 24             	mov    %eax,(%esp)
f010090a:	e8 22 fa ff ff       	call   f0100331 <lpt_putc>
	cga_putc(c);
f010090f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100912:	89 04 24             	mov    %eax,(%esp)
f0100915:	e8 56 fb ff ff       	call   f0100470 <cga_putc>
}
f010091a:	c9                   	leave  
f010091b:	c3                   	ret    

f010091c <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010091c:	55                   	push   %ebp
f010091d:	89 e5                	mov    %esp,%ebp
f010091f:	83 ec 08             	sub    $0x8,%esp
	cga_init();
f0100922:	e8 81 fa ff ff       	call   f01003a8 <cga_init>
	kbd_init();
f0100927:	e8 1e ff ff ff       	call   f010084a <kbd_init>
	serial_init();
f010092c:	e8 f8 f8 ff ff       	call   f0100229 <serial_init>

	if (!serial_exists)
f0100931:	a1 e4 35 11 f0       	mov    0xf01135e4,%eax
f0100936:	85 c0                	test   %eax,%eax
f0100938:	75 0c                	jne    f0100946 <cons_init+0x2a>
		cprintf("Serial port does not exist!\n");
f010093a:	c7 04 24 51 37 10 f0 	movl   $0xf0103751,(%esp)
f0100941:	e8 d1 19 00 00       	call   f0102317 <cprintf>
}
f0100946:	c9                   	leave  
f0100947:	c3                   	ret    

f0100948 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100948:	55                   	push   %ebp
f0100949:	89 e5                	mov    %esp,%ebp
f010094b:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010094e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100951:	89 04 24             	mov    %eax,(%esp)
f0100954:	e8 a5 ff ff ff       	call   f01008fe <cons_putc>
}
f0100959:	c9                   	leave  
f010095a:	c3                   	ret    

f010095b <getchar>:

int
getchar(void)
{
f010095b:	55                   	push   %ebp
f010095c:	89 e5                	mov    %esp,%ebp
f010095e:	83 ec 18             	sub    $0x18,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100961:	e8 34 ff ff ff       	call   f010089a <cons_getc>
f0100966:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0100969:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f010096d:	74 f2                	je     f0100961 <getchar+0x6>
		/* do nothing */;
	return c;
f010096f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0100972:	c9                   	leave  
f0100973:	c3                   	ret    

f0100974 <iscons>:

int
iscons(int fdnum)
{
f0100974:	55                   	push   %ebp
f0100975:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
f0100977:	b8 01 00 00 00       	mov    $0x1,%eax
}
f010097c:	5d                   	pop    %ebp
f010097d:	c3                   	ret    
	...

f0100980 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100980:	55                   	push   %ebp
f0100981:	89 e5                	mov    %esp,%ebp
f0100983:	83 ec 28             	sub    $0x28,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100986:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f010098d:	eb 3c                	jmp    f01009cb <mon_help+0x4b>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010098f:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100992:	89 d0                	mov    %edx,%eax
f0100994:	01 c0                	add    %eax,%eax
f0100996:	01 d0                	add    %edx,%eax
f0100998:	c1 e0 02             	shl    $0x2,%eax
f010099b:	8b 88 44 35 11 f0    	mov    -0xfeecabc(%eax),%ecx
f01009a1:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01009a4:	89 d0                	mov    %edx,%eax
f01009a6:	01 c0                	add    %eax,%eax
f01009a8:	01 d0                	add    %edx,%eax
f01009aa:	c1 e0 02             	shl    $0x2,%eax
f01009ad:	8b 80 40 35 11 f0    	mov    -0xfeecac0(%eax),%eax
f01009b3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01009b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009bb:	c7 04 24 e2 37 10 f0 	movl   $0xf01037e2,(%esp)
f01009c2:	e8 50 19 00 00       	call   f0102317 <cprintf>
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f01009c7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f01009cb:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01009ce:	83 f8 02             	cmp    $0x2,%eax
f01009d1:	76 bc                	jbe    f010098f <mon_help+0xf>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
f01009d3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01009d8:	c9                   	leave  
f01009d9:	c3                   	ret    

f01009da <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01009da:	55                   	push   %ebp
f01009db:	89 e5                	mov    %esp,%ebp
f01009dd:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01009e0:	c7 04 24 eb 37 10 f0 	movl   $0xf01037eb,(%esp)
f01009e7:	e8 2b 19 00 00       	call   f0102317 <cprintf>
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
f01009ec:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01009f3:	00 
f01009f4:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01009fb:	f0 
f01009fc:	c7 04 24 04 38 10 f0 	movl   $0xf0103804,(%esp)
f0100a03:	e8 0f 19 00 00       	call   f0102317 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100a08:	c7 44 24 08 a5 36 10 	movl   $0x1036a5,0x8(%esp)
f0100a0f:	00 
f0100a10:	c7 44 24 04 a5 36 10 	movl   $0xf01036a5,0x4(%esp)
f0100a17:	f0 
f0100a18:	c7 04 24 28 38 10 f0 	movl   $0xf0103828,(%esp)
f0100a1f:	e8 f3 18 00 00       	call   f0102317 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100a24:	c7 44 24 08 b8 35 11 	movl   $0x1135b8,0x8(%esp)
f0100a2b:	00 
f0100a2c:	c7 44 24 04 b8 35 11 	movl   $0xf01135b8,0x4(%esp)
f0100a33:	f0 
f0100a34:	c7 04 24 4c 38 10 f0 	movl   $0xf010384c,(%esp)
f0100a3b:	e8 d7 18 00 00       	call   f0102317 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100a40:	c7 44 24 08 30 3c 11 	movl   $0x113c30,0x8(%esp)
f0100a47:	00 
f0100a48:	c7 44 24 04 30 3c 11 	movl   $0xf0113c30,0x4(%esp)
f0100a4f:	f0 
f0100a50:	c7 04 24 70 38 10 f0 	movl   $0xf0103870,(%esp)
f0100a57:	e8 bb 18 00 00       	call   f0102317 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100a5c:	ba 0c 00 10 f0       	mov    $0xf010000c,%edx
f0100a61:	b8 ff 03 00 00       	mov    $0x3ff,%eax
f0100a66:	29 d0                	sub    %edx,%eax
f0100a68:	05 30 3c 11 f0       	add    $0xf0113c30,%eax
f0100a6d:	89 c2                	mov    %eax,%edx
f0100a6f:	89 d0                	mov    %edx,%eax
f0100a71:	c1 f8 1f             	sar    $0x1f,%eax
f0100a74:	c1 e8 16             	shr    $0x16,%eax
f0100a77:	01 d0                	add    %edx,%eax
f0100a79:	c1 f8 0a             	sar    $0xa,%eax
f0100a7c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a80:	c7 04 24 94 38 10 f0 	movl   $0xf0103894,(%esp)
f0100a87:	e8 8b 18 00 00       	call   f0102317 <cprintf>
		(end-_start+1023)/1024);
	return 0;
f0100a8c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100a91:	c9                   	leave  
f0100a92:	c3                   	ret    

f0100a93 <mon_backtrace>:

void test_backtrace(int x);

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100a93:	55                   	push   %ebp
f0100a94:	89 e5                	mov    %esp,%ebp
f0100a96:	83 ec 04             	sub    $0x4,%esp
	// Your code here.

}
f0100a99:	c9                   	leave  
f0100a9a:	c3                   	ret    

f0100a9b <runcmd>:
#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
f0100a9b:	55                   	push   %ebp
f0100a9c:	89 e5                	mov    %esp,%ebp
f0100a9e:	83 ec 68             	sub    $0x68,%esp
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100aa1:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	argv[argc] = 0;
f0100aa8:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100aab:	c7 44 85 b8 00 00 00 	movl   $0x0,-0x48(%ebp,%eax,4)
f0100ab2:	00 
f0100ab3:	eb 0a                	jmp    f0100abf <runcmd+0x24>
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100ab5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ab8:	c6 00 00             	movb   $0x0,(%eax)
f0100abb:	83 45 08 01          	addl   $0x1,0x8(%ebp)
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100abf:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ac2:	0f b6 00             	movzbl (%eax),%eax
f0100ac5:	84 c0                	test   %al,%al
f0100ac7:	74 1d                	je     f0100ae6 <runcmd+0x4b>
f0100ac9:	8b 45 08             	mov    0x8(%ebp),%eax
f0100acc:	0f b6 00             	movzbl (%eax),%eax
f0100acf:	0f be c0             	movsbl %al,%eax
f0100ad2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ad6:	c7 04 24 be 38 10 f0 	movl   $0xf01038be,(%esp)
f0100add:	e8 f7 25 00 00       	call   f01030d9 <strchr>
f0100ae2:	85 c0                	test   %eax,%eax
f0100ae4:	75 cf                	jne    f0100ab5 <runcmd+0x1a>
			*buf++ = 0;
		if (*buf == 0)
f0100ae6:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ae9:	0f b6 00             	movzbl (%eax),%eax
f0100aec:	84 c0                	test   %al,%al
f0100aee:	74 66                	je     f0100b56 <runcmd+0xbb>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100af0:	83 7d fc 0f          	cmpl   $0xf,-0x4(%ebp)
f0100af4:	75 20                	jne    f0100b16 <runcmd+0x7b>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100af6:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100afd:	00 
f0100afe:	c7 04 24 c3 38 10 f0 	movl   $0xf01038c3,(%esp)
f0100b05:	e8 0d 18 00 00       	call   f0102317 <cprintf>
			return 0;
f0100b0a:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
f0100b11:	e9 de 00 00 00       	jmp    f0100bf4 <runcmd+0x159>
		}
		argv[argc++] = buf;
f0100b16:	8b 55 fc             	mov    -0x4(%ebp),%edx
f0100b19:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b1c:	89 44 95 b8          	mov    %eax,-0x48(%ebp,%edx,4)
f0100b20:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f0100b24:	eb 04                	jmp    f0100b2a <runcmd+0x8f>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100b26:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b2a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b2d:	0f b6 00             	movzbl (%eax),%eax
f0100b30:	84 c0                	test   %al,%al
f0100b32:	74 8b                	je     f0100abf <runcmd+0x24>
f0100b34:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b37:	0f b6 00             	movzbl (%eax),%eax
f0100b3a:	0f be c0             	movsbl %al,%eax
f0100b3d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b41:	c7 04 24 be 38 10 f0 	movl   $0xf01038be,(%esp)
f0100b48:	e8 8c 25 00 00       	call   f01030d9 <strchr>
f0100b4d:	85 c0                	test   %eax,%eax
f0100b4f:	74 d5                	je     f0100b26 <runcmd+0x8b>
f0100b51:	e9 69 ff ff ff       	jmp    f0100abf <runcmd+0x24>
			buf++;
	}
	argv[argc] = 0;
f0100b56:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100b59:	c7 44 85 b8 00 00 00 	movl   $0x0,-0x48(%ebp,%eax,4)
f0100b60:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100b61:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f0100b65:	75 0c                	jne    f0100b73 <runcmd+0xd8>
		return 0;
f0100b67:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
f0100b6e:	e9 81 00 00 00       	jmp    f0100bf4 <runcmd+0x159>
	for (i = 0; i < NCOMMANDS; i++) {
f0100b73:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
f0100b7a:	eb 56                	jmp    f0100bd2 <runcmd+0x137>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100b7c:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0100b7f:	89 d0                	mov    %edx,%eax
f0100b81:	01 c0                	add    %eax,%eax
f0100b83:	01 d0                	add    %edx,%eax
f0100b85:	c1 e0 02             	shl    $0x2,%eax
f0100b88:	8b 80 40 35 11 f0    	mov    -0xfeecac0(%eax),%eax
f0100b8e:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0100b91:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b95:	89 14 24             	mov    %edx,(%esp)
f0100b98:	e8 9a 24 00 00       	call   f0103037 <strcmp>
f0100b9d:	85 c0                	test   %eax,%eax
f0100b9f:	75 2d                	jne    f0100bce <runcmd+0x133>
			return commands[i].func(argc, argv, tf);
f0100ba1:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0100ba4:	89 d0                	mov    %edx,%eax
f0100ba6:	01 c0                	add    %eax,%eax
f0100ba8:	01 d0                	add    %edx,%eax
f0100baa:	c1 e0 02             	shl    $0x2,%eax
f0100bad:	8b 90 48 35 11 f0    	mov    -0xfeecab8(%eax),%edx
f0100bb3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bb6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100bba:	8d 45 b8             	lea    -0x48(%ebp),%eax
f0100bbd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bc1:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100bc4:	89 04 24             	mov    %eax,(%esp)
f0100bc7:	ff d2                	call   *%edx
f0100bc9:	89 45 ac             	mov    %eax,-0x54(%ebp)
f0100bcc:	eb 26                	jmp    f0100bf4 <runcmd+0x159>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100bce:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
f0100bd2:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100bd5:	83 f8 02             	cmp    $0x2,%eax
f0100bd8:	76 a2                	jbe    f0100b7c <runcmd+0xe1>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100bda:	8b 45 b8             	mov    -0x48(%ebp),%eax
f0100bdd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100be1:	c7 04 24 e0 38 10 f0 	movl   $0xf01038e0,(%esp)
f0100be8:	e8 2a 17 00 00       	call   f0102317 <cprintf>
	return 0;
f0100bed:	c7 45 ac 00 00 00 00 	movl   $0x0,-0x54(%ebp)
f0100bf4:	8b 45 ac             	mov    -0x54(%ebp),%eax
}
f0100bf7:	c9                   	leave  
f0100bf8:	c3                   	ret    

f0100bf9 <monitor>:

void
monitor(struct Trapframe *tf)
{
f0100bf9:	55                   	push   %ebp
f0100bfa:	89 e5                	mov    %esp,%ebp
f0100bfc:	83 ec 18             	sub    $0x18,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100bff:	c7 04 24 f8 38 10 f0 	movl   $0xf01038f8,(%esp)
f0100c06:	e8 0c 17 00 00       	call   f0102317 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100c0b:	c7 04 24 1c 39 10 f0 	movl   $0xf010391c,(%esp)
f0100c12:	e8 00 17 00 00       	call   f0102317 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100c17:	c7 04 24 41 39 10 f0 	movl   $0xf0103941,(%esp)
f0100c1e:	e8 05 22 00 00       	call   f0102e28 <readline>
f0100c23:	89 45 fc             	mov    %eax,-0x4(%ebp)
		if (buf != NULL)
f0100c26:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f0100c2a:	74 eb                	je     f0100c17 <monitor+0x1e>
			if (runcmd(buf, tf) < 0)
f0100c2c:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c2f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c33:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100c36:	89 04 24             	mov    %eax,(%esp)
f0100c39:	e8 5d fe ff ff       	call   f0100a9b <runcmd>
f0100c3e:	85 c0                	test   %eax,%eax
f0100c40:	79 d5                	jns    f0100c17 <monitor+0x1e>
				break;
	}
}
f0100c42:	c9                   	leave  
f0100c43:	c3                   	ret    

f0100c44 <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f0100c44:	55                   	push   %ebp
f0100c45:	89 e5                	mov    %esp,%ebp
f0100c47:	83 ec 04             	sub    $0x4,%esp
  __asm __volatile("movl 4(%ebp), %eax");
f0100c4a:	8b 45 04             	mov    0x4(%ebp),%eax
}
f0100c4d:	c9                   	leave  
f0100c4e:	c3                   	ret    
	...

f0100c50 <nvram_read>:
	0, sizeof(gdt) - 1, (unsigned long) gdt,
};

static int
nvram_read(int r)
{
f0100c50:	55                   	push   %ebp
f0100c51:	89 e5                	mov    %esp,%ebp
f0100c53:	53                   	push   %ebx
f0100c54:	83 ec 04             	sub    $0x4,%esp
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100c57:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c5a:	89 04 24             	mov    %eax,(%esp)
f0100c5d:	e8 fa 15 00 00       	call   f010225c <mc146818_read>
f0100c62:	89 c3                	mov    %eax,%ebx
f0100c64:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c67:	83 c0 01             	add    $0x1,%eax
f0100c6a:	89 04 24             	mov    %eax,(%esp)
f0100c6d:	e8 ea 15 00 00       	call   f010225c <mc146818_read>
f0100c72:	c1 e0 08             	shl    $0x8,%eax
f0100c75:	09 d8                	or     %ebx,%eax
}
f0100c77:	83 c4 04             	add    $0x4,%esp
f0100c7a:	5b                   	pop    %ebx
f0100c7b:	5d                   	pop    %ebp
f0100c7c:	c3                   	ret    

f0100c7d <i386_detect_memory>:

void
i386_detect_memory(void)
{
f0100c7d:	55                   	push   %ebp
f0100c7e:	89 e5                	mov    %esp,%ebp
f0100c80:	83 ec 28             	sub    $0x28,%esp
	// CMOS tells us how many kilobytes there are
	basemem = ROUNDDOWN(nvram_read(NVRAM_BASELO)*1024, PGSIZE);
f0100c83:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f0100c8a:	e8 c1 ff ff ff       	call   f0100c50 <nvram_read>
f0100c8f:	c1 e0 0a             	shl    $0xa,%eax
f0100c92:	89 45 fc             	mov    %eax,-0x4(%ebp)
f0100c95:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100c98:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c9d:	a3 0c 38 11 f0       	mov    %eax,0xf011380c
	extmem = ROUNDDOWN(nvram_read(NVRAM_EXTLO)*1024, PGSIZE);
f0100ca2:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0100ca9:	e8 a2 ff ff ff       	call   f0100c50 <nvram_read>
f0100cae:	c1 e0 0a             	shl    $0xa,%eax
f0100cb1:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0100cb4:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100cb7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100cbc:	a3 10 38 11 f0       	mov    %eax,0xf0113810

	// Calculate the maxmium physical address based on whether
	// or not there is any extended memory.  See comment in ../inc/mmu.h.
	if (extmem)
f0100cc1:	a1 10 38 11 f0       	mov    0xf0113810,%eax
f0100cc6:	85 c0                	test   %eax,%eax
f0100cc8:	74 11                	je     f0100cdb <i386_detect_memory+0x5e>
		maxpa = EXTPHYSMEM + extmem;
f0100cca:	a1 10 38 11 f0       	mov    0xf0113810,%eax
f0100ccf:	05 00 00 10 00       	add    $0x100000,%eax
f0100cd4:	a3 08 38 11 f0       	mov    %eax,0xf0113808
f0100cd9:	eb 0a                	jmp    f0100ce5 <i386_detect_memory+0x68>
	else
		maxpa = basemem;
f0100cdb:	a1 0c 38 11 f0       	mov    0xf011380c,%eax
f0100ce0:	a3 08 38 11 f0       	mov    %eax,0xf0113808

	npage = maxpa / PGSIZE;
f0100ce5:	a1 08 38 11 f0       	mov    0xf0113808,%eax
f0100cea:	c1 e8 0c             	shr    $0xc,%eax
f0100ced:	a3 20 3c 11 f0       	mov    %eax,0xf0113c20

	cprintf("Physical memory: %dK available, ", (int)(maxpa/1024));
f0100cf2:	a1 08 38 11 f0       	mov    0xf0113808,%eax
f0100cf7:	c1 e8 0a             	shr    $0xa,%eax
f0100cfa:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cfe:	c7 04 24 48 39 10 f0 	movl   $0xf0103948,(%esp)
f0100d05:	e8 0d 16 00 00       	call   f0102317 <cprintf>
	cprintf("base = %dK, extended = %dK\n", (int)(basemem/1024), (int)(extmem/1024));
f0100d0a:	a1 10 38 11 f0       	mov    0xf0113810,%eax
f0100d0f:	c1 e8 0a             	shr    $0xa,%eax
f0100d12:	89 c2                	mov    %eax,%edx
f0100d14:	a1 0c 38 11 f0       	mov    0xf011380c,%eax
f0100d19:	c1 e8 0a             	shr    $0xa,%eax
f0100d1c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d20:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d24:	c7 04 24 69 39 10 f0 	movl   $0xf0103969,(%esp)
f0100d2b:	e8 e7 15 00 00       	call   f0102317 <cprintf>
}
f0100d30:	c9                   	leave  
f0100d31:	c3                   	ret    

f0100d32 <boot_alloc>:
// This function may ONLY be used during initialization,
// before the page_free_list has been set up.
// 
static void*
boot_alloc(uint32_t n, uint32_t align)
{
f0100d32:	55                   	push   %ebp
f0100d33:	89 e5                	mov    %esp,%ebp
f0100d35:	83 ec 18             	sub    $0x18,%esp
	// Initialize boot_freemem if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment -
	// i.e., the first virtual address that the linker
	// did _not_ assign to any kernel code or global variables.
	if (boot_freemem == 0)
f0100d38:	a1 14 38 11 f0       	mov    0xf0113814,%eax
f0100d3d:	85 c0                	test   %eax,%eax
f0100d3f:	75 0a                	jne    f0100d4b <boot_alloc+0x19>
		boot_freemem = end;
f0100d41:	c7 05 14 38 11 f0 30 	movl   $0xf0113c30,0xf0113814
f0100d48:	3c 11 f0 
	//	Step 1: round boot_freemem up to be aligned properly
	//	Step 2: save current value of boot_freemem as allocated chunk
	//	Step 3: increase boot_freemem to record allocation
	//	Step 4: return allocated chunk

	boot_freemem = ROUNDUP(boot_freemem, align);
f0100d4b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d4e:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0100d51:	8b 15 14 38 11 f0    	mov    0xf0113814,%edx
f0100d57:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100d5a:	83 e8 01             	sub    $0x1,%eax
f0100d5d:	8d 04 02             	lea    (%edx,%eax,1),%eax
f0100d60:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100d63:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100d66:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0100d69:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100d6c:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d71:	f7 75 f8             	divl   -0x8(%ebp)
f0100d74:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100d77:	29 d0                	sub    %edx,%eax
f0100d79:	a3 14 38 11 f0       	mov    %eax,0xf0113814
	v = (void*)boot_freemem;
f0100d7e:	a1 14 38 11 f0       	mov    0xf0113814,%eax
f0100d83:	89 45 fc             	mov    %eax,-0x4(%ebp)
	boot_freemem += n;
f0100d86:	a1 14 38 11 f0       	mov    0xf0113814,%eax
f0100d8b:	03 45 08             	add    0x8(%ebp),%eax
f0100d8e:	a3 14 38 11 f0       	mov    %eax,0xf0113814
	return v;
f0100d93:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0100d96:	c9                   	leave  
f0100d97:	c3                   	ret    

f0100d98 <boot_pgdir_walk>:
// This function may ONLY be used during initialization,
// before the page_free_list has been set up.
//
static pte_t*
boot_pgdir_walk(pde_t *pgdir, uintptr_t la, int create)
{
f0100d98:	55                   	push   %ebp
f0100d99:	89 e5                	mov    %esp,%ebp
f0100d9b:	83 ec 38             	sub    $0x38,%esp
	// Get the PDE for the LA
	pde_t *pde = &pgdir[PDX(la)];
f0100d9e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100da1:	c1 e8 16             	shr    $0x16,%eax
f0100da4:	c1 e0 02             	shl    $0x2,%eax
f0100da7:	03 45 08             	add    0x8(%ebp),%eax
f0100daa:	89 45 fc             	mov    %eax,-0x4(%ebp)

	// If the PT is present
	if (*pde & PTE_P) {
f0100dad:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100db0:	8b 00                	mov    (%eax),%eax
f0100db2:	83 e0 01             	and    $0x1,%eax
f0100db5:	84 c0                	test   %al,%al
f0100db7:	74 65                	je     f0100e1e <boot_pgdir_walk+0x86>
		// Return a pointer to the PTE
		return (pte_t*)KADDR(PTE_ADDR(*pde)) + PTX(la);
f0100db9:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100dbc:	8b 00                	mov    (%eax),%eax
f0100dbe:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100dc3:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0100dc6:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100dc9:	c1 e8 0c             	shr    $0xc,%eax
f0100dcc:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100dcf:	a1 20 3c 11 f0       	mov    0xf0113c20,%eax
f0100dd4:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f0100dd7:	72 23                	jb     f0100dfc <boot_pgdir_walk+0x64>
f0100dd9:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100ddc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100de0:	c7 44 24 08 88 39 10 	movl   $0xf0103988,0x8(%esp)
f0100de7:	f0 
f0100de8:	c7 44 24 04 9e 00 00 	movl   $0x9e,0x4(%esp)
f0100def:	00 
f0100df0:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0100df7:	e8 19 f3 ff ff       	call   f0100115 <_panic>
f0100dfc:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100dff:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e04:	89 c2                	mov    %eax,%edx
f0100e06:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e09:	c1 e8 0c             	shr    $0xc,%eax
f0100e0c:	25 ff 03 00 00       	and    $0x3ff,%eax
f0100e11:	c1 e0 02             	shl    $0x2,%eax
f0100e14:	01 c2                	add    %eax,%edx
f0100e16:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100e19:	e9 aa 00 00 00       	jmp    f0100ec8 <boot_pgdir_walk+0x130>
	} else {
		// If we need to create the PT
		if (create) {
f0100e1e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100e22:	0f 84 99 00 00 00    	je     f0100ec1 <boot_pgdir_walk+0x129>
			// Allocate the PT
			pte_t *pt = (pte_t*)boot_alloc(PGSIZE, PGSIZE);
f0100e28:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0100e2f:	00 
f0100e30:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
f0100e37:	e8 f6 fe ff ff       	call   f0100d32 <boot_alloc>
f0100e3c:	89 45 f0             	mov    %eax,-0x10(%ebp)
			memset(pt, 0, PGSIZE);
f0100e3f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100e46:	00 
f0100e47:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100e4e:	00 
f0100e4f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100e52:	89 04 24             	mov    %eax,(%esp)
f0100e55:	e8 e6 22 00 00       	call   f0103140 <memset>
			void *ppt = (void*)PADDR(pt);
f0100e5a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100e5d:	89 45 e8             	mov    %eax,-0x18(%ebp)
f0100e60:	81 7d e8 ff ff ff ef 	cmpl   $0xefffffff,-0x18(%ebp)
f0100e67:	77 23                	ja     f0100e8c <boot_pgdir_walk+0xf4>
f0100e69:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100e6c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e70:	c7 44 24 08 b8 39 10 	movl   $0xf01039b8,0x8(%esp)
f0100e77:	f0 
f0100e78:	c7 44 24 04 a5 00 00 	movl   $0xa5,0x4(%esp)
f0100e7f:	00 
f0100e80:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0100e87:	e8 89 f2 ff ff       	call   f0100115 <_panic>
f0100e8c:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100e8f:	05 00 00 00 10       	add    $0x10000000,%eax
f0100e94:	89 45 ec             	mov    %eax,-0x14(%ebp)
			*pde = PTE_ADDR(ppt)|PTE_W|PTE_P;
f0100e97:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100e9a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100e9f:	89 c2                	mov    %eax,%edx
f0100ea1:	83 ca 03             	or     $0x3,%edx
f0100ea4:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100ea7:	89 10                	mov    %edx,(%eax)
			return (pt + PTX(la));
f0100ea9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100eac:	c1 e8 0c             	shr    $0xc,%eax
f0100eaf:	25 ff 03 00 00       	and    $0x3ff,%eax
f0100eb4:	c1 e0 02             	shl    $0x2,%eax
f0100eb7:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100eba:	01 c2                	add    %eax,%edx
f0100ebc:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100ebf:	eb 07                	jmp    f0100ec8 <boot_pgdir_walk+0x130>
		} else {
			return (pte_t*)0;
f0100ec1:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100ec8:	8b 45 dc             	mov    -0x24(%ebp),%eax
		}
	}
}
f0100ecb:	c9                   	leave  
f0100ecc:	c3                   	ret    

f0100ecd <boot_map_segment>:
// This function may ONLY be used during initialization,
// before the page_free_list has been set up.
//
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, physaddr_t pa, int perm)
{
f0100ecd:	55                   	push   %ebp
f0100ece:	89 e5                	mov    %esp,%ebp
f0100ed0:	83 ec 28             	sub    $0x28,%esp
	int i;
	
	for (i = 0; i < size / PGSIZE; i++) {
f0100ed3:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0100eda:	eb 47                	jmp    f0100f23 <boot_map_segment+0x56>
		pte_t *pte = boot_pgdir_walk(pgdir, la + i * PGSIZE, 1);
f0100edc:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100edf:	c1 e0 0c             	shl    $0xc,%eax
f0100ee2:	03 45 0c             	add    0xc(%ebp),%eax
f0100ee5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100eec:	00 
f0100eed:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ef1:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ef4:	89 04 24             	mov    %eax,(%esp)
f0100ef7:	e8 9c fe ff ff       	call   f0100d98 <boot_pgdir_walk>
f0100efc:	89 45 f8             	mov    %eax,-0x8(%ebp)
		*pte = PTE_ADDR(pa + i * PGSIZE)|perm|PTE_P;
f0100eff:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100f02:	c1 e0 0c             	shl    $0xc,%eax
f0100f05:	03 45 14             	add    0x14(%ebp),%eax
f0100f08:	89 c2                	mov    %eax,%edx
f0100f0a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100f10:	8b 45 18             	mov    0x18(%ebp),%eax
f0100f13:	09 d0                	or     %edx,%eax
f0100f15:	89 c2                	mov    %eax,%edx
f0100f17:	83 ca 01             	or     $0x1,%edx
f0100f1a:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0100f1d:	89 10                	mov    %edx,(%eax)
static void
boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size, physaddr_t pa, int perm)
{
	int i;
	
	for (i = 0; i < size / PGSIZE; i++) {
f0100f1f:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f0100f23:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100f26:	8b 55 10             	mov    0x10(%ebp),%edx
f0100f29:	c1 ea 0c             	shr    $0xc,%edx
f0100f2c:	39 d0                	cmp    %edx,%eax
f0100f2e:	72 ac                	jb     f0100edc <boot_map_segment+0xf>
		pte_t *pte = boot_pgdir_walk(pgdir, la + i * PGSIZE, 1);
		*pte = PTE_ADDR(pa + i * PGSIZE)|perm|PTE_P;
	}
}
f0100f30:	c9                   	leave  
f0100f31:	c3                   	ret    

f0100f32 <i386_vm_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read (or write). 
void
i386_vm_init(void)
{
f0100f32:	55                   	push   %ebp
f0100f33:	89 e5                	mov    %esp,%ebp
f0100f35:	83 ec 68             	sub    $0x68,%esp
	// Remove this line when you're ready to test this function.
	//~ panic("i386_vm_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	pgdir = boot_alloc(PGSIZE, PGSIZE);
f0100f38:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0100f3f:	00 
f0100f40:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
f0100f47:	e8 e6 fd ff ff       	call   f0100d32 <boot_alloc>
f0100f4c:	89 45 fc             	mov    %eax,-0x4(%ebp)
	memset(pgdir, 0, PGSIZE);
f0100f4f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f56:	00 
f0100f57:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f5e:	00 
f0100f5f:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100f62:	89 04 24             	mov    %eax,(%esp)
f0100f65:	e8 d6 21 00 00       	call   f0103140 <memset>
	boot_pgdir = pgdir;
f0100f6a:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100f6d:	a3 28 3c 11 f0       	mov    %eax,0xf0113c28
	boot_cr3 = PADDR(pgdir);
f0100f72:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100f75:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100f78:	81 7d f0 ff ff ff ef 	cmpl   $0xefffffff,-0x10(%ebp)
f0100f7f:	77 23                	ja     f0100fa4 <i386_vm_init+0x72>
f0100f81:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f84:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f88:	c7 44 24 08 b8 39 10 	movl   $0xf01039b8,0x8(%esp)
f0100f8f:	f0 
f0100f90:	c7 44 24 04 dc 00 00 	movl   $0xdc,0x4(%esp)
f0100f97:	00 
f0100f98:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0100f9f:	e8 71 f1 ff ff       	call   f0100115 <_panic>
f0100fa4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100fa7:	05 00 00 00 10       	add    $0x10000000,%eax
f0100fac:	a3 24 3c 11 f0       	mov    %eax,0xf0113c24
	// a virtual page table at virtual address VPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel RW, user NONE
	pgdir[PDX(VPT)] = PADDR(pgdir)|PTE_W|PTE_P;
f0100fb1:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100fb4:	05 fc 0e 00 00       	add    $0xefc,%eax
f0100fb9:	89 45 b8             	mov    %eax,-0x48(%ebp)
f0100fbc:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0100fbf:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100fc2:	81 7d ec ff ff ff ef 	cmpl   $0xefffffff,-0x14(%ebp)
f0100fc9:	77 23                	ja     f0100fee <i386_vm_init+0xbc>
f0100fcb:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100fce:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fd2:	c7 44 24 08 b8 39 10 	movl   $0xf01039b8,0x8(%esp)
f0100fd9:	f0 
f0100fda:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
f0100fe1:	00 
f0100fe2:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0100fe9:	e8 27 f1 ff ff       	call   f0100115 <_panic>
f0100fee:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100ff1:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ff6:	83 c8 03             	or     $0x3,%eax
f0100ff9:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0100ffc:	89 02                	mov    %eax,(%edx)

	// same for UVPT
	// Permissions: kernel R, user R 
	pgdir[PDX(UVPT)] = PADDR(pgdir)|PTE_U|PTE_P;
f0100ffe:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101001:	05 f4 0e 00 00       	add    $0xef4,%eax
f0101006:	89 45 bc             	mov    %eax,-0x44(%ebp)
f0101009:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010100c:	89 45 e8             	mov    %eax,-0x18(%ebp)
f010100f:	81 7d e8 ff ff ff ef 	cmpl   $0xefffffff,-0x18(%ebp)
f0101016:	77 23                	ja     f010103b <i386_vm_init+0x109>
f0101018:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010101b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010101f:	c7 44 24 08 b8 39 10 	movl   $0xf01039b8,0x8(%esp)
f0101026:	f0 
f0101027:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
f010102e:	00 
f010102f:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101036:	e8 da f0 ff ff       	call   f0100115 <_panic>
f010103b:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010103e:	05 00 00 00 10       	add    $0x10000000,%eax
f0101043:	83 c8 05             	or     $0x5,%eax
f0101046:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0101049:	89 02                	mov    %eax,(%edx)
	//     * [KSTACKTOP-KSTKSIZE, KSTACKTOP) -- backed by physical memory
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed => faults
	//     Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_segment(pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W); 
f010104b:	c7 45 e4 00 b0 10 f0 	movl   $0xf010b000,-0x1c(%ebp)
f0101052:	81 7d e4 ff ff ff ef 	cmpl   $0xefffffff,-0x1c(%ebp)
f0101059:	77 23                	ja     f010107e <i386_vm_init+0x14c>
f010105b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010105e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101062:	c7 44 24 08 b8 39 10 	movl   $0xf01039b8,0x8(%esp)
f0101069:	f0 
f010106a:	c7 44 24 04 f4 00 00 	movl   $0xf4,0x4(%esp)
f0101071:	00 
f0101072:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101079:	e8 97 f0 ff ff       	call   f0100115 <_panic>
f010107e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101081:	05 00 00 00 10       	add    $0x10000000,%eax
f0101086:	c7 44 24 10 02 00 00 	movl   $0x2,0x10(%esp)
f010108d:	00 
f010108e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101092:	c7 44 24 08 00 80 00 	movl   $0x8000,0x8(%esp)
f0101099:	00 
f010109a:	c7 44 24 04 00 80 bf 	movl   $0xefbf8000,0x4(%esp)
f01010a1:	ef 
f01010a2:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01010a5:	89 04 24             	mov    %eax,(%esp)
f01010a8:	e8 20 fe ff ff       	call   f0100ecd <boot_map_segment>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:

	boot_map_segment(pgdir, KERNBASE, 0xFFFFFFFF - KERNBASE + 1, 0, PTE_W);
f01010ad:	c7 44 24 10 02 00 00 	movl   $0x2,0x10(%esp)
f01010b4:	00 
f01010b5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01010bc:	00 
f01010bd:	c7 44 24 08 00 00 00 	movl   $0x10000000,0x8(%esp)
f01010c4:	10 
f01010c5:	c7 44 24 04 00 00 00 	movl   $0xf0000000,0x4(%esp)
f01010cc:	f0 
f01010cd:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01010d0:	89 04 24             	mov    %eax,(%esp)
f01010d3:	e8 f5 fd ff ff       	call   f0100ecd <boot_map_segment>
	// Permissions:
	//    - pages -- kernel RW, user NONE
	//    - the image mapped at UPAGES  -- kernel R, user R
	// Your code goes here: 

	size_t spages = ROUNDUP(npage * sizeof(struct Page), PGSIZE);
f01010d8:	c7 45 dc 00 10 00 00 	movl   $0x1000,-0x24(%ebp)
f01010df:	8b 15 20 3c 11 f0    	mov    0xf0113c20,%edx
f01010e5:	89 d0                	mov    %edx,%eax
f01010e7:	01 c0                	add    %eax,%eax
f01010e9:	01 d0                	add    %edx,%eax
f01010eb:	c1 e0 02             	shl    $0x2,%eax
f01010ee:	03 45 dc             	add    -0x24(%ebp),%eax
f01010f1:	83 e8 01             	sub    $0x1,%eax
f01010f4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010f7:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010fa:	89 45 b0             	mov    %eax,-0x50(%ebp)
f01010fd:	8b 45 b0             	mov    -0x50(%ebp),%eax
f0101100:	ba 00 00 00 00       	mov    $0x0,%edx
f0101105:	f7 75 dc             	divl   -0x24(%ebp)
f0101108:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010110b:	29 d0                	sub    %edx,%eax
f010110d:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pages = (struct Page*)boot_alloc(spages, PGSIZE);
f0101110:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101117:	00 
f0101118:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010111b:	89 04 24             	mov    %eax,(%esp)
f010111e:	e8 0f fc ff ff       	call   f0100d32 <boot_alloc>
f0101123:	a3 2c 3c 11 f0       	mov    %eax,0xf0113c2c
	physaddr_t ppages = PADDR(pages);
f0101128:	a1 2c 3c 11 f0       	mov    0xf0113c2c,%eax
f010112d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101130:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0101137:	77 23                	ja     f010115c <i386_vm_init+0x22a>
f0101139:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010113c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101140:	c7 44 24 08 b8 39 10 	movl   $0xf01039b8,0x8(%esp)
f0101147:	f0 
f0101148:	c7 44 24 04 10 01 00 	movl   $0x110,0x4(%esp)
f010114f:	00 
f0101150:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101157:	e8 b9 ef ff ff       	call   f0100115 <_panic>
f010115c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010115f:	05 00 00 00 10       	add    $0x10000000,%eax
f0101164:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	boot_map_segment(pgdir, UPAGES, spages, ppages, PTE_U);
f0101167:	c7 44 24 10 04 00 00 	movl   $0x4,0x10(%esp)
f010116e:	00 
f010116f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101172:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101176:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101179:	89 44 24 08          	mov    %eax,0x8(%esp)
f010117d:	c7 44 24 04 00 00 00 	movl   $0xef000000,0x4(%esp)
f0101184:	ef 
f0101185:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101188:	89 04 24             	mov    %eax,(%esp)
f010118b:	e8 3d fd ff ff       	call   f0100ecd <boot_map_segment>
	
	// Check that the initial page directory has been set up correctly.
	check_boot_pgdir();
f0101190:	e8 92 00 00 00       	call   f0101227 <check_boot_pgdir>
	// mapping, even though we are turning on paging and reconfiguring
	// segmentation.

	// Map VA 0:4MB same as VA KERNBASE, i.e. to PA 0:4MB.
	// (Limits our kernel to <4MB)
	pgdir[0] = pgdir[PDX(KERNBASE)];
f0101195:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101198:	05 00 0f 00 00       	add    $0xf00,%eax
f010119d:	8b 10                	mov    (%eax),%edx
f010119f:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01011a2:	89 10                	mov    %edx,(%eax)

	// Install page table.
	lcr3(boot_cr3);
f01011a4:	a1 24 3c 11 f0       	mov    0xf0113c24,%eax
f01011a9:	89 45 cc             	mov    %eax,-0x34(%ebp)
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01011ac:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01011af:	0f 22 d8             	mov    %eax,%cr3

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01011b2:	0f 20 c0             	mov    %cr0,%eax
f01011b5:	89 45 c8             	mov    %eax,-0x38(%ebp)
	return val;
f01011b8:	8b 45 c8             	mov    -0x38(%ebp),%eax

	// Turn on paging.
	cr0 = rcr0();
f01011bb:	89 45 f8             	mov    %eax,-0x8(%ebp)
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_TS|CR0_EM|CR0_MP;
f01011be:	81 4d f8 2f 00 05 80 	orl    $0x8005002f,-0x8(%ebp)
	cr0 &= ~(CR0_TS|CR0_EM);
f01011c5:	83 65 f8 f3          	andl   $0xfffffff3,-0x8(%ebp)
f01011c9:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01011cc:	89 45 c4             	mov    %eax,-0x3c(%ebp)
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01011cf:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01011d2:	0f 22 c0             	mov    %eax,%cr0

	// Current mapping: KERNBASE+x => x => x.
	// (x < 4MB so uses paging pgdir[0])

	// Reload all segment registers.
	asm volatile("lgdt gdt_pd+2");
f01011d5:	0f 01 15 b2 35 11 f0 	lgdtl  0xf01135b2
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01011dc:	b8 23 00 00 00       	mov    $0x23,%eax
f01011e1:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01011e3:	b8 23 00 00 00       	mov    $0x23,%eax
f01011e8:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01011ea:	b8 10 00 00 00       	mov    $0x10,%eax
f01011ef:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01011f1:	b8 10 00 00 00       	mov    $0x10,%eax
f01011f6:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01011f8:	b8 10 00 00 00       	mov    $0x10,%eax
f01011fd:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));  // reload cs
f01011ff:	ea 06 12 10 f0 08 00 	ljmp   $0x8,$0xf0101206
	asm volatile("lldt %%ax" :: "a" (0));
f0101206:	b8 00 00 00 00       	mov    $0x0,%eax
f010120b:	0f 00 d0             	lldt   %ax

	// Final mapping: KERNBASE+x => KERNBASE+x => x.

	// This mapping was only used after paging was turned on but
	// before the segment registers were reloaded.
	pgdir[0] = 0;
f010120e:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101211:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	// Flush the TLB for good measure, to kill the pgdir[0] mapping.
	lcr3(boot_cr3);
f0101217:	a1 24 3c 11 f0       	mov    0xf0113c24,%eax
f010121c:	89 45 c0             	mov    %eax,-0x40(%ebp)
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010121f:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0101222:	0f 22 d8             	mov    %eax,%cr3
}
f0101225:	c9                   	leave  
f0101226:	c3                   	ret    

f0101227 <check_boot_pgdir>:
//
static physaddr_t check_va2pa(pde_t *pgdir, uintptr_t va);

static void
check_boot_pgdir(void)
{
f0101227:	55                   	push   %ebp
f0101228:	89 e5                	mov    %esp,%ebp
f010122a:	83 ec 48             	sub    $0x48,%esp
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = boot_pgdir;
f010122d:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f0101232:	89 45 f4             	mov    %eax,-0xc(%ebp)

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
f0101235:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
f010123c:	8b 15 20 3c 11 f0    	mov    0xf0113c20,%edx
f0101242:	89 d0                	mov    %edx,%eax
f0101244:	01 c0                	add    %eax,%eax
f0101246:	01 d0                	add    %edx,%eax
f0101248:	c1 e0 02             	shl    $0x2,%eax
f010124b:	03 45 f0             	add    -0x10(%ebp),%eax
f010124e:	83 e8 01             	sub    $0x1,%eax
f0101251:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101254:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101257:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010125a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010125d:	ba 00 00 00 00       	mov    $0x0,%edx
f0101262:	f7 75 f0             	divl   -0x10(%ebp)
f0101265:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101268:	29 d0                	sub    %edx,%eax
f010126a:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < n; i += PGSIZE)
f010126d:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0101274:	e9 89 00 00 00       	jmp    f0101302 <check_boot_pgdir+0xdb>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0101279:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010127c:	2d 00 00 00 11       	sub    $0x11000000,%eax
f0101281:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101285:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101288:	89 04 24             	mov    %eax,(%esp)
f010128b:	e8 56 02 00 00       	call   f01014e6 <check_va2pa>
f0101290:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101293:	a1 2c 3c 11 f0       	mov    0xf0113c2c,%eax
f0101298:	89 45 e8             	mov    %eax,-0x18(%ebp)
f010129b:	81 7d e8 ff ff ff ef 	cmpl   $0xefffffff,-0x18(%ebp)
f01012a2:	77 23                	ja     f01012c7 <check_boot_pgdir+0xa0>
f01012a4:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01012a7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012ab:	c7 44 24 08 b8 39 10 	movl   $0xf01039b8,0x8(%esp)
f01012b2:	f0 
f01012b3:	c7 44 24 04 5d 01 00 	movl   $0x15d,0x4(%esp)
f01012ba:	00 
f01012bb:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f01012c2:	e8 4e ee ff ff       	call   f0100115 <_panic>
f01012c7:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01012ca:	05 00 00 00 10       	add    $0x10000000,%eax
f01012cf:	03 45 fc             	add    -0x4(%ebp),%eax
f01012d2:	39 45 d8             	cmp    %eax,-0x28(%ebp)
f01012d5:	74 24                	je     f01012fb <check_boot_pgdir+0xd4>
f01012d7:	c7 44 24 0c dc 39 10 	movl   $0xf01039dc,0xc(%esp)
f01012de:	f0 
f01012df:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f01012e6:	f0 
f01012e7:	c7 44 24 04 5d 01 00 	movl   $0x15d,0x4(%esp)
f01012ee:	00 
f01012ef:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f01012f6:	e8 1a ee ff ff       	call   f0100115 <_panic>

	pgdir = boot_pgdir;

	// check pages array
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01012fb:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%ebp)
f0101302:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101305:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f0101308:	0f 82 6b ff ff ff    	jb     f0101279 <check_boot_pgdir+0x52>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; KERNBASE + i != 0; i += PGSIZE)
f010130e:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0101315:	eb 47                	jmp    f010135e <check_boot_pgdir+0x137>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0101317:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010131a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010131f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101323:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101326:	89 04 24             	mov    %eax,(%esp)
f0101329:	e8 b8 01 00 00       	call   f01014e6 <check_va2pa>
f010132e:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f0101331:	74 24                	je     f0101357 <check_boot_pgdir+0x130>
f0101333:	c7 44 24 0c 24 3a 10 	movl   $0xf0103a24,0xc(%esp)
f010133a:	f0 
f010133b:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101342:	f0 
f0101343:	c7 44 24 04 61 01 00 	movl   $0x161,0x4(%esp)
f010134a:	00 
f010134b:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101352:	e8 be ed ff ff       	call   f0100115 <_panic>
	n = ROUNDUP(npage*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check phys mem
	for (i = 0; KERNBASE + i != 0; i += PGSIZE)
f0101357:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%ebp)
f010135e:	81 7d fc 00 00 00 10 	cmpl   $0x10000000,-0x4(%ebp)
f0101365:	75 b0                	jne    f0101317 <check_boot_pgdir+0xf0>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0101367:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f010136e:	e9 88 00 00 00       	jmp    f01013fb <check_boot_pgdir+0x1d4>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0101373:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101376:	2d 00 80 40 10       	sub    $0x10408000,%eax
f010137b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010137f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101382:	89 04 24             	mov    %eax,(%esp)
f0101385:	e8 5c 01 00 00       	call   f01014e6 <check_va2pa>
f010138a:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010138d:	c7 45 e4 00 b0 10 f0 	movl   $0xf010b000,-0x1c(%ebp)
f0101394:	81 7d e4 ff ff ff ef 	cmpl   $0xefffffff,-0x1c(%ebp)
f010139b:	77 23                	ja     f01013c0 <check_boot_pgdir+0x199>
f010139d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01013a0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013a4:	c7 44 24 08 b8 39 10 	movl   $0xf01039b8,0x8(%esp)
f01013ab:	f0 
f01013ac:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
f01013b3:	00 
f01013b4:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f01013bb:	e8 55 ed ff ff       	call   f0100115 <_panic>
f01013c0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01013c3:	05 00 00 00 10       	add    $0x10000000,%eax
f01013c8:	03 45 fc             	add    -0x4(%ebp),%eax
f01013cb:	39 45 dc             	cmp    %eax,-0x24(%ebp)
f01013ce:	74 24                	je     f01013f4 <check_boot_pgdir+0x1cd>
f01013d0:	c7 44 24 0c 4c 3a 10 	movl   $0xf0103a4c,0xc(%esp)
f01013d7:	f0 
f01013d8:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f01013df:	f0 
f01013e0:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
f01013e7:	00 
f01013e8:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f01013ef:	e8 21 ed ff ff       	call   f0100115 <_panic>
	// check phys mem
	for (i = 0; KERNBASE + i != 0; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01013f4:	81 45 fc 00 10 00 00 	addl   $0x1000,-0x4(%ebp)
f01013fb:	81 7d fc ff 7f 00 00 	cmpl   $0x7fff,-0x4(%ebp)
f0101402:	0f 86 6b ff ff ff    	jbe    f0101373 <check_boot_pgdir+0x14c>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f0101408:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f010140f:	e9 b7 00 00 00       	jmp    f01014cb <check_boot_pgdir+0x2a4>
		switch (i) {
f0101414:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101417:	2d bc 03 00 00       	sub    $0x3bc,%eax
f010141c:	83 f8 03             	cmp    $0x3,%eax
f010141f:	77 37                	ja     f0101458 <check_boot_pgdir+0x231>
		case PDX(VPT):
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i]);
f0101421:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101424:	c1 e0 02             	shl    $0x2,%eax
f0101427:	03 45 f4             	add    -0xc(%ebp),%eax
f010142a:	8b 00                	mov    (%eax),%eax
f010142c:	85 c0                	test   %eax,%eax
f010142e:	0f 85 93 00 00 00    	jne    f01014c7 <check_boot_pgdir+0x2a0>
f0101434:	c7 44 24 0c 91 3a 10 	movl   $0xf0103a91,0xc(%esp)
f010143b:	f0 
f010143c:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101443:	f0 
f0101444:	c7 44 24 04 6e 01 00 	movl   $0x16e,0x4(%esp)
f010144b:	00 
f010144c:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101453:	e8 bd ec ff ff       	call   f0100115 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE))
f0101458:	81 7d fc bf 03 00 00 	cmpl   $0x3bf,-0x4(%ebp)
f010145f:	76 33                	jbe    f0101494 <check_boot_pgdir+0x26d>
				assert(pgdir[i]);
f0101461:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101464:	c1 e0 02             	shl    $0x2,%eax
f0101467:	03 45 f4             	add    -0xc(%ebp),%eax
f010146a:	8b 00                	mov    (%eax),%eax
f010146c:	85 c0                	test   %eax,%eax
f010146e:	75 57                	jne    f01014c7 <check_boot_pgdir+0x2a0>
f0101470:	c7 44 24 0c 91 3a 10 	movl   $0xf0103a91,0xc(%esp)
f0101477:	f0 
f0101478:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f010147f:	f0 
f0101480:	c7 44 24 04 72 01 00 	movl   $0x172,0x4(%esp)
f0101487:	00 
f0101488:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f010148f:	e8 81 ec ff ff       	call   f0100115 <_panic>
			else
				assert(pgdir[i] == 0);
f0101494:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101497:	c1 e0 02             	shl    $0x2,%eax
f010149a:	03 45 f4             	add    -0xc(%ebp),%eax
f010149d:	8b 00                	mov    (%eax),%eax
f010149f:	85 c0                	test   %eax,%eax
f01014a1:	74 24                	je     f01014c7 <check_boot_pgdir+0x2a0>
f01014a3:	c7 44 24 0c 9a 3a 10 	movl   $0xf0103a9a,0xc(%esp)
f01014aa:	f0 
f01014ab:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f01014b2:	f0 
f01014b3:	c7 44 24 04 74 01 00 	movl   $0x174,0x4(%esp)
f01014ba:	00 
f01014bb:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f01014c2:	e8 4e ec ff ff       	call   f0100115 <_panic>
	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);

	// check for zero/non-zero in PDEs
	for (i = 0; i < NPDENTRIES; i++) {
f01014c7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f01014cb:	81 7d fc ff 03 00 00 	cmpl   $0x3ff,-0x4(%ebp)
f01014d2:	0f 86 3c ff ff ff    	jbe    f0101414 <check_boot_pgdir+0x1ed>
			else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_boot_pgdir() succeeded!\n");
f01014d8:	c7 04 24 a8 3a 10 f0 	movl   $0xf0103aa8,(%esp)
f01014df:	e8 33 0e 00 00       	call   f0102317 <cprintf>
}
f01014e4:	c9                   	leave  
f01014e5:	c3                   	ret    

f01014e6 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_boot_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f01014e6:	55                   	push   %ebp
f01014e7:	89 e5                	mov    %esp,%ebp
f01014e9:	83 ec 28             	sub    $0x28,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f01014ec:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014ef:	c1 e8 16             	shr    $0x16,%eax
f01014f2:	c1 e0 02             	shl    $0x2,%eax
f01014f5:	01 45 08             	add    %eax,0x8(%ebp)
	if (!(*pgdir & PTE_P))
f01014f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01014fb:	8b 00                	mov    (%eax),%eax
f01014fd:	83 e0 01             	and    $0x1,%eax
f0101500:	85 c0                	test   %eax,%eax
f0101502:	75 0c                	jne    f0101510 <check_va2pa+0x2a>
		return ~0;
f0101504:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
f010150b:	e9 8f 00 00 00       	jmp    f010159f <check_va2pa+0xb9>
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0101510:	8b 45 08             	mov    0x8(%ebp),%eax
f0101513:	8b 00                	mov    (%eax),%eax
f0101515:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010151a:	89 45 f8             	mov    %eax,-0x8(%ebp)
f010151d:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101520:	c1 e8 0c             	shr    $0xc,%eax
f0101523:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0101526:	a1 20 3c 11 f0       	mov    0xf0113c20,%eax
f010152b:	39 45 f4             	cmp    %eax,-0xc(%ebp)
f010152e:	72 23                	jb     f0101553 <check_va2pa+0x6d>
f0101530:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101533:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101537:	c7 44 24 08 88 39 10 	movl   $0xf0103988,0x8(%esp)
f010153e:	f0 
f010153f:	c7 44 24 04 88 01 00 	movl   $0x188,0x4(%esp)
f0101546:	00 
f0101547:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f010154e:	e8 c2 eb ff ff       	call   f0100115 <_panic>
f0101553:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101556:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010155b:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (!(p[PTX(va)] & PTE_P))
f010155e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101561:	c1 e8 0c             	shr    $0xc,%eax
f0101564:	25 ff 03 00 00       	and    $0x3ff,%eax
f0101569:	c1 e0 02             	shl    $0x2,%eax
f010156c:	03 45 fc             	add    -0x4(%ebp),%eax
f010156f:	8b 00                	mov    (%eax),%eax
f0101571:	83 e0 01             	and    $0x1,%eax
f0101574:	85 c0                	test   %eax,%eax
f0101576:	75 09                	jne    f0101581 <check_va2pa+0x9b>
		return ~0;
f0101578:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
f010157f:	eb 1e                	jmp    f010159f <check_va2pa+0xb9>
	return PTE_ADDR(p[PTX(va)]);
f0101581:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101584:	c1 e8 0c             	shr    $0xc,%eax
f0101587:	25 ff 03 00 00       	and    $0x3ff,%eax
f010158c:	c1 e0 02             	shl    $0x2,%eax
f010158f:	03 45 fc             	add    -0x4(%ebp),%eax
f0101592:	8b 00                	mov    (%eax),%eax
f0101594:	89 c2                	mov    %eax,%edx
f0101596:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010159c:	89 55 ec             	mov    %edx,-0x14(%ebp)
f010159f:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
f01015a2:	c9                   	leave  
f01015a3:	c3                   	ret    

f01015a4 <page_init>:
// to allocate and deallocate physical memory via the page_free_list,
// and NEVER use boot_alloc() or the related boot-time functions above.
//
void
page_init(void)
{
f01015a4:	55                   	push   %ebp
f01015a5:	89 e5                	mov    %esp,%ebp
f01015a7:	53                   	push   %ebx
f01015a8:	83 ec 34             	sub    $0x34,%esp
	//
	// Change the code to reflect this.

	int i;
	extern char end[];
	LIST_INIT(&page_free_list);
f01015ab:	c7 05 18 38 11 f0 00 	movl   $0x0,0xf0113818
f01015b2:	00 00 00 

	size_t nbasepages = IOPHYSMEM / PGSIZE;
f01015b5:	c7 45 f4 a0 00 00 00 	movl   $0xa0,-0xc(%ebp)
	size_t ntotalbasepages = EXTPHYSMEM / PGSIZE;
f01015bc:	c7 45 f0 00 01 00 00 	movl   $0x100,-0x10(%ebp)

	physaddr_t kernbase =  PADDR(0xF0100000);
f01015c3:	c7 45 e8 00 00 10 f0 	movl   $0xf0100000,-0x18(%ebp)
f01015ca:	81 7d e8 ff ff ff ef 	cmpl   $0xefffffff,-0x18(%ebp)
f01015d1:	77 23                	ja     f01015f6 <page_init+0x52>
f01015d3:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01015d6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01015da:	c7 44 24 08 b8 39 10 	movl   $0xf01039b8,0x8(%esp)
f01015e1:	f0 
f01015e2:	c7 44 24 04 b2 01 00 	movl   $0x1b2,0x4(%esp)
f01015e9:	00 
f01015ea:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f01015f1:	e8 1f eb ff ff       	call   f0100115 <_panic>
f01015f6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01015f9:	05 00 00 00 10       	add    $0x10000000,%eax
f01015fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
	physaddr_t structend = PADDR(boot_freemem);
f0101601:	a1 14 38 11 f0       	mov    0xf0113814,%eax
f0101606:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101609:	81 7d e0 ff ff ff ef 	cmpl   $0xefffffff,-0x20(%ebp)
f0101610:	77 23                	ja     f0101635 <page_init+0x91>
f0101612:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101615:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101619:	c7 44 24 08 b8 39 10 	movl   $0xf01039b8,0x8(%esp)
f0101620:	f0 
f0101621:	c7 44 24 04 b3 01 00 	movl   $0x1b3,0x4(%esp)
f0101628:	00 
f0101629:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101630:	e8 e0 ea ff ff       	call   f0100115 <_panic>
f0101635:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101638:	05 00 00 00 10       	add    $0x10000000,%eax
f010163d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	
	for (i = 0; i < npage; i++) {
f0101640:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
f0101647:	e9 25 01 00 00       	jmp    f0101771 <page_init+0x1cd>
		if (i == 0) {
f010164c:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
f0101650:	75 20                	jne    f0101672 <page_init+0xce>
			// First page is in use
			pages[i].pp_ref = 1;
f0101652:	8b 0d 2c 3c 11 f0    	mov    0xf0113c2c,%ecx
f0101658:	8b 55 f8             	mov    -0x8(%ebp),%edx
f010165b:	89 d0                	mov    %edx,%eax
f010165d:	01 c0                	add    %eax,%eax
f010165f:	01 d0                	add    %edx,%eax
f0101661:	c1 e0 02             	shl    $0x2,%eax
f0101664:	8d 04 01             	lea    (%ecx,%eax,1),%eax
f0101667:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
f010166d:	e9 fb 00 00 00       	jmp    f010176d <page_init+0x1c9>
		}
		else if (i >= nbasepages && i < ntotalbasepages) {
f0101672:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0101675:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0101678:	72 28                	jb     f01016a2 <page_init+0xfe>
f010167a:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010167d:	3b 45 f0             	cmp    -0x10(%ebp),%eax
f0101680:	73 20                	jae    f01016a2 <page_init+0xfe>
			// IO pages are in use
			pages[i].pp_ref = 1;
f0101682:	8b 0d 2c 3c 11 f0    	mov    0xf0113c2c,%ecx
f0101688:	8b 55 f8             	mov    -0x8(%ebp),%edx
f010168b:	89 d0                	mov    %edx,%eax
f010168d:	01 c0                	add    %eax,%eax
f010168f:	01 d0                	add    %edx,%eax
f0101691:	c1 e0 02             	shl    $0x2,%eax
f0101694:	8d 04 01             	lea    (%ecx,%eax,1),%eax
f0101697:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
f010169d:	e9 cb 00 00 00       	jmp    f010176d <page_init+0x1c9>
		}
		else if (i >= (kernbase / 1024) && i < (structend / PGSIZE)) {
f01016a2:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01016a5:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01016a8:	c1 ea 0a             	shr    $0xa,%edx
f01016ab:	39 d0                	cmp    %edx,%eax
f01016ad:	72 2d                	jb     f01016dc <page_init+0x138>
f01016af:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01016b2:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01016b5:	c1 ea 0c             	shr    $0xc,%edx
f01016b8:	39 d0                	cmp    %edx,%eax
f01016ba:	73 20                	jae    f01016dc <page_init+0x138>
			// Kernel code and data structures are in use
			pages[i].pp_ref = 1;
f01016bc:	8b 0d 2c 3c 11 f0    	mov    0xf0113c2c,%ecx
f01016c2:	8b 55 f8             	mov    -0x8(%ebp),%edx
f01016c5:	89 d0                	mov    %edx,%eax
f01016c7:	01 c0                	add    %eax,%eax
f01016c9:	01 d0                	add    %edx,%eax
f01016cb:	c1 e0 02             	shl    $0x2,%eax
f01016ce:	8d 04 01             	lea    (%ecx,%eax,1),%eax
f01016d1:	66 c7 40 08 01 00    	movw   $0x1,0x8(%eax)
f01016d7:	e9 91 00 00 00       	jmp    f010176d <page_init+0x1c9>
		}
		else {
			// The rest of the pages are free
			pages[i].pp_ref = 0;
f01016dc:	8b 0d 2c 3c 11 f0    	mov    0xf0113c2c,%ecx
f01016e2:	8b 55 f8             	mov    -0x8(%ebp),%edx
f01016e5:	89 d0                	mov    %edx,%eax
f01016e7:	01 c0                	add    %eax,%eax
f01016e9:	01 d0                	add    %edx,%eax
f01016eb:	c1 e0 02             	shl    $0x2,%eax
f01016ee:	8d 04 01             	lea    (%ecx,%eax,1),%eax
f01016f1:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)
			LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
f01016f7:	8b 0d 2c 3c 11 f0    	mov    0xf0113c2c,%ecx
f01016fd:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0101700:	89 d0                	mov    %edx,%eax
f0101702:	01 c0                	add    %eax,%eax
f0101704:	01 d0                	add    %edx,%eax
f0101706:	c1 e0 02             	shl    $0x2,%eax
f0101709:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f010170c:	a1 18 38 11 f0       	mov    0xf0113818,%eax
f0101711:	89 02                	mov    %eax,(%edx)
f0101713:	8b 02                	mov    (%edx),%eax
f0101715:	85 c0                	test   %eax,%eax
f0101717:	74 1e                	je     f0101737 <page_init+0x193>
f0101719:	8b 0d 18 38 11 f0    	mov    0xf0113818,%ecx
f010171f:	8b 1d 2c 3c 11 f0    	mov    0xf0113c2c,%ebx
f0101725:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0101728:	89 d0                	mov    %edx,%eax
f010172a:	01 c0                	add    %eax,%eax
f010172c:	01 d0                	add    %edx,%eax
f010172e:	c1 e0 02             	shl    $0x2,%eax
f0101731:	8d 04 03             	lea    (%ebx,%eax,1),%eax
f0101734:	89 41 04             	mov    %eax,0x4(%ecx)
f0101737:	8b 0d 2c 3c 11 f0    	mov    0xf0113c2c,%ecx
f010173d:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0101740:	89 d0                	mov    %edx,%eax
f0101742:	01 c0                	add    %eax,%eax
f0101744:	01 d0                	add    %edx,%eax
f0101746:	c1 e0 02             	shl    $0x2,%eax
f0101749:	8d 04 01             	lea    (%ecx,%eax,1),%eax
f010174c:	a3 18 38 11 f0       	mov    %eax,0xf0113818
f0101751:	8b 0d 2c 3c 11 f0    	mov    0xf0113c2c,%ecx
f0101757:	8b 55 f8             	mov    -0x8(%ebp),%edx
f010175a:	89 d0                	mov    %edx,%eax
f010175c:	01 c0                	add    %eax,%eax
f010175e:	01 d0                	add    %edx,%eax
f0101760:	c1 e0 02             	shl    $0x2,%eax
f0101763:	8d 04 01             	lea    (%ecx,%eax,1),%eax
f0101766:	c7 40 04 18 38 11 f0 	movl   $0xf0113818,0x4(%eax)
	size_t ntotalbasepages = EXTPHYSMEM / PGSIZE;

	physaddr_t kernbase =  PADDR(0xF0100000);
	physaddr_t structend = PADDR(boot_freemem);
	
	for (i = 0; i < npage; i++) {
f010176d:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
f0101771:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0101774:	a1 20 3c 11 f0       	mov    0xf0113c20,%eax
f0101779:	39 c2                	cmp    %eax,%edx
f010177b:	0f 82 cb fe ff ff    	jb     f010164c <page_init+0xa8>
			// The rest of the pages are free
			pages[i].pp_ref = 0;
			LIST_INSERT_HEAD(&page_free_list, &pages[i], pp_link);
		}
	}
}
f0101781:	83 c4 34             	add    $0x34,%esp
f0101784:	5b                   	pop    %ebx
f0101785:	5d                   	pop    %ebp
f0101786:	c3                   	ret    

f0101787 <page_initpp>:
// The result has null links and 0 refcount.
// Note that the corresponding physical page is NOT initialized!
//
static void
page_initpp(struct Page *pp)
{
f0101787:	55                   	push   %ebp
f0101788:	89 e5                	mov    %esp,%ebp
f010178a:	83 ec 18             	sub    $0x18,%esp
	memset(pp, 0, sizeof(*pp));
f010178d:	c7 44 24 08 0c 00 00 	movl   $0xc,0x8(%esp)
f0101794:	00 
f0101795:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010179c:	00 
f010179d:	8b 45 08             	mov    0x8(%ebp),%eax
f01017a0:	89 04 24             	mov    %eax,(%esp)
f01017a3:	e8 98 19 00 00       	call   f0103140 <memset>
}
f01017a8:	c9                   	leave  
f01017a9:	c3                   	ret    

f01017aa <page_alloc>:
//
// Hint: use LIST_FIRST, LIST_REMOVE, and page_initpp
// Hint: pp_ref should not be incremented 
int
page_alloc(struct Page **pp_store)
{
f01017aa:	55                   	push   %ebp
f01017ab:	89 e5                	mov    %esp,%ebp
f01017ad:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in

}
f01017b0:	c9                   	leave  
f01017b1:	c3                   	ret    

f01017b2 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f01017b2:	55                   	push   %ebp
f01017b3:	89 e5                	mov    %esp,%ebp
	// Fill this function in

}
f01017b5:	5d                   	pop    %ebp
f01017b6:	c3                   	ret    

f01017b7 <page_decref>:
//
// Decrement the reference count on a page, freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f01017b7:	55                   	push   %ebp
f01017b8:	89 e5                	mov    %esp,%ebp
f01017ba:	83 ec 04             	sub    $0x4,%esp
	if (--pp->pp_ref == 0)
f01017bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01017c0:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f01017c4:	8d 50 ff             	lea    -0x1(%eax),%edx
f01017c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01017ca:	66 89 50 08          	mov    %dx,0x8(%eax)
f01017ce:	8b 45 08             	mov    0x8(%ebp),%eax
f01017d1:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f01017d5:	66 85 c0             	test   %ax,%ax
f01017d8:	75 0b                	jne    f01017e5 <page_decref+0x2e>
		page_free(pp);
f01017da:	8b 45 08             	mov    0x8(%ebp),%eax
f01017dd:	89 04 24             	mov    %eax,(%esp)
f01017e0:	e8 cd ff ff ff       	call   f01017b2 <page_free>
}
f01017e5:	c9                   	leave  
f01017e6:	c3                   	ret    

f01017e7 <pgdir_walk>:
//
// Hint: you can turn a Page * into the physical address of the
// page it refers to with page2pa() from kern/pmap.h
int
pgdir_walk(pde_t *pgdir, const void *va, int create, pte_t **pte_store)
{
f01017e7:	55                   	push   %ebp
f01017e8:	89 e5                	mov    %esp,%ebp
f01017ea:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in

}
f01017ed:	c9                   	leave  
f01017ee:	c3                   	ret    

f01017ef <page_insert>:
// Hint: The TA solution is implemented using
//   pgdir_walk() and and page_remove().
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm) 
{
f01017ef:	55                   	push   %ebp
f01017f0:	89 e5                	mov    %esp,%ebp
f01017f2:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in

}
f01017f5:	c9                   	leave  
f01017f6:	c3                   	ret    

f01017f7 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01017f7:	55                   	push   %ebp
f01017f8:	89 e5                	mov    %esp,%ebp
f01017fa:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in

}
f01017fd:	c9                   	leave  
f01017fe:	c3                   	ret    

f01017ff <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01017ff:	55                   	push   %ebp
f0101800:	89 e5                	mov    %esp,%ebp
	// Fill this function in

}
f0101802:	5d                   	pop    %ebp
f0101803:	c3                   	ret    

f0101804 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101804:	55                   	push   %ebp
f0101805:	89 e5                	mov    %esp,%ebp
f0101807:	83 ec 10             	sub    $0x10,%esp
f010180a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010180d:	89 45 fc             	mov    %eax,-0x4(%ebp)
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101810:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0101813:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101816:	c9                   	leave  
f0101817:	c3                   	ret    

f0101818 <page_check>:

void
page_check(void)
{
f0101818:	55                   	push   %ebp
f0101819:	89 e5                	mov    %esp,%ebp
f010181b:	53                   	push   %ebx
f010181c:	83 ec 34             	sub    $0x34,%esp
	struct Page *pp, *pp0, *pp1, *pp2;
	struct Page_list fl;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
f010181f:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
f0101826:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101829:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010182c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010182f:	89 45 f4             	mov    %eax,-0xc(%ebp)
	assert(page_alloc(&pp0) == 0);
f0101832:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101835:	89 04 24             	mov    %eax,(%esp)
f0101838:	e8 6d ff ff ff       	call   f01017aa <page_alloc>
f010183d:	85 c0                	test   %eax,%eax
f010183f:	74 24                	je     f0101865 <page_check+0x4d>
f0101841:	c7 44 24 0c c7 3a 10 	movl   $0xf0103ac7,0xc(%esp)
f0101848:	f0 
f0101849:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101850:	f0 
f0101851:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
f0101858:	00 
f0101859:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101860:	e8 b0 e8 ff ff       	call   f0100115 <_panic>
	assert(page_alloc(&pp1) == 0);
f0101865:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0101868:	89 04 24             	mov    %eax,(%esp)
f010186b:	e8 3a ff ff ff       	call   f01017aa <page_alloc>
f0101870:	85 c0                	test   %eax,%eax
f0101872:	74 24                	je     f0101898 <page_check+0x80>
f0101874:	c7 44 24 0c dd 3a 10 	movl   $0xf0103add,0xc(%esp)
f010187b:	f0 
f010187c:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101883:	f0 
f0101884:	c7 44 24 04 68 02 00 	movl   $0x268,0x4(%esp)
f010188b:	00 
f010188c:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101893:	e8 7d e8 ff ff       	call   f0100115 <_panic>
	assert(page_alloc(&pp2) == 0);
f0101898:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010189b:	89 04 24             	mov    %eax,(%esp)
f010189e:	e8 07 ff ff ff       	call   f01017aa <page_alloc>
f01018a3:	85 c0                	test   %eax,%eax
f01018a5:	74 24                	je     f01018cb <page_check+0xb3>
f01018a7:	c7 44 24 0c f3 3a 10 	movl   $0xf0103af3,0xc(%esp)
f01018ae:	f0 
f01018af:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f01018b6:	f0 
f01018b7:	c7 44 24 04 69 02 00 	movl   $0x269,0x4(%esp)
f01018be:	00 
f01018bf:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f01018c6:	e8 4a e8 ff ff       	call   f0100115 <_panic>

	assert(pp0);
f01018cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01018ce:	85 c0                	test   %eax,%eax
f01018d0:	75 24                	jne    f01018f6 <page_check+0xde>
f01018d2:	c7 44 24 0c 09 3b 10 	movl   $0xf0103b09,0xc(%esp)
f01018d9:	f0 
f01018da:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f01018e1:	f0 
f01018e2:	c7 44 24 04 6b 02 00 	movl   $0x26b,0x4(%esp)
f01018e9:	00 
f01018ea:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f01018f1:	e8 1f e8 ff ff       	call   f0100115 <_panic>
	assert(pp1 && pp1 != pp0);
f01018f6:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01018f9:	85 c0                	test   %eax,%eax
f01018fb:	74 0a                	je     f0101907 <page_check+0xef>
f01018fd:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0101900:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101903:	39 c2                	cmp    %eax,%edx
f0101905:	75 24                	jne    f010192b <page_check+0x113>
f0101907:	c7 44 24 0c 0d 3b 10 	movl   $0xf0103b0d,0xc(%esp)
f010190e:	f0 
f010190f:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101916:	f0 
f0101917:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f010191e:	00 
f010191f:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101926:	e8 ea e7 ff ff       	call   f0100115 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010192b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010192e:	85 c0                	test   %eax,%eax
f0101930:	74 14                	je     f0101946 <page_check+0x12e>
f0101932:	8b 55 ec             	mov    -0x14(%ebp),%edx
f0101935:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101938:	39 c2                	cmp    %eax,%edx
f010193a:	74 0a                	je     f0101946 <page_check+0x12e>
f010193c:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010193f:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101942:	39 c2                	cmp    %eax,%edx
f0101944:	75 24                	jne    f010196a <page_check+0x152>
f0101946:	c7 44 24 0c 20 3b 10 	movl   $0xf0103b20,0xc(%esp)
f010194d:	f0 
f010194e:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101955:	f0 
f0101956:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f010195d:	00 
f010195e:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101965:	e8 ab e7 ff ff       	call   f0100115 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010196a:	a1 18 38 11 f0       	mov    0xf0113818,%eax
f010196f:	89 45 e8             	mov    %eax,-0x18(%ebp)
	LIST_INIT(&page_free_list);
f0101972:	c7 05 18 38 11 f0 00 	movl   $0x0,0xf0113818
f0101979:	00 00 00 

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f010197c:	8d 45 f8             	lea    -0x8(%ebp),%eax
f010197f:	89 04 24             	mov    %eax,(%esp)
f0101982:	e8 23 fe ff ff       	call   f01017aa <page_alloc>
f0101987:	83 f8 fc             	cmp    $0xfffffffc,%eax
f010198a:	74 24                	je     f01019b0 <page_check+0x198>
f010198c:	c7 44 24 0c 40 3b 10 	movl   $0xf0103b40,0xc(%esp)
f0101993:	f0 
f0101994:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f010199b:	f0 
f010199c:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
f01019a3:	00 
f01019a4:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f01019ab:	e8 65 e7 ff ff       	call   f0100115 <_panic>

	// there is no free memory, so we can't allocate a page table 
	assert(page_insert(boot_pgdir, pp1, 0x0, 0) < 0);
f01019b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01019b3:	8b 15 28 3c 11 f0    	mov    0xf0113c28,%edx
f01019b9:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01019c0:	00 
f01019c1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019c8:	00 
f01019c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019cd:	89 14 24             	mov    %edx,(%esp)
f01019d0:	e8 1a fe ff ff       	call   f01017ef <page_insert>
f01019d5:	85 c0                	test   %eax,%eax
f01019d7:	78 24                	js     f01019fd <page_check+0x1e5>
f01019d9:	c7 44 24 0c 60 3b 10 	movl   $0xf0103b60,0xc(%esp)
f01019e0:	f0 
f01019e1:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f01019e8:	f0 
f01019e9:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
f01019f0:	00 
f01019f1:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f01019f8:	e8 18 e7 ff ff       	call   f0100115 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a00:	89 04 24             	mov    %eax,(%esp)
f0101a03:	e8 aa fd ff ff       	call   f01017b2 <page_free>
	assert(page_insert(boot_pgdir, pp1, 0x0, 0) == 0);
f0101a08:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101a0b:	8b 15 28 3c 11 f0    	mov    0xf0113c28,%edx
f0101a11:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101a18:	00 
f0101a19:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a20:	00 
f0101a21:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a25:	89 14 24             	mov    %edx,(%esp)
f0101a28:	e8 c2 fd ff ff       	call   f01017ef <page_insert>
f0101a2d:	85 c0                	test   %eax,%eax
f0101a2f:	74 24                	je     f0101a55 <page_check+0x23d>
f0101a31:	c7 44 24 0c 8c 3b 10 	movl   $0xf0103b8c,0xc(%esp)
f0101a38:	f0 
f0101a39:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101a40:	f0 
f0101a41:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f0101a48:	00 
f0101a49:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101a50:	e8 c0 e6 ff ff       	call   f0100115 <_panic>
	assert(PTE_ADDR(boot_pgdir[0]) == page2pa(pp0));
f0101a55:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f0101a5a:	8b 00                	mov    (%eax),%eax
f0101a5c:	89 c3                	mov    %eax,%ebx
f0101a5e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0101a64:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101a67:	89 04 24             	mov    %eax,(%esp)
f0101a6a:	e8 ba 07 00 00       	call   f0102229 <page2pa>
f0101a6f:	39 c3                	cmp    %eax,%ebx
f0101a71:	74 24                	je     f0101a97 <page_check+0x27f>
f0101a73:	c7 44 24 0c b8 3b 10 	movl   $0xf0103bb8,0xc(%esp)
f0101a7a:	f0 
f0101a7b:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101a82:	f0 
f0101a83:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
f0101a8a:	00 
f0101a8b:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101a92:	e8 7e e6 ff ff       	call   f0100115 <_panic>
	assert(check_va2pa(boot_pgdir, 0x0) == page2pa(pp1));
f0101a97:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f0101a9c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101aa3:	00 
f0101aa4:	89 04 24             	mov    %eax,(%esp)
f0101aa7:	e8 3a fa ff ff       	call   f01014e6 <check_va2pa>
f0101aac:	89 c3                	mov    %eax,%ebx
f0101aae:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101ab1:	89 04 24             	mov    %eax,(%esp)
f0101ab4:	e8 70 07 00 00       	call   f0102229 <page2pa>
f0101ab9:	39 c3                	cmp    %eax,%ebx
f0101abb:	74 24                	je     f0101ae1 <page_check+0x2c9>
f0101abd:	c7 44 24 0c e0 3b 10 	movl   $0xf0103be0,0xc(%esp)
f0101ac4:	f0 
f0101ac5:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101acc:	f0 
f0101acd:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f0101ad4:	00 
f0101ad5:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101adc:	e8 34 e6 ff ff       	call   f0100115 <_panic>
	assert(pp1->pp_ref == 1);
f0101ae1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101ae4:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0101ae8:	66 83 f8 01          	cmp    $0x1,%ax
f0101aec:	74 24                	je     f0101b12 <page_check+0x2fa>
f0101aee:	c7 44 24 0c 0d 3c 10 	movl   $0xf0103c0d,0xc(%esp)
f0101af5:	f0 
f0101af6:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101afd:	f0 
f0101afe:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f0101b05:	00 
f0101b06:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101b0d:	e8 03 e6 ff ff       	call   f0100115 <_panic>
	assert(pp0->pp_ref == 1);
f0101b12:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101b15:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0101b19:	66 83 f8 01          	cmp    $0x1,%ax
f0101b1d:	74 24                	je     f0101b43 <page_check+0x32b>
f0101b1f:	c7 44 24 0c 1e 3c 10 	movl   $0xf0103c1e,0xc(%esp)
f0101b26:	f0 
f0101b27:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101b2e:	f0 
f0101b2f:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f0101b36:	00 
f0101b37:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101b3e:	e8 d2 e5 ff ff       	call   f0100115 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, 0) == 0);
f0101b43:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101b46:	8b 15 28 3c 11 f0    	mov    0xf0113c28,%edx
f0101b4c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101b53:	00 
f0101b54:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b5b:	00 
f0101b5c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101b60:	89 14 24             	mov    %edx,(%esp)
f0101b63:	e8 87 fc ff ff       	call   f01017ef <page_insert>
f0101b68:	85 c0                	test   %eax,%eax
f0101b6a:	74 24                	je     f0101b90 <page_check+0x378>
f0101b6c:	c7 44 24 0c 30 3c 10 	movl   $0xf0103c30,0xc(%esp)
f0101b73:	f0 
f0101b74:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101b7b:	f0 
f0101b7c:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
f0101b83:	00 
f0101b84:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101b8b:	e8 85 e5 ff ff       	call   f0100115 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
f0101b90:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f0101b95:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101b9c:	00 
f0101b9d:	89 04 24             	mov    %eax,(%esp)
f0101ba0:	e8 41 f9 ff ff       	call   f01014e6 <check_va2pa>
f0101ba5:	89 c3                	mov    %eax,%ebx
f0101ba7:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101baa:	89 04 24             	mov    %eax,(%esp)
f0101bad:	e8 77 06 00 00       	call   f0102229 <page2pa>
f0101bb2:	39 c3                	cmp    %eax,%ebx
f0101bb4:	74 24                	je     f0101bda <page_check+0x3c2>
f0101bb6:	c7 44 24 0c 68 3c 10 	movl   $0xf0103c68,0xc(%esp)
f0101bbd:	f0 
f0101bbe:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101bc5:	f0 
f0101bc6:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
f0101bcd:	00 
f0101bce:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101bd5:	e8 3b e5 ff ff       	call   f0100115 <_panic>
	assert(pp2->pp_ref == 1);
f0101bda:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101bdd:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0101be1:	66 83 f8 01          	cmp    $0x1,%ax
f0101be5:	74 24                	je     f0101c0b <page_check+0x3f3>
f0101be7:	c7 44 24 0c 98 3c 10 	movl   $0xf0103c98,0xc(%esp)
f0101bee:	f0 
f0101bef:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101bf6:	f0 
f0101bf7:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
f0101bfe:	00 
f0101bff:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101c06:	e8 0a e5 ff ff       	call   f0100115 <_panic>

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f0101c0b:	8d 45 f8             	lea    -0x8(%ebp),%eax
f0101c0e:	89 04 24             	mov    %eax,(%esp)
f0101c11:	e8 94 fb ff ff       	call   f01017aa <page_alloc>
f0101c16:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101c19:	74 24                	je     f0101c3f <page_check+0x427>
f0101c1b:	c7 44 24 0c 40 3b 10 	movl   $0xf0103b40,0xc(%esp)
f0101c22:	f0 
f0101c23:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101c2a:	f0 
f0101c2b:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f0101c32:	00 
f0101c33:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101c3a:	e8 d6 e4 ff ff       	call   f0100115 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(boot_pgdir, pp2, (void*) PGSIZE, 0) == 0);
f0101c3f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101c42:	8b 15 28 3c 11 f0    	mov    0xf0113c28,%edx
f0101c48:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101c4f:	00 
f0101c50:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c57:	00 
f0101c58:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101c5c:	89 14 24             	mov    %edx,(%esp)
f0101c5f:	e8 8b fb ff ff       	call   f01017ef <page_insert>
f0101c64:	85 c0                	test   %eax,%eax
f0101c66:	74 24                	je     f0101c8c <page_check+0x474>
f0101c68:	c7 44 24 0c 30 3c 10 	movl   $0xf0103c30,0xc(%esp)
f0101c6f:	f0 
f0101c70:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101c77:	f0 
f0101c78:	c7 44 24 04 8a 02 00 	movl   $0x28a,0x4(%esp)
f0101c7f:	00 
f0101c80:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101c87:	e8 89 e4 ff ff       	call   f0100115 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp2));
f0101c8c:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f0101c91:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101c98:	00 
f0101c99:	89 04 24             	mov    %eax,(%esp)
f0101c9c:	e8 45 f8 ff ff       	call   f01014e6 <check_va2pa>
f0101ca1:	89 c3                	mov    %eax,%ebx
f0101ca3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101ca6:	89 04 24             	mov    %eax,(%esp)
f0101ca9:	e8 7b 05 00 00       	call   f0102229 <page2pa>
f0101cae:	39 c3                	cmp    %eax,%ebx
f0101cb0:	74 24                	je     f0101cd6 <page_check+0x4be>
f0101cb2:	c7 44 24 0c 68 3c 10 	movl   $0xf0103c68,0xc(%esp)
f0101cb9:	f0 
f0101cba:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101cc1:	f0 
f0101cc2:	c7 44 24 04 8b 02 00 	movl   $0x28b,0x4(%esp)
f0101cc9:	00 
f0101cca:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101cd1:	e8 3f e4 ff ff       	call   f0100115 <_panic>
	assert(pp2->pp_ref == 1);
f0101cd6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101cd9:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0101cdd:	66 83 f8 01          	cmp    $0x1,%ax
f0101ce1:	74 24                	je     f0101d07 <page_check+0x4ef>
f0101ce3:	c7 44 24 0c 98 3c 10 	movl   $0xf0103c98,0xc(%esp)
f0101cea:	f0 
f0101ceb:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101cf2:	f0 
f0101cf3:	c7 44 24 04 8c 02 00 	movl   $0x28c,0x4(%esp)
f0101cfa:	00 
f0101cfb:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101d02:	e8 0e e4 ff ff       	call   f0100115 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(page_alloc(&pp) == -E_NO_MEM);
f0101d07:	8d 45 f8             	lea    -0x8(%ebp),%eax
f0101d0a:	89 04 24             	mov    %eax,(%esp)
f0101d0d:	e8 98 fa ff ff       	call   f01017aa <page_alloc>
f0101d12:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0101d15:	74 24                	je     f0101d3b <page_check+0x523>
f0101d17:	c7 44 24 0c 40 3b 10 	movl   $0xf0103b40,0xc(%esp)
f0101d1e:	f0 
f0101d1f:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101d26:	f0 
f0101d27:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f0101d2e:	00 
f0101d2f:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101d36:	e8 da e3 ff ff       	call   f0100115 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(boot_pgdir, pp0, (void*) PTSIZE, 0) < 0);
f0101d3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101d3e:	8b 15 28 3c 11 f0    	mov    0xf0113c28,%edx
f0101d44:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101d4b:	00 
f0101d4c:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101d53:	00 
f0101d54:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101d58:	89 14 24             	mov    %edx,(%esp)
f0101d5b:	e8 8f fa ff ff       	call   f01017ef <page_insert>
f0101d60:	85 c0                	test   %eax,%eax
f0101d62:	78 24                	js     f0101d88 <page_check+0x570>
f0101d64:	c7 44 24 0c ac 3c 10 	movl   $0xf0103cac,0xc(%esp)
f0101d6b:	f0 
f0101d6c:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101d73:	f0 
f0101d74:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f0101d7b:	00 
f0101d7c:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101d83:	e8 8d e3 ff ff       	call   f0100115 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(boot_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101d88:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101d8b:	8b 15 28 3c 11 f0    	mov    0xf0113c28,%edx
f0101d91:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0101d98:	00 
f0101d99:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101da0:	00 
f0101da1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101da5:	89 14 24             	mov    %edx,(%esp)
f0101da8:	e8 42 fa ff ff       	call   f01017ef <page_insert>
f0101dad:	85 c0                	test   %eax,%eax
f0101daf:	74 24                	je     f0101dd5 <page_check+0x5bd>
f0101db1:	c7 44 24 0c e0 3c 10 	movl   $0xf0103ce0,0xc(%esp)
f0101db8:	f0 
f0101db9:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101dc0:	f0 
f0101dc1:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f0101dc8:	00 
f0101dc9:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101dd0:	e8 40 e3 ff ff       	call   f0100115 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(boot_pgdir, 0) == page2pa(pp1));
f0101dd5:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f0101dda:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101de1:	00 
f0101de2:	89 04 24             	mov    %eax,(%esp)
f0101de5:	e8 fc f6 ff ff       	call   f01014e6 <check_va2pa>
f0101dea:	89 c3                	mov    %eax,%ebx
f0101dec:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101def:	89 04 24             	mov    %eax,(%esp)
f0101df2:	e8 32 04 00 00       	call   f0102229 <page2pa>
f0101df7:	39 c3                	cmp    %eax,%ebx
f0101df9:	74 24                	je     f0101e1f <page_check+0x607>
f0101dfb:	c7 44 24 0c 18 3d 10 	movl   $0xf0103d18,0xc(%esp)
f0101e02:	f0 
f0101e03:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101e0a:	f0 
f0101e0b:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f0101e12:	00 
f0101e13:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101e1a:	e8 f6 e2 ff ff       	call   f0100115 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp1));
f0101e1f:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f0101e24:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e2b:	00 
f0101e2c:	89 04 24             	mov    %eax,(%esp)
f0101e2f:	e8 b2 f6 ff ff       	call   f01014e6 <check_va2pa>
f0101e34:	89 c3                	mov    %eax,%ebx
f0101e36:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101e39:	89 04 24             	mov    %eax,(%esp)
f0101e3c:	e8 e8 03 00 00       	call   f0102229 <page2pa>
f0101e41:	39 c3                	cmp    %eax,%ebx
f0101e43:	74 24                	je     f0101e69 <page_check+0x651>
f0101e45:	c7 44 24 0c 44 3d 10 	movl   $0xf0103d44,0xc(%esp)
f0101e4c:	f0 
f0101e4d:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101e54:	f0 
f0101e55:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f0101e5c:	00 
f0101e5d:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101e64:	e8 ac e2 ff ff       	call   f0100115 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e69:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101e6c:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0101e70:	66 83 f8 02          	cmp    $0x2,%ax
f0101e74:	74 24                	je     f0101e9a <page_check+0x682>
f0101e76:	c7 44 24 0c 74 3d 10 	movl   $0xf0103d74,0xc(%esp)
f0101e7d:	f0 
f0101e7e:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101e85:	f0 
f0101e86:	c7 44 24 04 9c 02 00 	movl   $0x29c,0x4(%esp)
f0101e8d:	00 
f0101e8e:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101e95:	e8 7b e2 ff ff       	call   f0100115 <_panic>
	assert(pp2->pp_ref == 0);
f0101e9a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101e9d:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0101ea1:	66 85 c0             	test   %ax,%ax
f0101ea4:	74 24                	je     f0101eca <page_check+0x6b2>
f0101ea6:	c7 44 24 0c 85 3d 10 	movl   $0xf0103d85,0xc(%esp)
f0101ead:	f0 
f0101eae:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101eb5:	f0 
f0101eb6:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
f0101ebd:	00 
f0101ebe:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101ec5:	e8 4b e2 ff ff       	call   f0100115 <_panic>

	// pp2 should be returned by page_alloc
	assert(page_alloc(&pp) == 0 && pp == pp2);
f0101eca:	8d 45 f8             	lea    -0x8(%ebp),%eax
f0101ecd:	89 04 24             	mov    %eax,(%esp)
f0101ed0:	e8 d5 f8 ff ff       	call   f01017aa <page_alloc>
f0101ed5:	85 c0                	test   %eax,%eax
f0101ed7:	75 0a                	jne    f0101ee3 <page_check+0x6cb>
f0101ed9:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0101edc:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101edf:	39 c2                	cmp    %eax,%edx
f0101ee1:	74 24                	je     f0101f07 <page_check+0x6ef>
f0101ee3:	c7 44 24 0c 98 3d 10 	movl   $0xf0103d98,0xc(%esp)
f0101eea:	f0 
f0101eeb:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101ef2:	f0 
f0101ef3:	c7 44 24 04 a0 02 00 	movl   $0x2a0,0x4(%esp)
f0101efa:	00 
f0101efb:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101f02:	e8 0e e2 ff ff       	call   f0100115 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(boot_pgdir, 0x0);
f0101f07:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f0101f0c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101f13:	00 
f0101f14:	89 04 24             	mov    %eax,(%esp)
f0101f17:	e8 e3 f8 ff ff       	call   f01017ff <page_remove>
	assert(check_va2pa(boot_pgdir, 0x0) == ~0);
f0101f1c:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f0101f21:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101f28:	00 
f0101f29:	89 04 24             	mov    %eax,(%esp)
f0101f2c:	e8 b5 f5 ff ff       	call   f01014e6 <check_va2pa>
f0101f31:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f34:	74 24                	je     f0101f5a <page_check+0x742>
f0101f36:	c7 44 24 0c bc 3d 10 	movl   $0xf0103dbc,0xc(%esp)
f0101f3d:	f0 
f0101f3e:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101f45:	f0 
f0101f46:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
f0101f4d:	00 
f0101f4e:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101f55:	e8 bb e1 ff ff       	call   f0100115 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == page2pa(pp1));
f0101f5a:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f0101f5f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f66:	00 
f0101f67:	89 04 24             	mov    %eax,(%esp)
f0101f6a:	e8 77 f5 ff ff       	call   f01014e6 <check_va2pa>
f0101f6f:	89 c3                	mov    %eax,%ebx
f0101f71:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101f74:	89 04 24             	mov    %eax,(%esp)
f0101f77:	e8 ad 02 00 00       	call   f0102229 <page2pa>
f0101f7c:	39 c3                	cmp    %eax,%ebx
f0101f7e:	74 24                	je     f0101fa4 <page_check+0x78c>
f0101f80:	c7 44 24 0c 44 3d 10 	movl   $0xf0103d44,0xc(%esp)
f0101f87:	f0 
f0101f88:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101f8f:	f0 
f0101f90:	c7 44 24 04 a5 02 00 	movl   $0x2a5,0x4(%esp)
f0101f97:	00 
f0101f98:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101f9f:	e8 71 e1 ff ff       	call   f0100115 <_panic>
	assert(pp1->pp_ref == 1);
f0101fa4:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101fa7:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0101fab:	66 83 f8 01          	cmp    $0x1,%ax
f0101faf:	74 24                	je     f0101fd5 <page_check+0x7bd>
f0101fb1:	c7 44 24 0c 0d 3c 10 	movl   $0xf0103c0d,0xc(%esp)
f0101fb8:	f0 
f0101fb9:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101fc0:	f0 
f0101fc1:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f0101fc8:	00 
f0101fc9:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0101fd0:	e8 40 e1 ff ff       	call   f0100115 <_panic>
	assert(pp2->pp_ref == 0);
f0101fd5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101fd8:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f0101fdc:	66 85 c0             	test   %ax,%ax
f0101fdf:	74 24                	je     f0102005 <page_check+0x7ed>
f0101fe1:	c7 44 24 0c 85 3d 10 	movl   $0xf0103d85,0xc(%esp)
f0101fe8:	f0 
f0101fe9:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0101ff0:	f0 
f0101ff1:	c7 44 24 04 a7 02 00 	movl   $0x2a7,0x4(%esp)
f0101ff8:	00 
f0101ff9:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0102000:	e8 10 e1 ff ff       	call   f0100115 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(boot_pgdir, (void*) PGSIZE);
f0102005:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f010200a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102011:	00 
f0102012:	89 04 24             	mov    %eax,(%esp)
f0102015:	e8 e5 f7 ff ff       	call   f01017ff <page_remove>
	assert(check_va2pa(boot_pgdir, 0x0) == ~0);
f010201a:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f010201f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102026:	00 
f0102027:	89 04 24             	mov    %eax,(%esp)
f010202a:	e8 b7 f4 ff ff       	call   f01014e6 <check_va2pa>
f010202f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102032:	74 24                	je     f0102058 <page_check+0x840>
f0102034:	c7 44 24 0c bc 3d 10 	movl   $0xf0103dbc,0xc(%esp)
f010203b:	f0 
f010203c:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0102043:	f0 
f0102044:	c7 44 24 04 ab 02 00 	movl   $0x2ab,0x4(%esp)
f010204b:	00 
f010204c:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0102053:	e8 bd e0 ff ff       	call   f0100115 <_panic>
	assert(check_va2pa(boot_pgdir, PGSIZE) == ~0);
f0102058:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f010205d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102064:	00 
f0102065:	89 04 24             	mov    %eax,(%esp)
f0102068:	e8 79 f4 ff ff       	call   f01014e6 <check_va2pa>
f010206d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102070:	74 24                	je     f0102096 <page_check+0x87e>
f0102072:	c7 44 24 0c e0 3d 10 	movl   $0xf0103de0,0xc(%esp)
f0102079:	f0 
f010207a:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0102081:	f0 
f0102082:	c7 44 24 04 ac 02 00 	movl   $0x2ac,0x4(%esp)
f0102089:	00 
f010208a:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0102091:	e8 7f e0 ff ff       	call   f0100115 <_panic>
	assert(pp1->pp_ref == 0);
f0102096:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102099:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f010209d:	66 85 c0             	test   %ax,%ax
f01020a0:	74 24                	je     f01020c6 <page_check+0x8ae>
f01020a2:	c7 44 24 0c 06 3e 10 	movl   $0xf0103e06,0xc(%esp)
f01020a9:	f0 
f01020aa:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f01020b1:	f0 
f01020b2:	c7 44 24 04 ad 02 00 	movl   $0x2ad,0x4(%esp)
f01020b9:	00 
f01020ba:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f01020c1:	e8 4f e0 ff ff       	call   f0100115 <_panic>
	assert(pp2->pp_ref == 0);
f01020c6:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01020c9:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f01020cd:	66 85 c0             	test   %ax,%ax
f01020d0:	74 24                	je     f01020f6 <page_check+0x8de>
f01020d2:	c7 44 24 0c 85 3d 10 	movl   $0xf0103d85,0xc(%esp)
f01020d9:	f0 
f01020da:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f01020e1:	f0 
f01020e2:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f01020e9:	00 
f01020ea:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f01020f1:	e8 1f e0 ff ff       	call   f0100115 <_panic>

	// so it should be returned by page_alloc
	assert(page_alloc(&pp) == 0 && pp == pp1);
f01020f6:	8d 45 f8             	lea    -0x8(%ebp),%eax
f01020f9:	89 04 24             	mov    %eax,(%esp)
f01020fc:	e8 a9 f6 ff ff       	call   f01017aa <page_alloc>
f0102101:	85 c0                	test   %eax,%eax
f0102103:	75 0a                	jne    f010210f <page_check+0x8f7>
f0102105:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0102108:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010210b:	39 c2                	cmp    %eax,%edx
f010210d:	74 24                	je     f0102133 <page_check+0x91b>
f010210f:	c7 44 24 0c 18 3e 10 	movl   $0xf0103e18,0xc(%esp)
f0102116:	f0 
f0102117:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f010211e:	f0 
f010211f:	c7 44 24 04 b1 02 00 	movl   $0x2b1,0x4(%esp)
f0102126:	00 
f0102127:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f010212e:	e8 e2 df ff ff       	call   f0100115 <_panic>

	// should be no free memory
	assert(page_alloc(&pp) == -E_NO_MEM);
f0102133:	8d 45 f8             	lea    -0x8(%ebp),%eax
f0102136:	89 04 24             	mov    %eax,(%esp)
f0102139:	e8 6c f6 ff ff       	call   f01017aa <page_alloc>
f010213e:	83 f8 fc             	cmp    $0xfffffffc,%eax
f0102141:	74 24                	je     f0102167 <page_check+0x94f>
f0102143:	c7 44 24 0c 40 3b 10 	movl   $0xf0103b40,0xc(%esp)
f010214a:	f0 
f010214b:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0102152:	f0 
f0102153:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f010215a:	00 
f010215b:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f0102162:	e8 ae df ff ff       	call   f0100115 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(boot_pgdir[0]) == page2pa(pp0));
f0102167:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f010216c:	8b 00                	mov    (%eax),%eax
f010216e:	89 c3                	mov    %eax,%ebx
f0102170:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
f0102176:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102179:	89 04 24             	mov    %eax,(%esp)
f010217c:	e8 a8 00 00 00       	call   f0102229 <page2pa>
f0102181:	39 c3                	cmp    %eax,%ebx
f0102183:	74 24                	je     f01021a9 <page_check+0x991>
f0102185:	c7 44 24 0c b8 3b 10 	movl   $0xf0103bb8,0xc(%esp)
f010218c:	f0 
f010218d:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f0102194:	f0 
f0102195:	c7 44 24 04 b7 02 00 	movl   $0x2b7,0x4(%esp)
f010219c:	00 
f010219d:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f01021a4:	e8 6c df ff ff       	call   f0100115 <_panic>
	boot_pgdir[0] = 0;
f01021a9:	a1 28 3c 11 f0       	mov    0xf0113c28,%eax
f01021ae:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01021b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01021b7:	0f b7 40 08          	movzwl 0x8(%eax),%eax
f01021bb:	66 83 f8 01          	cmp    $0x1,%ax
f01021bf:	74 24                	je     f01021e5 <page_check+0x9cd>
f01021c1:	c7 44 24 0c 1e 3c 10 	movl   $0xf0103c1e,0xc(%esp)
f01021c8:	f0 
f01021c9:	c7 44 24 08 0f 3a 10 	movl   $0xf0103a0f,0x8(%esp)
f01021d0:	f0 
f01021d1:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
f01021d8:	00 
f01021d9:	c7 04 24 ab 39 10 f0 	movl   $0xf01039ab,(%esp)
f01021e0:	e8 30 df ff ff       	call   f0100115 <_panic>
	pp0->pp_ref = 0;
f01021e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01021e8:	66 c7 40 08 00 00    	movw   $0x0,0x8(%eax)

	// give free list back
	page_free_list = fl;
f01021ee:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01021f1:	a3 18 38 11 f0       	mov    %eax,0xf0113818

	// free the pages we took
	page_free(pp0);
f01021f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01021f9:	89 04 24             	mov    %eax,(%esp)
f01021fc:	e8 b1 f5 ff ff       	call   f01017b2 <page_free>
	page_free(pp1);
f0102201:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102204:	89 04 24             	mov    %eax,(%esp)
f0102207:	e8 a6 f5 ff ff       	call   f01017b2 <page_free>
	page_free(pp2);
f010220c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010220f:	89 04 24             	mov    %eax,(%esp)
f0102212:	e8 9b f5 ff ff       	call   f01017b2 <page_free>

	cprintf("page_check() succeeded!\n");
f0102217:	c7 04 24 3a 3e 10 f0 	movl   $0xf0103e3a,(%esp)
f010221e:	e8 f4 00 00 00       	call   f0102317 <cprintf>
}
f0102223:	83 c4 34             	add    $0x34,%esp
f0102226:	5b                   	pop    %ebx
f0102227:	5d                   	pop    %ebp
f0102228:	c3                   	ret    

f0102229 <page2pa>:
	return pp - pages;
}

static inline physaddr_t
page2pa(struct Page *pp)
{
f0102229:	55                   	push   %ebp
f010222a:	89 e5                	mov    %esp,%ebp
f010222c:	83 ec 08             	sub    $0x8,%esp
	return page2ppn(pp) << PGSHIFT;
f010222f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102232:	89 04 24             	mov    %eax,(%esp)
f0102235:	e8 05 00 00 00       	call   f010223f <page2ppn>
f010223a:	c1 e0 0c             	shl    $0xc,%eax
}
f010223d:	c9                   	leave  
f010223e:	c3                   	ret    

f010223f <page2ppn>:
void	page_decref(struct Page *pp);
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline ppn_t
page2ppn(struct Page *pp)
{
f010223f:	55                   	push   %ebp
f0102240:	89 e5                	mov    %esp,%ebp
	return pp - pages;
f0102242:	8b 55 08             	mov    0x8(%ebp),%edx
f0102245:	a1 2c 3c 11 f0       	mov    0xf0113c2c,%eax
f010224a:	89 d1                	mov    %edx,%ecx
f010224c:	29 c1                	sub    %eax,%ecx
f010224e:	89 c8                	mov    %ecx,%eax
f0102250:	c1 f8 02             	sar    $0x2,%eax
f0102253:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
}
f0102259:	5d                   	pop    %ebp
f010225a:	c3                   	ret    
	...

f010225c <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010225c:	55                   	push   %ebp
f010225d:	89 e5                	mov    %esp,%ebp
f010225f:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
f0102262:	8b 45 08             	mov    0x8(%ebp),%eax
f0102265:	0f b6 c0             	movzbl %al,%eax
f0102268:	c7 45 f8 70 00 00 00 	movl   $0x70,-0x8(%ebp)
f010226f:	88 45 ff             	mov    %al,-0x1(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102272:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
f0102276:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0102279:	ee                   	out    %al,(%dx)
f010227a:	c7 45 f4 71 00 00 00 	movl   $0x71,-0xc(%ebp)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102281:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102284:	ec                   	in     (%dx),%al
f0102285:	88 45 fe             	mov    %al,-0x2(%ebp)
	return data;
f0102288:	0f b6 45 fe          	movzbl -0x2(%ebp),%eax
	return inb(IO_RTC+1);
f010228c:	0f b6 c0             	movzbl %al,%eax
}
f010228f:	c9                   	leave  
f0102290:	c3                   	ret    

f0102291 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102291:	55                   	push   %ebp
f0102292:	89 e5                	mov    %esp,%ebp
f0102294:	83 ec 10             	sub    $0x10,%esp
	outb(IO_RTC, reg);
f0102297:	8b 45 08             	mov    0x8(%ebp),%eax
f010229a:	0f b6 c0             	movzbl %al,%eax
f010229d:	c7 45 f8 70 00 00 00 	movl   $0x70,-0x8(%ebp)
f01022a4:	88 45 ff             	mov    %al,-0x1(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01022a7:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
f01022ab:	8b 55 f8             	mov    -0x8(%ebp),%edx
f01022ae:	ee                   	out    %al,(%dx)
	outb(IO_RTC+1, datum);
f01022af:	8b 45 0c             	mov    0xc(%ebp),%eax
f01022b2:	0f b6 c0             	movzbl %al,%eax
f01022b5:	c7 45 f4 71 00 00 00 	movl   $0x71,-0xc(%ebp)
f01022bc:	88 45 fe             	mov    %al,-0x2(%ebp)
f01022bf:	0f b6 45 fe          	movzbl -0x2(%ebp),%eax
f01022c3:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01022c6:	ee                   	out    %al,(%dx)
}
f01022c7:	c9                   	leave  
f01022c8:	c3                   	ret    
f01022c9:	00 00                	add    %al,(%eax)
	...

f01022cc <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01022cc:	55                   	push   %ebp
f01022cd:	89 e5                	mov    %esp,%ebp
f01022cf:	83 ec 08             	sub    $0x8,%esp
	cputchar(ch);
f01022d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01022d5:	89 04 24             	mov    %eax,(%esp)
f01022d8:	e8 6b e6 ff ff       	call   f0100948 <cputchar>
	*cnt++;
f01022dd:	83 45 0c 04          	addl   $0x4,0xc(%ebp)
}
f01022e1:	c9                   	leave  
f01022e2:	c3                   	ret    

f01022e3 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01022e3:	55                   	push   %ebp
f01022e4:	89 e5                	mov    %esp,%ebp
f01022e6:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01022e9:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01022f0:	ba cc 22 10 f0       	mov    $0xf01022cc,%edx
f01022f5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01022f8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01022fc:	8b 45 08             	mov    0x8(%ebp),%eax
f01022ff:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102303:	8d 45 fc             	lea    -0x4(%ebp),%eax
f0102306:	89 44 24 04          	mov    %eax,0x4(%esp)
f010230a:	89 14 24             	mov    %edx,(%esp)
f010230d:	e8 b5 05 00 00       	call   f01028c7 <vprintfmt>
	return cnt;
f0102312:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0102315:	c9                   	leave  
f0102316:	c3                   	ret    

f0102317 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102317:	55                   	push   %ebp
f0102318:	89 e5                	mov    %esp,%ebp
f010231a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010231d:	8d 45 08             	lea    0x8(%ebp),%eax
f0102320:	83 c0 04             	add    $0x4,%eax
f0102323:	89 45 fc             	mov    %eax,-0x4(%ebp)
	cnt = vcprintf(fmt, ap);
f0102326:	8b 55 08             	mov    0x8(%ebp),%edx
f0102329:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010232c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102330:	89 14 24             	mov    %edx,(%esp)
f0102333:	e8 ab ff ff ff       	call   f01022e3 <vcprintf>
f0102338:	89 45 f8             	mov    %eax,-0x8(%ebp)
	va_end(ap);

	return cnt;
f010233b:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f010233e:	c9                   	leave  
f010233f:	c3                   	ret    

f0102340 <stab_binsearch>:
extern const struct Stab __STAB_BEGIN__[], __STAB_END__[];
extern const char __STABSTR_BEGIN__[], __STABSTR_END__[];

static void
stab_binsearch(const struct Stab *stabs, uintptr_t addr, int *lx, int *rx, int type)
{
f0102340:	55                   	push   %ebp
f0102341:	89 e5                	mov    %esp,%ebp
f0102343:	83 ec 10             	sub    $0x10,%esp
	int l = *lx, r = *rx;
f0102346:	8b 45 10             	mov    0x10(%ebp),%eax
f0102349:	8b 00                	mov    (%eax),%eax
f010234b:	89 45 fc             	mov    %eax,-0x4(%ebp)
f010234e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102351:	8b 00                	mov    (%eax),%eax
f0102353:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0102356:	e9 c6 00 00 00       	jmp    f0102421 <stab_binsearch+0xe1>
	
	while (l <= r) {
		int m = (l + r) / 2;
f010235b:	8b 55 f8             	mov    -0x8(%ebp),%edx
f010235e:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102361:	8d 14 10             	lea    (%eax,%edx,1),%edx
f0102364:	89 d0                	mov    %edx,%eax
f0102366:	c1 e8 1f             	shr    $0x1f,%eax
f0102369:	01 d0                	add    %edx,%eax
f010236b:	d1 f8                	sar    %eax
f010236d:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0102370:	eb 04                	jmp    f0102376 <stab_binsearch+0x36>
		while (m >= l && stabs[m].n_type != type)
			m--;
f0102372:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
{
	int l = *lx, r = *rx;
	
	while (l <= r) {
		int m = (l + r) / 2;
		while (m >= l && stabs[m].n_type != type)
f0102376:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102379:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f010237c:	7c 1b                	jl     f0102399 <stab_binsearch+0x59>
f010237e:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102381:	89 d0                	mov    %edx,%eax
f0102383:	01 c0                	add    %eax,%eax
f0102385:	01 d0                	add    %edx,%eax
f0102387:	c1 e0 02             	shl    $0x2,%eax
f010238a:	03 45 08             	add    0x8(%ebp),%eax
f010238d:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0102391:	0f b6 c0             	movzbl %al,%eax
f0102394:	3b 45 18             	cmp    0x18(%ebp),%eax
f0102397:	75 d9                	jne    f0102372 <stab_binsearch+0x32>
			m--;
		if (m < l)
f0102399:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010239c:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f010239f:	7d 1a                	jge    f01023bb <stab_binsearch+0x7b>
			l = (l + r) / 2 + 1;
f01023a1:	8b 55 f8             	mov    -0x8(%ebp),%edx
f01023a4:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01023a7:	8d 14 10             	lea    (%eax,%edx,1),%edx
f01023aa:	89 d0                	mov    %edx,%eax
f01023ac:	c1 e8 1f             	shr    $0x1f,%eax
f01023af:	01 d0                	add    %edx,%eax
f01023b1:	d1 f8                	sar    %eax
f01023b3:	83 c0 01             	add    $0x1,%eax
f01023b6:	89 45 fc             	mov    %eax,-0x4(%ebp)
f01023b9:	eb 66                	jmp    f0102421 <stab_binsearch+0xe1>
		else if (stabs[m].n_value < addr) {
f01023bb:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01023be:	89 d0                	mov    %edx,%eax
f01023c0:	01 c0                	add    %eax,%eax
f01023c2:	01 d0                	add    %edx,%eax
f01023c4:	c1 e0 02             	shl    $0x2,%eax
f01023c7:	03 45 08             	add    0x8(%ebp),%eax
f01023ca:	8b 40 08             	mov    0x8(%eax),%eax
f01023cd:	3b 45 0c             	cmp    0xc(%ebp),%eax
f01023d0:	73 13                	jae    f01023e5 <stab_binsearch+0xa5>
			*lx = m;
f01023d2:	8b 55 10             	mov    0x10(%ebp),%edx
f01023d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01023d8:	89 02                	mov    %eax,(%edx)
			l = m + 1;
f01023da:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01023dd:	83 c0 01             	add    $0x1,%eax
f01023e0:	89 45 fc             	mov    %eax,-0x4(%ebp)
f01023e3:	eb 3c                	jmp    f0102421 <stab_binsearch+0xe1>
		} else if (stabs[m].n_value > addr) {
f01023e5:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01023e8:	89 d0                	mov    %edx,%eax
f01023ea:	01 c0                	add    %eax,%eax
f01023ec:	01 d0                	add    %edx,%eax
f01023ee:	c1 e0 02             	shl    $0x2,%eax
f01023f1:	03 45 08             	add    0x8(%ebp),%eax
f01023f4:	8b 40 08             	mov    0x8(%eax),%eax
f01023f7:	3b 45 0c             	cmp    0xc(%ebp),%eax
f01023fa:	76 13                	jbe    f010240f <stab_binsearch+0xcf>
			*rx = m;
f01023fc:	8b 55 14             	mov    0x14(%ebp),%edx
f01023ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102402:	89 02                	mov    %eax,(%edx)
			r = m - 1;
f0102404:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102407:	83 e8 01             	sub    $0x1,%eax
f010240a:	89 45 f8             	mov    %eax,-0x8(%ebp)
f010240d:	eb 12                	jmp    f0102421 <stab_binsearch+0xe1>
		} else {
			*lx = m;
f010240f:	8b 45 10             	mov    0x10(%ebp),%eax
f0102412:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102415:	89 10                	mov    %edx,(%eax)
			l = m;
f0102417:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010241a:	89 45 fc             	mov    %eax,-0x4(%ebp)
			addr++;
f010241d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
static void
stab_binsearch(const struct Stab *stabs, uintptr_t addr, int *lx, int *rx, int type)
{
	int l = *lx, r = *rx;
	
	while (l <= r) {
f0102421:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102424:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f0102427:	0f 8e 2e ff ff ff    	jle    f010235b <stab_binsearch+0x1b>
			*lx = m;
			l = m;
			addr++;
		}
	}
}
f010242d:	c9                   	leave  
f010242e:	c3                   	ret    

f010242f <debuginfo_eip>:


int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010242f:	55                   	push   %ebp
f0102430:	89 e5                	mov    %esp,%ebp
f0102432:	53                   	push   %ebx
f0102433:	83 ec 54             	sub    $0x54,%esp
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	info->eip_fn = "<unknown>";
f0102436:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102439:	c7 00 53 3e 10 f0    	movl   $0xf0103e53,(%eax)
	info->eip_fnaddr = addr;
f010243f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102442:	8b 45 08             	mov    0x8(%ebp),%eax
f0102445:	89 42 08             	mov    %eax,0x8(%edx)
	info->eip_fnlen = 9;
f0102448:	8b 45 0c             	mov    0xc(%ebp),%eax
f010244b:	c7 40 04 09 00 00 00 	movl   $0x9,0x4(%eax)
	info->eip_file = "<unknown>";
f0102452:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102455:	c7 40 0c 53 3e 10 f0 	movl   $0xf0103e53,0xc(%eax)
	info->eip_line = 0;
f010245c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010245f:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)

	if (addr >= KERNBASE) {
f0102466:	81 7d 08 ff ff ff ef 	cmpl   $0xefffffff,0x8(%ebp)
f010246d:	76 6f                	jbe    f01024de <debuginfo_eip+0xaf>
		stabs = __STAB_BEGIN__;
f010246f:	c7 45 f8 b0 40 10 f0 	movl   $0xf01040b0,-0x8(%ebp)
		stab_end = __STAB_END__;
f0102476:	c7 45 f4 2c 8e 10 f0 	movl   $0xf0108e2c,-0xc(%ebp)
		stabstr = __STABSTR_BEGIN__;
f010247d:	c7 45 f0 2d 8e 10 f0 	movl   $0xf0108e2d,-0x10(%ebp)
		stabstr_end = __STABSTR_END__;
f0102484:	c7 45 ec a1 ab 10 f0 	movl   $0xf010aba1,-0x14(%ebp)
	} else {
  	        panic ("User address");
	}

	lfile = 0, rfile = stab_end - stabs - 1;
f010248b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
f0102492:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102495:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0102498:	89 d1                	mov    %edx,%ecx
f010249a:	29 c1                	sub    %eax,%ecx
f010249c:	89 c8                	mov    %ecx,%eax
f010249e:	c1 f8 02             	sar    $0x2,%eax
f01024a1:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01024a7:	83 e8 01             	sub    $0x1,%eax
f01024aa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	stab_binsearch(stabs, addr, &lfile, &rfile, N_SO);
f01024ad:	c7 44 24 10 64 00 00 	movl   $0x64,0x10(%esp)
f01024b4:	00 
f01024b5:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01024b8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01024bc:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01024bf:	89 44 24 08          	mov    %eax,0x8(%esp)
f01024c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01024c6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01024ca:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01024cd:	89 04 24             	mov    %eax,(%esp)
f01024d0:	e8 6b fe ff ff       	call   f0102340 <stab_binsearch>
	if (lfile == 0)
f01024d5:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01024d8:	85 c0                	test   %eax,%eax
f01024da:	74 1e                	je     f01024fa <debuginfo_eip+0xcb>
f01024dc:	eb 28                	jmp    f0102506 <debuginfo_eip+0xd7>
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
  	        panic ("User address");
f01024de:	c7 44 24 08 5d 3e 10 	movl   $0xf0103e5d,0x8(%esp)
f01024e5:	f0 
f01024e6:	c7 44 24 04 40 00 00 	movl   $0x40,0x4(%esp)
f01024ed:	00 
f01024ee:	c7 04 24 6a 3e 10 f0 	movl   $0xf0103e6a,(%esp)
f01024f5:	e8 1b dc ff ff       	call   f0100115 <_panic>
	}

	lfile = 0, rfile = stab_end - stabs - 1;
	stab_binsearch(stabs, addr, &lfile, &rfile, N_SO);
	if (lfile == 0)
		return -1;
f01024fa:	c7 45 c8 ff ff ff ff 	movl   $0xffffffff,-0x38(%ebp)
f0102501:	e9 c5 01 00 00       	jmp    f01026cb <debuginfo_eip+0x29c>

	lfun = lfile, rfun = rfile;
f0102506:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102509:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010250c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010250f:	89 45 dc             	mov    %eax,-0x24(%ebp)
	stab_binsearch(stabs, addr, &lfun, &rfun, N_FUN);
f0102512:	c7 44 24 10 24 00 00 	movl   $0x24,0x10(%esp)
f0102519:	00 
f010251a:	8d 45 dc             	lea    -0x24(%ebp),%eax
f010251d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102521:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0102524:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102528:	8b 45 08             	mov    0x8(%ebp),%eax
f010252b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010252f:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0102532:	89 04 24             	mov    %eax,(%esp)
f0102535:	e8 06 fe ff ff       	call   f0102340 <stab_binsearch>

	/* At this point we know the function name. */
	if (lfun != lfile) {
f010253a:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010253d:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102540:	39 c2                	cmp    %eax,%edx
f0102542:	74 71                	je     f01025b5 <debuginfo_eip+0x186>
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102544:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102547:	89 c2                	mov    %eax,%edx
f0102549:	89 d0                	mov    %edx,%eax
f010254b:	01 c0                	add    %eax,%eax
f010254d:	01 d0                	add    %edx,%eax
f010254f:	c1 e0 02             	shl    $0x2,%eax
f0102552:	03 45 f8             	add    -0x8(%ebp),%eax
f0102555:	8b 08                	mov    (%eax),%ecx
f0102557:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010255a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010255d:	89 d3                	mov    %edx,%ebx
f010255f:	29 c3                	sub    %eax,%ebx
f0102561:	89 d8                	mov    %ebx,%eax
f0102563:	39 c1                	cmp    %eax,%ecx
f0102565:	73 1d                	jae    f0102584 <debuginfo_eip+0x155>
			info->eip_fn = stabstr + stabs[lfun].n_strx;
f0102567:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010256a:	89 c2                	mov    %eax,%edx
f010256c:	89 d0                	mov    %edx,%eax
f010256e:	01 c0                	add    %eax,%eax
f0102570:	01 d0                	add    %edx,%eax
f0102572:	c1 e0 02             	shl    $0x2,%eax
f0102575:	03 45 f8             	add    -0x8(%ebp),%eax
f0102578:	8b 00                	mov    (%eax),%eax
f010257a:	89 c2                	mov    %eax,%edx
f010257c:	03 55 f0             	add    -0x10(%ebp),%edx
f010257f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102582:	89 10                	mov    %edx,(%eax)
		info->eip_fnaddr = stabs[lfun].n_value;
f0102584:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102587:	89 c2                	mov    %eax,%edx
f0102589:	89 d0                	mov    %edx,%eax
f010258b:	01 c0                	add    %eax,%eax
f010258d:	01 d0                	add    %edx,%eax
f010258f:	c1 e0 02             	shl    $0x2,%eax
f0102592:	03 45 f8             	add    -0x8(%ebp),%eax
f0102595:	8b 50 08             	mov    0x8(%eax),%edx
f0102598:	8b 45 0c             	mov    0xc(%ebp),%eax
f010259b:	89 50 08             	mov    %edx,0x8(%eax)
		addr -= info->eip_fnaddr;
f010259e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025a1:	8b 40 08             	mov    0x8(%eax),%eax
f01025a4:	29 45 08             	sub    %eax,0x8(%ebp)
		lline = lfun, rline = rfun;
f01025a7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01025aa:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01025ad:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01025b0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01025b3:	eb 26                	jmp    f01025db <debuginfo_eip+0x1ac>
	} else {
		info->eip_fn = info->eip_file;
f01025b5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025b8:	8b 50 0c             	mov    0xc(%eax),%edx
f01025bb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025be:	89 10                	mov    %edx,(%eax)
		info->eip_fnaddr = addr;
f01025c0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01025c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01025c6:	89 42 08             	mov    %eax,0x8(%edx)
		lline = lfun = lfile, rline = rfile;
f01025c9:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01025cc:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01025cf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01025d2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01025d5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01025d8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	}
	info->eip_fnlen = strfind(info->eip_fn, ':') - info->eip_fn;
f01025db:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025de:	8b 00                	mov    (%eax),%eax
f01025e0:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01025e7:	00 
f01025e8:	89 04 24             	mov    %eax,(%esp)
f01025eb:	e8 24 0b 00 00       	call   f0103114 <strfind>
f01025f0:	89 c2                	mov    %eax,%edx
f01025f2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025f5:	8b 00                	mov    (%eax),%eax
f01025f7:	29 c2                	sub    %eax,%edx
f01025f9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01025fc:	89 50 04             	mov    %edx,0x4(%eax)

	/* Search for the line number: */
	// You code here
	if (lline == 0)
f01025ff:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102603:	75 0c                	jne    f0102611 <debuginfo_eip+0x1e2>
		return -1;
f0102605:	c7 45 c8 ff ff ff ff 	movl   $0xffffffff,-0x38(%ebp)
f010260c:	e9 ba 00 00 00       	jmp    f01026cb <debuginfo_eip+0x29c>

	/* Found line number, store it and search backwards for filename */
	info->eip_line = stabs[lline].n_desc;
f0102611:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102614:	89 d0                	mov    %edx,%eax
f0102616:	01 c0                	add    %eax,%eax
f0102618:	01 d0                	add    %edx,%eax
f010261a:	c1 e0 02             	shl    $0x2,%eax
f010261d:	03 45 f8             	add    -0x8(%ebp),%eax
f0102620:	0f b7 40 06          	movzwl 0x6(%eax),%eax
f0102624:	0f b7 d0             	movzwl %ax,%edx
f0102627:	8b 45 0c             	mov    0xc(%ebp),%eax
f010262a:	89 50 10             	mov    %edx,0x10(%eax)
f010262d:	eb 04                	jmp    f0102633 <debuginfo_eip+0x204>
	while (lline >= lfile && stabs[lline].n_type != N_SOL && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010262f:	83 6d d8 01          	subl   $0x1,-0x28(%ebp)
	if (lline == 0)
		return -1;

	/* Found line number, store it and search backwards for filename */
	info->eip_line = stabs[lline].n_desc;
	while (lline >= lfile && stabs[lline].n_type != N_SOL && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102633:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102636:	39 45 d8             	cmp    %eax,-0x28(%ebp)
f0102639:	7c 44                	jl     f010267f <debuginfo_eip+0x250>
f010263b:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010263e:	89 d0                	mov    %edx,%eax
f0102640:	01 c0                	add    %eax,%eax
f0102642:	01 d0                	add    %edx,%eax
f0102644:	c1 e0 02             	shl    $0x2,%eax
f0102647:	03 45 f8             	add    -0x8(%ebp),%eax
f010264a:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f010264e:	3c 84                	cmp    $0x84,%al
f0102650:	74 2d                	je     f010267f <debuginfo_eip+0x250>
f0102652:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102655:	89 d0                	mov    %edx,%eax
f0102657:	01 c0                	add    %eax,%eax
f0102659:	01 d0                	add    %edx,%eax
f010265b:	c1 e0 02             	shl    $0x2,%eax
f010265e:	03 45 f8             	add    -0x8(%ebp),%eax
f0102661:	0f b6 40 04          	movzbl 0x4(%eax),%eax
f0102665:	3c 64                	cmp    $0x64,%al
f0102667:	75 c6                	jne    f010262f <debuginfo_eip+0x200>
f0102669:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010266c:	89 d0                	mov    %edx,%eax
f010266e:	01 c0                	add    %eax,%eax
f0102670:	01 d0                	add    %edx,%eax
f0102672:	c1 e0 02             	shl    $0x2,%eax
f0102675:	03 45 f8             	add    -0x8(%ebp),%eax
f0102678:	8b 40 08             	mov    0x8(%eax),%eax
f010267b:	85 c0                	test   %eax,%eax
f010267d:	74 b0                	je     f010262f <debuginfo_eip+0x200>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010267f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0102682:	39 45 d8             	cmp    %eax,-0x28(%ebp)
f0102685:	7c 3d                	jl     f01026c4 <debuginfo_eip+0x295>
f0102687:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010268a:	89 d0                	mov    %edx,%eax
f010268c:	01 c0                	add    %eax,%eax
f010268e:	01 d0                	add    %edx,%eax
f0102690:	c1 e0 02             	shl    $0x2,%eax
f0102693:	03 45 f8             	add    -0x8(%ebp),%eax
f0102696:	8b 08                	mov    (%eax),%ecx
f0102698:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010269b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010269e:	89 d3                	mov    %edx,%ebx
f01026a0:	29 c3                	sub    %eax,%ebx
f01026a2:	89 d8                	mov    %ebx,%eax
f01026a4:	39 c1                	cmp    %eax,%ecx
f01026a6:	73 1c                	jae    f01026c4 <debuginfo_eip+0x295>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01026a8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01026ab:	89 d0                	mov    %edx,%eax
f01026ad:	01 c0                	add    %eax,%eax
f01026af:	01 d0                	add    %edx,%eax
f01026b1:	c1 e0 02             	shl    $0x2,%eax
f01026b4:	03 45 f8             	add    -0x8(%ebp),%eax
f01026b7:	8b 00                	mov    (%eax),%eax
f01026b9:	89 c2                	mov    %eax,%edx
f01026bb:	03 55 f0             	add    -0x10(%ebp),%edx
f01026be:	8b 45 0c             	mov    0xc(%ebp),%eax
f01026c1:	89 50 0c             	mov    %edx,0xc(%eax)
	
	return 0;
f01026c4:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f01026cb:	8b 45 c8             	mov    -0x38(%ebp),%eax
}
f01026ce:	83 c4 54             	add    $0x54,%esp
f01026d1:	5b                   	pop    %ebx
f01026d2:	5d                   	pop    %ebp
f01026d3:	c3                   	ret    

f01026d4 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01026d4:	55                   	push   %ebp
f01026d5:	89 e5                	mov    %esp,%ebp
f01026d7:	53                   	push   %ebx
f01026d8:	83 ec 34             	sub    $0x34,%esp
f01026db:	8b 45 10             	mov    0x10(%ebp),%eax
f01026de:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01026e1:	8b 45 14             	mov    0x14(%ebp),%eax
f01026e4:	89 45 f4             	mov    %eax,-0xc(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01026e7:	8b 45 18             	mov    0x18(%ebp),%eax
f01026ea:	ba 00 00 00 00       	mov    $0x0,%edx
f01026ef:	89 45 e8             	mov    %eax,-0x18(%ebp)
f01026f2:	89 55 ec             	mov    %edx,-0x14(%ebp)
f01026f5:	8b 55 ec             	mov    -0x14(%ebp),%edx
f01026f8:	3b 55 f4             	cmp    -0xc(%ebp),%edx
f01026fb:	77 7c                	ja     f0102779 <printnum+0xa5>
f01026fd:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102700:	3b 45 f4             	cmp    -0xc(%ebp),%eax
f0102703:	72 08                	jb     f010270d <printnum+0x39>
f0102705:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102708:	3b 55 f0             	cmp    -0x10(%ebp),%edx
f010270b:	77 6c                	ja     f0102779 <printnum+0xa5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010270d:	8b 45 1c             	mov    0x1c(%ebp),%eax
f0102710:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0102713:	8b 45 18             	mov    0x18(%ebp),%eax
f0102716:	ba 00 00 00 00       	mov    $0x0,%edx
f010271b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010271f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102723:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102726:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0102729:	89 04 24             	mov    %eax,(%esp)
f010272c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102730:	e8 fb 0c 00 00       	call   f0103430 <__udivdi3>
f0102735:	89 d1                	mov    %edx,%ecx
f0102737:	89 c2                	mov    %eax,%edx
f0102739:	8b 45 20             	mov    0x20(%ebp),%eax
f010273c:	89 44 24 18          	mov    %eax,0x18(%esp)
f0102740:	89 5c 24 14          	mov    %ebx,0x14(%esp)
f0102744:	8b 45 18             	mov    0x18(%ebp),%eax
f0102747:	89 44 24 10          	mov    %eax,0x10(%esp)
f010274b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010274f:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102753:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102756:	89 44 24 04          	mov    %eax,0x4(%esp)
f010275a:	8b 45 08             	mov    0x8(%ebp),%eax
f010275d:	89 04 24             	mov    %eax,(%esp)
f0102760:	e8 6f ff ff ff       	call   f01026d4 <printnum>
f0102765:	eb 1c                	jmp    f0102783 <printnum+0xaf>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0102767:	8b 45 0c             	mov    0xc(%ebp),%eax
f010276a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010276e:	8b 45 20             	mov    0x20(%ebp),%eax
f0102771:	89 04 24             	mov    %eax,(%esp)
f0102774:	8b 45 08             	mov    0x8(%ebp),%eax
f0102777:	ff d0                	call   *%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102779:	83 6d 1c 01          	subl   $0x1,0x1c(%ebp)
f010277d:	83 7d 1c 00          	cmpl   $0x0,0x1c(%ebp)
f0102781:	7f e4                	jg     f0102767 <printnum+0x93>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102783:	8b 45 18             	mov    0x18(%ebp),%eax
f0102786:	ba 00 00 00 00       	mov    $0x0,%edx
f010278b:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f010278e:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0102791:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102795:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102799:	89 0c 24             	mov    %ecx,(%esp)
f010279c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01027a0:	e8 bb 0d 00 00       	call   f0103560 <__umoddi3>
f01027a5:	05 20 3f 10 f0       	add    $0xf0103f20,%eax
f01027aa:	0f b6 00             	movzbl (%eax),%eax
f01027ad:	0f be d0             	movsbl %al,%edx
f01027b0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01027b3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01027b7:	89 14 24             	mov    %edx,(%esp)
f01027ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01027bd:	ff d0                	call   *%eax
}
f01027bf:	83 c4 34             	add    $0x34,%esp
f01027c2:	5b                   	pop    %ebx
f01027c3:	5d                   	pop    %ebp
f01027c4:	c3                   	ret    

f01027c5 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01027c5:	55                   	push   %ebp
f01027c6:	89 e5                	mov    %esp,%ebp
f01027c8:	83 ec 08             	sub    $0x8,%esp
	if (lflag >= 2)
f01027cb:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f01027cf:	7e 22                	jle    f01027f3 <getuint+0x2e>
		return va_arg(*ap, unsigned long long);
f01027d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01027d4:	8b 00                	mov    (%eax),%eax
f01027d6:	8d 50 08             	lea    0x8(%eax),%edx
f01027d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01027dc:	89 10                	mov    %edx,(%eax)
f01027de:	8b 45 08             	mov    0x8(%ebp),%eax
f01027e1:	8b 00                	mov    (%eax),%eax
f01027e3:	83 e8 08             	sub    $0x8,%eax
f01027e6:	8b 10                	mov    (%eax),%edx
f01027e8:	8b 48 04             	mov    0x4(%eax),%ecx
f01027eb:	89 55 f8             	mov    %edx,-0x8(%ebp)
f01027ee:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f01027f1:	eb 4a                	jmp    f010283d <getuint+0x78>
	else if (lflag)
f01027f3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01027f7:	74 23                	je     f010281c <getuint+0x57>
		return va_arg(*ap, unsigned long);
f01027f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01027fc:	8b 00                	mov    (%eax),%eax
f01027fe:	8d 50 04             	lea    0x4(%eax),%edx
f0102801:	8b 45 08             	mov    0x8(%ebp),%eax
f0102804:	89 10                	mov    %edx,(%eax)
f0102806:	8b 45 08             	mov    0x8(%ebp),%eax
f0102809:	8b 00                	mov    (%eax),%eax
f010280b:	83 e8 04             	sub    $0x4,%eax
f010280e:	8b 00                	mov    (%eax),%eax
f0102810:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0102813:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f010281a:	eb 21                	jmp    f010283d <getuint+0x78>
	else
		return va_arg(*ap, unsigned int);
f010281c:	8b 45 08             	mov    0x8(%ebp),%eax
f010281f:	8b 00                	mov    (%eax),%eax
f0102821:	8d 50 04             	lea    0x4(%eax),%edx
f0102824:	8b 45 08             	mov    0x8(%ebp),%eax
f0102827:	89 10                	mov    %edx,(%eax)
f0102829:	8b 45 08             	mov    0x8(%ebp),%eax
f010282c:	8b 00                	mov    (%eax),%eax
f010282e:	83 e8 04             	sub    $0x4,%eax
f0102831:	8b 00                	mov    (%eax),%eax
f0102833:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0102836:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f010283d:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0102840:	8b 55 fc             	mov    -0x4(%ebp),%edx
}
f0102843:	c9                   	leave  
f0102844:	c3                   	ret    

f0102845 <getint>:

// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
f0102845:	55                   	push   %ebp
f0102846:	89 e5                	mov    %esp,%ebp
f0102848:	83 ec 08             	sub    $0x8,%esp
	if (lflag >= 2)
f010284b:	83 7d 0c 01          	cmpl   $0x1,0xc(%ebp)
f010284f:	7e 22                	jle    f0102873 <getint+0x2e>
		return va_arg(*ap, long long);
f0102851:	8b 45 08             	mov    0x8(%ebp),%eax
f0102854:	8b 00                	mov    (%eax),%eax
f0102856:	8d 50 08             	lea    0x8(%eax),%edx
f0102859:	8b 45 08             	mov    0x8(%ebp),%eax
f010285c:	89 10                	mov    %edx,(%eax)
f010285e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102861:	8b 00                	mov    (%eax),%eax
f0102863:	83 e8 08             	sub    $0x8,%eax
f0102866:	8b 10                	mov    (%eax),%edx
f0102868:	8b 48 04             	mov    0x4(%eax),%ecx
f010286b:	89 55 f8             	mov    %edx,-0x8(%ebp)
f010286e:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f0102871:	eb 4c                	jmp    f01028bf <getint+0x7a>
	else if (lflag)
f0102873:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0102877:	74 24                	je     f010289d <getint+0x58>
		return va_arg(*ap, long);
f0102879:	8b 45 08             	mov    0x8(%ebp),%eax
f010287c:	8b 00                	mov    (%eax),%eax
f010287e:	8d 50 04             	lea    0x4(%eax),%edx
f0102881:	8b 45 08             	mov    0x8(%ebp),%eax
f0102884:	89 10                	mov    %edx,(%eax)
f0102886:	8b 45 08             	mov    0x8(%ebp),%eax
f0102889:	8b 00                	mov    (%eax),%eax
f010288b:	83 e8 04             	sub    $0x4,%eax
f010288e:	8b 00                	mov    (%eax),%eax
f0102890:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0102893:	89 c1                	mov    %eax,%ecx
f0102895:	c1 f9 1f             	sar    $0x1f,%ecx
f0102898:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f010289b:	eb 22                	jmp    f01028bf <getint+0x7a>
	else
		return va_arg(*ap, int);
f010289d:	8b 45 08             	mov    0x8(%ebp),%eax
f01028a0:	8b 00                	mov    (%eax),%eax
f01028a2:	8d 50 04             	lea    0x4(%eax),%edx
f01028a5:	8b 45 08             	mov    0x8(%ebp),%eax
f01028a8:	89 10                	mov    %edx,(%eax)
f01028aa:	8b 45 08             	mov    0x8(%ebp),%eax
f01028ad:	8b 00                	mov    (%eax),%eax
f01028af:	83 e8 04             	sub    $0x4,%eax
f01028b2:	8b 00                	mov    (%eax),%eax
f01028b4:	89 45 f8             	mov    %eax,-0x8(%ebp)
f01028b7:	89 c2                	mov    %eax,%edx
f01028b9:	c1 fa 1f             	sar    $0x1f,%edx
f01028bc:	89 55 fc             	mov    %edx,-0x4(%ebp)
f01028bf:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01028c2:	8b 55 fc             	mov    -0x4(%ebp),%edx
}
f01028c5:	c9                   	leave  
f01028c6:	c3                   	ret    

f01028c7 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01028c7:	55                   	push   %ebp
f01028c8:	89 e5                	mov    %esp,%ebp
f01028ca:	83 ec 58             	sub    $0x58,%esp
f01028cd:	eb 1c                	jmp    f01028eb <vprintfmt+0x24>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01028cf:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f01028d3:	0f 84 44 04 00 00    	je     f0102d1d <vprintfmt+0x456>
				return;
			putch(ch, putdat);
f01028d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01028e0:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01028e3:	89 04 24             	mov    %eax,(%esp)
f01028e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01028e9:	ff d0                	call   *%eax
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01028eb:	8b 45 10             	mov    0x10(%ebp),%eax
f01028ee:	0f b6 00             	movzbl (%eax),%eax
f01028f1:	0f b6 c0             	movzbl %al,%eax
f01028f4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01028f7:	83 7d d8 25          	cmpl   $0x25,-0x28(%ebp)
f01028fb:	0f 95 c0             	setne  %al
f01028fe:	83 45 10 01          	addl   $0x1,0x10(%ebp)
f0102902:	84 c0                	test   %al,%al
f0102904:	75 c9                	jne    f01028cf <vprintfmt+0x8>
				return;
			putch(ch, putdat);
		}

		// Process a %-escape sequence
		padc = ' ';
f0102906:	c6 45 ff 20          	movb   $0x20,-0x1(%ebp)
		width = -1;
f010290a:	c7 45 f0 ff ff ff ff 	movl   $0xffffffff,-0x10(%ebp)
		precision = -1;
f0102911:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
		lflag = 0;
f0102918:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
		altflag = 0;
f010291f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102926:	8b 45 10             	mov    0x10(%ebp),%eax
f0102929:	0f b6 00             	movzbl (%eax),%eax
f010292c:	0f b6 c0             	movzbl %al,%eax
f010292f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102932:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102935:	83 45 10 01          	addl   $0x1,0x10(%ebp)
f0102939:	83 e8 23             	sub    $0x23,%eax
f010293c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010293f:	83 7d d0 55          	cmpl   $0x55,-0x30(%ebp)
f0102943:	0f 87 86 03 00 00    	ja     f0102ccf <vprintfmt+0x408>
f0102949:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010294c:	8b 04 95 44 3f 10 f0 	mov    -0xfefc0bc(,%edx,4),%eax
f0102953:	ff e0                	jmp    *%eax

		// flag to pad on the right
		case '-':
			padc = '-';
f0102955:	c6 45 ff 2d          	movb   $0x2d,-0x1(%ebp)
f0102959:	eb cb                	jmp    f0102926 <vprintfmt+0x5f>
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f010295b:	c6 45 ff 30          	movb   $0x30,-0x1(%ebp)
f010295f:	eb c5                	jmp    f0102926 <vprintfmt+0x5f>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102961:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
				precision = precision * 10 + ch - '0';
f0102968:	8b 55 ec             	mov    -0x14(%ebp),%edx
f010296b:	89 d0                	mov    %edx,%eax
f010296d:	c1 e0 02             	shl    $0x2,%eax
f0102970:	01 d0                	add    %edx,%eax
f0102972:	01 c0                	add    %eax,%eax
f0102974:	03 45 d8             	add    -0x28(%ebp),%eax
f0102977:	83 e8 30             	sub    $0x30,%eax
f010297a:	89 45 ec             	mov    %eax,-0x14(%ebp)
				ch = *fmt;
f010297d:	8b 45 10             	mov    0x10(%ebp),%eax
f0102980:	0f b6 00             	movzbl (%eax),%eax
f0102983:	0f be c0             	movsbl %al,%eax
f0102986:	89 45 d8             	mov    %eax,-0x28(%ebp)
				if (ch < '0' || ch > '9')
f0102989:	83 7d d8 2f          	cmpl   $0x2f,-0x28(%ebp)
f010298d:	7e 44                	jle    f01029d3 <vprintfmt+0x10c>
f010298f:	83 7d d8 39          	cmpl   $0x39,-0x28(%ebp)
f0102993:	7f 3e                	jg     f01029d3 <vprintfmt+0x10c>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0102995:	83 45 10 01          	addl   $0x1,0x10(%ebp)
f0102999:	eb cd                	jmp    f0102968 <vprintfmt+0xa1>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f010299b:	8b 45 14             	mov    0x14(%ebp),%eax
f010299e:	83 c0 04             	add    $0x4,%eax
f01029a1:	89 45 14             	mov    %eax,0x14(%ebp)
f01029a4:	8b 45 14             	mov    0x14(%ebp),%eax
f01029a7:	83 e8 04             	sub    $0x4,%eax
f01029aa:	8b 00                	mov    (%eax),%eax
f01029ac:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01029af:	eb 22                	jmp    f01029d3 <vprintfmt+0x10c>
			goto process_precision;

		case '.':
			if (width < 0)
f01029b1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f01029b5:	0f 89 6b ff ff ff    	jns    f0102926 <vprintfmt+0x5f>
				width = 0;
f01029bb:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
f01029c2:	e9 5f ff ff ff       	jmp    f0102926 <vprintfmt+0x5f>
			goto reswitch;

		case '#':
			altflag = 1;
f01029c7:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01029ce:	e9 53 ff ff ff       	jmp    f0102926 <vprintfmt+0x5f>
			goto reswitch;

		process_precision:
			if (width < 0)
f01029d3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f01029d7:	0f 89 49 ff ff ff    	jns    f0102926 <vprintfmt+0x5f>
				width = precision, precision = -1;
f01029dd:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01029e0:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01029e3:	c7 45 ec ff ff ff ff 	movl   $0xffffffff,-0x14(%ebp)
f01029ea:	e9 37 ff ff ff       	jmp    f0102926 <vprintfmt+0x5f>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01029ef:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
f01029f3:	e9 2e ff ff ff       	jmp    f0102926 <vprintfmt+0x5f>
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01029f8:	8b 45 14             	mov    0x14(%ebp),%eax
f01029fb:	83 c0 04             	add    $0x4,%eax
f01029fe:	89 45 14             	mov    %eax,0x14(%ebp)
f0102a01:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a04:	83 e8 04             	sub    $0x4,%eax
f0102a07:	8b 10                	mov    (%eax),%edx
f0102a09:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a0c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102a10:	89 14 24             	mov    %edx,(%esp)
f0102a13:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a16:	ff d0                	call   *%eax
f0102a18:	e9 ce fe ff ff       	jmp    f01028eb <vprintfmt+0x24>
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0102a1d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a20:	83 c0 04             	add    $0x4,%eax
f0102a23:	89 45 14             	mov    %eax,0x14(%ebp)
f0102a26:	8b 45 14             	mov    0x14(%ebp),%eax
f0102a29:	83 e8 04             	sub    $0x4,%eax
f0102a2c:	8b 00                	mov    (%eax),%eax
f0102a2e:	89 45 dc             	mov    %eax,-0x24(%ebp)
			if (err < 0)
f0102a31:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102a35:	79 03                	jns    f0102a3a <vprintfmt+0x173>
				err = -err;
f0102a37:	f7 5d dc             	negl   -0x24(%ebp)
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f0102a3a:	83 7d dc 07          	cmpl   $0x7,-0x24(%ebp)
f0102a3e:	7f 13                	jg     f0102a53 <vprintfmt+0x18c>
f0102a40:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102a43:	8b 04 85 00 3f 10 f0 	mov    -0xfefc100(,%eax,4),%eax
f0102a4a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102a4d:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0102a51:	75 26                	jne    f0102a79 <vprintfmt+0x1b2>
				printfmt(putch, putdat, "error %d", err);
f0102a53:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102a56:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a5a:	c7 44 24 08 31 3f 10 	movl   $0xf0103f31,0x8(%esp)
f0102a61:	f0 
f0102a62:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a65:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102a69:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a6c:	89 04 24             	mov    %eax,(%esp)
f0102a6f:	e8 ab 02 00 00       	call   f0102d1f <printfmt>
f0102a74:	e9 72 fe ff ff       	jmp    f01028eb <vprintfmt+0x24>
			else
				printfmt(putch, putdat, "%s", p);
f0102a79:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102a7c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102a80:	c7 44 24 08 3a 3f 10 	movl   $0xf0103f3a,0x8(%esp)
f0102a87:	f0 
f0102a88:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102a8b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102a8f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a92:	89 04 24             	mov    %eax,(%esp)
f0102a95:	e8 85 02 00 00       	call   f0102d1f <printfmt>
f0102a9a:	e9 4c fe ff ff       	jmp    f01028eb <vprintfmt+0x24>
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0102a9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0102aa2:	83 c0 04             	add    $0x4,%eax
f0102aa5:	89 45 14             	mov    %eax,0x14(%ebp)
f0102aa8:	8b 45 14             	mov    0x14(%ebp),%eax
f0102aab:	83 e8 04             	sub    $0x4,%eax
f0102aae:	8b 00                	mov    (%eax),%eax
f0102ab0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102ab3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0102ab7:	75 07                	jne    f0102ac0 <vprintfmt+0x1f9>
				p = "(null)";
f0102ab9:	c7 45 d4 3d 3f 10 f0 	movl   $0xf0103f3d,-0x2c(%ebp)
			if (width > 0 && padc != '-')
f0102ac0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0102ac4:	7e 79                	jle    f0102b3f <vprintfmt+0x278>
f0102ac6:	80 7d ff 2d          	cmpb   $0x2d,-0x1(%ebp)
f0102aca:	74 73                	je     f0102b3f <vprintfmt+0x278>
				for (width -= strnlen(p, precision); width > 0; width--)
f0102acc:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0102acf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102ad3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ad6:	89 04 24             	mov    %eax,(%esp)
f0102ad9:	e8 64 04 00 00       	call   f0102f42 <strnlen>
f0102ade:	29 45 f0             	sub    %eax,-0x10(%ebp)
f0102ae1:	eb 17                	jmp    f0102afa <vprintfmt+0x233>
					putch(padc, putdat);
f0102ae3:	0f be 45 ff          	movsbl -0x1(%ebp),%eax
f0102ae7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102aea:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102aee:	89 04 24             	mov    %eax,(%esp)
f0102af1:	8b 45 08             	mov    0x8(%ebp),%eax
f0102af4:	ff d0                	call   *%eax
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0102af6:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
f0102afa:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0102afe:	7f e3                	jg     f0102ae3 <vprintfmt+0x21c>
f0102b00:	eb 3d                	jmp    f0102b3f <vprintfmt+0x278>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0102b02:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0102b06:	74 21                	je     f0102b29 <vprintfmt+0x262>
f0102b08:	83 7d d8 1f          	cmpl   $0x1f,-0x28(%ebp)
f0102b0c:	7e 06                	jle    f0102b14 <vprintfmt+0x24d>
f0102b0e:	83 7d d8 7e          	cmpl   $0x7e,-0x28(%ebp)
f0102b12:	7e 15                	jle    f0102b29 <vprintfmt+0x262>
					putch('?', putdat);
f0102b14:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b17:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102b1b:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0102b22:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b25:	ff d0                	call   *%eax
f0102b27:	eb 12                	jmp    f0102b3b <vprintfmt+0x274>
				else
					putch(ch, putdat);
f0102b29:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b2c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102b30:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102b33:	89 14 24             	mov    %edx,(%esp)
f0102b36:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b39:	ff d0                	call   *%eax
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102b3b:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
f0102b3f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102b42:	0f b6 02             	movzbl (%edx),%eax
f0102b45:	0f be c0             	movsbl %al,%eax
f0102b48:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102b4b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0102b4f:	0f 95 c0             	setne  %al
f0102b52:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
f0102b56:	83 f0 01             	xor    $0x1,%eax
f0102b59:	84 c0                	test   %al,%al
f0102b5b:	75 29                	jne    f0102b86 <vprintfmt+0x2bf>
f0102b5d:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102b61:	78 9f                	js     f0102b02 <vprintfmt+0x23b>
f0102b63:	83 6d ec 01          	subl   $0x1,-0x14(%ebp)
f0102b67:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102b6b:	79 95                	jns    f0102b02 <vprintfmt+0x23b>
f0102b6d:	eb 17                	jmp    f0102b86 <vprintfmt+0x2bf>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0102b6f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b72:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102b76:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0102b7d:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b80:	ff d0                	call   *%eax
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102b82:	83 6d f0 01          	subl   $0x1,-0x10(%ebp)
f0102b86:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
f0102b8a:	7f e3                	jg     f0102b6f <vprintfmt+0x2a8>
f0102b8c:	e9 5a fd ff ff       	jmp    f01028eb <vprintfmt+0x24>
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0102b91:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102b94:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102b98:	8d 45 14             	lea    0x14(%ebp),%eax
f0102b9b:	89 04 24             	mov    %eax,(%esp)
f0102b9e:	e8 a2 fc ff ff       	call   f0102845 <getint>
f0102ba3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102ba6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			if ((long long) num < 0) {
f0102ba9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102bac:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102baf:	85 d2                	test   %edx,%edx
f0102bb1:	79 26                	jns    f0102bd9 <vprintfmt+0x312>
				putch('-', putdat);
f0102bb3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102bb6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102bba:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0102bc1:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bc4:	ff d0                	call   *%eax
				num = -(long long) num;
f0102bc6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102bc9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102bcc:	f7 d8                	neg    %eax
f0102bce:	83 d2 00             	adc    $0x0,%edx
f0102bd1:	f7 da                	neg    %edx
f0102bd3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102bd6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			}
			base = 10;
f0102bd9:	c7 45 f8 0a 00 00 00 	movl   $0xa,-0x8(%ebp)
f0102be0:	e9 af 00 00 00       	jmp    f0102c94 <vprintfmt+0x3cd>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0102be5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102be8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102bec:	8d 45 14             	lea    0x14(%ebp),%eax
f0102bef:	89 04 24             	mov    %eax,(%esp)
f0102bf2:	e8 ce fb ff ff       	call   f01027c5 <getuint>
f0102bf7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102bfa:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			base = 10;
f0102bfd:	c7 45 f8 0a 00 00 00 	movl   $0xa,-0x8(%ebp)
f0102c04:	e9 8b 00 00 00       	jmp    f0102c94 <vprintfmt+0x3cd>
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0102c09:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102c0c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102c10:	8d 45 14             	lea    0x14(%ebp),%eax
f0102c13:	89 04 24             	mov    %eax,(%esp)
f0102c16:	e8 aa fb ff ff       	call   f01027c5 <getuint>
f0102c1b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c1e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			base = 8;
f0102c21:	c7 45 f8 08 00 00 00 	movl   $0x8,-0x8(%ebp)
f0102c28:	eb 6a                	jmp    f0102c94 <vprintfmt+0x3cd>
			goto number;

		// pointer
		case 'p':
			putch('0', putdat);
f0102c2a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c2d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102c31:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0102c38:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c3b:	ff d0                	call   *%eax
			putch('x', putdat);
f0102c3d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c40:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102c44:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0102c4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102c4e:	ff d0                	call   *%eax
			num = (unsigned long long)
f0102c50:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c53:	83 c0 04             	add    $0x4,%eax
f0102c56:	89 45 14             	mov    %eax,0x14(%ebp)
f0102c59:	8b 45 14             	mov    0x14(%ebp),%eax
f0102c5c:	83 e8 04             	sub    $0x4,%eax
f0102c5f:	8b 00                	mov    (%eax),%eax
f0102c61:	ba 00 00 00 00       	mov    $0x0,%edx
f0102c66:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c69:	89 55 e4             	mov    %edx,-0x1c(%ebp)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0102c6c:	c7 45 f8 10 00 00 00 	movl   $0x10,-0x8(%ebp)
f0102c73:	eb 1f                	jmp    f0102c94 <vprintfmt+0x3cd>
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102c75:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102c78:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102c7c:	8d 45 14             	lea    0x14(%ebp),%eax
f0102c7f:	89 04 24             	mov    %eax,(%esp)
f0102c82:	e8 3e fb ff ff       	call   f01027c5 <getuint>
f0102c87:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0102c8a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
			base = 16;
f0102c8d:	c7 45 f8 10 00 00 00 	movl   $0x10,-0x8(%ebp)
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102c94:	0f be 45 ff          	movsbl -0x1(%ebp),%eax
f0102c98:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0102c9b:	89 44 24 18          	mov    %eax,0x18(%esp)
f0102c9f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102ca2:	89 44 24 14          	mov    %eax,0x14(%esp)
f0102ca6:	89 54 24 10          	mov    %edx,0x10(%esp)
f0102caa:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102cad:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102cb0:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102cb4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102cb8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cbb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102cbf:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cc2:	89 04 24             	mov    %eax,(%esp)
f0102cc5:	e8 0a fa ff ff       	call   f01026d4 <printnum>
f0102cca:	e9 1c fc ff ff       	jmp    f01028eb <vprintfmt+0x24>
			break;

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0102ccf:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102cd2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102cd6:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0102cdd:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ce0:	ff d0                	call   *%eax
f0102ce2:	eb 13                	jmp    f0102cf7 <vprintfmt+0x430>
			while (lflag-- > 0)
				putch('l', putdat);
f0102ce4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ce7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102ceb:	c7 04 24 6c 00 00 00 	movl   $0x6c,(%esp)
f0102cf2:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cf5:	ff d0                	call   *%eax
			break;

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			while (lflag-- > 0)
f0102cf7:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0102cfb:	0f 9f c0             	setg   %al
f0102cfe:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
f0102d02:	84 c0                	test   %al,%al
f0102d04:	75 de                	jne    f0102ce4 <vprintfmt+0x41d>
				putch('l', putdat);
			/* FALLTHROUGH */

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102d06:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d09:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d0d:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102d10:	89 04 24             	mov    %eax,(%esp)
f0102d13:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d16:	ff d0                	call   *%eax
f0102d18:	e9 ce fb ff ff       	jmp    f01028eb <vprintfmt+0x24>
		}
	}
}
f0102d1d:	c9                   	leave  
f0102d1e:	c3                   	ret    

f0102d1f <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0102d1f:	55                   	push   %ebp
f0102d20:	89 e5                	mov    %esp,%ebp
f0102d22:	83 ec 28             	sub    $0x28,%esp
	va_list ap;

	va_start(ap, fmt);
f0102d25:	8d 45 10             	lea    0x10(%ebp),%eax
f0102d28:	83 c0 04             	add    $0x4,%eax
f0102d2b:	89 45 fc             	mov    %eax,-0x4(%ebp)
	vprintfmt(putch, putdat, fmt, ap);
f0102d2e:	8b 55 10             	mov    0x10(%ebp),%edx
f0102d31:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102d34:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d38:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102d3c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d3f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d43:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d46:	89 04 24             	mov    %eax,(%esp)
f0102d49:	e8 79 fb ff ff       	call   f01028c7 <vprintfmt>
	va_end(ap);
}
f0102d4e:	c9                   	leave  
f0102d4f:	c3                   	ret    

f0102d50 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0102d50:	55                   	push   %ebp
f0102d51:	89 e5                	mov    %esp,%ebp
	b->cnt++;
f0102d53:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d56:	8b 40 08             	mov    0x8(%eax),%eax
f0102d59:	8d 50 01             	lea    0x1(%eax),%edx
f0102d5c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d5f:	89 50 08             	mov    %edx,0x8(%eax)
	if (b->buf < b->ebuf)
f0102d62:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d65:	8b 10                	mov    (%eax),%edx
f0102d67:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d6a:	8b 40 04             	mov    0x4(%eax),%eax
f0102d6d:	39 c2                	cmp    %eax,%edx
f0102d6f:	73 12                	jae    f0102d83 <sprintputch+0x33>
		*b->buf++ = ch;
f0102d71:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d74:	8b 10                	mov    (%eax),%edx
f0102d76:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d79:	88 02                	mov    %al,(%edx)
f0102d7b:	83 c2 01             	add    $0x1,%edx
f0102d7e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d81:	89 10                	mov    %edx,(%eax)
}
f0102d83:	5d                   	pop    %ebp
f0102d84:	c3                   	ret    

f0102d85 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0102d85:	55                   	push   %ebp
f0102d86:	89 e5                	mov    %esp,%ebp
f0102d88:	83 ec 28             	sub    $0x28,%esp
	struct sprintbuf b = {buf, buf+n-1, 0};
f0102d8b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d8e:	83 e8 01             	sub    $0x1,%eax
f0102d91:	89 c2                	mov    %eax,%edx
f0102d93:	03 55 08             	add    0x8(%ebp),%edx
f0102d96:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d99:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0102d9c:	89 55 f8             	mov    %edx,-0x8(%ebp)
f0102d9f:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)

	if (buf == NULL || n < 1)
f0102da6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0102daa:	74 06                	je     f0102db2 <vsnprintf+0x2d>
f0102dac:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0102db0:	7f 09                	jg     f0102dbb <vsnprintf+0x36>
		return -E_INVAL;
f0102db2:	c7 45 ec fd ff ff ff 	movl   $0xfffffffd,-0x14(%ebp)
f0102db9:	eb 2e                	jmp    f0102de9 <vsnprintf+0x64>

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0102dbb:	ba 50 2d 10 f0       	mov    $0xf0102d50,%edx
f0102dc0:	8b 45 14             	mov    0x14(%ebp),%eax
f0102dc3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dc7:	8b 45 10             	mov    0x10(%ebp),%eax
f0102dca:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102dce:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102dd1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102dd5:	89 14 24             	mov    %edx,(%esp)
f0102dd8:	e8 ea fa ff ff       	call   f01028c7 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0102ddd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102de0:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102de3:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102de6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0102de9:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
f0102dec:	c9                   	leave  
f0102ded:	c3                   	ret    

f0102dee <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0102dee:	55                   	push   %ebp
f0102def:	89 e5                	mov    %esp,%ebp
f0102df1:	83 ec 28             	sub    $0x28,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102df4:	8d 45 10             	lea    0x10(%ebp),%eax
f0102df7:	83 c0 04             	add    $0x4,%eax
f0102dfa:	89 45 fc             	mov    %eax,-0x4(%ebp)
	rc = vsnprintf(buf, n, fmt, ap);
f0102dfd:	8b 55 10             	mov    0x10(%ebp),%edx
f0102e00:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102e03:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e07:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102e0b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e0e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102e12:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e15:	89 04 24             	mov    %eax,(%esp)
f0102e18:	e8 68 ff ff ff       	call   f0102d85 <vsnprintf>
f0102e1d:	89 45 f8             	mov    %eax,-0x8(%ebp)
	va_end(ap);

	return rc;
f0102e20:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0102e23:	c9                   	leave  
f0102e24:	c3                   	ret    
f0102e25:	00 00                	add    %al,(%eax)
	...

f0102e28 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102e28:	55                   	push   %ebp
f0102e29:	89 e5                	mov    %esp,%ebp
f0102e2b:	83 ec 28             	sub    $0x28,%esp
	int i, c, echoing;

	if (prompt != NULL)
f0102e2e:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0102e32:	74 13                	je     f0102e47 <readline+0x1f>
		cprintf("%s", prompt);
f0102e34:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e37:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102e3b:	c7 04 24 9c 40 10 f0 	movl   $0xf010409c,(%esp)
f0102e42:	e8 d0 f4 ff ff       	call   f0102317 <cprintf>

	i = 0;
f0102e47:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	echoing = iscons(0);
f0102e4e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e55:	e8 1a db ff ff       	call   f0100974 <iscons>
f0102e5a:	89 45 f4             	mov    %eax,-0xc(%ebp)
	while (1) {
		c = getchar();
f0102e5d:	e8 f9 da ff ff       	call   f010095b <getchar>
f0102e62:	89 45 f8             	mov    %eax,-0x8(%ebp)
		if (c < 0) {
f0102e65:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
f0102e69:	79 1f                	jns    f0102e8a <readline+0x62>
			cprintf("read error: %e\n", c);
f0102e6b:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0102e6e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102e72:	c7 04 24 9f 40 10 f0 	movl   $0xf010409f,(%esp)
f0102e79:	e8 99 f4 ff ff       	call   f0102317 <cprintf>
			return NULL;
f0102e7e:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
f0102e85:	e9 8a 00 00 00       	jmp    f0102f14 <readline+0xec>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0102e8a:	83 7d f8 1f          	cmpl   $0x1f,-0x8(%ebp)
f0102e8e:	7e 2c                	jle    f0102ebc <readline+0x94>
f0102e90:	81 7d fc fe 03 00 00 	cmpl   $0x3fe,-0x4(%ebp)
f0102e97:	7f 23                	jg     f0102ebc <readline+0x94>
			if (echoing)
f0102e99:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0102e9d:	74 0b                	je     f0102eaa <readline+0x82>
				cputchar(c);
f0102e9f:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0102ea2:	89 04 24             	mov    %eax,(%esp)
f0102ea5:	e8 9e da ff ff       	call   f0100948 <cputchar>
			buf[i++] = c;
f0102eaa:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102ead:	8b 55 f8             	mov    -0x8(%ebp),%edx
f0102eb0:	88 90 20 38 11 f0    	mov    %dl,-0xfeec7e0(%eax)
f0102eb6:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f0102eba:	eb a1                	jmp    f0102e5d <readline+0x35>
		} else if (c == '\b' && i > 0) {
f0102ebc:	83 7d f8 08          	cmpl   $0x8,-0x8(%ebp)
f0102ec0:	75 20                	jne    f0102ee2 <readline+0xba>
f0102ec2:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f0102ec6:	7e 1a                	jle    f0102ee2 <readline+0xba>
			if (echoing)
f0102ec8:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0102ecc:	74 0b                	je     f0102ed9 <readline+0xb1>
				cputchar(c);
f0102ece:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0102ed1:	89 04 24             	mov    %eax,(%esp)
f0102ed4:	e8 6f da ff ff       	call   f0100948 <cputchar>
			i--;
f0102ed9:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
f0102edd:	e9 7b ff ff ff       	jmp    f0102e5d <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0102ee2:	83 7d f8 0a          	cmpl   $0xa,-0x8(%ebp)
f0102ee6:	74 0a                	je     f0102ef2 <readline+0xca>
f0102ee8:	83 7d f8 0d          	cmpl   $0xd,-0x8(%ebp)
f0102eec:	0f 85 6b ff ff ff    	jne    f0102e5d <readline+0x35>
			if (echoing)
f0102ef2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
f0102ef6:	74 0b                	je     f0102f03 <readline+0xdb>
				cputchar(c);
f0102ef8:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0102efb:	89 04 24             	mov    %eax,(%esp)
f0102efe:	e8 45 da ff ff       	call   f0100948 <cputchar>
			buf[i] = 0;
f0102f03:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102f06:	c6 80 20 38 11 f0 00 	movb   $0x0,-0xfeec7e0(%eax)
			return buf;
f0102f0d:	c7 45 ec 20 38 11 f0 	movl   $0xf0113820,-0x14(%ebp)
		}
	}
f0102f14:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
f0102f17:	c9                   	leave  
f0102f18:	c3                   	ret    
f0102f19:	00 00                	add    %al,(%eax)
	...

f0102f1c <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f0102f1c:	55                   	push   %ebp
f0102f1d:	89 e5                	mov    %esp,%ebp
f0102f1f:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; *s != '\0'; s++)
f0102f22:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0102f29:	eb 08                	jmp    f0102f33 <strlen+0x17>
		n++;
f0102f2b:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0102f2f:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0102f33:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f36:	0f b6 00             	movzbl (%eax),%eax
f0102f39:	84 c0                	test   %al,%al
f0102f3b:	75 ee                	jne    f0102f2b <strlen+0xf>
		n++;
	return n;
f0102f3d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0102f40:	c9                   	leave  
f0102f41:	c3                   	ret    

f0102f42 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0102f42:	55                   	push   %ebp
f0102f43:	89 e5                	mov    %esp,%ebp
f0102f45:	83 ec 10             	sub    $0x10,%esp
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102f48:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0102f4f:	eb 0c                	jmp    f0102f5d <strnlen+0x1b>
		n++;
f0102f51:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102f55:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0102f59:	83 6d 0c 01          	subl   $0x1,0xc(%ebp)
f0102f5d:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0102f61:	74 0a                	je     f0102f6d <strnlen+0x2b>
f0102f63:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f66:	0f b6 00             	movzbl (%eax),%eax
f0102f69:	84 c0                	test   %al,%al
f0102f6b:	75 e4                	jne    f0102f51 <strnlen+0xf>
		n++;
	return n;
f0102f6d:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0102f70:	c9                   	leave  
f0102f71:	c3                   	ret    

f0102f72 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0102f72:	55                   	push   %ebp
f0102f73:	89 e5                	mov    %esp,%ebp
f0102f75:	83 ec 10             	sub    $0x10,%esp
	char *ret;

	ret = dst;
f0102f78:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f7b:	89 45 fc             	mov    %eax,-0x4(%ebp)
	while ((*dst++ = *src++) != '\0')
f0102f7e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f81:	0f b6 10             	movzbl (%eax),%edx
f0102f84:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f87:	88 10                	mov    %dl,(%eax)
f0102f89:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f8c:	0f b6 00             	movzbl (%eax),%eax
f0102f8f:	84 c0                	test   %al,%al
f0102f91:	0f 95 c0             	setne  %al
f0102f94:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0102f98:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0102f9c:	84 c0                	test   %al,%al
f0102f9e:	75 de                	jne    f0102f7e <strcpy+0xc>
		/* do nothing */;
	return ret;
f0102fa0:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f0102fa3:	c9                   	leave  
f0102fa4:	c3                   	ret    

f0102fa5 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0102fa5:	55                   	push   %ebp
f0102fa6:	89 e5                	mov    %esp,%ebp
f0102fa8:	83 ec 10             	sub    $0x10,%esp
	size_t i;
	char *ret;

	ret = dst;
f0102fab:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fae:	89 45 f8             	mov    %eax,-0x8(%ebp)
	for (i = 0; i < size; i++) {
f0102fb1:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f0102fb8:	eb 21                	jmp    f0102fdb <strncpy+0x36>
		*dst++ = *src;
f0102fba:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fbd:	0f b6 10             	movzbl (%eax),%edx
f0102fc0:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fc3:	88 10                	mov    %dl,(%eax)
f0102fc5:	83 45 08 01          	addl   $0x1,0x8(%ebp)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
f0102fc9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fcc:	0f b6 00             	movzbl (%eax),%eax
f0102fcf:	84 c0                	test   %al,%al
f0102fd1:	74 04                	je     f0102fd7 <strncpy+0x32>
			src++;
f0102fd3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0102fd7:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f0102fdb:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0102fde:	3b 45 10             	cmp    0x10(%ebp),%eax
f0102fe1:	72 d7                	jb     f0102fba <strncpy+0x15>
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
f0102fe3:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0102fe6:	c9                   	leave  
f0102fe7:	c3                   	ret    

f0102fe8 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0102fe8:	55                   	push   %ebp
f0102fe9:	89 e5                	mov    %esp,%ebp
f0102feb:	83 ec 10             	sub    $0x10,%esp
	char *dst_in;

	dst_in = dst;
f0102fee:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ff1:	89 45 fc             	mov    %eax,-0x4(%ebp)
	if (size > 0) {
f0102ff4:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0102ff8:	74 2f                	je     f0103029 <strlcpy+0x41>
f0102ffa:	eb 13                	jmp    f010300f <strlcpy+0x27>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0102ffc:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fff:	0f b6 10             	movzbl (%eax),%edx
f0103002:	8b 45 08             	mov    0x8(%ebp),%eax
f0103005:	88 10                	mov    %dl,(%eax)
f0103007:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f010300b:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010300f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f0103013:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0103017:	74 0a                	je     f0103023 <strlcpy+0x3b>
f0103019:	8b 45 0c             	mov    0xc(%ebp),%eax
f010301c:	0f b6 00             	movzbl (%eax),%eax
f010301f:	84 c0                	test   %al,%al
f0103021:	75 d9                	jne    f0102ffc <strlcpy+0x14>
			*dst++ = *src++;
		*dst = '\0';
f0103023:	8b 45 08             	mov    0x8(%ebp),%eax
f0103026:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103029:	8b 55 08             	mov    0x8(%ebp),%edx
f010302c:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010302f:	89 d1                	mov    %edx,%ecx
f0103031:	29 c1                	sub    %eax,%ecx
f0103033:	89 c8                	mov    %ecx,%eax
}
f0103035:	c9                   	leave  
f0103036:	c3                   	ret    

f0103037 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103037:	55                   	push   %ebp
f0103038:	89 e5                	mov    %esp,%ebp
f010303a:	eb 08                	jmp    f0103044 <strcmp+0xd>
	while (*p && *p == *q)
		p++, q++;
f010303c:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0103040:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103044:	8b 45 08             	mov    0x8(%ebp),%eax
f0103047:	0f b6 00             	movzbl (%eax),%eax
f010304a:	84 c0                	test   %al,%al
f010304c:	74 10                	je     f010305e <strcmp+0x27>
f010304e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103051:	0f b6 10             	movzbl (%eax),%edx
f0103054:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103057:	0f b6 00             	movzbl (%eax),%eax
f010305a:	38 c2                	cmp    %al,%dl
f010305c:	74 de                	je     f010303c <strcmp+0x5>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010305e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103061:	0f b6 00             	movzbl (%eax),%eax
f0103064:	0f b6 d0             	movzbl %al,%edx
f0103067:	8b 45 0c             	mov    0xc(%ebp),%eax
f010306a:	0f b6 00             	movzbl (%eax),%eax
f010306d:	0f b6 c0             	movzbl %al,%eax
f0103070:	89 d1                	mov    %edx,%ecx
f0103072:	29 c1                	sub    %eax,%ecx
f0103074:	89 c8                	mov    %ecx,%eax
}
f0103076:	5d                   	pop    %ebp
f0103077:	c3                   	ret    

f0103078 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103078:	55                   	push   %ebp
f0103079:	89 e5                	mov    %esp,%ebp
f010307b:	83 ec 04             	sub    $0x4,%esp
f010307e:	eb 0c                	jmp    f010308c <strncmp+0x14>
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
f0103080:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f0103084:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0103088:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010308c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0103090:	74 1a                	je     f01030ac <strncmp+0x34>
f0103092:	8b 45 08             	mov    0x8(%ebp),%eax
f0103095:	0f b6 00             	movzbl (%eax),%eax
f0103098:	84 c0                	test   %al,%al
f010309a:	74 10                	je     f01030ac <strncmp+0x34>
f010309c:	8b 45 08             	mov    0x8(%ebp),%eax
f010309f:	0f b6 10             	movzbl (%eax),%edx
f01030a2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030a5:	0f b6 00             	movzbl (%eax),%eax
f01030a8:	38 c2                	cmp    %al,%dl
f01030aa:	74 d4                	je     f0103080 <strncmp+0x8>
		n--, p++, q++;
	if (n == 0)
f01030ac:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01030b0:	75 09                	jne    f01030bb <strncmp+0x43>
		return 0;
f01030b2:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
f01030b9:	eb 19                	jmp    f01030d4 <strncmp+0x5c>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01030bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01030be:	0f b6 00             	movzbl (%eax),%eax
f01030c1:	0f b6 d0             	movzbl %al,%edx
f01030c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030c7:	0f b6 00             	movzbl (%eax),%eax
f01030ca:	0f b6 c0             	movzbl %al,%eax
f01030cd:	89 d1                	mov    %edx,%ecx
f01030cf:	29 c1                	sub    %eax,%ecx
f01030d1:	89 4d fc             	mov    %ecx,-0x4(%ebp)
f01030d4:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
f01030d7:	c9                   	leave  
f01030d8:	c3                   	ret    

f01030d9 <strchr>:

char *
strchr(const char *s, char c)
{
f01030d9:	55                   	push   %ebp
f01030da:	89 e5                	mov    %esp,%ebp
f01030dc:	83 ec 08             	sub    $0x8,%esp
f01030df:	8b 45 0c             	mov    0xc(%ebp),%eax
f01030e2:	88 45 fc             	mov    %al,-0x4(%ebp)
f01030e5:	eb 17                	jmp    f01030fe <strchr+0x25>
	for (; *s; s++)
		if (*s == c)
f01030e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01030ea:	0f b6 00             	movzbl (%eax),%eax
f01030ed:	3a 45 fc             	cmp    -0x4(%ebp),%al
f01030f0:	75 08                	jne    f01030fa <strchr+0x21>
			return (char *) s;
f01030f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01030f5:	89 45 f8             	mov    %eax,-0x8(%ebp)
f01030f8:	eb 15                	jmp    f010310f <strchr+0x36>
}

char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01030fa:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f01030fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103101:	0f b6 00             	movzbl (%eax),%eax
f0103104:	84 c0                	test   %al,%al
f0103106:	75 df                	jne    f01030e7 <strchr+0xe>
		if (*s == c)
			return (char *) s;
	return 0;
f0103108:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
f010310f:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
f0103112:	c9                   	leave  
f0103113:	c3                   	ret    

f0103114 <strfind>:

char *
strfind(const char *s, char c)
{
f0103114:	55                   	push   %ebp
f0103115:	89 e5                	mov    %esp,%ebp
f0103117:	83 ec 04             	sub    $0x4,%esp
f010311a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010311d:	88 45 fc             	mov    %al,-0x4(%ebp)
f0103120:	eb 0f                	jmp    f0103131 <strfind+0x1d>
	for (; *s; s++)
		if (*s == c)
f0103122:	8b 45 08             	mov    0x8(%ebp),%eax
f0103125:	0f b6 00             	movzbl (%eax),%eax
f0103128:	3a 45 fc             	cmp    -0x4(%ebp),%al
f010312b:	74 0e                	je     f010313b <strfind+0x27>
}

char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010312d:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0103131:	8b 45 08             	mov    0x8(%ebp),%eax
f0103134:	0f b6 00             	movzbl (%eax),%eax
f0103137:	84 c0                	test   %al,%al
f0103139:	75 e7                	jne    f0103122 <strfind+0xe>
		if (*s == c)
			break;
	return (char *) s;
f010313b:	8b 45 08             	mov    0x8(%ebp),%eax
}
f010313e:	c9                   	leave  
f010313f:	c3                   	ret    

f0103140 <memset>:


void *
memset(void *v, int c, size_t n)
{
f0103140:	55                   	push   %ebp
f0103141:	89 e5                	mov    %esp,%ebp
f0103143:	83 ec 10             	sub    $0x10,%esp
	char *p;
	int m;

	p = v;
f0103146:	8b 45 08             	mov    0x8(%ebp),%eax
f0103149:	89 45 fc             	mov    %eax,-0x4(%ebp)
	m = n;
f010314c:	8b 45 10             	mov    0x10(%ebp),%eax
f010314f:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0103152:	eb 0e                	jmp    f0103162 <memset+0x22>
	while (--m >= 0)
		*p++ = c;
f0103154:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103157:	89 c2                	mov    %eax,%edx
f0103159:	8b 45 fc             	mov    -0x4(%ebp),%eax
f010315c:	88 10                	mov    %dl,(%eax)
f010315e:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f0103162:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
f0103166:	83 7d f8 00          	cmpl   $0x0,-0x8(%ebp)
f010316a:	79 e8                	jns    f0103154 <memset+0x14>
		*p++ = c;

	return v;
f010316c:	8b 45 08             	mov    0x8(%ebp),%eax
}
f010316f:	c9                   	leave  
f0103170:	c3                   	ret    

f0103171 <memcpy>:

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103171:	55                   	push   %ebp
f0103172:	89 e5                	mov    %esp,%ebp
f0103174:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;

	s = src;
f0103177:	8b 45 0c             	mov    0xc(%ebp),%eax
f010317a:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
f010317d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103180:	89 45 f8             	mov    %eax,-0x8(%ebp)
f0103183:	eb 13                	jmp    f0103198 <memcpy+0x27>
	while (n-- > 0)
		*d++ = *s++;
f0103185:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0103188:	0f b6 10             	movzbl (%eax),%edx
f010318b:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010318e:	88 10                	mov    %dl,(%eax)
f0103190:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
f0103194:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
	const char *s;
	char *d;

	s = src;
	d = dst;
	while (n-- > 0)
f0103198:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010319c:	0f 95 c0             	setne  %al
f010319f:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f01031a3:	84 c0                	test   %al,%al
f01031a5:	75 de                	jne    f0103185 <memcpy+0x14>
		*d++ = *s++;

	return dst;
f01031a7:	8b 45 08             	mov    0x8(%ebp),%eax
}
f01031aa:	c9                   	leave  
f01031ab:	c3                   	ret    

f01031ac <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01031ac:	55                   	push   %ebp
f01031ad:	89 e5                	mov    %esp,%ebp
f01031af:	83 ec 10             	sub    $0x10,%esp
	const char *s;
	char *d;
	
	s = src;
f01031b2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031b5:	89 45 fc             	mov    %eax,-0x4(%ebp)
	d = dst;
f01031b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01031bb:	89 45 f8             	mov    %eax,-0x8(%ebp)
	if (s < d && s + n > d) {
f01031be:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01031c1:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f01031c4:	73 53                	jae    f0103219 <memmove+0x6d>
f01031c6:	8b 45 10             	mov    0x10(%ebp),%eax
f01031c9:	8b 55 fc             	mov    -0x4(%ebp),%edx
f01031cc:	8d 04 02             	lea    (%edx,%eax,1),%eax
f01031cf:	3b 45 f8             	cmp    -0x8(%ebp),%eax
f01031d2:	76 45                	jbe    f0103219 <memmove+0x6d>
		s += n;
f01031d4:	8b 45 10             	mov    0x10(%ebp),%eax
f01031d7:	01 45 fc             	add    %eax,-0x4(%ebp)
		d += n;
f01031da:	8b 45 10             	mov    0x10(%ebp),%eax
f01031dd:	01 45 f8             	add    %eax,-0x8(%ebp)
f01031e0:	eb 13                	jmp    f01031f5 <memmove+0x49>
		while (n-- > 0)
			*--d = *--s;
f01031e2:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
f01031e6:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
f01031ea:	8b 45 fc             	mov    -0x4(%ebp),%eax
f01031ed:	0f b6 10             	movzbl (%eax),%edx
f01031f0:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01031f3:	88 10                	mov    %dl,(%eax)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f01031f5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01031f9:	0f 95 c0             	setne  %al
f01031fc:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f0103200:	84 c0                	test   %al,%al
f0103202:	75 de                	jne    f01031e2 <memmove+0x36>
f0103204:	eb 22                	jmp    f0103228 <memmove+0x7c>
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
f0103206:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0103209:	0f b6 10             	movzbl (%eax),%edx
f010320c:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010320f:	88 10                	mov    %dl,(%eax)
f0103211:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
f0103215:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0103219:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010321d:	0f 95 c0             	setne  %al
f0103220:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f0103224:	84 c0                	test   %al,%al
f0103226:	75 de                	jne    f0103206 <memmove+0x5a>
			*d++ = *s++;

	return dst;
f0103228:	8b 45 08             	mov    0x8(%ebp),%eax
}
f010322b:	c9                   	leave  
f010322c:	c3                   	ret    

f010322d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010322d:	55                   	push   %ebp
f010322e:	89 e5                	mov    %esp,%ebp
f0103230:	83 ec 14             	sub    $0x14,%esp
	const uint8_t *s1 = (const uint8_t *) v1;
f0103233:	8b 45 08             	mov    0x8(%ebp),%eax
f0103236:	89 45 fc             	mov    %eax,-0x4(%ebp)
	const uint8_t *s2 = (const uint8_t *) v2;
f0103239:	8b 45 0c             	mov    0xc(%ebp),%eax
f010323c:	89 45 f8             	mov    %eax,-0x8(%ebp)
f010323f:	eb 33                	jmp    f0103274 <memcmp+0x47>

	while (n-- > 0) {
		if (*s1 != *s2)
f0103241:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0103244:	0f b6 10             	movzbl (%eax),%edx
f0103247:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010324a:	0f b6 00             	movzbl (%eax),%eax
f010324d:	38 c2                	cmp    %al,%dl
f010324f:	74 1b                	je     f010326c <memcmp+0x3f>
			return (int) *s1 - (int) *s2;
f0103251:	8b 45 fc             	mov    -0x4(%ebp),%eax
f0103254:	0f b6 00             	movzbl (%eax),%eax
f0103257:	0f b6 d0             	movzbl %al,%edx
f010325a:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010325d:	0f b6 00             	movzbl (%eax),%eax
f0103260:	0f b6 c0             	movzbl %al,%eax
f0103263:	89 d1                	mov    %edx,%ecx
f0103265:	29 c1                	sub    %eax,%ecx
f0103267:	89 4d ec             	mov    %ecx,-0x14(%ebp)
f010326a:	eb 1e                	jmp    f010328a <memcmp+0x5d>
		s1++, s2++;
f010326c:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
f0103270:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103274:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0103278:	0f 95 c0             	setne  %al
f010327b:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
f010327f:	84 c0                	test   %al,%al
f0103281:	75 be                	jne    f0103241 <memcmp+0x14>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103283:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
f010328a:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
f010328d:	c9                   	leave  
f010328e:	c3                   	ret    

f010328f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010328f:	55                   	push   %ebp
f0103290:	89 e5                	mov    %esp,%ebp
f0103292:	83 ec 10             	sub    $0x10,%esp
	const void *ends = (const char *) s + n;
f0103295:	8b 45 10             	mov    0x10(%ebp),%eax
f0103298:	8b 55 08             	mov    0x8(%ebp),%edx
f010329b:	8d 04 02             	lea    (%edx,%eax,1),%eax
f010329e:	89 45 fc             	mov    %eax,-0x4(%ebp)
f01032a1:	eb 11                	jmp    f01032b4 <memfind+0x25>
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01032a3:	8b 45 08             	mov    0x8(%ebp),%eax
f01032a6:	0f b6 10             	movzbl (%eax),%edx
f01032a9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032ac:	38 c2                	cmp    %al,%dl
f01032ae:	74 0c                	je     f01032bc <memfind+0x2d>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01032b0:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f01032b4:	8b 45 08             	mov    0x8(%ebp),%eax
f01032b7:	3b 45 fc             	cmp    -0x4(%ebp),%eax
f01032ba:	72 e7                	jb     f01032a3 <memfind+0x14>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
f01032bc:	8b 45 08             	mov    0x8(%ebp),%eax
}
f01032bf:	c9                   	leave  
f01032c0:	c3                   	ret    

f01032c1 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01032c1:	55                   	push   %ebp
f01032c2:	89 e5                	mov    %esp,%ebp
f01032c4:	83 ec 14             	sub    $0x14,%esp
	int neg = 0;
f01032c7:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
	long val = 0;
f01032ce:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
f01032d5:	eb 04                	jmp    f01032db <strtol+0x1a>

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
		s++;
f01032d7:	83 45 08 01          	addl   $0x1,0x8(%ebp)
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01032db:	8b 45 08             	mov    0x8(%ebp),%eax
f01032de:	0f b6 00             	movzbl (%eax),%eax
f01032e1:	3c 20                	cmp    $0x20,%al
f01032e3:	74 f2                	je     f01032d7 <strtol+0x16>
f01032e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01032e8:	0f b6 00             	movzbl (%eax),%eax
f01032eb:	3c 09                	cmp    $0x9,%al
f01032ed:	74 e8                	je     f01032d7 <strtol+0x16>
		s++;

	// plus/minus sign
	if (*s == '+')
f01032ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01032f2:	0f b6 00             	movzbl (%eax),%eax
f01032f5:	3c 2b                	cmp    $0x2b,%al
f01032f7:	75 06                	jne    f01032ff <strtol+0x3e>
		s++;
f01032f9:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f01032fd:	eb 15                	jmp    f0103314 <strtol+0x53>
	else if (*s == '-')
f01032ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0103302:	0f b6 00             	movzbl (%eax),%eax
f0103305:	3c 2d                	cmp    $0x2d,%al
f0103307:	75 0b                	jne    f0103314 <strtol+0x53>
		s++, neg = 1;
f0103309:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f010330d:	c7 45 fc 01 00 00 00 	movl   $0x1,-0x4(%ebp)

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103314:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0103318:	74 06                	je     f0103320 <strtol+0x5f>
f010331a:	83 7d 10 10          	cmpl   $0x10,0x10(%ebp)
f010331e:	75 24                	jne    f0103344 <strtol+0x83>
f0103320:	8b 45 08             	mov    0x8(%ebp),%eax
f0103323:	0f b6 00             	movzbl (%eax),%eax
f0103326:	3c 30                	cmp    $0x30,%al
f0103328:	75 1a                	jne    f0103344 <strtol+0x83>
f010332a:	8b 45 08             	mov    0x8(%ebp),%eax
f010332d:	83 c0 01             	add    $0x1,%eax
f0103330:	0f b6 00             	movzbl (%eax),%eax
f0103333:	3c 78                	cmp    $0x78,%al
f0103335:	75 0d                	jne    f0103344 <strtol+0x83>
		s += 2, base = 16;
f0103337:	83 45 08 02          	addl   $0x2,0x8(%ebp)
f010333b:	c7 45 10 10 00 00 00 	movl   $0x10,0x10(%ebp)
f0103342:	eb 2a                	jmp    f010336e <strtol+0xad>
	else if (base == 0 && s[0] == '0')
f0103344:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0103348:	75 17                	jne    f0103361 <strtol+0xa0>
f010334a:	8b 45 08             	mov    0x8(%ebp),%eax
f010334d:	0f b6 00             	movzbl (%eax),%eax
f0103350:	3c 30                	cmp    $0x30,%al
f0103352:	75 0d                	jne    f0103361 <strtol+0xa0>
		s++, base = 8;
f0103354:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f0103358:	c7 45 10 08 00 00 00 	movl   $0x8,0x10(%ebp)
f010335f:	eb 0d                	jmp    f010336e <strtol+0xad>
	else if (base == 0)
f0103361:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0103365:	75 07                	jne    f010336e <strtol+0xad>
		base = 10;
f0103367:	c7 45 10 0a 00 00 00 	movl   $0xa,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010336e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103371:	0f b6 00             	movzbl (%eax),%eax
f0103374:	3c 2f                	cmp    $0x2f,%al
f0103376:	7e 1b                	jle    f0103393 <strtol+0xd2>
f0103378:	8b 45 08             	mov    0x8(%ebp),%eax
f010337b:	0f b6 00             	movzbl (%eax),%eax
f010337e:	3c 39                	cmp    $0x39,%al
f0103380:	7f 11                	jg     f0103393 <strtol+0xd2>
			dig = *s - '0';
f0103382:	8b 45 08             	mov    0x8(%ebp),%eax
f0103385:	0f b6 00             	movzbl (%eax),%eax
f0103388:	0f be c0             	movsbl %al,%eax
f010338b:	83 e8 30             	sub    $0x30,%eax
f010338e:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0103391:	eb 48                	jmp    f01033db <strtol+0x11a>
		else if (*s >= 'a' && *s <= 'z')
f0103393:	8b 45 08             	mov    0x8(%ebp),%eax
f0103396:	0f b6 00             	movzbl (%eax),%eax
f0103399:	3c 60                	cmp    $0x60,%al
f010339b:	7e 1b                	jle    f01033b8 <strtol+0xf7>
f010339d:	8b 45 08             	mov    0x8(%ebp),%eax
f01033a0:	0f b6 00             	movzbl (%eax),%eax
f01033a3:	3c 7a                	cmp    $0x7a,%al
f01033a5:	7f 11                	jg     f01033b8 <strtol+0xf7>
			dig = *s - 'a' + 10;
f01033a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01033aa:	0f b6 00             	movzbl (%eax),%eax
f01033ad:	0f be c0             	movsbl %al,%eax
f01033b0:	83 e8 57             	sub    $0x57,%eax
f01033b3:	89 45 f4             	mov    %eax,-0xc(%ebp)
f01033b6:	eb 23                	jmp    f01033db <strtol+0x11a>
		else if (*s >= 'A' && *s <= 'Z')
f01033b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01033bb:	0f b6 00             	movzbl (%eax),%eax
f01033be:	3c 40                	cmp    $0x40,%al
f01033c0:	7e 37                	jle    f01033f9 <strtol+0x138>
f01033c2:	8b 45 08             	mov    0x8(%ebp),%eax
f01033c5:	0f b6 00             	movzbl (%eax),%eax
f01033c8:	3c 5a                	cmp    $0x5a,%al
f01033ca:	7f 2d                	jg     f01033f9 <strtol+0x138>
			dig = *s - 'A' + 10;
f01033cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01033cf:	0f b6 00             	movzbl (%eax),%eax
f01033d2:	0f be c0             	movsbl %al,%eax
f01033d5:	83 e8 37             	sub    $0x37,%eax
f01033d8:	89 45 f4             	mov    %eax,-0xc(%ebp)
		else
			break;
		if (dig >= base)
f01033db:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01033de:	3b 45 10             	cmp    0x10(%ebp),%eax
f01033e1:	7d 16                	jge    f01033f9 <strtol+0x138>
			break;
		s++, val = (val * base) + dig;
f01033e3:	83 45 08 01          	addl   $0x1,0x8(%ebp)
f01033e7:	8b 45 f8             	mov    -0x8(%ebp),%eax
f01033ea:	0f af 45 10          	imul   0x10(%ebp),%eax
f01033ee:	03 45 f4             	add    -0xc(%ebp),%eax
f01033f1:	89 45 f8             	mov    %eax,-0x8(%ebp)
f01033f4:	e9 75 ff ff ff       	jmp    f010336e <strtol+0xad>
		// we don't properly detect overflow!
	}

	if (endptr)
f01033f9:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01033fd:	74 08                	je     f0103407 <strtol+0x146>
		*endptr = (char *) s;
f01033ff:	8b 55 08             	mov    0x8(%ebp),%edx
f0103402:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103405:	89 10                	mov    %edx,(%eax)
	return (neg ? -val : val);
f0103407:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
f010340b:	74 0c                	je     f0103419 <strtol+0x158>
f010340d:	8b 45 f8             	mov    -0x8(%ebp),%eax
f0103410:	89 c2                	mov    %eax,%edx
f0103412:	f7 da                	neg    %edx
f0103414:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0103417:	eb 06                	jmp    f010341f <strtol+0x15e>
f0103419:	8b 45 f8             	mov    -0x8(%ebp),%eax
f010341c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010341f:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
f0103422:	c9                   	leave  
f0103423:	c3                   	ret    
	...

f0103430 <__udivdi3>:
f0103430:	55                   	push   %ebp
f0103431:	89 e5                	mov    %esp,%ebp
f0103433:	57                   	push   %edi
f0103434:	56                   	push   %esi
f0103435:	83 ec 1c             	sub    $0x1c,%esp
f0103438:	8b 45 10             	mov    0x10(%ebp),%eax
f010343b:	8b 55 08             	mov    0x8(%ebp),%edx
f010343e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103441:	89 c6                	mov    %eax,%esi
f0103443:	8b 45 14             	mov    0x14(%ebp),%eax
f0103446:	89 55 ec             	mov    %edx,-0x14(%ebp)
f0103449:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010344c:	85 c0                	test   %eax,%eax
f010344e:	75 38                	jne    f0103488 <__udivdi3+0x58>
f0103450:	39 ce                	cmp    %ecx,%esi
f0103452:	77 4c                	ja     f01034a0 <__udivdi3+0x70>
f0103454:	85 f6                	test   %esi,%esi
f0103456:	75 0d                	jne    f0103465 <__udivdi3+0x35>
f0103458:	b9 01 00 00 00       	mov    $0x1,%ecx
f010345d:	31 d2                	xor    %edx,%edx
f010345f:	89 c8                	mov    %ecx,%eax
f0103461:	f7 f6                	div    %esi
f0103463:	89 c6                	mov    %eax,%esi
f0103465:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0103468:	31 d2                	xor    %edx,%edx
f010346a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010346d:	89 f8                	mov    %edi,%eax
f010346f:	f7 f6                	div    %esi
f0103471:	89 c7                	mov    %eax,%edi
f0103473:	89 c8                	mov    %ecx,%eax
f0103475:	f7 f6                	div    %esi
f0103477:	89 fe                	mov    %edi,%esi
f0103479:	89 c1                	mov    %eax,%ecx
f010347b:	89 c8                	mov    %ecx,%eax
f010347d:	89 f2                	mov    %esi,%edx
f010347f:	83 c4 1c             	add    $0x1c,%esp
f0103482:	5e                   	pop    %esi
f0103483:	5f                   	pop    %edi
f0103484:	5d                   	pop    %ebp
f0103485:	c3                   	ret    
f0103486:	66 90                	xchg   %ax,%ax
f0103488:	3b 45 dc             	cmp    -0x24(%ebp),%eax
f010348b:	76 2b                	jbe    f01034b8 <__udivdi3+0x88>
f010348d:	31 c9                	xor    %ecx,%ecx
f010348f:	31 f6                	xor    %esi,%esi
f0103491:	89 c8                	mov    %ecx,%eax
f0103493:	89 f2                	mov    %esi,%edx
f0103495:	83 c4 1c             	add    $0x1c,%esp
f0103498:	5e                   	pop    %esi
f0103499:	5f                   	pop    %edi
f010349a:	5d                   	pop    %ebp
f010349b:	c3                   	ret    
f010349c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01034a0:	89 d1                	mov    %edx,%ecx
f01034a2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034a5:	89 c8                	mov    %ecx,%eax
f01034a7:	f7 f6                	div    %esi
f01034a9:	31 f6                	xor    %esi,%esi
f01034ab:	89 c1                	mov    %eax,%ecx
f01034ad:	89 c8                	mov    %ecx,%eax
f01034af:	89 f2                	mov    %esi,%edx
f01034b1:	83 c4 1c             	add    $0x1c,%esp
f01034b4:	5e                   	pop    %esi
f01034b5:	5f                   	pop    %edi
f01034b6:	5d                   	pop    %ebp
f01034b7:	c3                   	ret    
f01034b8:	0f bd f8             	bsr    %eax,%edi
f01034bb:	83 f7 1f             	xor    $0x1f,%edi
f01034be:	75 20                	jne    f01034e0 <__udivdi3+0xb0>
f01034c0:	3b 45 dc             	cmp    -0x24(%ebp),%eax
f01034c3:	72 05                	jb     f01034ca <__udivdi3+0x9a>
f01034c5:	3b 75 ec             	cmp    -0x14(%ebp),%esi
f01034c8:	77 c3                	ja     f010348d <__udivdi3+0x5d>
f01034ca:	b9 01 00 00 00       	mov    $0x1,%ecx
f01034cf:	31 f6                	xor    %esi,%esi
f01034d1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01034d8:	eb b7                	jmp    f0103491 <__udivdi3+0x61>
f01034da:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034e0:	89 f9                	mov    %edi,%ecx
f01034e2:	89 f2                	mov    %esi,%edx
f01034e4:	d3 e0                	shl    %cl,%eax
f01034e6:	b9 20 00 00 00       	mov    $0x20,%ecx
f01034eb:	29 f9                	sub    %edi,%ecx
f01034ed:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01034f0:	d3 ea                	shr    %cl,%edx
f01034f2:	89 f9                	mov    %edi,%ecx
f01034f4:	d3 e6                	shl    %cl,%esi
f01034f6:	0f b6 4d e0          	movzbl -0x20(%ebp),%ecx
f01034fa:	09 d0                	or     %edx,%eax
f01034fc:	89 75 f4             	mov    %esi,-0xc(%ebp)
f01034ff:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103502:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103505:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103508:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010350b:	d3 ee                	shr    %cl,%esi
f010350d:	89 f9                	mov    %edi,%ecx
f010350f:	d3 e2                	shl    %cl,%edx
f0103511:	0f b6 4d e0          	movzbl -0x20(%ebp),%ecx
f0103515:	d3 e8                	shr    %cl,%eax
f0103517:	09 d0                	or     %edx,%eax
f0103519:	89 f2                	mov    %esi,%edx
f010351b:	f7 75 f0             	divl   -0x10(%ebp)
f010351e:	89 d6                	mov    %edx,%esi
f0103520:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103523:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103526:	f7 65 e0             	mull   -0x20(%ebp)
f0103529:	39 d6                	cmp    %edx,%esi
f010352b:	89 45 e8             	mov    %eax,-0x18(%ebp)
f010352e:	72 20                	jb     f0103550 <__udivdi3+0x120>
f0103530:	74 0e                	je     f0103540 <__udivdi3+0x110>
f0103532:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103535:	31 f6                	xor    %esi,%esi
f0103537:	e9 55 ff ff ff       	jmp    f0103491 <__udivdi3+0x61>
f010353c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103540:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103543:	89 f9                	mov    %edi,%ecx
f0103545:	d3 e0                	shl    %cl,%eax
f0103547:	3b 45 e8             	cmp    -0x18(%ebp),%eax
f010354a:	73 e6                	jae    f0103532 <__udivdi3+0x102>
f010354c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103550:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103553:	31 f6                	xor    %esi,%esi
f0103555:	83 e9 01             	sub    $0x1,%ecx
f0103558:	e9 34 ff ff ff       	jmp    f0103491 <__udivdi3+0x61>
f010355d:	00 00                	add    %al,(%eax)
	...

f0103560 <__umoddi3>:
f0103560:	55                   	push   %ebp
f0103561:	89 e5                	mov    %esp,%ebp
f0103563:	57                   	push   %edi
f0103564:	56                   	push   %esi
f0103565:	83 ec 20             	sub    $0x20,%esp
f0103568:	8b 45 10             	mov    0x10(%ebp),%eax
f010356b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010356e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103571:	89 c7                	mov    %eax,%edi
f0103573:	8b 45 14             	mov    0x14(%ebp),%eax
f0103576:	89 4d e8             	mov    %ecx,-0x18(%ebp)
f0103579:	89 4d ec             	mov    %ecx,-0x14(%ebp)
f010357c:	85 c0                	test   %eax,%eax
f010357e:	75 18                	jne    f0103598 <__umoddi3+0x38>
f0103580:	39 f7                	cmp    %esi,%edi
f0103582:	76 24                	jbe    f01035a8 <__umoddi3+0x48>
f0103584:	89 c8                	mov    %ecx,%eax
f0103586:	89 f2                	mov    %esi,%edx
f0103588:	f7 f7                	div    %edi
f010358a:	89 d0                	mov    %edx,%eax
f010358c:	31 d2                	xor    %edx,%edx
f010358e:	83 c4 20             	add    $0x20,%esp
f0103591:	5e                   	pop    %esi
f0103592:	5f                   	pop    %edi
f0103593:	5d                   	pop    %ebp
f0103594:	c3                   	ret    
f0103595:	8d 76 00             	lea    0x0(%esi),%esi
f0103598:	39 f0                	cmp    %esi,%eax
f010359a:	76 2c                	jbe    f01035c8 <__umoddi3+0x68>
f010359c:	89 c8                	mov    %ecx,%eax
f010359e:	89 f2                	mov    %esi,%edx
f01035a0:	83 c4 20             	add    $0x20,%esp
f01035a3:	5e                   	pop    %esi
f01035a4:	5f                   	pop    %edi
f01035a5:	5d                   	pop    %ebp
f01035a6:	c3                   	ret    
f01035a7:	90                   	nop    
f01035a8:	85 ff                	test   %edi,%edi
f01035aa:	75 0b                	jne    f01035b7 <__umoddi3+0x57>
f01035ac:	b8 01 00 00 00       	mov    $0x1,%eax
f01035b1:	31 d2                	xor    %edx,%edx
f01035b3:	f7 f7                	div    %edi
f01035b5:	89 c7                	mov    %eax,%edi
f01035b7:	89 f0                	mov    %esi,%eax
f01035b9:	31 d2                	xor    %edx,%edx
f01035bb:	f7 f7                	div    %edi
f01035bd:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01035c0:	f7 f7                	div    %edi
f01035c2:	eb c6                	jmp    f010358a <__umoddi3+0x2a>
f01035c4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035c8:	0f bd d0             	bsr    %eax,%edx
f01035cb:	83 f2 1f             	xor    $0x1f,%edx
f01035ce:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01035d1:	75 1d                	jne    f01035f0 <__umoddi3+0x90>
f01035d3:	39 f0                	cmp    %esi,%eax
f01035d5:	0f 83 b5 00 00 00    	jae    f0103690 <__umoddi3+0x130>
f01035db:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01035de:	29 f9                	sub    %edi,%ecx
f01035e0:	19 c6                	sbb    %eax,%esi
f01035e2:	89 4d ec             	mov    %ecx,-0x14(%ebp)
f01035e5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01035e8:	89 f2                	mov    %esi,%edx
f01035ea:	eb b4                	jmp    f01035a0 <__umoddi3+0x40>
f01035ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01035f0:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
f01035f4:	89 c2                	mov    %eax,%edx
f01035f6:	b8 20 00 00 00       	mov    $0x20,%eax
f01035fb:	2b 45 e4             	sub    -0x1c(%ebp),%eax
f01035fe:	d3 e2                	shl    %cl,%edx
f0103600:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103603:	0f b6 4d e0          	movzbl -0x20(%ebp),%ecx
f0103607:	89 f8                	mov    %edi,%eax
f0103609:	d3 e8                	shr    %cl,%eax
f010360b:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
f010360f:	09 d0                	or     %edx,%eax
f0103611:	89 f2                	mov    %esi,%edx
f0103613:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103616:	89 f0                	mov    %esi,%eax
f0103618:	d3 e7                	shl    %cl,%edi
f010361a:	0f b6 4d e0          	movzbl -0x20(%ebp),%ecx
f010361e:	89 7d f4             	mov    %edi,-0xc(%ebp)
f0103621:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0103624:	d3 e8                	shr    %cl,%eax
f0103626:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
f010362a:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010362d:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103630:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0103633:	d3 e2                	shl    %cl,%edx
f0103635:	0f b6 4d e0          	movzbl -0x20(%ebp),%ecx
f0103639:	d3 e8                	shr    %cl,%eax
f010363b:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
f010363f:	09 d0                	or     %edx,%eax
f0103641:	89 f2                	mov    %esi,%edx
f0103643:	f7 75 f0             	divl   -0x10(%ebp)
f0103646:	89 d6                	mov    %edx,%esi
f0103648:	d3 e7                	shl    %cl,%edi
f010364a:	f7 65 f4             	mull   -0xc(%ebp)
f010364d:	39 d6                	cmp    %edx,%esi
f010364f:	73 2f                	jae    f0103680 <__umoddi3+0x120>
f0103651:	2b 45 f4             	sub    -0xc(%ebp),%eax
f0103654:	1b 55 f0             	sbb    -0x10(%ebp),%edx
f0103657:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
f010365b:	29 c7                	sub    %eax,%edi
f010365d:	19 d6                	sbb    %edx,%esi
f010365f:	89 fa                	mov    %edi,%edx
f0103661:	89 f0                	mov    %esi,%eax
f0103663:	d3 ea                	shr    %cl,%edx
f0103665:	0f b6 4d e0          	movzbl -0x20(%ebp),%ecx
f0103669:	d3 e0                	shl    %cl,%eax
f010366b:	0f b6 4d e4          	movzbl -0x1c(%ebp),%ecx
f010366f:	09 d0                	or     %edx,%eax
f0103671:	89 f2                	mov    %esi,%edx
f0103673:	d3 ea                	shr    %cl,%edx
f0103675:	e9 26 ff ff ff       	jmp    f01035a0 <__umoddi3+0x40>
f010367a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103680:	75 d5                	jne    f0103657 <__umoddi3+0xf7>
f0103682:	39 c7                	cmp    %eax,%edi
f0103684:	73 d1                	jae    f0103657 <__umoddi3+0xf7>
f0103686:	66 90                	xchg   %ax,%ax
f0103688:	eb c7                	jmp    f0103651 <__umoddi3+0xf1>
f010368a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103690:	3b 7d ec             	cmp    -0x14(%ebp),%edi
f0103693:	90                   	nop    
f0103694:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103698:	0f 87 47 ff ff ff    	ja     f01035e5 <__umoddi3+0x85>
f010369e:	66 90                	xchg   %ax,%ax
f01036a0:	e9 36 ff ff ff       	jmp    f01035db <__umoddi3+0x7b>
