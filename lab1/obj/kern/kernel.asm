
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 80 1a 10 f0 	movl   $0xf0101a80,(%esp)
f0100055:	e8 57 09 00 00       	call   f01009b1 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 14 07 00 00       	call   f010079b <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 9c 1a 10 f0 	movl   $0xf0101a9c,(%esp)
f0100092:	e8 1a 09 00 00       	call   f01009b1 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 12 15 00 00       	call   f01015d7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 95 04 00 00       	call   f010055f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 b7 1a 10 f0 	movl   $0xf0101ab7,(%esp)
f01000d9:	e8 d3 08 00 00       	call   f01009b1 <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 42 07 00 00       	call   f0100838 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 d2 1a 10 f0 	movl   $0xf0101ad2,(%esp)
f010012c:	e8 80 08 00 00       	call   f01009b1 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 41 08 00 00       	call   f010097e <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 0e 1b 10 f0 	movl   $0xf0101b0e,(%esp)
f0100144:	e8 68 08 00 00       	call   f01009b1 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 e3 06 00 00       	call   f0100838 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 ea 1a 10 f0 	movl   $0xf0101aea,(%esp)
f0100176:	e8 36 08 00 00       	call   f01009b1 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 f4 07 00 00       	call   f010097e <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 0e 1b 10 f0 	movl   $0xf0101b0e,(%esp)
f0100191:	e8 1b 08 00 00       	call   f01009b1 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	53                   	push   %ebx
f01001c0:	83 ec 04             	sub    $0x4,%esp
f01001c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c5:	eb 2a                	jmp    f01001f1 <cons_intr+0x35>
		if (c == 0)
f01001c7:	85 d2                	test   %edx,%edx
f01001c9:	74 26                	je     f01001f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01001cb:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01001d3:	89 0d 24 25 11 f0    	mov    %ecx,0xf0112524
f01001d9:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01001df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001e5:	75 0a                	jne    f01001f1 <cons_intr+0x35>
			cons.wpos = 0;
f01001e7:	c7 05 24 25 11 f0 00 	movl   $0x0,0xf0112524
f01001ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001f1:	ff d3                	call   *%ebx
f01001f3:	89 c2                	mov    %eax,%edx
f01001f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001f8:	75 cd                	jne    f01001c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001fa:	83 c4 04             	add    $0x4,%esp
f01001fd:	5b                   	pop    %ebx
f01001fe:	5d                   	pop    %ebp
f01001ff:	c3                   	ret    

f0100200 <kbd_proc_data>:
f0100200:	ba 64 00 00 00       	mov    $0x64,%edx
f0100205:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100206:	a8 01                	test   $0x1,%al
f0100208:	0f 84 ef 00 00 00    	je     f01002fd <kbd_proc_data+0xfd>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010020e:	a8 20                	test   $0x20,%al
f0100210:	0f 85 ed 00 00 00    	jne    f0100303 <kbd_proc_data+0x103>
f0100216:	b2 60                	mov    $0x60,%dl
f0100218:	ec                   	in     (%dx),%al
f0100219:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010021b:	3c e0                	cmp    $0xe0,%al
f010021d:	75 0d                	jne    f010022c <kbd_proc_data+0x2c>
		// E0 escape character
		shift |= E0ESC;
f010021f:	83 0d 00 23 11 f0 40 	orl    $0x40,0xf0112300
		return 0;
f0100226:	b8 00 00 00 00       	mov    $0x0,%eax
f010022b:	c3                   	ret    
	} else if (data & 0x80) {
f010022c:	84 c0                	test   %al,%al
f010022e:	79 30                	jns    f0100260 <kbd_proc_data+0x60>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100230:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f0100236:	f6 c1 40             	test   $0x40,%cl
f0100239:	75 05                	jne    f0100240 <kbd_proc_data+0x40>
f010023b:	83 e0 7f             	and    $0x7f,%eax
f010023e:	89 c2                	mov    %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100240:	0f b6 d2             	movzbl %dl,%edx
f0100243:	0f b6 82 60 1c 10 f0 	movzbl -0xfefe3a0(%edx),%eax
f010024a:	83 c8 40             	or     $0x40,%eax
f010024d:	0f b6 c0             	movzbl %al,%eax
f0100250:	f7 d0                	not    %eax
f0100252:	21 c1                	and    %eax,%ecx
f0100254:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
		return 0;
f010025a:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f010025f:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100260:	55                   	push   %ebp
f0100261:	89 e5                	mov    %esp,%ebp
f0100263:	53                   	push   %ebx
f0100264:	83 ec 14             	sub    $0x14,%esp
	} else if (data & 0x80) {
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
		shift &= ~(shiftcode[data] | E0ESC);
		return 0;
	} else if (shift & E0ESC) {
f0100267:	8b 0d 00 23 11 f0    	mov    0xf0112300,%ecx
f010026d:	f6 c1 40             	test   $0x40,%cl
f0100270:	74 0e                	je     f0100280 <kbd_proc_data+0x80>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100272:	83 c8 80             	or     $0xffffff80,%eax
f0100275:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100277:	83 e1 bf             	and    $0xffffffbf,%ecx
f010027a:	89 0d 00 23 11 f0    	mov    %ecx,0xf0112300
	}

	shift |= shiftcode[data];
f0100280:	0f b6 d2             	movzbl %dl,%edx
f0100283:	0f b6 82 60 1c 10 f0 	movzbl -0xfefe3a0(%edx),%eax
f010028a:	0b 05 00 23 11 f0    	or     0xf0112300,%eax
	shift ^= togglecode[data];
f0100290:	0f b6 8a 60 1b 10 f0 	movzbl -0xfefe4a0(%edx),%ecx
f0100297:	31 c8                	xor    %ecx,%eax
f0100299:	a3 00 23 11 f0       	mov    %eax,0xf0112300

	c = charcode[shift & (CTL | SHIFT)][data];
f010029e:	89 c1                	mov    %eax,%ecx
f01002a0:	83 e1 03             	and    $0x3,%ecx
f01002a3:	8b 0c 8d 40 1b 10 f0 	mov    -0xfefe4c0(,%ecx,4),%ecx
f01002aa:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002ae:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01002b1:	a8 08                	test   $0x8,%al
f01002b3:	74 1a                	je     f01002cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01002b5:	89 da                	mov    %ebx,%edx
f01002b7:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01002ba:	83 f9 19             	cmp    $0x19,%ecx
f01002bd:	77 05                	ja     f01002c4 <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f01002bf:	83 eb 20             	sub    $0x20,%ebx
f01002c2:	eb 0b                	jmp    f01002cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01002c4:	83 ea 41             	sub    $0x41,%edx
f01002c7:	83 fa 19             	cmp    $0x19,%edx
f01002ca:	77 03                	ja     f01002cf <kbd_proc_data+0xcf>
			c += 'a' - 'A';
f01002cc:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002cf:	f7 d0                	not    %eax
f01002d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d5:	f6 c2 06             	test   $0x6,%dl
f01002d8:	75 2f                	jne    f0100309 <kbd_proc_data+0x109>
f01002da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002e0:	75 27                	jne    f0100309 <kbd_proc_data+0x109>
		cprintf("Rebooting!\n");
f01002e2:	c7 04 24 04 1b 10 f0 	movl   $0xf0101b04,(%esp)
f01002e9:	e8 c3 06 00 00       	call   f01009b1 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01002f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002f9:	89 d8                	mov    %ebx,%eax
f01002fb:	eb 0c                	jmp    f0100309 <kbd_proc_data+0x109>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01002fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100302:	c3                   	ret    
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f0100303:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100308:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100309:	83 c4 14             	add    $0x14,%esp
f010030c:	5b                   	pop    %ebx
f010030d:	5d                   	pop    %ebp
f010030e:	c3                   	ret    

f010030f <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010030f:	55                   	push   %ebp
f0100310:	89 e5                	mov    %esp,%ebp
f0100312:	57                   	push   %edi
f0100313:	56                   	push   %esi
f0100314:	53                   	push   %ebx
f0100315:	83 ec 1c             	sub    $0x1c,%esp
f0100318:	89 c7                	mov    %eax,%edi
f010031a:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010031f:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100324:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100329:	eb 06                	jmp    f0100331 <cons_putc+0x22>
f010032b:	89 ca                	mov    %ecx,%edx
f010032d:	ec                   	in     (%dx),%al
f010032e:	ec                   	in     (%dx),%al
f010032f:	ec                   	in     (%dx),%al
f0100330:	ec                   	in     (%dx),%al
f0100331:	89 f2                	mov    %esi,%edx
f0100333:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100334:	a8 20                	test   $0x20,%al
f0100336:	75 05                	jne    f010033d <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100338:	83 eb 01             	sub    $0x1,%ebx
f010033b:	75 ee                	jne    f010032b <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f010033d:	89 f8                	mov    %edi,%eax
f010033f:	0f b6 c0             	movzbl %al,%eax
f0100342:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100345:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010034a:	ee                   	out    %al,(%dx)
f010034b:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100350:	be 79 03 00 00       	mov    $0x379,%esi
f0100355:	b9 84 00 00 00       	mov    $0x84,%ecx
f010035a:	eb 06                	jmp    f0100362 <cons_putc+0x53>
f010035c:	89 ca                	mov    %ecx,%edx
f010035e:	ec                   	in     (%dx),%al
f010035f:	ec                   	in     (%dx),%al
f0100360:	ec                   	in     (%dx),%al
f0100361:	ec                   	in     (%dx),%al
f0100362:	89 f2                	mov    %esi,%edx
f0100364:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100365:	84 c0                	test   %al,%al
f0100367:	78 05                	js     f010036e <cons_putc+0x5f>
f0100369:	83 eb 01             	sub    $0x1,%ebx
f010036c:	75 ee                	jne    f010035c <cons_putc+0x4d>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010036e:	ba 78 03 00 00       	mov    $0x378,%edx
f0100373:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100377:	ee                   	out    %al,(%dx)
f0100378:	b2 7a                	mov    $0x7a,%dl
f010037a:	b8 0d 00 00 00       	mov    $0xd,%eax
f010037f:	ee                   	out    %al,(%dx)
f0100380:	b8 08 00 00 00       	mov    $0x8,%eax
f0100385:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100386:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f010038c:	75 06                	jne    f0100394 <cons_putc+0x85>
		c |= 0x0700;
f010038e:	81 cf 00 07 00 00    	or     $0x700,%edi

	switch (c & 0xff) {
f0100394:	89 f8                	mov    %edi,%eax
f0100396:	0f b6 c0             	movzbl %al,%eax
f0100399:	83 f8 09             	cmp    $0x9,%eax
f010039c:	74 74                	je     f0100412 <cons_putc+0x103>
f010039e:	83 f8 09             	cmp    $0x9,%eax
f01003a1:	7f 0a                	jg     f01003ad <cons_putc+0x9e>
f01003a3:	83 f8 08             	cmp    $0x8,%eax
f01003a6:	74 14                	je     f01003bc <cons_putc+0xad>
f01003a8:	e9 99 00 00 00       	jmp    f0100446 <cons_putc+0x137>
f01003ad:	83 f8 0a             	cmp    $0xa,%eax
f01003b0:	74 3a                	je     f01003ec <cons_putc+0xdd>
f01003b2:	83 f8 0d             	cmp    $0xd,%eax
f01003b5:	74 3d                	je     f01003f4 <cons_putc+0xe5>
f01003b7:	e9 8a 00 00 00       	jmp    f0100446 <cons_putc+0x137>
	case '\b':
		if (crt_pos > 0) {
f01003bc:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003c3:	66 85 c0             	test   %ax,%ax
f01003c6:	0f 84 e5 00 00 00    	je     f01004b1 <cons_putc+0x1a2>
			crt_pos--;
f01003cc:	83 e8 01             	sub    $0x1,%eax
f01003cf:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01003d5:	0f b7 c0             	movzwl %ax,%eax
f01003d8:	66 81 e7 00 ff       	and    $0xff00,%di
f01003dd:	83 cf 20             	or     $0x20,%edi
f01003e0:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f01003e6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003ea:	eb 78                	jmp    f0100464 <cons_putc+0x155>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ec:	66 83 05 28 25 11 f0 	addw   $0x50,0xf0112528
f01003f3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003f4:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f01003fb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100401:	c1 e8 16             	shr    $0x16,%eax
f0100404:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100407:	c1 e0 04             	shl    $0x4,%eax
f010040a:	66 a3 28 25 11 f0    	mov    %ax,0xf0112528
f0100410:	eb 52                	jmp    f0100464 <cons_putc+0x155>
		break;
	case '\t':
		cons_putc(' ');
f0100412:	b8 20 00 00 00       	mov    $0x20,%eax
f0100417:	e8 f3 fe ff ff       	call   f010030f <cons_putc>
		cons_putc(' ');
f010041c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100421:	e8 e9 fe ff ff       	call   f010030f <cons_putc>
		cons_putc(' ');
f0100426:	b8 20 00 00 00       	mov    $0x20,%eax
f010042b:	e8 df fe ff ff       	call   f010030f <cons_putc>
		cons_putc(' ');
f0100430:	b8 20 00 00 00       	mov    $0x20,%eax
f0100435:	e8 d5 fe ff ff       	call   f010030f <cons_putc>
		cons_putc(' ');
f010043a:	b8 20 00 00 00       	mov    $0x20,%eax
f010043f:	e8 cb fe ff ff       	call   f010030f <cons_putc>
f0100444:	eb 1e                	jmp    f0100464 <cons_putc+0x155>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100446:	0f b7 05 28 25 11 f0 	movzwl 0xf0112528,%eax
f010044d:	8d 50 01             	lea    0x1(%eax),%edx
f0100450:	66 89 15 28 25 11 f0 	mov    %dx,0xf0112528
f0100457:	0f b7 c0             	movzwl %ax,%eax
f010045a:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
f0100460:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100464:	66 81 3d 28 25 11 f0 	cmpw   $0x7cf,0xf0112528
f010046b:	cf 07 
f010046d:	76 42                	jbe    f01004b1 <cons_putc+0x1a2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010046f:	a1 2c 25 11 f0       	mov    0xf011252c,%eax
f0100474:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010047b:	00 
f010047c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100482:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100486:	89 04 24             	mov    %eax,(%esp)
f0100489:	e8 96 11 00 00       	call   f0101624 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010048e:	8b 15 2c 25 11 f0    	mov    0xf011252c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100494:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100499:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010049f:	83 c0 01             	add    $0x1,%eax
f01004a2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01004a7:	75 f0                	jne    f0100499 <cons_putc+0x18a>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01004a9:	66 83 2d 28 25 11 f0 	subw   $0x50,0xf0112528
f01004b0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01004b1:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01004b7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004bc:	89 ca                	mov    %ecx,%edx
f01004be:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004bf:	0f b7 1d 28 25 11 f0 	movzwl 0xf0112528,%ebx
f01004c6:	8d 71 01             	lea    0x1(%ecx),%esi
f01004c9:	89 d8                	mov    %ebx,%eax
f01004cb:	66 c1 e8 08          	shr    $0x8,%ax
f01004cf:	89 f2                	mov    %esi,%edx
f01004d1:	ee                   	out    %al,(%dx)
f01004d2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004d7:	89 ca                	mov    %ecx,%edx
f01004d9:	ee                   	out    %al,(%dx)
f01004da:	89 d8                	mov    %ebx,%eax
f01004dc:	89 f2                	mov    %esi,%edx
f01004de:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004df:	83 c4 1c             	add    $0x1c,%esp
f01004e2:	5b                   	pop    %ebx
f01004e3:	5e                   	pop    %esi
f01004e4:	5f                   	pop    %edi
f01004e5:	5d                   	pop    %ebp
f01004e6:	c3                   	ret    

f01004e7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004e7:	80 3d 34 25 11 f0 00 	cmpb   $0x0,0xf0112534
f01004ee:	74 11                	je     f0100501 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004f0:	55                   	push   %ebp
f01004f1:	89 e5                	mov    %esp,%ebp
f01004f3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004f6:	b8 a0 01 10 f0       	mov    $0xf01001a0,%eax
f01004fb:	e8 bc fc ff ff       	call   f01001bc <cons_intr>
}
f0100500:	c9                   	leave  
f0100501:	f3 c3                	repz ret 

f0100503 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100503:	55                   	push   %ebp
f0100504:	89 e5                	mov    %esp,%ebp
f0100506:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100509:	b8 00 02 10 f0       	mov    $0xf0100200,%eax
f010050e:	e8 a9 fc ff ff       	call   f01001bc <cons_intr>
}
f0100513:	c9                   	leave  
f0100514:	c3                   	ret    

