#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <MacTypes.h>
#include <MacMemory.h>
#include <Quickdraw.h>
#include <Events.h>
#include <Palettes.h>
#include <Resources.h>
#include <LowMem.h>
#include <StandardFile.h>
#include <Folders.h>
#include <Script.h>
#include <DriverGestalt.h>
#include <SCSI.h>

#include "preprocessor.h"


#define nvram_pref_name "\pTOF NVRAM"

typedef int bool;



typedef struct {
	void *base;
	unsigned long size;
} phys_item;

typedef struct {
	void *base;
	unsigned long size;
	void *rom;
} phys_item_plus_rom;

typedef struct {
	void *v_base;
	unsigned long v_line;
	unsigned long v_width;
} vid_info;

typedef struct {
	void *entrypoint;
	void *text;
	void *nvram;
	void *devtree;
	unsigned long text_len;
	unsigned long dt_len;
	void *phys;
	unsigned long phys_cnt;
	unsigned long nvram_plen;
	vid_info *debug_vid;
} entry_struct;

#pragma options align=mac68k

typedef struct {
	unsigned long xsum;
	unsigned short len;
	struct {
		unsigned : 9;
		unsigned vm_mod_ath : 1;
		unsigned use_nvramrc : 1;
		unsigned diag_switch : 1;
		unsigned fcode_debug : 1;
		unsigned auto_boot : 1;
		unsigned little_endian : 1;
		unsigned real_mode : 1;
	} bits;
	unsigned long real_base;
	unsigned long real_size;
	unsigned long virt_base;
	unsigned long virt_size;
	unsigned long load_base;
	unsigned long screen_rows;
	unsigned long screen_columns;
	unsigned long nvram_block;
	char nvram_device[0x10];
	char boot_device[0x40];
	char boot_file[0x20];
	char diag_device[0x40];
	char diag_file[0x20];
	char input_device[0x20];
	char output_device[0x20];
	char boot_command[0x40];
	char nvramrc[0x88];
} nvram_struct;
#define nvram_len 0x200

#pragma options align=reset

extern char ppc_boot[];
extern long ppc_boot_len;
extern void denter(entry_struct *);
extern void enter(void *code68k, entry_struct *);

QDGlobals qd;
Ptr spring;
FSSpec nvramFSp;

char page_storage[0x1FFFF];
char *ps_real, *ps_virt;

vid_info *vi;
entry_struct *es;
nvram_struct *nv;
nvram_struct nv_default;

char *eot;				// end of text address, where extra stuff goes.
int text_extra = 0x300;
int is_vm;

// Modifiers as reported by GetModifierKeys
enum {mCntl = 8, mOpt = 4, mCmd = 2, mShift = 1};

void *round_to_bound(void *addr, unsigned long bound)
{
	return (void *) ((((unsigned long) addr) + bound) & ~bound);
}

void MacSetup()
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

int GetModifierKeys()
{
	KeyMap km;

	GetKeys(km);
	
	return (km[1] & 0x0D) | ((km[1] >> 14) & 2);
}

bool GetPrefsFile(FSSpec *dest, bool *exists)
{
	short pfVRN;
	long pfDID;
	OSErr e;
	
	if (FindFolder(kOnSystemDisk, kPreferencesFolderType, true, &pfVRN, &pfDID))
		return false;
	e = FSMakeFSSpec(pfVRN, pfDID, nvram_pref_name, dest);
	
	*exists = (e == noErr);
	return (e == noErr) || (e == fnfErr);
}

OSErr CreatePrefsFile(FSSpec *dest)
{
	return FSpCreate(dest, 'tof*', 'PREF', smSystemScript);
}

void InvalidateNVRAMFSSpec()
{
	nvramFSp.vRefNum = 0;
}

