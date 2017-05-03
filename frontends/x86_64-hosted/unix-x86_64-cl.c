#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <termios.h>
#include <poll.h>
#include <fcntl.h>
#include <setjmp.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <sys/mman.h>


#include "preprocessor.h"

typedef char bool;
#define FALSE 0
#define TRUE 1

#define ENOERR 0


typedef long long int64;		
typedef int64 cell;

// Forth data area set up: 4M, aligned to 4K
#define fdsize 0x400000
#define fdalign 0x1000

// Terminal globals
struct termios old_tio, our_tio;

struct {
	char c;
	bool have;
} saved_key = {0, 0};

#define SIGSTACK_SIZE SIGSTKSZ
char sigstack_storage[SIGSTACK_SIZE];

volatile sig_atomic_t need_window_update = FALSE;

// Pointers to Forth values #lines, #columns
cell *forth_lines = NULL;
cell *forth_columns = NULL;


// Contexts
typedef struct {
	int64 rax;
	int64 rbx;
	int64 rcx;
	int64 rdx;
	int64 rsi;
	int64 rdi;
	int64 rbp;
	int64 rsp;
	int64 r8;
	int64 r9;
	int64 r10;
	int64 r11;
	int64 r12;
	int64 r13;
	int64 r14;
	int64 r15;
} context;

extern context forth_ctx, sys_ctx;

// Forth init-vector
typedef struct {
	void	*dataBase;
	void	*bdBase;
	cell	*stackBase;
	void	**rstackBase;
	char	*ftextBase;
	void	*amBase;
	void	*realBase;
	int64	realSize;
	void	*virtBase;
	int64	virtSize;
} Initvec;

// Global data for x86 core
typedef struct {
	void	*bdBase;
	int64	bdCount;
	void	*interpPtr;
	void	*compPtr;
	void	*forthPtr;
	Initvec	*initvec;
	void	*sysStack;
} GData;


// Signal globals
enum ReentryCauses {
	CAUSE_EXCEPTION = 0,
	CAUSE_ALARM = 1
};

sigjmp_buf jbuf;
volatile sig_atomic_t reentry_cause, reentry_data[4];


extern void fentry(void *data, unsigned int len, void *text);
extern void freentry(int cause, const int *data);
extern void sighandler(int sig, siginfo_t *info, void *uap);

void *fdata;
char *ftext;

void Failed(const char *reason, const char *extrainfo);
void terminal_setup();
void terminal_resetup();
void terminal_teardown();
void update_window();




/* Display a fatal error from the Forth text preprocessor. */
void Failed(const char *reason, const char *extrainfo)
{
	fputs(reason, stderr);
	if (extrainfo) {
		fputs(": ", stderr);
		fputs(extrainfo, stderr);
	}
	fputc('\n', stderr);
	
	exit(1);
}


/* Routines for setting up the terminal. */
void terminal_setup()
{
	tcgetattr(STDIN_FILENO, &old_tio);			/* get current terminal settings */
	
	our_tio = old_tio;							/* form new settings */
	our_tio.c_lflag &= (~ICANON & ~ECHO);		/* noncanonical mode, no local echo */
	
	terminal_resetup();
	
	atexit(terminal_teardown);
}

void terminal_resetup()
{
	// Note: this procedure must be async-signal-safe.
	tcsetattr(STDIN_FILENO, TCSANOW, &our_tio);	/* update settings */	
	fcntl(STDIN_FILENO, F_SETFL, O_NONBLOCK);	/* make terminal input non-blocking */	
}

void terminal_teardown()
{
	tcsetattr(STDIN_FILENO, TCSANOW, &old_tio);	/* restore former settings */
}

// Update Forth's #lines, #columns values
void update_window()
{
	struct winsize ws;
	
	if (ioctl(STDIN_FILENO, TIOCGWINSZ, &ws))
		return;
	
	if (forth_lines)
		*forth_lines = ws.ws_row;
	if (forth_columns)
		*forth_columns = ws.ws_col;	
}

// Routines backing the hosted Forth I/O primitives.
int c_host_key()
{
	struct pollfd fds;
	char c;
	
	if (saved_key.have) {
		c = saved_key.c;
		saved_key.have = FALSE;
	} else {	
		fds.fd = STDIN_FILENO;
		fds.events = POLLIN;
		
		do
			(void) poll(&fds, 1, -1);				/* block until input available */
		while (read(STDIN_FILENO, &c, 1) < 1);		/* try to read a character */
	}
	
	return c;
}

