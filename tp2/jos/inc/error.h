/* See COPYRIGHT for copyright information. */

#ifndef JOS_INC_ERROR_H
#define JOS_INC_ERROR_H

// Kernel error codes -- keep in sync with list in lib/printfmt.c.
#define E_UNSPECIFIED	1	// Unspecified or unknown problem
#define E_BAD_ENV	2	// Environment doesn't exist or otherwise
				// cannot be used in requested action
#define E_INVAL		3	// Invalid parameter
#define E_NO_MEM	4	// Request failed due to memory shortage
#define E_NO_FREE_ENV	5	// Attempt to create a new environment beyond
				// the maximum allowed
#define E_IPC_NOT_RECV	6	// Attempt to send to env that is not recving
#define E_EOF		7	// Unexpected end of file

#define	MAXERROR	7

#endif	// !JOS_INC_ERROR_H */