bool WriteDefaultNVRAMToFile(FSSpec *fsp)
{
	short rn;
	long len;
	
	if (FSpOpenDF(fsp, fsWrPerm, &rn))
		return false;
	if (SetFPos(rn, fsFromStart, 0)) {
		FSClose(rn);
		return false;
	}
	len = nvram_len;
	if (FSWrite(rn, &len, (Ptr) &nv_default)) {
		FSClose(rn);
		return false;
	}
	if (len != nvram_len) {
		FSClose(rn);
		return false;
	}
	if (SetEOF(rn, nvram_len)) {
		FSClose(rn);
		return false;
	}
	FSClose(rn);
	FlushVol(NULL, fsp->vRefNum);
	return true;
}

bool LoadNVRAMFromFile(FSSpec *fsp, bool isPrefs)
{
	long len;
	short rn;
	
	if (FSpOpenDF(fsp, fsRdPerm, &rn))
		return false;
	if (SetFPos(rn, fsFromStart, 0)) {
		FSClose(rn);
		return false;
	}
	if (GetEOF(rn, &len)) {
		FSClose(rn);
		return false;
	}
	if (len < nvram_len) {
		if (FSClose(rn))
			return false;
		if (isPrefs)
			WriteDefaultNVRAMToFile(fsp);
		return false;
	}
	len = nvram_len;
	if (FSRead(rn, &len, (Ptr) nv)) {
		FSClose(rn);
		return false;
	}
	if (len != nvram_len) {
		FSClose(rn);
		return false;
	}
	nv->len = nvram_len >> 2;				// in words
	FSClose(rn);

	nvramFSp = *fsp;
		
	return true;
}

bool WriteDefaultNVRAMToPrefs()
{
	FSSpec fsp;
	bool exists;
	
	if (!GetPrefsFile(&fsp, &exists))
		return false;
	
	if (!exists)
		if (CreatePrefsFile(&fsp))
			return false;

	nvramFSp = fsp;	
	return WriteDefaultNVRAMToFile(&fsp);
}

bool LoadNVRAMFromPrefs()
{
	FSSpec fsp;
	bool exists;
	
	if (!GetPrefsFile(&fsp, &exists))
		return false;
	
	if (exists) {
		return LoadNVRAMFromFile(&fsp, true);
	} else {
		if (CreatePrefsFile(&fsp))
			return false;
		return WriteDefaultNVRAMToFile(&fsp);
	}
}

bool LoadNVRAMFromDialog()
{
	StandardFileReply sfr;

	StandardGetFile(NULL, 0, NULL, &sfr);

	if (!sfr.sfGood)
		ExitToShell();
		
	return LoadNVRAMFromFile(&sfr.sfFile, false);
}

void *VirtPhys(void *virt)
{
	LogicalToPhysicalTable ltpt;
	unsigned long npe;
	OSErr err;
		
	npe = 1;
	ltpt.logical.address = round_to_bound(virt, 0xFFF);
	ltpt.logical.count = 0x1000;
	err = GetPhysical(&ltpt, &npe);
	if (err || (npe != 1))
		return virt;
	
	return ltpt.physical[0].address;
}

void Failed(const unsigned char *why)
{
	DebugStr(why);
	while (true) ;
}

void Load68KSpringboard()
{
	Handle vs;
	long vsl;
	
	vs = GetResource('zcod', 1111);
	if (!vs)
		Failed("\pCould not load 68k springboard");
	
	vsl = GetHandleSize(vs);
	spring = NewPtr(vsl);
	if (!spring)
		Failed("\pCould not allocate memory for springboard");
	
	BlockMoveData(*vs, spring, vsl);
	
	ReleaseResource(vs);
}

void AlignStructs()
{
	char *pa;
	
	ps_virt = pa = round_to_bound(&page_storage[0], 0xFFF);

	es = (void *) pa;
	vi = (void *) (pa += ((sizeof(entry_struct) + 0x1F) & ~0x1F));
#if 0
	nv = (void *) (pa += ((sizeof(vid_info) + 0x1F) & ~0x1F));
#endif
}