bool c_host_key_question()
{
	if (saved_key.have) return TRUE;
	
	saved_key.have = (read(STDIN_FILENO, &saved_key.c, 1) == 1);
	
	return saved_key.have;
}

void c_host_emit(char c)
{
	putchar(c);	
	fflush(stdout);
}

void c_host_rest()
{
	struct pollfd fds;
	
	// Wait for either 200ms to elapse, or a signal or keystroke to arrive.
	fds.fd = STDIN_FILENO;
	fds.events = POLLIN;
	
	(void) poll(&fds, 1, 200);
	
	// Check for SIGWINCH and update window size (not async-signal-safe...) now
	//  if necessary
	if (need_window_update) {
		need_window_update = FALSE;
		update_window();
	}
}

void c_host_is_window(int64 *pLines, int64 *pColumns)
{
	forth_lines = pLines;
	forth_columns = pColumns;
	update_window();
}

void c_host_bye()
{
	exit(0);
}



// Debugging routines
void ctx_dump(const context *ctx)
{
	printf("\nContext dump:\n");
	printf("    rax: %016llX   rbx: %016llX   rcx: %016llX   rdx: %016llX\n", ctx->rax, ctx->rbx, ctx->rcx, ctx->rdx);
	printf("    rsi: %016llX   rdi: %016llX   rbp: %016llX   rsp: %016llX\n", ctx->rsi, ctx->rdi, ctx->rbp, ctx->rsp);
	printf("     r8: %016llX    r9: %016llX   r10: %016llX   r11: %016llX\n", ctx->r8,  ctx->r9,  ctx->r10, ctx->r11);
	printf("    r12: %016llX   r13: %016llX   r14: %016llX   r15: %016llX\n", ctx->r12, ctx->r13, ctx->r14, ctx->r15);
}

void c_dump(int64 tos, int64 _1, int64 _2, cell *stack, void **rstack, GData *gdata)
{
	cell *stackBase = gdata->initvec->stackBase;
	void **rstackBase = gdata->initvec->rstackBase;
	int nstack = 1 + (stackBase - stack);
	
	// Ignore last two items on rstack (which are due to the call to the bracketdump primitive)
	rstack += 2;
	
	fputs("[------<debug>------]\nStack:", stdout);
	
	if (nstack > 0) {
		while (stack < stackBase)
			printf(" %llX", *--stackBase);
		printf(" %llX", tos);
	} else if (nstack == 0)
		fputs(" (empty)", stdout);
	else
		printf(" underflow (%d)", -nstack);

	fputs("\nReturn stack:", stdout);
	while (rstack < rstackBase)
		printf(" %016llX", (int64) *--rstackBase);

	printf("\n_1 = %llX\n_2 = %llX\n", _1, _2);
}