f0100515 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100515:	55                   	push   %ebp
f0100516:	89 e5                	mov    %esp,%ebp
f0100518:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010051b:	e8 c7 ff ff ff       	call   f01004e7 <serial_intr>
	kbd_intr();
f0100520:	e8 de ff ff ff       	call   f0100503 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100525:	a1 20 25 11 f0       	mov    0xf0112520,%eax
f010052a:	3b 05 24 25 11 f0    	cmp    0xf0112524,%eax
f0100530:	74 26                	je     f0100558 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100532:	8d 50 01             	lea    0x1(%eax),%edx
f0100535:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010053b:	0f b6 88 20 23 11 f0 	movzbl -0xfeedce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100542:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100544:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054a:	75 11                	jne    f010055d <cons_getc+0x48>
			cons.rpos = 0;
f010054c:	c7 05 20 25 11 f0 00 	movl   $0x0,0xf0112520
f0100553:	00 00 00 
f0100556:	eb 05                	jmp    f010055d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100558:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010055d:	c9                   	leave  
f010055e:	c3                   	ret    

f010055f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010055f:	55                   	push   %ebp
f0100560:	89 e5                	mov    %esp,%ebp
f0100562:	57                   	push   %edi
f0100563:	56                   	push   %esi
f0100564:	53                   	push   %ebx
f0100565:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100568:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100576:	5a a5 
	if (*cp != 0xA55A) {
f0100578:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100583:	74 11                	je     f0100596 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100585:	c7 05 30 25 11 f0 b4 	movl   $0x3b4,0xf0112530
f010058c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100594:	eb 16                	jmp    f01005ac <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100596:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059d:	c7 05 30 25 11 f0 d4 	movl   $0x3d4,0xf0112530
f01005a4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005ac:	8b 0d 30 25 11 f0    	mov    0xf0112530,%ecx
f01005b2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b7:	89 ca                	mov    %ecx,%edx
f01005b9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005ba:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005bd:	89 da                	mov    %ebx,%edx
f01005bf:	ec                   	in     (%dx),%al
f01005c0:	0f b6 f0             	movzbl %al,%esi
f01005c3:	c1 e6 08             	shl    $0x8,%esi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005cb:	89 ca                	mov    %ecx,%edx
f01005cd:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ce:	89 da                	mov    %ebx,%edx
f01005d0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005d1:	89 3d 2c 25 11 f0    	mov    %edi,0xf011252c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005d7:	0f b6 d8             	movzbl %al,%ebx
f01005da:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005dc:	66 89 35 28 25 11 f0 	mov    %si,0xf0112528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005e8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ed:	89 f2                	mov    %esi,%edx
f01005ef:	ee                   	out    %al,(%dx)
f01005f0:	b2 fb                	mov    $0xfb,%dl
f01005f2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f7:	ee                   	out    %al,(%dx)
f01005f8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005fd:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100602:	89 da                	mov    %ebx,%edx
f0100604:	ee                   	out    %al,(%dx)
f0100605:	b2 f9                	mov    $0xf9,%dl
f0100607:	b8 00 00 00 00       	mov    $0x0,%eax
f010060c:	ee                   	out    %al,(%dx)
f010060d:	b2 fb                	mov    $0xfb,%dl
f010060f:	b8 03 00 00 00       	mov    $0x3,%eax
f0100614:	ee                   	out    %al,(%dx)
f0100615:	b2 fc                	mov    $0xfc,%dl
f0100617:	b8 00 00 00 00       	mov    $0x0,%eax
f010061c:	ee                   	out    %al,(%dx)
f010061d:	b2 f9                	mov    $0xf9,%dl
f010061f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100624:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100625:	b2 fd                	mov    $0xfd,%dl
f0100627:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100628:	3c ff                	cmp    $0xff,%al
f010062a:	0f 95 c1             	setne  %cl
f010062d:	88 0d 34 25 11 f0    	mov    %cl,0xf0112534
f0100633:	89 f2                	mov    %esi,%edx
f0100635:	ec                   	in     (%dx),%al
f0100636:	89 da                	mov    %ebx,%edx
f0100638:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100639:	84 c9                	test   %cl,%cl
f010063b:	75 0c                	jne    f0100649 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010063d:	c7 04 24 10 1b 10 f0 	movl   $0xf0101b10,(%esp)
f0100644:	e8 68 03 00 00       	call   f01009b1 <cprintf>
}
f0100649:	83 c4 1c             	add    $0x1c,%esp
f010064c:	5b                   	pop    %ebx
f010064d:	5e                   	pop    %esi
f010064e:	5f                   	pop    %edi
f010064f:	5d                   	pop    %ebp
f0100650:	c3                   	ret    

f0100651 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100651:	55                   	push   %ebp
f0100652:	89 e5                	mov    %esp,%ebp
f0100654:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100657:	8b 45 08             	mov    0x8(%ebp),%eax
f010065a:	e8 b0 fc ff ff       	call   f010030f <cons_putc>
}
f010065f:	c9                   	leave  
f0100660:	c3                   	ret    

f0100661 <getchar>:

int
getchar(void)
{
f0100661:	55                   	push   %ebp
f0100662:	89 e5                	mov    %esp,%ebp
f0100664:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100667:	e8 a9 fe ff ff       	call   f0100515 <cons_getc>
f010066c:	85 c0                	test   %eax,%eax
f010066e:	74 f7                	je     f0100667 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100670:	c9                   	leave  
f0100671:	c3                   	ret    

f0100672 <iscons>:

int
iscons(int fdnum)
{
f0100672:	55                   	push   %ebp
f0100673:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100675:	b8 01 00 00 00       	mov    $0x1,%eax
f010067a:	5d                   	pop    %ebp
f010067b:	c3                   	ret    
f010067c:	66 90                	xchg   %ax,%ax
f010067e:	66 90                	xchg   %ax,%ax

f0100680 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100686:	c7 44 24 08 60 1d 10 	movl   $0xf0101d60,0x8(%esp)
f010068d:	f0 
f010068e:	c7 44 24 04 7e 1d 10 	movl   $0xf0101d7e,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 83 1d 10 f0 	movl   $0xf0101d83,(%esp)
f010069d:	e8 0f 03 00 00       	call   f01009b1 <cprintf>
f01006a2:	c7 44 24 08 1c 1e 10 	movl   $0xf0101e1c,0x8(%esp)
f01006a9:	f0 
f01006aa:	c7 44 24 04 8c 1d 10 	movl   $0xf0101d8c,0x4(%esp)
f01006b1:	f0 
f01006b2:	c7 04 24 83 1d 10 f0 	movl   $0xf0101d83,(%esp)
f01006b9:	e8 f3 02 00 00       	call   f01009b1 <cprintf>
f01006be:	c7 44 24 08 95 1d 10 	movl   $0xf0101d95,0x8(%esp)
f01006c5:	f0 
f01006c6:	c7 44 24 04 ab 1d 10 	movl   $0xf0101dab,0x4(%esp)
f01006cd:	f0 
f01006ce:	c7 04 24 83 1d 10 f0 	movl   $0xf0101d83,(%esp)
f01006d5:	e8 d7 02 00 00       	call   f01009b1 <cprintf>
	return 0;
}
f01006da:	b8 00 00 00 00       	mov    $0x0,%eax
f01006df:	c9                   	leave  
f01006e0:	c3                   	ret    

f01006e1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006e1:	55                   	push   %ebp
f01006e2:	89 e5                	mov    %esp,%ebp
f01006e4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006e7:	c7 04 24 b5 1d 10 f0 	movl   $0xf0101db5,(%esp)
f01006ee:	e8 be 02 00 00       	call   f01009b1 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006f3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006fa:	00 
f01006fb:	c7 04 24 44 1e 10 f0 	movl   $0xf0101e44,(%esp)
f0100702:	e8 aa 02 00 00       	call   f01009b1 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100707:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010070e:	00 
f010070f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100716:	f0 
f0100717:	c7 04 24 6c 1e 10 f0 	movl   $0xf0101e6c,(%esp)
f010071e:	e8 8e 02 00 00       	call   f01009b1 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100723:	c7 44 24 08 67 1a 10 	movl   $0x101a67,0x8(%esp)
f010072a:	00 
f010072b:	c7 44 24 04 67 1a 10 	movl   $0xf0101a67,0x4(%esp)
f0100732:	f0 
f0100733:	c7 04 24 90 1e 10 f0 	movl   $0xf0101e90,(%esp)
f010073a:	e8 72 02 00 00       	call   f01009b1 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010073f:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f0100746:	00 
f0100747:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f010074e:	f0 
f010074f:	c7 04 24 b4 1e 10 f0 	movl   $0xf0101eb4,(%esp)
f0100756:	e8 56 02 00 00       	call   f01009b1 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010075b:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100762:	00 
f0100763:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f010076a:	f0 
f010076b:	c7 04 24 d8 1e 10 f0 	movl   $0xf0101ed8,(%esp)
f0100772:	e8 3a 02 00 00       	call   f01009b1 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100777:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010077c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100781:	c1 f8 0a             	sar    $0xa,%eax
f0100784:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100788:	c7 04 24 fc 1e 10 f0 	movl   $0xf0101efc,(%esp)
f010078f:	e8 1d 02 00 00       	call   f01009b1 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100794:	b8 00 00 00 00       	mov    $0x0,%eax
f0100799:	c9                   	leave  
f010079a:	c3                   	ret    

f010079b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010079b:	55                   	push   %ebp
f010079c:	89 e5                	mov    %esp,%ebp
f010079e:	57                   	push   %edi
f010079f:	56                   	push   %esi
f01007a0:	53                   	push   %ebx
f01007a1:	83 ec 4c             	sub    $0x4c,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01007a4:	89 e8                	mov    %ebp,%eax
	{
		p = (uint32_t *) ebp;
		eip = p[1];	
		cprintf("ebp %x eip %x args %08x %08x %08x %08x %08x\n", 
			ebp, eip, p[2], p[3], p[4], p[5], p[6]);
		if(debuginfo_eip(eip, &info) == 0)
f01007a6:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp, eip, *p;
	struct Eipdebuginfo info;

	ebp  = read_ebp();
	while(ebp != 0)
f01007a9:	eb 7d                	jmp    f0100828 <mon_backtrace+0x8d>
	{
		p = (uint32_t *) ebp;
f01007ab:	89 c6                	mov    %eax,%esi
		eip = p[1];	
f01007ad:	8b 58 04             	mov    0x4(%eax),%ebx
		cprintf("ebp %x eip %x args %08x %08x %08x %08x %08x\n", 
f01007b0:	8b 50 18             	mov    0x18(%eax),%edx
f01007b3:	89 54 24 1c          	mov    %edx,0x1c(%esp)
f01007b7:	8b 50 14             	mov    0x14(%eax),%edx
f01007ba:	89 54 24 18          	mov    %edx,0x18(%esp)
f01007be:	8b 50 10             	mov    0x10(%eax),%edx
f01007c1:	89 54 24 14          	mov    %edx,0x14(%esp)
f01007c5:	8b 50 0c             	mov    0xc(%eax),%edx
f01007c8:	89 54 24 10          	mov    %edx,0x10(%esp)
f01007cc:	8b 50 08             	mov    0x8(%eax),%edx
f01007cf:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01007d3:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01007d7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007db:	c7 04 24 28 1f 10 f0 	movl   $0xf0101f28,(%esp)
f01007e2:	e8 ca 01 00 00       	call   f01009b1 <cprintf>
			ebp, eip, p[2], p[3], p[4], p[5], p[6]);
		if(debuginfo_eip(eip, &info) == 0)
f01007e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007eb:	89 1c 24             	mov    %ebx,(%esp)
f01007ee:	e8 b5 02 00 00       	call   f0100aa8 <debuginfo_eip>
f01007f3:	85 c0                	test   %eax,%eax
f01007f5:	75 2f                	jne    f0100826 <mon_backtrace+0x8b>
		{
			int fn_offset = eip - info.eip_fn_addr;
f01007f7:	2b 5d e0             	sub    -0x20(%ebp),%ebx
			cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, fn_offset);	
f01007fa:	89 5c 24 14          	mov    %ebx,0x14(%esp)
f01007fe:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100801:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100805:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100808:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010080c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010080f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100813:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100816:	89 44 24 04          	mov    %eax,0x4(%esp)
f010081a:	c7 04 24 ce 1d 10 f0 	movl   $0xf0101dce,(%esp)
f0100821:	e8 8b 01 00 00       	call   f01009b1 <cprintf>
		}
		ebp = p[0];
f0100826:	8b 06                	mov    (%esi),%eax
{
	uint32_t ebp, eip, *p;
	struct Eipdebuginfo info;

	ebp  = read_ebp();
	while(ebp != 0)
f0100828:	85 c0                	test   %eax,%eax
f010082a:	0f 85 7b ff ff ff    	jne    f01007ab <mon_backtrace+0x10>
			cprintf("%s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, fn_offset);	
		}
		ebp = p[0];
	}	
	return 0;
}
f0100830:	83 c4 4c             	add    $0x4c,%esp
f0100833:	5b                   	pop    %ebx
f0100834:	5e                   	pop    %esi
f0100835:	5f                   	pop    %edi
f0100836:	5d                   	pop    %ebp
f0100837:	c3                   	ret    

f0100838 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100838:	55                   	push   %ebp
f0100839:	89 e5                	mov    %esp,%ebp
f010083b:	57                   	push   %edi
f010083c:	56                   	push   %esi
f010083d:	53                   	push   %ebx
f010083e:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100841:	c7 04 24 58 1f 10 f0 	movl   $0xf0101f58,(%esp)
f0100848:	e8 64 01 00 00       	call   f01009b1 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010084d:	c7 04 24 7c 1f 10 f0 	movl   $0xf0101f7c,(%esp)
f0100854:	e8 58 01 00 00       	call   f01009b1 <cprintf>


	while (1) {
		buf = readline("K> ");
f0100859:	c7 04 24 de 1d 10 f0 	movl   $0xf0101dde,(%esp)
f0100860:	e8 1b 0b 00 00       	call   f0101380 <readline>
f0100865:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100867:	85 c0                	test   %eax,%eax
f0100869:	74 ee                	je     f0100859 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010086b:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100872:	be 00 00 00 00       	mov    $0x0,%esi
f0100877:	eb 0a                	jmp    f0100883 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100879:	c6 03 00             	movb   $0x0,(%ebx)
f010087c:	89 f7                	mov    %esi,%edi
f010087e:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100881:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100883:	0f b6 03             	movzbl (%ebx),%eax
f0100886:	84 c0                	test   %al,%al
f0100888:	74 63                	je     f01008ed <monitor+0xb5>
f010088a:	0f be c0             	movsbl %al,%eax
f010088d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100891:	c7 04 24 e2 1d 10 f0 	movl   $0xf0101de2,(%esp)
f0100898:	e8 fd 0c 00 00       	call   f010159a <strchr>
f010089d:	85 c0                	test   %eax,%eax
f010089f:	75 d8                	jne    f0100879 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f01008a1:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008a4:	74 47                	je     f01008ed <monitor+0xb5>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008a6:	83 fe 0f             	cmp    $0xf,%esi
f01008a9:	75 16                	jne    f01008c1 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008ab:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008b2:	00 
f01008b3:	c7 04 24 e7 1d 10 f0 	movl   $0xf0101de7,(%esp)
f01008ba:	e8 f2 00 00 00       	call   f01009b1 <cprintf>
f01008bf:	eb 98                	jmp    f0100859 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008c1:	8d 7e 01             	lea    0x1(%esi),%edi
f01008c4:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008c8:	eb 03                	jmp    f01008cd <monitor+0x95>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008ca:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008cd:	0f b6 03             	movzbl (%ebx),%eax
f01008d0:	84 c0                	test   %al,%al
f01008d2:	74 ad                	je     f0100881 <monitor+0x49>
f01008d4:	0f be c0             	movsbl %al,%eax
f01008d7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008db:	c7 04 24 e2 1d 10 f0 	movl   $0xf0101de2,(%esp)
f01008e2:	e8 b3 0c 00 00       	call   f010159a <strchr>
f01008e7:	85 c0                	test   %eax,%eax
f01008e9:	74 df                	je     f01008ca <monitor+0x92>
f01008eb:	eb 94                	jmp    f0100881 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f01008ed:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008f4:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008f5:	85 f6                	test   %esi,%esi
f01008f7:	0f 84 5c ff ff ff    	je     f0100859 <monitor+0x21>
f01008fd:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100902:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100905:	8b 04 85 c0 1f 10 f0 	mov    -0xfefe040(,%eax,4),%eax
f010090c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100910:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100913:	89 04 24             	mov    %eax,(%esp)
f0100916:	e8 21 0c 00 00       	call   f010153c <strcmp>
f010091b:	85 c0                	test   %eax,%eax
f010091d:	75 24                	jne    f0100943 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010091f:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100922:	8b 55 08             	mov    0x8(%ebp),%edx
f0100925:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100929:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010092c:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100930:	89 34 24             	mov    %esi,(%esp)
f0100933:	ff 14 85 c8 1f 10 f0 	call   *-0xfefe038(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010093a:	85 c0                	test   %eax,%eax
f010093c:	78 25                	js     f0100963 <monitor+0x12b>
f010093e:	e9 16 ff ff ff       	jmp    f0100859 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100943:	83 c3 01             	add    $0x1,%ebx
f0100946:	83 fb 03             	cmp    $0x3,%ebx
f0100949:	75 b7                	jne    f0100902 <monitor+0xca>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010094b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010094e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100952:	c7 04 24 04 1e 10 f0 	movl   $0xf0101e04,(%esp)
f0100959:	e8 53 00 00 00       	call   f01009b1 <cprintf>
f010095e:	e9 f6 fe ff ff       	jmp    f0100859 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100963:	83 c4 5c             	add    $0x5c,%esp
f0100966:	5b                   	pop    %ebx
f0100967:	5e                   	pop    %esi
f0100968:	5f                   	pop    %edi
f0100969:	5d                   	pop    %ebp
f010096a:	c3                   	ret    

f010096b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010096b:	55                   	push   %ebp
f010096c:	89 e5                	mov    %esp,%ebp
f010096e:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100971:	8b 45 08             	mov    0x8(%ebp),%eax
f0100974:	89 04 24             	mov    %eax,(%esp)
f0100977:	e8 d5 fc ff ff       	call   f0100651 <cputchar>
	*cnt++;
}
f010097c:	c9                   	leave  
f010097d:	c3                   	ret    

f010097e <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010097e:	55                   	push   %ebp
f010097f:	89 e5                	mov    %esp,%ebp
f0100981:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100984:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010098b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010098e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100992:	8b 45 08             	mov    0x8(%ebp),%eax
f0100995:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100999:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010099c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009a0:	c7 04 24 6b 09 10 f0 	movl   $0xf010096b,(%esp)
f01009a7:	e8 78 04 00 00       	call   f0100e24 <vprintfmt>
	return cnt;
}
f01009ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009af:	c9                   	leave  
f01009b0:	c3                   	ret    

f01009b1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009b1:	55                   	push   %ebp
f01009b2:	89 e5                	mov    %esp,%ebp
f01009b4:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009b7:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009be:	8b 45 08             	mov    0x8(%ebp),%eax
f01009c1:	89 04 24             	mov    %eax,(%esp)
f01009c4:	e8 b5 ff ff ff       	call   f010097e <vcprintf>
	va_end(ap);

	return cnt;
}
f01009c9:	c9                   	leave  
f01009ca:	c3                   	ret    

f01009cb <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009cb:	55                   	push   %ebp
f01009cc:	89 e5                	mov    %esp,%ebp
f01009ce:	57                   	push   %edi
f01009cf:	56                   	push   %esi
f01009d0:	53                   	push   %ebx
f01009d1:	83 ec 10             	sub    $0x10,%esp
f01009d4:	89 c6                	mov    %eax,%esi
f01009d6:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009d9:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01009dc:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009df:	8b 1a                	mov    (%edx),%ebx
f01009e1:	8b 01                	mov    (%ecx),%eax
f01009e3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009e6:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f01009ed:	eb 77                	jmp    f0100a66 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f01009ef:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01009f2:	01 d8                	add    %ebx,%eax
f01009f4:	b9 02 00 00 00       	mov    $0x2,%ecx
f01009f9:	99                   	cltd   
f01009fa:	f7 f9                	idiv   %ecx
f01009fc:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01009fe:	eb 01                	jmp    f0100a01 <stab_binsearch+0x36>
			m--;
f0100a00:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a01:	39 d9                	cmp    %ebx,%ecx
f0100a03:	7c 1d                	jl     f0100a22 <stab_binsearch+0x57>
f0100a05:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a08:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a0d:	39 fa                	cmp    %edi,%edx
f0100a0f:	75 ef                	jne    f0100a00 <stab_binsearch+0x35>
f0100a11:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a14:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a17:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a1b:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a1e:	73 18                	jae    f0100a38 <stab_binsearch+0x6d>
f0100a20:	eb 05                	jmp    f0100a27 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a22:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a25:	eb 3f                	jmp    f0100a66 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a27:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a2a:	89 0b                	mov    %ecx,(%ebx)
			l = true_m + 1;
f0100a2c:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a2f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a36:	eb 2e                	jmp    f0100a66 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a38:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a3b:	73 15                	jae    f0100a52 <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a3d:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a40:	48                   	dec    %eax
f0100a41:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a44:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a47:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a49:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a50:	eb 14                	jmp    f0100a66 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a52:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a55:	8b 5d ec             	mov    -0x14(%ebp),%ebx
f0100a58:	89 18                	mov    %ebx,(%eax)
			l = m;
			addr++;
f0100a5a:	ff 45 0c             	incl   0xc(%ebp)
f0100a5d:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a5f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100a66:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a69:	7e 84                	jle    f01009ef <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a6b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a6f:	75 0d                	jne    f0100a7e <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a71:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0100a74:	8b 00                	mov    (%eax),%eax
f0100a76:	48                   	dec    %eax
f0100a77:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100a7a:	89 07                	mov    %eax,(%edi)
f0100a7c:	eb 22                	jmp    f0100aa0 <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a7e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a81:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a83:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0100a86:	8b 0b                	mov    (%ebx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a88:	eb 01                	jmp    f0100a8b <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a8a:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a8b:	39 c1                	cmp    %eax,%ecx
f0100a8d:	7d 0c                	jge    f0100a9b <stab_binsearch+0xd0>
f0100a8f:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100a92:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a97:	39 fa                	cmp    %edi,%edx
f0100a99:	75 ef                	jne    f0100a8a <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a9b:	8b 7d e8             	mov    -0x18(%ebp),%edi
f0100a9e:	89 07                	mov    %eax,(%edi)
	}
}
f0100aa0:	83 c4 10             	add    $0x10,%esp
f0100aa3:	5b                   	pop    %ebx
f0100aa4:	5e                   	pop    %esi
f0100aa5:	5f                   	pop    %edi
f0100aa6:	5d                   	pop    %ebp
f0100aa7:	c3                   	ret    

f0100aa8 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100aa8:	55                   	push   %ebp
f0100aa9:	89 e5                	mov    %esp,%ebp
f0100aab:	57                   	push   %edi
f0100aac:	56                   	push   %esi
f0100aad:	53                   	push   %ebx
f0100aae:	83 ec 3c             	sub    $0x3c,%esp
f0100ab1:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ab4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ab7:	c7 03 e4 1f 10 f0    	movl   $0xf0101fe4,(%ebx)
	info->eip_line = 0;
f0100abd:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ac4:	c7 43 08 e4 1f 10 f0 	movl   $0xf0101fe4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100acb:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ad2:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100ad5:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100adc:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ae2:	76 12                	jbe    f0100af6 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ae4:	b8 51 75 10 f0       	mov    $0xf0107551,%eax
f0100ae9:	3d 59 5c 10 f0       	cmp    $0xf0105c59,%eax
f0100aee:	0f 86 d7 01 00 00    	jbe    f0100ccb <debuginfo_eip+0x223>
f0100af4:	eb 1c                	jmp    f0100b12 <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100af6:	c7 44 24 08 ee 1f 10 	movl   $0xf0101fee,0x8(%esp)
f0100afd:	f0 
f0100afe:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b05:	00 
f0100b06:	c7 04 24 fb 1f 10 f0 	movl   $0xf0101ffb,(%esp)
f0100b0d:	e8 e6 f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b12:	80 3d 50 75 10 f0 00 	cmpb   $0x0,0xf0107550
f0100b19:	0f 85 b3 01 00 00    	jne    f0100cd2 <debuginfo_eip+0x22a>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b1f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b26:	b8 58 5c 10 f0       	mov    $0xf0105c58,%eax
f0100b2b:	2d 2c 22 10 f0       	sub    $0xf010222c,%eax
f0100b30:	c1 f8 02             	sar    $0x2,%eax
f0100b33:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b39:	83 e8 01             	sub    $0x1,%eax
f0100b3c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b3f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b43:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b4a:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b4d:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b50:	b8 2c 22 10 f0       	mov    $0xf010222c,%eax
f0100b55:	e8 71 fe ff ff       	call   f01009cb <stab_binsearch>
	if (lfile == 0)