GDHandle Find8Bit()
{
	GDHandle gd;
	
	gd = GetMainDevice();
	
	if (HasDepth(gd, 8, 1, 1))
		return gd;
	
	gd = GetDeviceList();
	
	while (gd) {
		if (HasDepth(gd, 8, 1, 1))
			return gd;
		gd = GetNextDevice(gd);
	}
	
	return 0;
}

void Set8Bit(GDHandle gd)
{
	OSErr err;
	
	if ((*(*gd)->gdPMap)->pixelSize == 8)		// Already in 256 colors?
		return;
	
	err = SetDepth(gd, 8, 1, 1);
	if (err)
		Failed("\pSetDepth failed!");
}

void SetISOCTab()
{
	CTabHandle cth;
	int i;
	
	for (i = 0; i < 256; i++)
		ProtectEntry(i, false);
	
	cth = GetCTable(256);
	HLock((Handle) cth);
	SetEntries(0, 0xFF, (*cth)->ctTable);
	HUnlock((Handle) cth);
	DisposeCTable(cth);
}

void BlankAllScreens()
{
	GDHandle gd, old;
	Rect r;
	
	old = GetGDevice();
	gd = GetMainDevice();
	
	while (gd) {
		SetGDevice(gd);
		r = (*(*gd)->gdPMap)->bounds;
		ForeColor(blackColor);
		PaintRect(&r);
		gd = GetNextDevice(gd);
	}
	
	SetGDevice(old);
}

void GatherDebugVideoParms(GDHandle gdh)
{
	PixMapPtr pmp;
	
	pmp = *((*gdh)->gdPMap);

	vi->v_base = pmp->baseAddr;
	vi->v_line = pmp->rowBytes & 0x3FFF;
	vi->v_width = pmp->bounds.right - pmp->bounds.left;
}

int LoadText()
{
	char *ftx;
	unsigned int ftl;
	
	ftx = preprocess("ppc-text.of", text_extra, &ftl);
	if (!ftx)
		return 0;
	
	ftl = (ftl + 0x1F) & ~0x1F;
	
	es->text = ftx;
	es->text_len = ftl + text_extra;
	eot = ftx + ftl;
	
	return 1;
}

void GatherMemConfig()
{
	phys_item_plus_rom *tpi;
	long gr;
	OSErr err;
	
	err = Gestalt('ram ', &gr);
	if (err)
		Failed("\pGestalt failed on ram!");
	
	tpi = round_to_bound(eot, 0x3);
	tpi->base = 0;
	tpi->size = gr;			// Assume for now.. we will need to do this between Visor and ppc-boot for non-contig unknowns.
	tpi->rom = LMGetROMBase();
	eot = ((char *) tpi) + sizeof(phys_item_plus_rom);
	
	es->phys = tpi;
	es->phys_cnt = 1;
}

void LoadDefaultNVRAM()
{
	Handle vs;

	vs = GetResource('nv! ', 1001);
	if (vs) {
		if (GetHandleSize(vs) != nvram_len)
			Failed("\pDefault NVRAM has incorrect length");
		BlockMoveData(*vs, &nv_default, nvram_len);
		ReleaseResource(vs);
	} else
		Failed("\pCould not load default NVRAM");
	
	nv_default.len = nvram_len >> 2;
	BlockMoveData(&nv_default, nv, nvram_len);
}


void InitNVRAM()
{
	nv = round_to_bound(eot, 0x3);
	eot = ((char *) nv) + sizeof(nvram_struct);
}

void XsumNVRAM()
{
	unsigned int i, k, xs;
	unsigned long *l;
	
	xs = 0;
	k = nv->len - 1;
	l = (unsigned long *) nv;
	
	for (i = 0; i < k; i++) {
		xs = (xs << 15) | (xs >> 17);
		xs ^= *++l;
	}
	
	nv->xsum = xs;
}

void InitEntryS()
{
	es->nvram = nv;
	es->devtree = 0;
	es->dt_len = 0;
	es->nvram_plen = nv->len << 2;
	es->debug_vid = vi;
	es->entrypoint = ppc_boot;
}

