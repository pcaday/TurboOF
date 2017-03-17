#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <Timer.h>
#include <MacTypes.h>
#include <MacMemory.h>
#include <Quickdraw.h>
#include <MacWindows.h>
#include <CodeFragments.h>
#include <DriverServices.h>
#include "preprocessor.h"

#define fdsize 0x100000
#define WRITE_BACK 1

extern char *trunc(const char *addr);
extern void fentry(void *addr, unsigned int len, void *ft);
extern void alarm_timer_handler(TMTaskPtr myTask);

char fstore[fdsize + 0xFFF];
char *fdata;
char *ftext;


QDGlobals qd;
WindowRef debugW;

QElemPtr alarm_task_ptr;
void *alarm_handler;
long stop_alarms;
void *alarm_dsp;
void *alarm_rsp;
void *alarm_iv;

int csh;

void Failed(const unsigned char *why)
{
	DebugStr(why);
}

char *get_file(const char *path, int *len)
{
	char *data;
	int flen;
	FILE *input;
	
	if (!(input = fopen(path, "r")))
		return NULL;
	fseek(input, 0, SEEK_END);
	flen = ftell(input);
	fseek(input, 0, SEEK_SET);
	
	data = malloc(flen);
	if (!data)
		return NULL;
		
	if (!fread(data, 1, flen, input)) {
		free(data);
		return NULL;
	}
	
	fclose(input);
	if (len)
		*len = flen;
		
	return data;
}

void appsetup()
{
	MaxApplZone();
	InitGraf(&qd.thePort);
	InitFonts();
	FlushEvents(everyEvent,0);
	InitWindows();
	InitMenus();
	TEInit();
	InitDialogs(0l);
	InitCursor();
}

void hostsetup()
{
	RGBColor rc;
	Rect r;
	short fam;
	
	r.top = r.left = 0;
	r.bottom = 480;
	r.right = 512;
	
	debugW = NewCWindow(NULL, &r, "\p", true, plainDBox, (WindowRef) -1, false, 0);
	SetPort(debugW);
	PenNormal();
	GetFNum("\pMonaco", &fam);
	TextFont(fam);
	TextSize(9);
	TextMode(srcCopy);
	rc.green = 0xFFFF; rc.red = rc.blue = 0;
	RGBForeColor(&rc);
	rc.green = 0;
	RGBBackColor(&rc);
	EraseRect(&r);
}

void alarmsetup(void)
{
	static TMTask alarmTask;
		
	alarm_task_ptr = (QElemPtr) &alarmTask;
	alarm_handler = NULL;
	stop_alarms = 1;
	
	alarmTask.tmAddr = NewTimerProc(&alarm_timer_handler);
	alarmTask.tmCount = 0;
	alarmTask.tmWakeUp = 0;
	alarmTask.tmReserved = 0;
	
	InsXTime(alarm_task_ptr);
}

void main(void)
{
	fdata = trunc(&fstore[0xFFF]);
	
	appsetup();	
	ftext = preprocess("ppc-hosted-text.of", 0, NULL);	
	hostsetup();
	alarmsetup();
	MakeDataExecutable(fdata, fdsize);

#if !WRITE_BACK
	if (SetProcessorCacheMode != kUnresolvedCFragSymbolAddress)
		SetProcessorCacheMode(kCurrentAddressSpaceID, fdata, fdsize, kProcessorCacheModeWriteThrough);  
#endif

	fentry(fdata, fdsize, ftext);
}

void fexit(void)
{
/*	WindowRef w;
	GrafPtr wMgrPort; */
	
	DisposeWindow(debugW);
	
/*	GetWMgrPort(&wMgrPort);
		
	w = NewCWindow(NULL, &(wMgrPort->portRect), "\p", true, plainDBox, (WindowRef) -1, false, 0);
	DisposeWindow(w); */
	
	ExitToShell();
}


/*
//MrC :TOF:ppc-wrap-new.c -o :TOF:object:ppc-wrap-new.c.o -i :TOF: -i :CIncludes: -traceback -w 2 -opt speed -inline 0

////PPCLink :TOF:object:ppc-core-wrap.S.o :TOF:object:ppc-wrap-new.c.o :TOF:object:preprocessor.c.o :Libraries:PPCLibraries:PPCCRuntime.o :Libraries:SharedLibraries:InterfaceLib :Libraries:SharedLibraries:StdCLib :Libraries:SharedLibraries:DriverServicesLib -d -m main -o :TOF:ppc-tof-new -ac 32

//PPCLink :TOF:object:ppc-core-wrap.S.o :TOF:object:ppc-hosted-alarm.S.o :TOF:object:ppc-wrap-new.c.o :TOF:object:preprocessor.c.o :Libraries:PPCLibraries:PPCCRuntime.o :Libraries:SharedLibraries:InterfaceLib :Libraries:SharedLibraries:StdCLib -d -m main -o :TOF:ppc-tof-new -ac 32


*/