// Main signal handler.
//  Called from raw signal handler (sighandler) in the system context.
void c_sighandler(int sig, siginfo_t *info, ucontext_t *uap, int64 wasInForth)
{
	// SIGCONT and SIGWINCH, unlike the others, just require some C code.
	switch (sig) {
		case SIGCONT:
			terminal_resetup();
			return;
		case SIGWINCH:
			need_window_update = TRUE;
			return;
	} 

	// Save info about this signal
	reentry_cause = sig;
	reentry_data[0] = info->si_code;
	reentry_data[1] = 0;
		
	// On OS X at least, sig_atomic_t (the type of reentry_data) is only 32 bits.
	if (sig == SIGSEGV || sig == SIGBUS) {
		reentry_data[2] = (int) (int64) info->si_addr;
		reentry_data[3] = (int) (((int64) info->si_addr) >> 32);
	} else {
		reentry_data[2] = 0;
		reentry_data[3] = 0;
	}
	// If we were in Forth, retrieve registers at the time of exception
	//  from the ucontext_t. This is system-dependent.
	if (wasInForth) {
		#ifdef _STRUCT_MCONTEXT64
			// Darwin/x86_64
			const _STRUCT_X86_THREAD_STATE64 *ss;
			int64_t *rsp;
			
			// Double underscores may be needed for some identifiers...
			#if __DARWIN_UNIX03
				#define du(ident) __##ident
			#else
				#define du(ident) ident
			#endif
			
			ss = &uap->uc_mcontext->du(ss);		
			
			forth_ctx.rax = ss->du(rax);
			forth_ctx.rbx = ss->du(rbx);
			forth_ctx.rcx = ss->du(rcx);
			forth_ctx.rdx = ss->du(rdx);
			forth_ctx.rsi = ss->du(rsi);
			forth_ctx.rdi = ss->du(rdi);
			forth_ctx.rbp = ss->du(rbp);
			forth_ctx.r8  = ss->du(r8);
			forth_ctx.r9  = ss->du(r9);
			forth_ctx.r10 = ss->du(r10);
			forth_ctx.r11 = ss->du(r11);
			forth_ctx.r12 = ss->du(r12);
			forth_ctx.r13 = ss->du(r13);
			forth_ctx.r14 = ss->du(r14);
			forth_ctx.r15 = ss->du(r15);

			rsp = (int64_t *) ss->du(rsp);
			*--rsp = ss->du(rip);				// Push EIP onto return stack so Forth handler
												//  knows where the exception occurred.
			forth_ctx.rsp = (int64_t) rsp;			
		#else
		#ifdef __linux__			
			const gregset_t *regs = &uap->uc_mcontext.gregs;
			int64_t *rsp;
			
			forth_ctx.rax = (*regs)[REG_RAX];
			forth_ctx.rbx = (*regs)[REG_RBX];
			forth_ctx.rcx = (*regs)[REG_RCX];
			forth_ctx.rdx = (*regs)[REG_RDX];
			forth_ctx.rsi = (*regs)[REG_RSI];
			forth_ctx.rdi = (*regs)[REG_RDI];
			forth_ctx.rbp = (*regs)[REG_RBP];
			forth_ctx.r8  = (*regs)[REG_R8];
			forth_ctx.r9  = (*regs)[REG_R9];
			forth_ctx.r10 = (*regs)[REG_R10];
			forth_ctx.r11 = (*regs)[REG_R11];
			forth_ctx.r12 = (*regs)[REG_R12];
			forth_ctx.r13 = (*regs)[REG_R13];
			forth_ctx.r14 = (*regs)[REG_R14];
			forth_ctx.r15 = (*regs)[REG_R15];
			rsp = (int64_t *) (*regs)[REG_RSP];
			*--rsp = (*regs)[REG_RIP];
			forth_ctx.rsp = (int64_t) rsp;
		#else
			#error I do not know how to get the registers from a ucontext_t in this environment.
		#endif
		#endif
	}

	// Save args and longjmp back into Forth.
	siglongjmp(jbuf, 1);
}


int main(int argc, char **argv)
{
	stack_t sigstack;
	struct sigaction sa;
	int local_rdata[4];
	const char *mainfname = "x86_64-hosted-text.of";
	
	//
	terminal_setup();
	
	// Allocate Forth memory
	fdata = mmap(NULL, fdsize, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANON, -1, 0);
	if (!fdata)
		Failed("Couldn't allocate Forth memory.", NULL);

/*	if (posix_memalign(&fdata, fdalign, fdsize))
		Failed("Couldn't allocate Forth memory.", NULL);
*/
	
	// Load and preprocess Forth text
	if (argc > 1)
		mainfname = argv[1];
	ftext = preprocess(mainfname, 0, NULL);	
	
	// Register alternate signal stack
/*	sigstack.ss_sp = sigstack_storage;
    sigstack.ss_size = SIGSTACK_SIZE;
    sigstack.ss_flags = 0;
    if (sigaltstack(&sigstack, NULL) < 0)
		perror("sigaltstack"); */
	
	// Install signal handlers
	sa.sa_sigaction = &sighandler;
	sigemptyset(&sa.sa_mask);
	sigaddset(&sa.sa_mask, SIGALRM);
	sa.sa_flags = SA_SIGINFO;
	
	sigaction(SIGINT, &sa, NULL);
	
	sigaction(SIGFPE, &sa, NULL);
	sigaction(SIGILL, &sa, NULL);
	sigaction(SIGBUS, &sa, NULL);
	sigaction(SIGSEGV, &sa, NULL);
	sigaction(SIGUSR1, &sa, NULL);
	sigaction(SIGUSR2, &sa, NULL);

	sigaction(SIGCONT, &sa, NULL);	
	sigaction(SIGWINCH, &sa, NULL);	
	
	// Prepare a setjmp to return to in case of signals
	if (sigsetjmp(jbuf, 1)) {
		// Signal!
		// First copy data out of volatile sig_atomic_t type...
		// This is really an array of int64s.
		local_rdata[0] = reentry_data[0];
		local_rdata[1] = reentry_data[1];
		local_rdata[2] = reentry_data[2];
		local_rdata[3] = reentry_data[3];
		
		freentry(reentry_cause, local_rdata);
	} else {
		// Main entry
		fentry(fdata, fdsize, ftext);
	}
	
	// This will never be reached.
	return 0;
}
