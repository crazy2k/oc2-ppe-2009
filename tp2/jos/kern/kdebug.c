#include <inc/stab.h>
#include <inc/string.h>

#include <kern/kdebug.h>
#include <kern/pmap.h>
// #include <kern/env.h>

struct Stab {
	uint32_t n_strx;	/* index into string table of name */
	uint8_t n_type;         /* type of symbol */
	uint8_t n_other;        /* misc info (usually empty) */
	uint16_t n_desc;        /* description field */
	uintptr_t n_value;	/* value of symbol */
};

extern const struct Stab __STAB_BEGIN__[], __STAB_END__[];
extern const char __STABSTR_BEGIN__[], __STABSTR_END__[];

static void
stab_binsearch(const struct Stab *stabs, uintptr_t addr, int *lx, int *rx, int type)
{
	int l = *lx, r = *rx;
	
	while (l <= r) {
		int m = (l + r) / 2;
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l)
			l = (l + r) / 2 + 1;
		else if (stabs[m].n_value < addr) {
			*lx = m;
			l = m + 1;
		} else if (stabs[m].n_value > addr) {
			*rx = m;
			r = m - 1;
		} else {
			*lx = m;
			l = m;
			addr++;
		}
	}
}


int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	info->eip_fn = "<unknown>";
	info->eip_fnaddr = addr;
	info->eip_fnlen = 9;
	info->eip_file = "<unknown>";
	info->eip_line = 0;

	if (addr >= KERNBASE) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
  	        panic ("User address");
	}

	lfile = 0, rfile = stab_end - stabs - 1;
	stab_binsearch(stabs, addr, &lfile, &rfile, N_SO);
	if (lfile == 0)
		return -1;

	lfun = lfile, rfun = rfile;
	stab_binsearch(stabs, addr, &lfun, &rfun, N_FUN);

	/* At this point we know the function name. */
	if (lfun != lfile) {
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
			info->eip_fn = stabstr + stabs[lfun].n_strx;
		info->eip_fnaddr = stabs[lfun].n_value;
		addr -= info->eip_fnaddr;
		lline = lfun, rline = rfun;
	} else {
		info->eip_fn = info->eip_file;
		info->eip_fnaddr = addr;
		lline = lfun = lfile, rline = rfile;
	}
	info->eip_fnlen = strfind(info->eip_fn, ':') - info->eip_fn;

	/* Search for the line number: */
	// You code here
	if (lline == 0)
		return -1;

	/* Found line number, store it and search backwards for filename */
	info->eip_line = stabs[lline].n_desc;
	while (lline >= lfile && stabs[lline].n_type != N_SOL && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
	
	return 0;
}
