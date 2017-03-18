#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <malloc.h>
#include <windows.h>
#include <conio.h>

#include "preprocessor.h"

typedef char bool;
#define FALSE 0
#define TRUE 1

#define ENOERR 0


// Forth data area set up: 1M, aligned to 4K
#define fdsize 0x100000
#define fdalign 0x1000

// Terminal globals
struct {
	char c;
	bool have;
} saved_key = {0, 0};

HANDLE hStdin, hStdout;
DWORD old_input_mode;

#define CHAR_CSI 0x9B


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



extern void fentry(void *data, unsigned int len, void *text);
extern void freentry(int cause, const int *data);

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
	hStdin = GetStdHandle(STD_INPUT_HANDLE);
	hStdout = GetStdHandle(STD_OUTPUT_HANDLE);
	if (hStdin == INVALID_HANDLE_VALUE || hStdout == INVALID_HANDLE_VALUE)
		Failed("Could not get console input/output handles", NULL);
	if (!GetConsoleMode(hStdin,&old_input_mode))
		Failed("Could not get console input mode", NULL);
	if (!SetConsoleMode(hStdin,0))
		Failed("Could not set console input mode", NULL);
		
	atexit(terminal_teardown);
}

void terminal_teardown()
{
	SetConsoleMode(hStdin, old_input_mode);
}

// Move the cursor n characters to the right. n may be negative.
void console_cursor_shift(int n)
{
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	int newx;
	
	if (!GetConsoleScreenBufferInfo(hStdout, &csbi))
		Failed("Could not get stdout info", NULL);
	
	newx = csbi.dwCursorPosition.X;
	newx += n;
	if (newx < 0) newx = 0;
	else if (newx >= csbi.dwSize.X) newx = csbi.dwSize.X - 1;
	csbi.dwCursorPosition.X = newx;
	
	if (!SetConsoleCursorPosition(hStdout, csbi.dwCursorPosition))
		Failed("Could not move cursor", NULL);
}

// Insert n spaces at cursor, shifting text to the right.
void console_insert(int n)
{
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	SMALL_RECT scroll;
	COORD dest, cursor;
	CHAR_INFO fill;
	int maxn, sizex;
	
	if (!GetConsoleScreenBufferInfo(hStdout, &csbi))
		Failed("Could not get stdout info", NULL);

	cursor = csbi.dwCursorPosition;
	sizex = csbi.dwSize.X;
	maxn = sizex - cursor.X;
	
	if (n > maxn) n = maxn;
	
	scroll.Left   = cursor.X;
	scroll.Right  = sizex - n;
	scroll.Top    = cursor.Y;
	scroll.Bottom = cursor.Y;
	
	dest.X = cursor.X + n;
	dest.Y = cursor.Y;
	
	fill.Char.AsciiChar = ' ';
	fill.Attributes = csbi.wAttributes;
	
	if (!ScrollConsoleScreenBuffer(hStdout, &scroll, NULL, dest, &fill))
		Failed("Scrolling console failed", NULL);
}

// Delete n characters at cursor, shifting text to the left.
void console_delete(int n)
{
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	SMALL_RECT scroll;
	COORD dest, cursor;
	CHAR_INFO fill;
	int maxn, sizex;
	
	if (!GetConsoleScreenBufferInfo(hStdout, &csbi))
		Failed("Could not get stdout info", NULL);

	cursor = csbi.dwCursorPosition;
	sizex = csbi.dwSize.X;
	maxn = sizex - cursor.X;
	
	if (n > maxn) n = maxn;
	
	scroll.Left   = cursor.X + n;
	scroll.Right  = sizex;
	scroll.Top    = cursor.Y;
	scroll.Bottom = cursor.Y;
	
	dest = cursor;
	
	fill.Char.AsciiChar = ' ';
	fill.Attributes = csbi.wAttributes;
	
	if (!ScrollConsoleScreenBuffer(hStdout, &scroll, NULL, dest, &fill))
		Failed("Scrolling console failed", NULL);
}

