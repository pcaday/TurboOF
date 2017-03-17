#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <ctype.h>

#define N_SWATHS 256

#define I_TEXT "`text"
#define I_TEXT_LEN 5

#define I_BINARY "`bin"
#define I_BINARY_LEN 4

#define F_BINARY ":binary "
#define F_BINARY_LEN 8

#define BINARY_ALIGN 4
#define BLEN_SIZE 4

#define FNAME_MAXLEN 63

#ifndef bool
#define bool int
#endif

#ifndef false
#define false 0
#endif

#ifndef true
#define true 1
#endif

typedef struct {
	char *begin;
	unsigned int len;
	bool is_master;
} swath;

swath swaths[N_SWATHS], *swp;
unsigned int text_len;
char *mdp, *mdend;

extern void Failed(const char *why, const char *info);


void *round_to_bound(void *addr, unsigned int bound)
{
	return (void *) ((((uintptr_t) addr) + bound) & ~bound);
}

unsigned int round_to_bound_int(unsigned int n, unsigned long bound)
{
	return (n + bound) & ~bound;
}

/* Open and read a file. The given file is looked for in the current
    directory as well as in a forth/ subdirectory of the current directory. */
char *pre_get_file(const char *path, unsigned int *len)
{
	#define N_EPATH 256
	char *data;
	unsigned int flen;
	FILE *input;
	char epath[N_EPATH];
	
	(void) snprintf(epath, N_EPATH, "forth/%s", path);
	
	if (!(input = fopen(epath, "r")))
		if (!(input = fopen(path, "r")))
			Failed("Could not open file", path);

	fseek(input, 0, SEEK_END);
	flen = ftell(input);
	fseek(input, 0, SEEK_SET);
	
	data = malloc(flen);
	if (!data)
		Failed("Could not allocate memory for file", path);
		
	if (!fread(data, 1, flen, input)) {
		free(data);
		Failed("Could not read file", path);
	}
	
	fclose(input);
	if (len)
		*len = flen;
		
	return data;
}

void big_lstore(void *ptr, unsigned long n)
{
	char *p = (char *) ptr;
	
	*p++ = (n >> 24) & 0xFF;
	*p++ = (n >> 16) & 0xFF;
	*p++ = (n >> 8)  & 0xFF;
	*p   = n         & 0xFF;
}

int skip_white()
{
	char *cp = mdp;
	
	while (cp < mdend)
		if (!isspace(*cp++)) {
			mdp = cp - 1;
			return 1;
		}

	mdp = mdend;
	return 0;
}

int get_token()
{
	const char *cp = mdp;
	
	while (cp < mdend)
		if (isspace(*cp++))
			return (cp - mdp) - 1;
	
	return mdend - mdp;
}

void next_swath()
{
	if (!swp)
		swp = &swaths[0];
	
	swp++;
	if (swp >= &swaths[N_SWATHS])
		Failed("No more swaths available", "increase N_SWATHS in preprocessor.c");
}

void new_swath(char *begin, unsigned int len, bool is_master)
{
	next_swath();
	
	swp->begin = begin;
	swp->len = len;
	swp->is_master = is_master;
	
	text_len += len;
}

void start_mt_swath()
{
	next_swath();
	
	swp->begin = mdp;
	swp->is_master = false;
}

void end_mt_swath()
{
	unsigned int swath_len;
	
	if (!swp->is_master) {
		swath_len = mdp - swp->begin;
		
		swp->len = swath_len;
		swp->is_master = true;
		text_len += swath_len;
	}
}

unsigned int insert_file_swath()
{
	unsigned int fname_len, swath_len;
	char fname_buf[FNAME_MAXLEN];
	char *file_buf;
	
	fname_len = get_token();
	
	if (fname_len > FNAME_MAXLEN)
		fname_len = FNAME_MAXLEN;
	
	memcpy(fname_buf, mdp, fname_len);
	fname_buf[fname_len] = '\0';
															// Load the file into a swath
	file_buf = pre_get_file(&fname_buf[0], &swath_len);
	new_swath(file_buf, swath_len, false);

	mdp += fname_len;
	
	return swath_len;
}


char *preprocess(const char *master, unsigned int extra_len, unsigned int *final_len)
{
	char *mdata, *text, *tptr;
	unsigned int mlen, swath_len, token_len;
	swath *swath_i;
		
	mdata = pre_get_file(master, &mlen);		// Get the master text.
	mdp = mdata;
	mdend = mdata + mlen;

	swp = NULL;
	start_mt_swath();
	
	text_len = 0;									// Record the total merged length
	
	while (mdp < mdend) {
		if (*mdp == '`') {
			token_len = get_token();
			
			if ((token_len == I_TEXT_LEN) && !memcmp(mdp, I_TEXT, I_TEXT_LEN)) {
				end_mt_swath();								// We've got an include. Cut this swath and load the file.
				mdp += I_TEXT_LEN;
				
				if (skip_white()) {
					(void) insert_file_swath();
					start_mt_swath();					
				}
			} else if ((token_len == I_BINARY_LEN) && !memcmp(mdp, I_BINARY, I_BINARY_LEN)) {
				char *b_intro;
				unsigned int bi_len;

				end_mt_swath();
				mdp += I_BINARY_LEN;
			
				if (skip_white()) {
					bi_len = F_BINARY_LEN + BLEN_SIZE;						// Manufacture introductory word
					b_intro = malloc(bi_len);
					
					if (!b_intro)
						Failed("Could not allocate text memory", NULL);

					new_swath(b_intro, bi_len, false);

					token_len = get_token() + 1;							// Make sure we get space afterward for create
					swath_len = round_to_bound_int(text_len + token_len, BINARY_ALIGN - 1) - text_len;

					new_swath(mdp, swath_len, true);

					mdp += token_len;

					if (!skip_white())
						Failed("Expected filename after `binary", NULL);
					
					swath_len = insert_file_swath();

					strcpy(b_intro, F_BINARY);								// Fill in the extra text
					big_lstore(b_intro + F_BINARY_LEN, swath_len);
																
					start_mt_swath();
				}
			} else
				mdp++;
		} else
			mdp++;
	}
	
	end_mt_swath();
	
	text = malloc(text_len + extra_len + 1 + 0x1F);		// Allocate the text and align it.
	if (!text)
		Failed("Could not allocate text memory", NULL);
	
	text = round_to_bound(text, 0x1F);	
												// Copy the swaths in
	for (swath_i = &swaths[0], tptr = text; swath_i <= swp; swath_i++) {
		memcpy(tptr, swath_i->begin, swath_i->len);
		tptr += swath_i->len;
	}
	*tptr = 0xD;								// Make sure the text ends with whitespace for interpreting/compiling.
												// Free the included files and extra text
	for (swath_i = &swaths[0]; swath_i <= swp; swath_i++)
		if (!swath_i->is_master)
			free(swath_i->begin);
	
	free(mdata);								// Free the master text.	
	
	if (final_len)
		*final_len = text_len;
	
	return text;
}

/*
//MrC :TOF:preprocessor.c -o :TOF:object:preprocessor.c.o -i :CIncludes: -traceback -w 2 -opt speed -inline 0

*/