f0100b5a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b5d:	85 c0                	test   %eax,%eax
f0100b5f:	0f 84 74 01 00 00    	je     f0100cd9 <debuginfo_eip+0x231>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b65:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b68:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b6b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b6e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b72:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b79:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b7c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b7f:	b8 2c 22 10 f0       	mov    $0xf010222c,%eax
f0100b84:	e8 42 fe ff ff       	call   f01009cb <stab_binsearch>

	if (lfun <= rfun) {
f0100b89:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100b8c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100b8f:	39 d0                	cmp    %edx,%eax
f0100b91:	7f 3d                	jg     f0100bd0 <debuginfo_eip+0x128>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b93:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100b96:	8d b9 2c 22 10 f0    	lea    -0xfefddd4(%ecx),%edi
f0100b9c:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0100b9f:	8b 89 2c 22 10 f0    	mov    -0xfefddd4(%ecx),%ecx
f0100ba5:	bf 51 75 10 f0       	mov    $0xf0107551,%edi
f0100baa:	81 ef 59 5c 10 f0    	sub    $0xf0105c59,%edi
f0100bb0:	39 f9                	cmp    %edi,%ecx
f0100bb2:	73 09                	jae    f0100bbd <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bb4:	81 c1 59 5c 10 f0    	add    $0xf0105c59,%ecx
f0100bba:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bbd:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100bc0:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100bc3:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100bc6:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100bc8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100bcb:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100bce:	eb 0f                	jmp    f0100bdf <debuginfo_eip+0x137>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bd0:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100bd3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100bd6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100bd9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bdc:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bdf:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100be6:	00 
f0100be7:	8b 43 08             	mov    0x8(%ebx),%eax
f0100bea:	89 04 24             	mov    %eax,(%esp)
f0100bed:	e8 c9 09 00 00       	call   f01015bb <strfind>
f0100bf2:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bf5:	89 43 0c             	mov    %eax,0xc(%ebx)
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.

	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100bf8:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100bfc:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c03:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100c06:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100c09:	b8 2c 22 10 f0       	mov    $0xf010222c,%eax
f0100c0e:	e8 b8 fd ff ff       	call   f01009cb <stab_binsearch>
	if(lline <= rline)
f0100c13:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c16:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100c19:	7f 0f                	jg     f0100c2a <debuginfo_eip+0x182>
		info->eip_line = stabs[lline].n_desc;
f0100c1b:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100c1e:	0f b7 80 32 22 10 f0 	movzwl -0xfefddce(%eax),%eax
f0100c25:	89 43 04             	mov    %eax,0x4(%ebx)
f0100c28:	eb 0c                	jmp    f0100c36 <debuginfo_eip+0x18e>
	else
		cprintf("line not find\n");
f0100c2a:	c7 04 24 09 20 10 f0 	movl   $0xf0102009,(%esp)
f0100c31:	e8 7b fd ff ff       	call   f01009b1 <cprintf>
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c36:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c39:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100c3c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c3f:	6b d0 0c             	imul   $0xc,%eax,%edx
f0100c42:	81 c2 2c 22 10 f0    	add    $0xf010222c,%edx
f0100c48:	eb 06                	jmp    f0100c50 <debuginfo_eip+0x1a8>
f0100c4a:	83 e8 01             	sub    $0x1,%eax
f0100c4d:	83 ea 0c             	sub    $0xc,%edx
f0100c50:	89 c6                	mov    %eax,%esi
f0100c52:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100c55:	7f 33                	jg     f0100c8a <debuginfo_eip+0x1e2>
	       && stabs[lline].n_type != N_SOL
f0100c57:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0100c5b:	80 f9 84             	cmp    $0x84,%cl
f0100c5e:	74 0b                	je     f0100c6b <debuginfo_eip+0x1c3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c60:	80 f9 64             	cmp    $0x64,%cl
f0100c63:	75 e5                	jne    f0100c4a <debuginfo_eip+0x1a2>
f0100c65:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100c69:	74 df                	je     f0100c4a <debuginfo_eip+0x1a2>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c6b:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100c6e:	8b 86 2c 22 10 f0    	mov    -0xfefddd4(%esi),%eax
f0100c74:	ba 51 75 10 f0       	mov    $0xf0107551,%edx
f0100c79:	81 ea 59 5c 10 f0    	sub    $0xf0105c59,%edx
f0100c7f:	39 d0                	cmp    %edx,%eax
f0100c81:	73 07                	jae    f0100c8a <debuginfo_eip+0x1e2>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c83:	05 59 5c 10 f0       	add    $0xf0105c59,%eax
f0100c88:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c8a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c8d:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c90:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c95:	39 ca                	cmp    %ecx,%edx
f0100c97:	7d 4c                	jge    f0100ce5 <debuginfo_eip+0x23d>
		for (lline = lfun + 1;
f0100c99:	8d 42 01             	lea    0x1(%edx),%eax
f0100c9c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100c9f:	89 c2                	mov    %eax,%edx
f0100ca1:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100ca4:	05 2c 22 10 f0       	add    $0xf010222c,%eax
f0100ca9:	89 ce                	mov    %ecx,%esi
f0100cab:	eb 04                	jmp    f0100cb1 <debuginfo_eip+0x209>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100cad:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100cb1:	39 d6                	cmp    %edx,%esi
f0100cb3:	7e 2b                	jle    f0100ce0 <debuginfo_eip+0x238>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cb5:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f0100cb9:	83 c2 01             	add    $0x1,%edx
f0100cbc:	83 c0 0c             	add    $0xc,%eax
f0100cbf:	80 f9 a0             	cmp    $0xa0,%cl
f0100cc2:	74 e9                	je     f0100cad <debuginfo_eip+0x205>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100cc4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cc9:	eb 1a                	jmp    f0100ce5 <debuginfo_eip+0x23d>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100ccb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cd0:	eb 13                	jmp    f0100ce5 <debuginfo_eip+0x23d>
f0100cd2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cd7:	eb 0c                	jmp    f0100ce5 <debuginfo_eip+0x23d>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100cd9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cde:	eb 05                	jmp    f0100ce5 <debuginfo_eip+0x23d>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ce0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ce5:	83 c4 3c             	add    $0x3c,%esp
f0100ce8:	5b                   	pop    %ebx
f0100ce9:	5e                   	pop    %esi
f0100cea:	5f                   	pop    %edi
f0100ceb:	5d                   	pop    %ebp
f0100cec:	c3                   	ret    
f0100ced:	66 90                	xchg   %ax,%ax
f0100cef:	90                   	nop

f0100cf0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cf0:	55                   	push   %ebp
f0100cf1:	89 e5                	mov    %esp,%ebp
f0100cf3:	57                   	push   %edi
f0100cf4:	56                   	push   %esi
f0100cf5:	53                   	push   %ebx
f0100cf6:	83 ec 3c             	sub    $0x3c,%esp
f0100cf9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100cfc:	89 d7                	mov    %edx,%edi
f0100cfe:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d01:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d04:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d07:	89 c3                	mov    %eax,%ebx
f0100d09:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d0c:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d0f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d12:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100d17:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d1a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100d1d:	39 d9                	cmp    %ebx,%ecx
f0100d1f:	72 05                	jb     f0100d26 <printnum+0x36>
f0100d21:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100d24:	77 69                	ja     f0100d8f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d26:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100d29:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100d2d:	83 ee 01             	sub    $0x1,%esi
f0100d30:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d34:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d38:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d3c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d40:	89 c3                	mov    %eax,%ebx
f0100d42:	89 d6                	mov    %edx,%esi
f0100d44:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100d47:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100d4a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100d4e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d52:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d55:	89 04 24             	mov    %eax,(%esp)
f0100d58:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d5b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d5f:	e8 7c 0a 00 00       	call   f01017e0 <__udivdi3>
f0100d64:	89 d9                	mov    %ebx,%ecx
f0100d66:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100d6a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d6e:	89 04 24             	mov    %eax,(%esp)
f0100d71:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d75:	89 fa                	mov    %edi,%edx
f0100d77:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d7a:	e8 71 ff ff ff       	call   f0100cf0 <printnum>
f0100d7f:	eb 1b                	jmp    f0100d9c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d81:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d85:	8b 45 18             	mov    0x18(%ebp),%eax
f0100d88:	89 04 24             	mov    %eax,(%esp)
f0100d8b:	ff d3                	call   *%ebx
f0100d8d:	eb 03                	jmp    f0100d92 <printnum+0xa2>
f0100d8f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d92:	83 ee 01             	sub    $0x1,%esi
f0100d95:	85 f6                	test   %esi,%esi
f0100d97:	7f e8                	jg     f0100d81 <printnum+0x91>
f0100d99:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d9c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100da0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100da4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100da7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100daa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100dae:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100db2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100db5:	89 04 24             	mov    %eax,(%esp)
f0100db8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100dbb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dbf:	e8 4c 0b 00 00       	call   f0101910 <__umoddi3>
f0100dc4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dc8:	0f be 80 18 20 10 f0 	movsbl -0xfefdfe8(%eax),%eax
f0100dcf:	89 04 24             	mov    %eax,(%esp)
f0100dd2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100dd5:	ff d0                	call   *%eax
}
f0100dd7:	83 c4 3c             	add    $0x3c,%esp
f0100dda:	5b                   	pop    %ebx
f0100ddb:	5e                   	pop    %esi
f0100ddc:	5f                   	pop    %edi
f0100ddd:	5d                   	pop    %ebp
f0100dde:	c3                   	ret    

f0100ddf <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100ddf:	55                   	push   %ebp
f0100de0:	89 e5                	mov    %esp,%ebp
f0100de2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100de5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100de9:	8b 10                	mov    (%eax),%edx
f0100deb:	3b 50 04             	cmp    0x4(%eax),%edx
f0100dee:	73 0a                	jae    f0100dfa <sprintputch+0x1b>
		*b->buf++ = ch;
f0100df0:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100df3:	89 08                	mov    %ecx,(%eax)
f0100df5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100df8:	88 02                	mov    %al,(%edx)
}
f0100dfa:	5d                   	pop    %ebp
f0100dfb:	c3                   	ret    

f0100dfc <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100dfc:	55                   	push   %ebp
f0100dfd:	89 e5                	mov    %esp,%ebp
f0100dff:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100e02:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e05:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e09:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e0c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e10:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e13:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e17:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e1a:	89 04 24             	mov    %eax,(%esp)
f0100e1d:	e8 02 00 00 00       	call   f0100e24 <vprintfmt>
	va_end(ap);
}
f0100e22:	c9                   	leave  
f0100e23:	c3                   	ret    

f0100e24 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e24:	55                   	push   %ebp
f0100e25:	89 e5                	mov    %esp,%ebp
f0100e27:	57                   	push   %edi
f0100e28:	56                   	push   %esi
f0100e29:	53                   	push   %ebx
f0100e2a:	83 ec 3c             	sub    $0x3c,%esp
f0100e2d:	8b 75 08             	mov    0x8(%ebp),%esi
f0100e30:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e33:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e36:	eb 11                	jmp    f0100e49 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e38:	85 c0                	test   %eax,%eax
f0100e3a:	0f 84 aa 04 00 00    	je     f01012ea <vprintfmt+0x4c6>
				return;
			putch(ch, putdat);
f0100e40:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e44:	89 04 24             	mov    %eax,(%esp)
f0100e47:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e49:	83 c7 01             	add    $0x1,%edi
f0100e4c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0100e50:	83 f8 25             	cmp    $0x25,%eax
f0100e53:	75 e3                	jne    f0100e38 <vprintfmt+0x14>
f0100e55:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0100e59:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100e60:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0100e67:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0100e6e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e73:	eb 1f                	jmp    f0100e94 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e75:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e78:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100e7c:	eb 16                	jmp    f0100e94 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e7e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e81:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100e85:	eb 0d                	jmp    f0100e94 <vprintfmt+0x70>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100e87:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100e8a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100e8d:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e94:	8d 47 01             	lea    0x1(%edi),%eax
f0100e97:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e9a:	0f b6 17             	movzbl (%edi),%edx
f0100e9d:	0f b6 c2             	movzbl %dl,%eax
f0100ea0:	83 ea 23             	sub    $0x23,%edx
f0100ea3:	80 fa 55             	cmp    $0x55,%dl
f0100ea6:	0f 87 21 04 00 00    	ja     f01012cd <vprintfmt+0x4a9>
f0100eac:	0f b6 d2             	movzbl %dl,%edx
f0100eaf:	ff 24 95 a8 20 10 f0 	jmp    *-0xfefdf58(,%edx,4)
f0100eb6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100eb9:	ba 00 00 00 00       	mov    $0x0,%edx
f0100ebe:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100ec1:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100ec4:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100ec8:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0100ecb:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100ece:	83 f9 09             	cmp    $0x9,%ecx
f0100ed1:	77 37                	ja     f0100f0a <vprintfmt+0xe6>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100ed3:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100ed6:	eb e9                	jmp    f0100ec1 <vprintfmt+0x9d>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100ed8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100edb:	8b 00                	mov    (%eax),%eax
f0100edd:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100ee0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ee3:	8d 40 04             	lea    0x4(%eax),%eax
f0100ee6:	89 45 14             	mov    %eax,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100eec:	eb 22                	jmp    f0100f10 <vprintfmt+0xec>
f0100eee:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ef1:	c1 f8 1f             	sar    $0x1f,%eax
f0100ef4:	f7 d0                	not    %eax
f0100ef6:	21 45 e0             	and    %eax,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100efc:	eb 96                	jmp    f0100e94 <vprintfmt+0x70>
f0100efe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f01:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f08:	eb 8a                	jmp    f0100e94 <vprintfmt+0x70>
f0100f0a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f0d:	89 55 d0             	mov    %edx,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0100f10:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f14:	0f 89 7a ff ff ff    	jns    f0100e94 <vprintfmt+0x70>
f0100f1a:	e9 68 ff ff ff       	jmp    f0100e87 <vprintfmt+0x63>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f1f:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f22:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f25:	e9 6a ff ff ff       	jmp    f0100e94 <vprintfmt+0x70>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f2a:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f2d:	8d 78 04             	lea    0x4(%eax),%edi
f0100f30:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f34:	8b 00                	mov    (%eax),%eax
f0100f36:	89 04 24             	mov    %eax,(%esp)
f0100f39:	ff d6                	call   *%esi
f0100f3b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f3e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100f41:	e9 03 ff ff ff       	jmp    f0100e49 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f46:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f49:	8d 78 04             	lea    0x4(%eax),%edi
f0100f4c:	8b 00                	mov    (%eax),%eax
f0100f4e:	99                   	cltd   
f0100f4f:	31 d0                	xor    %edx,%eax
f0100f51:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f53:	83 f8 06             	cmp    $0x6,%eax
f0100f56:	7f 0b                	jg     f0100f63 <vprintfmt+0x13f>
f0100f58:	8b 14 85 00 22 10 f0 	mov    -0xfefde00(,%eax,4),%edx
f0100f5f:	85 d2                	test   %edx,%edx
f0100f61:	75 23                	jne    f0100f86 <vprintfmt+0x162>
				printfmt(putch, putdat, "error %d", err);