// Update Forth's #lines, #columns values
void update_window()
{
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	if (!GetConsoleScreenBufferInfo(hStdout, &csbi)) 
    	return;
	
	if (forth_lines)
		*forth_lines = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
	if (forth_columns)
		*forth_columns = csbi.srWindow.Right - csbi.srWindow.Left + 1;
}

void key_save(char c)
{
	saved_key.have = TRUE;
	saved_key.c = c;
}

// Routines backing the hosted Forth I/O primitives.
int c_host_key()
{
	char c;
	
	if (saved_key.have) {
		saved_key.have = FALSE;
		c = saved_key.c;
	} else {
		c = _getch();
		
		// Win32 sends 0x00 or 0xE0 before special keys.
		// In this case, check for an arrow key and recode
		//  it in the format Forth expects.
		if (c == 0 || (c & 0xFF) == 0xE0) {
			c = _getch();
			switch (c) {
				case 0x48: // up arrow
					key_save('A');
					c = CHAR_CSI;
					break;
				case 0x50: // down arrow
					key_save('B');
					c = CHAR_CSI;
					break;
				case 0x4D: // right arrow
					key_save('C');
					c = CHAR_CSI;
					break;
				case 0x4B: // left arrow
					key_save('D');
					c = CHAR_CSI;
					break;
			}
		}
	}
	
	return c;
}

bool c_host_key_question()
{
	return saved_key.have || _kbhit();
}

void c_host_emit(char c)
{
	static int escStage = 0;
	static int n = 0;
	static bool gotn = FALSE;
	
	// Decode ANSI escape codes from Forth.
	// We need to support CUF, CUB, ICH, and DCH.
	if (c == 0x1B && escStage == 0)
		escStage = 1;
	else if (c == 0x5B && escStage == 1) {
		escStage = 2;
		n = 0;
		gotn = FALSE;
	} else if (escStage == 2) {
		if (c >= '0' && c <= '9') {
			n = 10*n + c - '0';
			gotn = TRUE;
		} else {
			if (!gotn) n = 1;
			switch (c) {
				case 'C':
					console_cursor_shift(n);
					break;
				case 'D':
					console_cursor_shift(-n);
					break;
				case '@':
					console_insert(n);
					break;
				case 'P':
					console_delete(n);
					break;
			}
			escStage = 0;
		}
	} else {
		escStage = 0;
		_putch(c);
	}
}

void c_host_rest()
{
//	(void) SwitchToThread();
	DWORD r, count;
	INPUT_RECORD buf;
	bool wait = TRUE;
	
	
	while (wait) {
		r = WaitForSingleObject(hStdin, 2000);
		switch (r) {
			case WAIT_OBJECT_0:
				if (!PeekConsoleInput(hStdin, &buf, 1, &count))
					Failed("PeekConsoleInput failed.", NULL);
				if (count == 0) break;
				if (buf.EventType == KEY_EVENT && buf.Event.KeyEvent.bKeyDown)
					wait = FALSE;
				else {
					if (!ReadConsoleInput(hStdin, &buf, 1, &count))
						Failed("ReadConsoleInput failed.", NULL);
				}
				break;
			case WAIT_TIMEOUT:
				wait = FALSE;
				break;
			default:
				Failed("Unknown response from WaitForSingleObject.", NULL);
				break;
		}
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


// Stub signal handler so that linking succeeds...
void c_sighandler() {}


int main()
{
	terminal_setup();
	
	// Allocate Forth memory
	fdata = _aligned_malloc(fdsize, fdalign);
	if (!fdata)
		Failed("Couldn't allocate Forth memory.", NULL);
	
	// Load and preprocess Forth text
	ftext = preprocess("x86-hosted-text.of", 0, NULL);	
	
	fentry(fdata, fdsize, ftext);
	
	// This will never be reached.
	return 0;
}
