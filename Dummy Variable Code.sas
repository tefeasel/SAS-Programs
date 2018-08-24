*Dummy table;
PROC SQL;
	CREATE TABLE monthlydum AS
	SELECT UNIQUE juris, revcls, month, year
	FROM weakwh;
QUIT;

DATA dummies;
	SET monthlydum;
	IF month = 1 THEN mon = 'jan';
	IF month = 2 THEN mon = 'feb';
	IF month = 3 THEN mon = 'mar';
	IF month = 4 THEN mon = 'apr';
	IF month = 5 THEN mon = 'may';
	IF month = 6 THEN mon = 'jun';
	IF month = 7 THEN mon = 'jul';
	IF month = 8 THEN mon = 'aug';
	IF month = 9 THEN mon = 'sep';
	IF month = 10 THEN mon = 'oct';
	IF month = 11 THEN mon = 'nov';
	IF month = 12 THEN mon = 'dec';
	modate = cat(mon,year);
	value = 1;
RUN;

PROC SORT DATA = dummies;
	BY month year juris revcls;

PROC TRANSPOSE DATA = dummies OUT = dummies2; *Creates a dummy for every unique month and year combo;
	BY month year juris revcls;
	ID modate;
RUN;

DATA dummies3;
	SET dummies2;
	ARRAY miss [*] _NUMERIC_; *Used to find all missing values created by the transpose proc;
	ARRAY yr [23] 8. _TEMPORARY_ (1993:2015); *Enter range of years and change array subscript to the appropriate number of years;
	ARRAY values [12] 8. _TEMPORARY_ (1:12); *Does not need to be changed;
	ARRAY months [12] jan feb mar apr may jun jul aug sep oct nov dec; *Does not need to be changed;
	ARRAY shift [*] d1993on d1994on d1995on d1996on d1997on d1998on d1999on d2000on d2001on d2002on d2003on d2004on d2005on d2006on d2007on d2008on d2009on d2010on d2011on d2012on d2013on d2014on d2015on; *For shift binaries - manually enter all years in dataset;
	ARRAY d [*] d1993 d1994 d1995 d1996 d1997 d1998 d1999 d2000 d2001 d2002 d2003 d2004 d2005 d2006 d2007 d2008 d2009 d2010 d2011 d2012 d2013 d2014 d2015; *For individual year binaries - manually enter all years in dataset with a d prefix;
		DO i = 1 TO DIM(miss); *Replaces all missing values with a 0;
			IF miss[i] = . THEN miss[i] = 0;
		END;
		DO i = 1 TO 12; *Creates a dummy for each month;
			IF month = values[i] THEN months[i] = 1;
			ELSE months[i]=0;
		END;
		DO i = 1 TO 23; *Creates a dummy for each year;
			IF year = yr[i] THEN d[i] = 1;
			ELSE d[i] = 0;
		END;
		DO i = 1 TO DIM(shift); *Creates a level shift dummy based on the year;
			IF year GE yr[i] THEN shift[i] = 1;
			ELSE shift[i] = 0;
		END;
	DROP _NAME_ i;
RUN;

PROC SQL;
	CREATE TABLE weakwh2 AS
	SELECT weakwh.*, dummies3.*
	FROM weakwh, dummies3
	WHERE (weakwh.year=dummies3.year) AND (weakwh.month=dummies3.month) AND (weakwh.juris=dummies3.juris) AND (weakwh.revcls=dummies3.revcls);
QUIT;