f0100f63:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f67:	c7 44 24 08 30 20 10 	movl   $0xf0102030,0x8(%esp)
f0100f6e:	f0 
f0100f6f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f73:	89 34 24             	mov    %esi,(%esp)
f0100f76:	e8 81 fe ff ff       	call   f0100dfc <printfmt>
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f7b:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f7e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f81:	e9 c3 fe ff ff       	jmp    f0100e49 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100f86:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f8a:	c7 44 24 08 39 20 10 	movl   $0xf0102039,0x8(%esp)
f0100f91:	f0 
f0100f92:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f96:	89 34 24             	mov    %esi,(%esp)
f0100f99:	e8 5e fe ff ff       	call   f0100dfc <printfmt>
			putch(va_arg(ap, int), putdat);
			break;

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f9e:	89 7d 14             	mov    %edi,0x14(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fa1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fa4:	e9 a0 fe ff ff       	jmp    f0100e49 <vprintfmt+0x25>
f0100fa9:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fac:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0100faf:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100fb2:	89 4d cc             	mov    %ecx,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100fb5:	83 45 14 04          	addl   $0x4,0x14(%ebp)
f0100fb9:	8b 38                	mov    (%eax),%edi
f0100fbb:	85 ff                	test   %edi,%edi
f0100fbd:	75 05                	jne    f0100fc4 <vprintfmt+0x1a0>
				p = "(null)";
f0100fbf:	bf 29 20 10 f0       	mov    $0xf0102029,%edi
			if (width > 0 && padc != '-')
f0100fc4:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100fc8:	0f 84 93 00 00 00    	je     f0101061 <vprintfmt+0x23d>
f0100fce:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0100fd2:	0f 8e 97 00 00 00    	jle    f010106f <vprintfmt+0x24b>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fd8:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100fdc:	89 3c 24             	mov    %edi,(%esp)
f0100fdf:	e8 84 04 00 00       	call   f0101468 <strnlen>
f0100fe4:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0100fe7:	29 c1                	sub    %eax,%ecx
f0100fe9:	89 4d cc             	mov    %ecx,-0x34(%ebp)
					putch(padc, putdat);
f0100fec:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0100ff0:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ff3:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100ff6:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100ff8:	eb 0f                	jmp    f0101009 <vprintfmt+0x1e5>
					putch(padc, putdat);
f0100ffa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ffe:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101001:	89 04 24             	mov    %eax,(%esp)
f0101004:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101006:	83 ef 01             	sub    $0x1,%edi
f0101009:	85 ff                	test   %edi,%edi
f010100b:	7f ed                	jg     f0100ffa <vprintfmt+0x1d6>
f010100d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101010:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101013:	89 c8                	mov    %ecx,%eax
f0101015:	c1 f8 1f             	sar    $0x1f,%eax
f0101018:	f7 d0                	not    %eax
f010101a:	21 c8                	and    %ecx,%eax
f010101c:	29 c1                	sub    %eax,%ecx
f010101e:	89 75 08             	mov    %esi,0x8(%ebp)
f0101021:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101024:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101027:	89 cb                	mov    %ecx,%ebx
f0101029:	eb 50                	jmp    f010107b <vprintfmt+0x257>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010102b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010102f:	74 1e                	je     f010104f <vprintfmt+0x22b>
f0101031:	0f be d2             	movsbl %dl,%edx
f0101034:	83 ea 20             	sub    $0x20,%edx
f0101037:	83 fa 5e             	cmp    $0x5e,%edx
f010103a:	76 13                	jbe    f010104f <vprintfmt+0x22b>
					putch('?', putdat);
f010103c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010103f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101043:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010104a:	ff 55 08             	call   *0x8(%ebp)
f010104d:	eb 0d                	jmp    f010105c <vprintfmt+0x238>
				else
					putch(ch, putdat);
f010104f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101052:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101056:	89 04 24             	mov    %eax,(%esp)
f0101059:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010105c:	83 eb 01             	sub    $0x1,%ebx
f010105f:	eb 1a                	jmp    f010107b <vprintfmt+0x257>
f0101061:	89 75 08             	mov    %esi,0x8(%ebp)
f0101064:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101067:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f010106a:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010106d:	eb 0c                	jmp    f010107b <vprintfmt+0x257>
f010106f:	89 75 08             	mov    %esi,0x8(%ebp)
f0101072:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101075:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101078:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010107b:	83 c7 01             	add    $0x1,%edi
f010107e:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101082:	0f be c2             	movsbl %dl,%eax
f0101085:	85 c0                	test   %eax,%eax
f0101087:	74 25                	je     f01010ae <vprintfmt+0x28a>
f0101089:	85 f6                	test   %esi,%esi
f010108b:	78 9e                	js     f010102b <vprintfmt+0x207>
f010108d:	83 ee 01             	sub    $0x1,%esi
f0101090:	79 99                	jns    f010102b <vprintfmt+0x207>
f0101092:	89 df                	mov    %ebx,%edi
f0101094:	8b 75 08             	mov    0x8(%ebp),%esi
f0101097:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010109a:	eb 1a                	jmp    f01010b6 <vprintfmt+0x292>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010109c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010a0:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01010a7:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01010a9:	83 ef 01             	sub    $0x1,%edi
f01010ac:	eb 08                	jmp    f01010b6 <vprintfmt+0x292>
f01010ae:	89 df                	mov    %ebx,%edi
f01010b0:	8b 75 08             	mov    0x8(%ebp),%esi
f01010b3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010b6:	85 ff                	test   %edi,%edi
f01010b8:	7f e2                	jg     f010109c <vprintfmt+0x278>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010ba:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010bd:	e9 87 fd ff ff       	jmp    f0100e49 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010c2:	83 f9 01             	cmp    $0x1,%ecx
f01010c5:	7e 19                	jle    f01010e0 <vprintfmt+0x2bc>
		return va_arg(*ap, long long);
f01010c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ca:	8b 50 04             	mov    0x4(%eax),%edx
f01010cd:	8b 00                	mov    (%eax),%eax
f01010cf:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010d2:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01010d5:	8b 45 14             	mov    0x14(%ebp),%eax
f01010d8:	8d 40 08             	lea    0x8(%eax),%eax
f01010db:	89 45 14             	mov    %eax,0x14(%ebp)
f01010de:	eb 38                	jmp    f0101118 <vprintfmt+0x2f4>
	else if (lflag)
f01010e0:	85 c9                	test   %ecx,%ecx
f01010e2:	74 1b                	je     f01010ff <vprintfmt+0x2db>
		return va_arg(*ap, long);
f01010e4:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e7:	8b 00                	mov    (%eax),%eax
f01010e9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010ec:	89 c1                	mov    %eax,%ecx
f01010ee:	c1 f9 1f             	sar    $0x1f,%ecx
f01010f1:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01010f4:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f7:	8d 40 04             	lea    0x4(%eax),%eax
f01010fa:	89 45 14             	mov    %eax,0x14(%ebp)
f01010fd:	eb 19                	jmp    f0101118 <vprintfmt+0x2f4>
	else
		return va_arg(*ap, int);
f01010ff:	8b 45 14             	mov    0x14(%ebp),%eax
f0101102:	8b 00                	mov    (%eax),%eax
f0101104:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101107:	89 c1                	mov    %eax,%ecx
f0101109:	c1 f9 1f             	sar    $0x1f,%ecx
f010110c:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010110f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101112:	8d 40 04             	lea    0x4(%eax),%eax
f0101115:	89 45 14             	mov    %eax,0x14(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101118:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010111b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010111e:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101123:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101127:	0f 89 64 01 00 00    	jns    f0101291 <vprintfmt+0x46d>
				putch('-', putdat);
f010112d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101131:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101138:	ff d6                	call   *%esi
				num = -(long long) num;
f010113a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010113d:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101140:	f7 da                	neg    %edx
f0101142:	83 d1 00             	adc    $0x0,%ecx
f0101145:	f7 d9                	neg    %ecx
			}
			base = 10;
f0101147:	b8 0a 00 00 00       	mov    $0xa,%eax
f010114c:	e9 40 01 00 00       	jmp    f0101291 <vprintfmt+0x46d>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101151:	83 f9 01             	cmp    $0x1,%ecx
f0101154:	7e 10                	jle    f0101166 <vprintfmt+0x342>
		return va_arg(*ap, unsigned long long);
f0101156:	8b 45 14             	mov    0x14(%ebp),%eax
f0101159:	8b 10                	mov    (%eax),%edx
f010115b:	8b 48 04             	mov    0x4(%eax),%ecx
f010115e:	8d 40 08             	lea    0x8(%eax),%eax
f0101161:	89 45 14             	mov    %eax,0x14(%ebp)
f0101164:	eb 26                	jmp    f010118c <vprintfmt+0x368>
	else if (lflag)
f0101166:	85 c9                	test   %ecx,%ecx
f0101168:	74 12                	je     f010117c <vprintfmt+0x358>
		return va_arg(*ap, unsigned long);
f010116a:	8b 45 14             	mov    0x14(%ebp),%eax
f010116d:	8b 10                	mov    (%eax),%edx
f010116f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101174:	8d 40 04             	lea    0x4(%eax),%eax
f0101177:	89 45 14             	mov    %eax,0x14(%ebp)
f010117a:	eb 10                	jmp    f010118c <vprintfmt+0x368>
	else
		return va_arg(*ap, unsigned int);
f010117c:	8b 45 14             	mov    0x14(%ebp),%eax
f010117f:	8b 10                	mov    (%eax),%edx
f0101181:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101186:	8d 40 04             	lea    0x4(%eax),%eax
f0101189:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
			base = 10;
f010118c:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f0101191:	e9 fb 00 00 00       	jmp    f0101291 <vprintfmt+0x46d>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101196:	83 f9 01             	cmp    $0x1,%ecx
f0101199:	7e 19                	jle    f01011b4 <vprintfmt+0x390>
		return va_arg(*ap, long long);
f010119b:	8b 45 14             	mov    0x14(%ebp),%eax
f010119e:	8b 50 04             	mov    0x4(%eax),%edx
f01011a1:	8b 00                	mov    (%eax),%eax
f01011a3:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011a6:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01011a9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011ac:	8d 40 08             	lea    0x8(%eax),%eax
f01011af:	89 45 14             	mov    %eax,0x14(%ebp)
f01011b2:	eb 38                	jmp    f01011ec <vprintfmt+0x3c8>
	else if (lflag)
f01011b4:	85 c9                	test   %ecx,%ecx
f01011b6:	74 1b                	je     f01011d3 <vprintfmt+0x3af>
		return va_arg(*ap, long);
f01011b8:	8b 45 14             	mov    0x14(%ebp),%eax
f01011bb:	8b 00                	mov    (%eax),%eax
f01011bd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011c0:	89 c1                	mov    %eax,%ecx
f01011c2:	c1 f9 1f             	sar    $0x1f,%ecx
f01011c5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01011c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01011cb:	8d 40 04             	lea    0x4(%eax),%eax
f01011ce:	89 45 14             	mov    %eax,0x14(%ebp)
f01011d1:	eb 19                	jmp    f01011ec <vprintfmt+0x3c8>
	else
		return va_arg(*ap, int);
f01011d3:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d6:	8b 00                	mov    (%eax),%eax
f01011d8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011db:	89 c1                	mov    %eax,%ecx
f01011dd:	c1 f9 1f             	sar    $0x1f,%ecx
f01011e0:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01011e3:	8b 45 14             	mov    0x14(%ebp),%eax
f01011e6:	8d 40 04             	lea    0x4(%eax),%eax
f01011e9:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap, lflag);
f01011ec:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01011ef:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 8;
f01011f2:	b8 08 00 00 00       	mov    $0x8,%eax

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01011f7:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01011fb:	0f 89 90 00 00 00    	jns    f0101291 <vprintfmt+0x46d>
				putch('-', putdat);
f0101201:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101205:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010120c:	ff d6                	call   *%esi
				num = -(long long) num;
f010120e:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101211:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101214:	f7 da                	neg    %edx
f0101216:	83 d1 00             	adc    $0x0,%ecx
f0101219:	f7 d9                	neg    %ecx
			}
			base = 8;
f010121b:	b8 08 00 00 00       	mov    $0x8,%eax
f0101220:	eb 6f                	jmp    f0101291 <vprintfmt+0x46d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101222:	8b 7d 14             	mov    0x14(%ebp),%edi
			goto number;
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0101225:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101229:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0101230:	ff d6                	call   *%esi
			putch('x', putdat);
f0101232:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101236:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010123d:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010123f:	83 45 14 04          	addl   $0x4,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101243:	8b 17                	mov    (%edi),%edx
f0101245:	b9 00 00 00 00       	mov    $0x0,%ecx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010124a:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010124f:	eb 40                	jmp    f0101291 <vprintfmt+0x46d>
// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101251:	83 f9 01             	cmp    $0x1,%ecx
f0101254:	7e 10                	jle    f0101266 <vprintfmt+0x442>
		return va_arg(*ap, unsigned long long);
f0101256:	8b 45 14             	mov    0x14(%ebp),%eax
f0101259:	8b 10                	mov    (%eax),%edx
f010125b:	8b 48 04             	mov    0x4(%eax),%ecx
f010125e:	8d 40 08             	lea    0x8(%eax),%eax
f0101261:	89 45 14             	mov    %eax,0x14(%ebp)
f0101264:	eb 26                	jmp    f010128c <vprintfmt+0x468>
	else if (lflag)
f0101266:	85 c9                	test   %ecx,%ecx
f0101268:	74 12                	je     f010127c <vprintfmt+0x458>
		return va_arg(*ap, unsigned long);