void GetVMEnabled()
{
	long gr, vgr;
	OSErr err;
	
	err = Gestalt('ram ', &gr);
	err |= Gestalt('lram', &vgr);
	if (err)
		Failed("\pGestalt failed on ram!");

	is_vm = gr != vgr;
}

void *VMLockdown(void *virt, unsigned long size)
{
	LogicalToPhysicalTable ltpt;
	unsigned long npe;
	OSErr err;
			
	err = LockMemoryContiguous(virt, size);
	if (err)
		return 0;
	
	npe = 1;
	ltpt.logical.address = virt;
	ltpt.logical.count = size;
	err = GetPhysical(&ltpt, &npe);
	if (err || (npe != 1))
		return 0;
	
	return ltpt.physical[0].address;
}

void FlushAll()
{
	MakeDataExecutable(ps_virt, 0x1000);
	MakeDataExecutable(es->text, es->text_len);
	MakeDataExecutable(ppc_boot, ppc_boot_len);
}

void ESToPhysical()
{
	char *et_real;

	es->text_len = (es->text_len + 0x1F) & ~0x1F;
	if (is_vm) {
		ps_real = VMLockdown(ps_virt, 0x1000);
		if (!ps_real)
			Failed("\pCould not lock down page storage");

		es->entrypoint = VMLockdown(es->entrypoint, ppc_boot_len);
		if (!es->entrypoint)
			Failed("\pCould not lock down ppc-boot");
			
		et_real = VMLockdown(es->text, es->text_len);
		if (!et_real)
			Failed("\pCould not lock down text");

		es->debug_vid = (vid_info *) (((char *) es->debug_vid - ps_virt) + ps_real);
		es->nvram = (nvram_struct *) (((char *) es->nvram - (char *) es->text) + et_real);
		es->phys = (phys_item *) (((char *) es->phys - (char *) es->text) + et_real);
		es->text = et_real;
	}
}

void main(void)
{
	bool loadedNVRAM = false;
	
	GDHandle myGD;
	
	MacSetup();

	Load68KSpringboard();
	
	AlignStructs();

	if (!LoadText())
		Failed("\pCould not load text!");
	
	GatherMemConfig();

	InitNVRAM();
	LoadDefaultNVRAM();
	
	if (GetModifierKeys() & mShift)
		(void) WriteDefaultNVRAMToPrefs();
	
	if (GetModifierKeys() & mOpt)
		loadedNVRAM = LoadNVRAMFromDialog();
	if (!loadedNVRAM)
		if (!LoadNVRAMFromPrefs())
			Failed("\pCould not load NVRAM");	// for testing; later, just use the defaults

	XsumNVRAM();

	myGD = Find8Bit();
	if (!myGD)
		Failed("\pNo screen device!");

	Set8Bit(myGD);

	SetGDevice(myGD);
	SetISOCTab();	

	HideCursor();
	BlankAllScreens();

	GatherDebugVideoParms(myGD);
	
	InitEntryS();
	
	FlushAll();
	GetVMEnabled();
//	ESToPhysical();

	Debugger();
	
	enter(spring, es);
//	denter(es);
}

/*
//MrC :TOF:mac-secondary.c -o :TOF:object:mac-secondary.c.o -i :CIncludes: -traceback -w 2 -opt speed -inline 0

ZapDrel :TOF:object:ppc-boot.S.o

PPCLink :TOF:object:ppc-boot.S.o :TOF:object:mac-secondary.c.o :TOF:object:mac-secondary.S.o :TOF:object:preprocessor.c.o :Libraries:PPCLibraries:PPCCRuntime.o :Libraries:SharedLibraries:InterfaceLib :Libraries:SharedLibraries:StdCLib -d -m main -ac 5 -o :TOF:mac-secondary

:TOF:mac-secondary



DeRez :TOF:mac-secondary > :TOF:mac-secondary.r

Rez :TOF:mac-secondary.r -o :TOF:mac-secondary



DumpFile -w 16 -g 4 'Macintosh HD:System Folder:Preferences:TOF NVRAM'

*/
