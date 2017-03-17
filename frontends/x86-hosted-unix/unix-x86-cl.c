#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <termios.h>
#include <poll.h>
#include <fcntl.h>
#include <setjmp.h>
#include <signal.h>
#include <sys/ioctl.h>


#include "preprocessor.h"

typedef char bool;
#define FALSE 0
#define TRUE 1

#define ENOERR 0


// Forth data area set up: 1M, aligned to 4K
#define fdsize 0x100000
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
unsigned int *forth_lines = NULL;
unsigned int *forth_columns = NULL;


// Contexts
typedef struct {
	int	eax;
	int ebx;
	int ecx;
	int edx;
	int esi;
	int edi;
	int ebp;
	int esp;
} context;

extern context forth_ctx, sys_ctx;

// Forth init-vector
typedef struct {
	void	*dataBase;
	void	*bdBase;
	int		*stackBase;
	void	**rstackBase;
	char	*ftextBase;
	void	*amBase;
	void	*realBase;
	int		realSize;
	void	*virtBase;
	int		virtSize;
} Initvec;

// Global data for x86 core
typedef struct {
	void	*bdBase;
	int		bdCount;
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
volatile sig_atomic_t reentry_cause, reentry_data[2];


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

void c_host_is_window(unsigned int *pLines, unsigned int *pColumns)
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
	printf("    eax: %08X   ebx: %08X   ecx: %08X   edx: %08X\n", ctx->eax, ctx->ebx, ctx->ecx, ctx->edx);
	printf("    esi: %08X   edi: %08X   ebp: %08X   esp: %08X\n", ctx->esi, ctx->edi, ctx->ebp, ctx->esp);
}

void c_dump(int tos, int _1, int _2, int *stack, void **rstack, GData *gdata)
{
	int *stackBase = gdata->initvec->stackBase;
	void **rstackBase = gdata->initvec->rstackBase;
	int nstack = 1 + (stackBase - stack);
	
	// Ignore last three items on rstack (which are due to the call to the bracketdump primitive)
	rstack += 3;
	
	fputs("[------<debug>------]\nStack:", stdout);
	
	if (nstack > 0) {
		while (stack < stackBase)
			printf(" %08X", *--stackBase);
		printf(" %08X", tos);
	} else if (nstack == 0)
		fputs(" (empty)", stdout);
	else
		printf(" underflow (%d)", -nstack);

	fputs("\nReturn stack:", stdout);
	while (rstack < rstackBase)
		printf(" %08X", (unsigned) *--rstackBase);

	printf("\n_1 = %X\n_2 = %X\n", _1, _2);
}


// Main signal handler.
//  Called from raw signal handler (sighandler) in the system context.
void c_sighandler(int wasInForth, int sig, siginfo_t *info, ucontext_t *uap)
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
		
	if (sig == SIGSEGV || sig == SIGBUS)
		reentry_data[1] = (int) info->si_addr;
	else
		reentry_data[1] = 0;

	// If we were in Forth, retrieve registers at the time of exception
	//  from the ucontext_t. This is system-dependent.
	if (wasInForth) {
		#ifdef _STRUCT_MCONTEXT32
			// Darwin/x86 
			const _STRUCT_X86_THREAD_STATE32 *ss;
			unsigned int *esp;
			
			// Double underscores may be needed for some identifiers...
			#if __DARWIN_UNIX03
				#define du(ident) __##ident
			#else
				#define du(ident) ident
			#endif
			
			ss = &uap->uc_mcontext->du(ss);		
			
			forth_ctx.eax = ss->du(eax);
			forth_ctx.ebx = ss->du(ebx);
			forth_ctx.ecx = ss->du(ecx);
			forth_ctx.edx = ss->du(edx);
			forth_ctx.esi = ss->du(esi);
			forth_ctx.edi = ss->du(edi);
			forth_ctx.ebp = ss->du(ebp);
			esp = (unsigned int *) ss->du(esp);
			*--esp = ss->du(eip);				// Push EIP onto return stack so Forth handler
												//  knows where the exception occurred.
			forth_ctx.esp = (int) esp;			
		#else
		#ifdef __linux__			
			const gregset_t *regs = &uap->uc_mcontext.gregs;
			unsigned int *esp;
			forth_ctx.eax = (*regs)[REG_EAX];
			forth_ctx.ebx = (*regs)[REG_EBX];
			forth_ctx.ecx = (*regs)[REG_ECX];
			forth_ctx.edx = (*regs)[REG_EDX];
			forth_ctx.esi = (*regs)[REG_ESI];
			forth_ctx.edi = (*regs)[REG_EDI];
			forth_ctx.ebp = (*regs)[REG_EBP];
			esp = (unsigned int *) (*regs)[REG_ESP];
			*--esp = (*regs)[REG_EIP];
			forth_ctx.esp = (int) esp;
		#else
			#error I do not know how to get the registers from a ucontext_t in this environment.
		#endif
		#endif
	}

	// Save args and longjmp back into Forth.
	siglongjmp(jbuf, 1);
}


int main()
{
	stack_t sigstack;
	struct sigaction sa;
	int local_rdata[2];
	
	terminal_setup();
	
	// Allocate Forth memory
	if (posix_memalign(&fdata, fdalign, fdsize))
		Failed("Couldn't allocate Forth memory.", NULL);
	
	// Load and preprocess Forth text
	ftext = preprocess("x86-hosted-text.of", 0, NULL);	
	
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
		local_rdata[0] = reentry_data[0];
		local_rdata[1] = reentry_data[1];
		
		freentry(reentry_cause, local_rdata);
	} else {
		// Main entry
		fentry(fdata, fdsize, ftext);
	}
	
	// This will never be reached.
	return 0;
}