f010126a:	8b 45 14             	mov    0x14(%ebp),%eax
f010126d:	8b 10                	mov    (%eax),%edx
f010126f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101274:	8d 40 04             	lea    0x4(%eax),%eax
f0101277:	89 45 14             	mov    %eax,0x14(%ebp)
f010127a:	eb 10                	jmp    f010128c <vprintfmt+0x468>
	else
		return va_arg(*ap, unsigned int);
f010127c:	8b 45 14             	mov    0x14(%ebp),%eax
f010127f:	8b 10                	mov    (%eax),%edx
f0101281:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101286:	8d 40 04             	lea    0x4(%eax),%eax
f0101289:	89 45 14             	mov    %eax,0x14(%ebp)
			goto number;

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
			base = 16;
f010128c:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101291:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101295:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0101299:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010129c:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01012a0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012a4:	89 14 24             	mov    %edx,(%esp)
f01012a7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01012ab:	89 da                	mov    %ebx,%edx
f01012ad:	89 f0                	mov    %esi,%eax
f01012af:	e8 3c fa ff ff       	call   f0100cf0 <printnum>
			break;
f01012b4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01012b7:	e9 8d fb ff ff       	jmp    f0100e49 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01012bc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012c0:	89 04 24             	mov    %eax,(%esp)
f01012c3:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012c5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01012c8:	e9 7c fb ff ff       	jmp    f0100e49 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01012cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012d1:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01012d8:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f01012da:	eb 03                	jmp    f01012df <vprintfmt+0x4bb>
f01012dc:	83 ef 01             	sub    $0x1,%edi
f01012df:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f01012e3:	75 f7                	jne    f01012dc <vprintfmt+0x4b8>
f01012e5:	e9 5f fb ff ff       	jmp    f0100e49 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01012ea:	83 c4 3c             	add    $0x3c,%esp
f01012ed:	5b                   	pop    %ebx
f01012ee:	5e                   	pop    %esi
f01012ef:	5f                   	pop    %edi
f01012f0:	5d                   	pop    %ebp
f01012f1:	c3                   	ret    

f01012f2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01012f2:	55                   	push   %ebp
f01012f3:	89 e5                	mov    %esp,%ebp
f01012f5:	83 ec 28             	sub    $0x28,%esp
f01012f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01012fb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01012fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101301:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101305:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101308:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010130f:	85 c0                	test   %eax,%eax
f0101311:	74 30                	je     f0101343 <vsnprintf+0x51>
f0101313:	85 d2                	test   %edx,%edx
f0101315:	7e 2c                	jle    f0101343 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101317:	8b 45 14             	mov    0x14(%ebp),%eax
f010131a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010131e:	8b 45 10             	mov    0x10(%ebp),%eax
f0101321:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101325:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101328:	89 44 24 04          	mov    %eax,0x4(%esp)
f010132c:	c7 04 24 df 0d 10 f0 	movl   $0xf0100ddf,(%esp)
f0101333:	e8 ec fa ff ff       	call   f0100e24 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101338:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010133b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010133e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101341:	eb 05                	jmp    f0101348 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101343:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101348:	c9                   	leave  
f0101349:	c3                   	ret    

f010134a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010134a:	55                   	push   %ebp
f010134b:	89 e5                	mov    %esp,%ebp
f010134d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101350:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101353:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101357:	8b 45 10             	mov    0x10(%ebp),%eax
f010135a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010135e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101361:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101365:	8b 45 08             	mov    0x8(%ebp),%eax
f0101368:	89 04 24             	mov    %eax,(%esp)
f010136b:	e8 82 ff ff ff       	call   f01012f2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101370:	c9                   	leave  
f0101371:	c3                   	ret    
f0101372:	66 90                	xchg   %ax,%ax
f0101374:	66 90                	xchg   %ax,%ax
f0101376:	66 90                	xchg   %ax,%ax
f0101378:	66 90                	xchg   %ax,%ax
f010137a:	66 90                	xchg   %ax,%ax
f010137c:	66 90                	xchg   %ax,%ax
f010137e:	66 90                	xchg   %ax,%ax

f0101380 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101380:	55                   	push   %ebp
f0101381:	89 e5                	mov    %esp,%ebp
f0101383:	57                   	push   %edi
f0101384:	56                   	push   %esi
f0101385:	53                   	push   %ebx
f0101386:	83 ec 1c             	sub    $0x1c,%esp
f0101389:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010138c:	85 c0                	test   %eax,%eax
f010138e:	74 10                	je     f01013a0 <readline+0x20>
		cprintf("%s", prompt);
f0101390:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101394:	c7 04 24 39 20 10 f0 	movl   $0xf0102039,(%esp)
f010139b:	e8 11 f6 ff ff       	call   f01009b1 <cprintf>

	i = 0;
	echoing = iscons(0);
f01013a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013a7:	e8 c6 f2 ff ff       	call   f0100672 <iscons>
f01013ac:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01013ae:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01013b3:	e8 a9 f2 ff ff       	call   f0100661 <getchar>
f01013b8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01013ba:	85 c0                	test   %eax,%eax
f01013bc:	79 17                	jns    f01013d5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01013be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013c2:	c7 04 24 1c 22 10 f0 	movl   $0xf010221c,(%esp)
f01013c9:	e8 e3 f5 ff ff       	call   f01009b1 <cprintf>
			return NULL;
f01013ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01013d3:	eb 6d                	jmp    f0101442 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01013d5:	83 f8 7f             	cmp    $0x7f,%eax
f01013d8:	74 05                	je     f01013df <readline+0x5f>
f01013da:	83 f8 08             	cmp    $0x8,%eax
f01013dd:	75 19                	jne    f01013f8 <readline+0x78>
f01013df:	85 f6                	test   %esi,%esi
f01013e1:	7e 15                	jle    f01013f8 <readline+0x78>
			if (echoing)
f01013e3:	85 ff                	test   %edi,%edi
f01013e5:	74 0c                	je     f01013f3 <readline+0x73>
				cputchar('\b');
f01013e7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01013ee:	e8 5e f2 ff ff       	call   f0100651 <cputchar>
			i--;
f01013f3:	83 ee 01             	sub    $0x1,%esi
f01013f6:	eb bb                	jmp    f01013b3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01013f8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01013fe:	7f 1c                	jg     f010141c <readline+0x9c>
f0101400:	83 fb 1f             	cmp    $0x1f,%ebx
f0101403:	7e 17                	jle    f010141c <readline+0x9c>
			if (echoing)
f0101405:	85 ff                	test   %edi,%edi
f0101407:	74 08                	je     f0101411 <readline+0x91>
				cputchar(c);
f0101409:	89 1c 24             	mov    %ebx,(%esp)
f010140c:	e8 40 f2 ff ff       	call   f0100651 <cputchar>
			buf[i++] = c;
f0101411:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101417:	8d 76 01             	lea    0x1(%esi),%esi
f010141a:	eb 97                	jmp    f01013b3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010141c:	83 fb 0d             	cmp    $0xd,%ebx
f010141f:	74 05                	je     f0101426 <readline+0xa6>
f0101421:	83 fb 0a             	cmp    $0xa,%ebx
f0101424:	75 8d                	jne    f01013b3 <readline+0x33>
			if (echoing)
f0101426:	85 ff                	test   %edi,%edi
f0101428:	74 0c                	je     f0101436 <readline+0xb6>
				cputchar('\n');
f010142a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101431:	e8 1b f2 ff ff       	call   f0100651 <cputchar>
			buf[i] = 0;
f0101436:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010143d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f0101442:	83 c4 1c             	add    $0x1c,%esp
f0101445:	5b                   	pop    %ebx
f0101446:	5e                   	pop    %esi
f0101447:	5f                   	pop    %edi
f0101448:	5d                   	pop    %ebp
f0101449:	c3                   	ret    
f010144a:	66 90                	xchg   %ax,%ax
f010144c:	66 90                	xchg   %ax,%ax
f010144e:	66 90                	xchg   %ax,%ax

f0101450 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101450:	55                   	push   %ebp
f0101451:	89 e5                	mov    %esp,%ebp
f0101453:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101456:	b8 00 00 00 00       	mov    $0x0,%eax
f010145b:	eb 03                	jmp    f0101460 <strlen+0x10>
		n++;
f010145d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101460:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101464:	75 f7                	jne    f010145d <strlen+0xd>
		n++;
	return n;
}
f0101466:	5d                   	pop    %ebp
f0101467:	c3                   	ret    

f0101468 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101468:	55                   	push   %ebp
f0101469:	89 e5                	mov    %esp,%ebp
f010146b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010146e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101471:	b8 00 00 00 00       	mov    $0x0,%eax
f0101476:	eb 03                	jmp    f010147b <strnlen+0x13>
		n++;
f0101478:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010147b:	39 d0                	cmp    %edx,%eax
f010147d:	74 06                	je     f0101485 <strnlen+0x1d>
f010147f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101483:	75 f3                	jne    f0101478 <strnlen+0x10>
		n++;
	return n;
}
f0101485:	5d                   	pop    %ebp
f0101486:	c3                   	ret    

f0101487 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101487:	55                   	push   %ebp
f0101488:	89 e5                	mov    %esp,%ebp
f010148a:	53                   	push   %ebx
f010148b:	8b 45 08             	mov    0x8(%ebp),%eax
f010148e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101491:	89 c2                	mov    %eax,%edx
f0101493:	83 c2 01             	add    $0x1,%edx
f0101496:	83 c1 01             	add    $0x1,%ecx
f0101499:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010149d:	88 5a ff             	mov    %bl,-0x1(%edx)
f01014a0:	84 db                	test   %bl,%bl
f01014a2:	75 ef                	jne    f0101493 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01014a4:	5b                   	pop    %ebx
f01014a5:	5d                   	pop    %ebp
f01014a6:	c3                   	ret    

f01014a7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01014a7:	55                   	push   %ebp
f01014a8:	89 e5                	mov    %esp,%ebp
f01014aa:	53                   	push   %ebx
f01014ab:	83 ec 08             	sub    $0x8,%esp
f01014ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01014b1:	89 1c 24             	mov    %ebx,(%esp)
f01014b4:	e8 97 ff ff ff       	call   f0101450 <strlen>
	strcpy(dst + len, src);
f01014b9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01014bc:	89 54 24 04          	mov    %edx,0x4(%esp)
f01014c0:	01 d8                	add    %ebx,%eax
f01014c2:	89 04 24             	mov    %eax,(%esp)
f01014c5:	e8 bd ff ff ff       	call   f0101487 <strcpy>
	return dst;
}
f01014ca:	89 d8                	mov    %ebx,%eax
f01014cc:	83 c4 08             	add    $0x8,%esp
f01014cf:	5b                   	pop    %ebx
f01014d0:	5d                   	pop    %ebp
f01014d1:	c3                   	ret    

f01014d2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01014d2:	55                   	push   %ebp
f01014d3:	89 e5                	mov    %esp,%ebp
f01014d5:	56                   	push   %esi
f01014d6:	53                   	push   %ebx
f01014d7:	8b 75 08             	mov    0x8(%ebp),%esi
f01014da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01014dd:	89 f3                	mov    %esi,%ebx
f01014df:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014e2:	89 f2                	mov    %esi,%edx
f01014e4:	eb 0f                	jmp    f01014f5 <strncpy+0x23>
		*dst++ = *src;
f01014e6:	83 c2 01             	add    $0x1,%edx
f01014e9:	0f b6 01             	movzbl (%ecx),%eax
f01014ec:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01014ef:	80 39 01             	cmpb   $0x1,(%ecx)
f01014f2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01014f5:	39 da                	cmp    %ebx,%edx
f01014f7:	75 ed                	jne    f01014e6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01014f9:	89 f0                	mov    %esi,%eax
f01014fb:	5b                   	pop    %ebx
f01014fc:	5e                   	pop    %esi
f01014fd:	5d                   	pop    %ebp
f01014fe:	c3                   	ret    

f01014ff <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01014ff:	55                   	push   %ebp
f0101500:	89 e5                	mov    %esp,%ebp
f0101502:	56                   	push   %esi
f0101503:	53                   	push   %ebx
f0101504:	8b 75 08             	mov    0x8(%ebp),%esi
f0101507:	8b 55 0c             	mov    0xc(%ebp),%edx
f010150a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010150d:	89 f0                	mov    %esi,%eax
f010150f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101513:	85 c9                	test   %ecx,%ecx
f0101515:	75 0b                	jne    f0101522 <strlcpy+0x23>
f0101517:	eb 1d                	jmp    f0101536 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101519:	83 c0 01             	add    $0x1,%eax
f010151c:	83 c2 01             	add    $0x1,%edx
f010151f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101522:	39 d8                	cmp    %ebx,%eax
f0101524:	74 0b                	je     f0101531 <strlcpy+0x32>
f0101526:	0f b6 0a             	movzbl (%edx),%ecx
f0101529:	84 c9                	test   %cl,%cl
f010152b:	75 ec                	jne    f0101519 <strlcpy+0x1a>
f010152d:	89 c2                	mov    %eax,%edx
f010152f:	eb 02                	jmp    f0101533 <strlcpy+0x34>
f0101531:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0101533:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101536:	29 f0                	sub    %esi,%eax
}
f0101538:	5b                   	pop    %ebx
f0101539:	5e                   	pop    %esi
f010153a:	5d                   	pop    %ebp
f010153b:	c3                   	ret    

f010153c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010153c:	55                   	push   %ebp
f010153d:	89 e5                	mov    %esp,%ebp
f010153f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101542:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101545:	eb 06                	jmp    f010154d <strcmp+0x11>
		p++, q++;
f0101547:	83 c1 01             	add    $0x1,%ecx
f010154a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010154d:	0f b6 01             	movzbl (%ecx),%eax
f0101550:	84 c0                	test   %al,%al
f0101552:	74 04                	je     f0101558 <strcmp+0x1c>
f0101554:	3a 02                	cmp    (%edx),%al
f0101556:	74 ef                	je     f0101547 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101558:	0f b6 c0             	movzbl %al,%eax
f010155b:	0f b6 12             	movzbl (%edx),%edx
f010155e:	29 d0                	sub    %edx,%eax
}
f0101560:	5d                   	pop    %ebp
f0101561:	c3                   	ret    

