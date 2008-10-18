#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "time64.h"

#define myPUSHi(int)   (PUSHs(sv_2mortal(newSViv(int))));
#define myPUSHn(num)   (PUSHs(sv_2mortal(newSVnv(num))));

MODULE = Time::Local::Extended          PACKAGE = Time::Local::Extended
PROTOTYPES: DISABLE

void
localtime64(time)
    const Time64_T time
    INIT:
        struct TM *err;
        struct TM date;
    PPCODE:
        err = localtime64_r(&time, &date);

        if( err == NULL )
            XSRETURN_EMPTY;

        EXTEND(SP, 9);
        myPUSHi(date.tm_sec);
	myPUSHi(date.tm_min);
	myPUSHi(date.tm_hour);
	myPUSHi(date.tm_mday);
	myPUSHi(date.tm_mon);
	myPUSHn(date.tm_year);
	myPUSHi(date.tm_wday);
	myPUSHi(date.tm_yday);
	myPUSHi(date.tm_isdst);


void
gmtime64(time)
    const Time64_T time
    INIT:
        struct TM *err;
        struct TM date;
    PPCODE:
        err = gmtime64_r(&time, &date);

        if( err == NULL )
            XSRETURN_EMPTY;

        EXTEND(SP, 9);
        myPUSHi(date.tm_sec);
	myPUSHi(date.tm_min);
	myPUSHi(date.tm_hour);
	myPUSHi(date.tm_mday);
	myPUSHi(date.tm_mon);
	myPUSHn(date.tm_year);
	myPUSHi(date.tm_wday);
	myPUSHi(date.tm_yday);
	myPUSHi(date.tm_isdst);


int
safe_year(year)
    const Year year
    CODE:
        RETVAL = safe_year(year);
    OUTPUT:
        RETVAL


Time64_T
timegm64(sec, min, hour, mday, mon, year)
    const int sec
    const int min
    const int hour
    const int mday
    const int mon
    const Year year

    INIT:
        struct TM date;
        Time64_T time;
    CODE:
        date.tm_sec  = sec;
        date.tm_min  = min;
        date.tm_hour = hour;
        date.tm_mday = mday;
        date.tm_mon  = mon;
        date.tm_year = year;

        RETVAL = timegm64(&date);
    OUTPUT:
        RETVAL