f0101562 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101562:	55                   	push   %ebp
f0101563:	89 e5                	mov    %esp,%ebp
f0101565:	53                   	push   %ebx
f0101566:	8b 45 08             	mov    0x8(%ebp),%eax
f0101569:	8b 55 0c             	mov    0xc(%ebp),%edx
f010156c:	89 c3                	mov    %eax,%ebx
f010156e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101571:	eb 06                	jmp    f0101579 <strncmp+0x17>
		n--, p++, q++;
f0101573:	83 c0 01             	add    $0x1,%eax
f0101576:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101579:	39 d8                	cmp    %ebx,%eax
f010157b:	74 15                	je     f0101592 <strncmp+0x30>
f010157d:	0f b6 08             	movzbl (%eax),%ecx
f0101580:	84 c9                	test   %cl,%cl
f0101582:	74 04                	je     f0101588 <strncmp+0x26>
f0101584:	3a 0a                	cmp    (%edx),%cl
f0101586:	74 eb                	je     f0101573 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101588:	0f b6 00             	movzbl (%eax),%eax
f010158b:	0f b6 12             	movzbl (%edx),%edx
f010158e:	29 d0                	sub    %edx,%eax
f0101590:	eb 05                	jmp    f0101597 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101592:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101597:	5b                   	pop    %ebx
f0101598:	5d                   	pop    %ebp
f0101599:	c3                   	ret    

f010159a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010159a:	55                   	push   %ebp
f010159b:	89 e5                	mov    %esp,%ebp
f010159d:	8b 45 08             	mov    0x8(%ebp),%eax
f01015a0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015a4:	eb 07                	jmp    f01015ad <strchr+0x13>
		if (*s == c)
f01015a6:	38 ca                	cmp    %cl,%dl
f01015a8:	74 0f                	je     f01015b9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01015aa:	83 c0 01             	add    $0x1,%eax
f01015ad:	0f b6 10             	movzbl (%eax),%edx
f01015b0:	84 d2                	test   %dl,%dl
f01015b2:	75 f2                	jne    f01015a6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01015b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015b9:	5d                   	pop    %ebp
f01015ba:	c3                   	ret    

f01015bb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01015bb:	55                   	push   %ebp
f01015bc:	89 e5                	mov    %esp,%ebp
f01015be:	8b 45 08             	mov    0x8(%ebp),%eax
f01015c1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015c5:	eb 07                	jmp    f01015ce <strfind+0x13>
		if (*s == c)
f01015c7:	38 ca                	cmp    %cl,%dl
f01015c9:	74 0a                	je     f01015d5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01015cb:	83 c0 01             	add    $0x1,%eax
f01015ce:	0f b6 10             	movzbl (%eax),%edx
f01015d1:	84 d2                	test   %dl,%dl
f01015d3:	75 f2                	jne    f01015c7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f01015d5:	5d                   	pop    %ebp
f01015d6:	c3                   	ret    

f01015d7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01015d7:	55                   	push   %ebp
f01015d8:	89 e5                	mov    %esp,%ebp
f01015da:	57                   	push   %edi
f01015db:	56                   	push   %esi
f01015dc:	53                   	push   %ebx
f01015dd:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015e0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01015e3:	85 c9                	test   %ecx,%ecx
f01015e5:	74 36                	je     f010161d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01015e7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015ed:	75 28                	jne    f0101617 <memset+0x40>
f01015ef:	f6 c1 03             	test   $0x3,%cl
f01015f2:	75 23                	jne    f0101617 <memset+0x40>
		c &= 0xFF;
f01015f4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01015f8:	89 d3                	mov    %edx,%ebx
f01015fa:	c1 e3 08             	shl    $0x8,%ebx
f01015fd:	89 d6                	mov    %edx,%esi
f01015ff:	c1 e6 18             	shl    $0x18,%esi
f0101602:	89 d0                	mov    %edx,%eax
f0101604:	c1 e0 10             	shl    $0x10,%eax
f0101607:	09 f0                	or     %esi,%eax
f0101609:	09 c2                	or     %eax,%edx
f010160b:	89 d0                	mov    %edx,%eax
f010160d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010160f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101612:	fc                   	cld    
f0101613:	f3 ab                	rep stos %eax,%es:(%edi)
f0101615:	eb 06                	jmp    f010161d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101617:	8b 45 0c             	mov    0xc(%ebp),%eax
f010161a:	fc                   	cld    
f010161b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010161d:	89 f8                	mov    %edi,%eax
f010161f:	5b                   	pop    %ebx
f0101620:	5e                   	pop    %esi
f0101621:	5f                   	pop    %edi
f0101622:	5d                   	pop    %ebp
f0101623:	c3                   	ret    

f0101624 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101624:	55                   	push   %ebp
f0101625:	89 e5                	mov    %esp,%ebp
f0101627:	57                   	push   %edi
f0101628:	56                   	push   %esi
f0101629:	8b 45 08             	mov    0x8(%ebp),%eax
f010162c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010162f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101632:	39 c6                	cmp    %eax,%esi
f0101634:	73 35                	jae    f010166b <memmove+0x47>
f0101636:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101639:	39 d0                	cmp    %edx,%eax
f010163b:	73 2e                	jae    f010166b <memmove+0x47>
		s += n;
		d += n;
f010163d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0101640:	89 d6                	mov    %edx,%esi
f0101642:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101644:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010164a:	75 13                	jne    f010165f <memmove+0x3b>
f010164c:	f6 c1 03             	test   $0x3,%cl
f010164f:	75 0e                	jne    f010165f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101651:	83 ef 04             	sub    $0x4,%edi
f0101654:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101657:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010165a:	fd                   	std    
f010165b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010165d:	eb 09                	jmp    f0101668 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010165f:	83 ef 01             	sub    $0x1,%edi
f0101662:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101665:	fd                   	std    
f0101666:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101668:	fc                   	cld    
f0101669:	eb 1d                	jmp    f0101688 <memmove+0x64>
f010166b:	89 f2                	mov    %esi,%edx
f010166d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010166f:	f6 c2 03             	test   $0x3,%dl
f0101672:	75 0f                	jne    f0101683 <memmove+0x5f>
f0101674:	f6 c1 03             	test   $0x3,%cl
f0101677:	75 0a                	jne    f0101683 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101679:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010167c:	89 c7                	mov    %eax,%edi
f010167e:	fc                   	cld    
f010167f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101681:	eb 05                	jmp    f0101688 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101683:	89 c7                	mov    %eax,%edi
f0101685:	fc                   	cld    
f0101686:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101688:	5e                   	pop    %esi
f0101689:	5f                   	pop    %edi
f010168a:	5d                   	pop    %ebp
f010168b:	c3                   	ret    

f010168c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010168c:	55                   	push   %ebp
f010168d:	89 e5                	mov    %esp,%ebp
f010168f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101692:	8b 45 10             	mov    0x10(%ebp),%eax
f0101695:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101699:	8b 45 0c             	mov    0xc(%ebp),%eax
f010169c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01016a3:	89 04 24             	mov    %eax,(%esp)
f01016a6:	e8 79 ff ff ff       	call   f0101624 <memmove>
}
f01016ab:	c9                   	leave  
f01016ac:	c3                   	ret    

f01016ad <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01016ad:	55                   	push   %ebp
f01016ae:	89 e5                	mov    %esp,%ebp
f01016b0:	56                   	push   %esi
f01016b1:	53                   	push   %ebx
f01016b2:	8b 55 08             	mov    0x8(%ebp),%edx
f01016b5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01016b8:	89 d6                	mov    %edx,%esi
f01016ba:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016bd:	eb 1a                	jmp    f01016d9 <memcmp+0x2c>
		if (*s1 != *s2)
f01016bf:	0f b6 02             	movzbl (%edx),%eax
f01016c2:	0f b6 19             	movzbl (%ecx),%ebx
f01016c5:	38 d8                	cmp    %bl,%al
f01016c7:	74 0a                	je     f01016d3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01016c9:	0f b6 c0             	movzbl %al,%eax
f01016cc:	0f b6 db             	movzbl %bl,%ebx
f01016cf:	29 d8                	sub    %ebx,%eax
f01016d1:	eb 0f                	jmp    f01016e2 <memcmp+0x35>
		s1++, s2++;
f01016d3:	83 c2 01             	add    $0x1,%edx
f01016d6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016d9:	39 f2                	cmp    %esi,%edx
f01016db:	75 e2                	jne    f01016bf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01016dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016e2:	5b                   	pop    %ebx
f01016e3:	5e                   	pop    %esi
f01016e4:	5d                   	pop    %ebp
f01016e5:	c3                   	ret    

f01016e6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016e6:	55                   	push   %ebp
f01016e7:	89 e5                	mov    %esp,%ebp
f01016e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01016ec:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01016ef:	89 c2                	mov    %eax,%edx
f01016f1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016f4:	eb 07                	jmp    f01016fd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01016f6:	38 08                	cmp    %cl,(%eax)
f01016f8:	74 07                	je     f0101701 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01016fa:	83 c0 01             	add    $0x1,%eax
f01016fd:	39 d0                	cmp    %edx,%eax
f01016ff:	72 f5                	jb     f01016f6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101701:	5d                   	pop    %ebp
f0101702:	c3                   	ret    

f0101703 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101703:	55                   	push   %ebp
f0101704:	89 e5                	mov    %esp,%ebp
f0101706:	57                   	push   %edi
f0101707:	56                   	push   %esi
f0101708:	53                   	push   %ebx
f0101709:	8b 55 08             	mov    0x8(%ebp),%edx
f010170c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010170f:	eb 03                	jmp    f0101714 <strtol+0x11>
		s++;
f0101711:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101714:	0f b6 02             	movzbl (%edx),%eax
f0101717:	3c 09                	cmp    $0x9,%al
f0101719:	74 f6                	je     f0101711 <strtol+0xe>
f010171b:	3c 20                	cmp    $0x20,%al
f010171d:	74 f2                	je     f0101711 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010171f:	3c 2b                	cmp    $0x2b,%al
f0101721:	75 0a                	jne    f010172d <strtol+0x2a>
		s++;
f0101723:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101726:	bf 00 00 00 00       	mov    $0x0,%edi
f010172b:	eb 10                	jmp    f010173d <strtol+0x3a>
f010172d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101732:	3c 2d                	cmp    $0x2d,%al
f0101734:	75 07                	jne    f010173d <strtol+0x3a>
		s++, neg = 1;
f0101736:	8d 52 01             	lea    0x1(%edx),%edx
f0101739:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010173d:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0101743:	75 15                	jne    f010175a <strtol+0x57>
f0101745:	80 3a 30             	cmpb   $0x30,(%edx)
f0101748:	75 10                	jne    f010175a <strtol+0x57>
f010174a:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010174e:	75 0a                	jne    f010175a <strtol+0x57>
		s += 2, base = 16;
f0101750:	83 c2 02             	add    $0x2,%edx
f0101753:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101758:	eb 10                	jmp    f010176a <strtol+0x67>
	else if (base == 0 && s[0] == '0')
f010175a:	85 db                	test   %ebx,%ebx
f010175c:	75 0c                	jne    f010176a <strtol+0x67>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010175e:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101760:	80 3a 30             	cmpb   $0x30,(%edx)
f0101763:	75 05                	jne    f010176a <strtol+0x67>
		s++, base = 8;
f0101765:	83 c2 01             	add    $0x1,%edx
f0101768:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010176a:	b8 00 00 00 00       	mov    $0x0,%eax
f010176f:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101772:	0f b6 0a             	movzbl (%edx),%ecx
f0101775:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101778:	89 f3                	mov    %esi,%ebx
f010177a:	80 fb 09             	cmp    $0x9,%bl
f010177d:	77 08                	ja     f0101787 <strtol+0x84>
			dig = *s - '0';
f010177f:	0f be c9             	movsbl %cl,%ecx
f0101782:	83 e9 30             	sub    $0x30,%ecx
f0101785:	eb 22                	jmp    f01017a9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0101787:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010178a:	89 f3                	mov    %esi,%ebx
f010178c:	80 fb 19             	cmp    $0x19,%bl
f010178f:	77 08                	ja     f0101799 <strtol+0x96>
			dig = *s - 'a' + 10;
f0101791:	0f be c9             	movsbl %cl,%ecx
f0101794:	83 e9 57             	sub    $0x57,%ecx
f0101797:	eb 10                	jmp    f01017a9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0101799:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010179c:	89 f3                	mov    %esi,%ebx
f010179e:	80 fb 19             	cmp    $0x19,%bl
f01017a1:	77 16                	ja     f01017b9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f01017a3:	0f be c9             	movsbl %cl,%ecx
f01017a6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01017a9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01017ac:	7d 0f                	jge    f01017bd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f01017ae:	83 c2 01             	add    $0x1,%edx
f01017b1:	0f af 45 10          	imul   0x10(%ebp),%eax
f01017b5:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f01017b7:	eb b9                	jmp    f0101772 <strtol+0x6f>
f01017b9:	89 c1                	mov    %eax,%ecx
f01017bb:	eb 02                	jmp    f01017bf <strtol+0xbc>
f01017bd:	89 c1                	mov    %eax,%ecx

	if (endptr)
f01017bf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017c3:	74 05                	je     f01017ca <strtol+0xc7>
		*endptr = (char *) s;
f01017c5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017c8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01017ca:	85 ff                	test   %edi,%edi
f01017cc:	74 04                	je     f01017d2 <strtol+0xcf>
f01017ce:	89 c8                	mov    %ecx,%eax
f01017d0:	f7 d8                	neg    %eax
}
f01017d2:	5b                   	pop    %ebx
f01017d3:	5e                   	pop    %esi
f01017d4:	5f                   	pop    %edi
f01017d5:	5d                   	pop    %ebp
f01017d6:	c3                   	ret    
f01017d7:	66 90                	xchg   %ax,%ax
f01017d9:	66 90                	xchg   %ax,%ax
f01017db:	66 90                	xchg   %ax,%ax
f01017dd:	66 90                	xchg   %ax,%ax
f01017df:	90                   	nop

f01017e0 <__udivdi3>:
f01017e0:	55                   	push   %ebp
f01017e1:	57                   	push   %edi
f01017e2:	56                   	push   %esi
f01017e3:	83 ec 0c             	sub    $0xc,%esp
f01017e6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01017ea:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01017ee:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f01017f2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01017f6:	85 c0                	test   %eax,%eax
f01017f8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017fc:	89 ea                	mov    %ebp,%edx
f01017fe:	89 0c 24             	mov    %ecx,(%esp)
f0101801:	75 2d                	jne    f0101830 <__udivdi3+0x50>
f0101803:	39 e9                	cmp    %ebp,%ecx
f0101805:	77 61                	ja     f0101868 <__udivdi3+0x88>
f0101807:	85 c9                	test   %ecx,%ecx
f0101809:	89 ce                	mov    %ecx,%esi
f010180b:	75 0b                	jne    f0101818 <__udivdi3+0x38>
f010180d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101812:	31 d2                	xor    %edx,%edx
f0101814:	f7 f1                	div    %ecx
f0101816:	89 c6                	mov    %eax,%esi
f0101818:	31 d2                	xor    %edx,%edx
f010181a:	89 e8                	mov    %ebp,%eax
f010181c:	f7 f6                	div    %esi
f010181e:	89 c5                	mov    %eax,%ebp
f0101820:	89 f8                	mov    %edi,%eax
f0101822:	f7 f6                	div    %esi
f0101824:	89 ea                	mov    %ebp,%edx
f0101826:	83 c4 0c             	add    $0xc,%esp
f0101829:	5e                   	pop    %esi
f010182a:	5f                   	pop    %edi
f010182b:	5d                   	pop    %ebp
f010182c:	c3                   	ret    
f010182d:	8d 76 00             	lea    0x0(%esi),%esi
f0101830:	39 e8                	cmp    %ebp,%eax
f0101832:	77 24                	ja     f0101858 <__udivdi3+0x78>
f0101834:	0f bd e8             	bsr    %eax,%ebp
f0101837:	83 f5 1f             	xor    $0x1f,%ebp
f010183a:	75 3c                	jne    f0101878 <__udivdi3+0x98>
f010183c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101840:	39 34 24             	cmp    %esi,(%esp)
f0101843:	0f 86 9f 00 00 00    	jbe    f01018e8 <__udivdi3+0x108>
f0101849:	39 d0                	cmp    %edx,%eax
f010184b:	0f 82 97 00 00 00    	jb     f01018e8 <__udivdi3+0x108>
f0101851:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101858:	31 d2                	xor    %edx,%edx
f010185a:	31 c0                	xor    %eax,%eax
f010185c:	83 c4 0c             	add    $0xc,%esp
f010185f:	5e                   	pop    %esi
f0101860:	5f                   	pop    %edi
f0101861:	5d                   	pop    %ebp
f0101862:	c3                   	ret    
f0101863:	90                   	nop
f0101864:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101868:	89 f8                	mov    %edi,%eax
f010186a:	f7 f1                	div    %ecx
f010186c:	31 d2                	xor    %edx,%edx
f010186e:	83 c4 0c             	add    $0xc,%esp
f0101871:	5e                   	pop    %esi
f0101872:	5f                   	pop    %edi
f0101873:	5d                   	pop    %ebp
f0101874:	c3                   	ret    
f0101875:	8d 76 00             	lea    0x0(%esi),%esi
f0101878:	89 e9                	mov    %ebp,%ecx
f010187a:	8b 3c 24             	mov    (%esp),%edi
f010187d:	d3 e0                	shl    %cl,%eax
f010187f:	89 c6                	mov    %eax,%esi
f0101881:	b8 20 00 00 00       	mov    $0x20,%eax
f0101886:	29 e8                	sub    %ebp,%eax
f0101888:	89 c1                	mov    %eax,%ecx
f010188a:	d3 ef                	shr    %cl,%edi
f010188c:	89 e9                	mov    %ebp,%ecx
f010188e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101892:	8b 3c 24             	mov    (%esp),%edi
f0101895:	09 74 24 08          	or     %esi,0x8(%esp)
f0101899:	89 d6                	mov    %edx,%esi
f010189b:	d3 e7                	shl    %cl,%edi
f010189d:	89 c1                	mov    %eax,%ecx
f010189f:	89 3c 24             	mov    %edi,(%esp)
f01018a2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01018a6:	d3 ee                	shr    %cl,%esi
f01018a8:	89 e9                	mov    %ebp,%ecx
f01018aa:	d3 e2                	shl    %cl,%edx
f01018ac:	89 c1                	mov    %eax,%ecx
f01018ae:	d3 ef                	shr    %cl,%edi
f01018b0:	09 d7                	or     %edx,%edi
f01018b2:	89 f2                	mov    %esi,%edx
f01018b4:	89 f8                	mov    %edi,%eax
f01018b6:	f7 74 24 08          	divl   0x8(%esp)
f01018ba:	89 d6                	mov    %edx,%esi
f01018bc:	89 c7                	mov    %eax,%edi
f01018be:	f7 24 24             	mull   (%esp)
f01018c1:	39 d6                	cmp    %edx,%esi
f01018c3:	89 14 24             	mov    %edx,(%esp)
f01018c6:	72 30                	jb     f01018f8 <__udivdi3+0x118>
f01018c8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01018cc:	89 e9                	mov    %ebp,%ecx
f01018ce:	d3 e2                	shl    %cl,%edx
f01018d0:	39 c2                	cmp    %eax,%edx
f01018d2:	73 05                	jae    f01018d9 <__udivdi3+0xf9>
f01018d4:	3b 34 24             	cmp    (%esp),%esi
f01018d7:	74 1f                	je     f01018f8 <__udivdi3+0x118>
f01018d9:	89 f8                	mov    %edi,%eax
f01018db:	31 d2                	xor    %edx,%edx
f01018dd:	e9 7a ff ff ff       	jmp    f010185c <__udivdi3+0x7c>
f01018e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018e8:	31 d2                	xor    %edx,%edx
f01018ea:	b8 01 00 00 00       	mov    $0x1,%eax
f01018ef:	e9 68 ff ff ff       	jmp    f010185c <__udivdi3+0x7c>
f01018f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01018f8:	8d 47 ff             	lea    -0x1(%edi),%eax
f01018fb:	31 d2                	xor    %edx,%edx
f01018fd:	83 c4 0c             	add    $0xc,%esp
f0101900:	5e                   	pop    %esi
f0101901:	5f                   	pop    %edi
f0101902:	5d                   	pop    %ebp
f0101903:	c3                   	ret    
f0101904:	66 90                	xchg   %ax,%ax
f0101906:	66 90                	xchg   %ax,%ax
f0101908:	66 90                	xchg   %ax,%ax
f010190a:	66 90                	xchg   %ax,%ax
f010190c:	66 90                	xchg   %ax,%ax
f010190e:	66 90                	xchg   %ax,%ax

f0101910 <__umoddi3>:
f0101910:	55                   	push   %ebp
f0101911:	57                   	push   %edi
f0101912:	56                   	push   %esi
f0101913:	83 ec 14             	sub    $0x14,%esp
f0101916:	8b 44 24 28          	mov    0x28(%esp),%eax
f010191a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010191e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101922:	89 c7                	mov    %eax,%edi
f0101924:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101928:	8b 44 24 30          	mov    0x30(%esp),%eax
f010192c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101930:	89 34 24             	mov    %esi,(%esp)
f0101933:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101937:	85 c0                	test   %eax,%eax
f0101939:	89 c2                	mov    %eax,%edx
f010193b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010193f:	75 17                	jne    f0101958 <__umoddi3+0x48>
f0101941:	39 fe                	cmp    %edi,%esi
f0101943:	76 4b                	jbe    f0101990 <__umoddi3+0x80>
f0101945:	89 c8                	mov    %ecx,%eax
f0101947:	89 fa                	mov    %edi,%edx
f0101949:	f7 f6                	div    %esi
f010194b:	89 d0                	mov    %edx,%eax
f010194d:	31 d2                	xor    %edx,%edx
f010194f:	83 c4 14             	add    $0x14,%esp
f0101952:	5e                   	pop    %esi
f0101953:	5f                   	pop    %edi
f0101954:	5d                   	pop    %ebp
f0101955:	c3                   	ret    
f0101956:	66 90                	xchg   %ax,%ax
f0101958:	39 f8                	cmp    %edi,%eax
f010195a:	77 54                	ja     f01019b0 <__umoddi3+0xa0>
f010195c:	0f bd e8             	bsr    %eax,%ebp
f010195f:	83 f5 1f             	xor    $0x1f,%ebp
f0101962:	75 5c                	jne    f01019c0 <__umoddi3+0xb0>
f0101964:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101968:	39 3c 24             	cmp    %edi,(%esp)
f010196b:	0f 87 e7 00 00 00    	ja     f0101a58 <__umoddi3+0x148>
f0101971:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101975:	29 f1                	sub    %esi,%ecx
f0101977:	19 c7                	sbb    %eax,%edi
f0101979:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010197d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101981:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101985:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101989:	83 c4 14             	add    $0x14,%esp
f010198c:	5e                   	pop    %esi
f010198d:	5f                   	pop    %edi
f010198e:	5d                   	pop    %ebp
f010198f:	c3                   	ret    
f0101990:	85 f6                	test   %esi,%esi
f0101992:	89 f5                	mov    %esi,%ebp
f0101994:	75 0b                	jne    f01019a1 <__umoddi3+0x91>
f0101996:	b8 01 00 00 00       	mov    $0x1,%eax
f010199b:	31 d2                	xor    %edx,%edx
f010199d:	f7 f6                	div    %esi
f010199f:	89 c5                	mov    %eax,%ebp
f01019a1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01019a5:	31 d2                	xor    %edx,%edx
f01019a7:	f7 f5                	div    %ebp
f01019a9:	89 c8                	mov    %ecx,%eax
f01019ab:	f7 f5                	div    %ebp
f01019ad:	eb 9c                	jmp    f010194b <__umoddi3+0x3b>
f01019af:	90                   	nop
f01019b0:	89 c8                	mov    %ecx,%eax
f01019b2:	89 fa                	mov    %edi,%edx
f01019b4:	83 c4 14             	add    $0x14,%esp
f01019b7:	5e                   	pop    %esi
f01019b8:	5f                   	pop    %edi
f01019b9:	5d                   	pop    %ebp
f01019ba:	c3                   	ret    
f01019bb:	90                   	nop
f01019bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019c0:	8b 04 24             	mov    (%esp),%eax
f01019c3:	be 20 00 00 00       	mov    $0x20,%esi
f01019c8:	89 e9                	mov    %ebp,%ecx
f01019ca:	29 ee                	sub    %ebp,%esi
f01019cc:	d3 e2                	shl    %cl,%edx
f01019ce:	89 f1                	mov    %esi,%ecx
f01019d0:	d3 e8                	shr    %cl,%eax
f01019d2:	89 e9                	mov    %ebp,%ecx
f01019d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01019d8:	8b 04 24             	mov    (%esp),%eax
f01019db:	09 54 24 04          	or     %edx,0x4(%esp)
f01019df:	89 fa                	mov    %edi,%edx
f01019e1:	d3 e0                	shl    %cl,%eax
f01019e3:	89 f1                	mov    %esi,%ecx
f01019e5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01019e9:	8b 44 24 10          	mov    0x10(%esp),%eax
f01019ed:	d3 ea                	shr    %cl,%edx
f01019ef:	89 e9                	mov    %ebp,%ecx
f01019f1:	d3 e7                	shl    %cl,%edi
f01019f3:	89 f1                	mov    %esi,%ecx
f01019f5:	d3 e8                	shr    %cl,%eax
f01019f7:	89 e9                	mov    %ebp,%ecx
f01019f9:	09 f8                	or     %edi,%eax
f01019fb:	8b 7c 24 10          	mov    0x10(%esp),%edi
f01019ff:	f7 74 24 04          	divl   0x4(%esp)
f0101a03:	d3 e7                	shl    %cl,%edi
f0101a05:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101a09:	89 d7                	mov    %edx,%edi
f0101a0b:	f7 64 24 08          	mull   0x8(%esp)
f0101a0f:	39 d7                	cmp    %edx,%edi
f0101a11:	89 c1                	mov    %eax,%ecx
f0101a13:	89 14 24             	mov    %edx,(%esp)
f0101a16:	72 2c                	jb     f0101a44 <__umoddi3+0x134>
f0101a18:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0101a1c:	72 22                	jb     f0101a40 <__umoddi3+0x130>
f0101a1e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101a22:	29 c8                	sub    %ecx,%eax
f0101a24:	19 d7                	sbb    %edx,%edi
f0101a26:	89 e9                	mov    %ebp,%ecx
f0101a28:	89 fa                	mov    %edi,%edx
f0101a2a:	d3 e8                	shr    %cl,%eax
f0101a2c:	89 f1                	mov    %esi,%ecx
f0101a2e:	d3 e2                	shl    %cl,%edx
f0101a30:	89 e9                	mov    %ebp,%ecx
f0101a32:	d3 ef                	shr    %cl,%edi
f0101a34:	09 d0                	or     %edx,%eax
f0101a36:	89 fa                	mov    %edi,%edx
f0101a38:	83 c4 14             	add    $0x14,%esp
f0101a3b:	5e                   	pop    %esi
f0101a3c:	5f                   	pop    %edi
f0101a3d:	5d                   	pop    %ebp
f0101a3e:	c3                   	ret    
f0101a3f:	90                   	nop
f0101a40:	39 d7                	cmp    %edx,%edi
f0101a42:	75 da                	jne    f0101a1e <__umoddi3+0x10e>
f0101a44:	8b 14 24             	mov    (%esp),%edx
f0101a47:	89 c1                	mov    %eax,%ecx
f0101a49:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0101a4d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101a51:	eb cb                	jmp    f0101a1e <__umoddi3+0x10e>
f0101a53:	90                   	nop
f0101a54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a58:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0101a5c:	0f 82 0f ff ff ff    	jb     f0101971 <__umoddi3+0x61>
f0101a62:	e9 1a ff ff ff       	jmp    f0101981 <__umoddi3+0x71>
