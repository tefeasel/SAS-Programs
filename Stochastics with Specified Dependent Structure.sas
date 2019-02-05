DATA parms;
	INPUT name $ gas power coal;
	DATALINES;
	y1 1 .47 .18
	y2 .47 1 .53
	y3 .18 .53 1
RUN;

PROC CONTENTS;
RUN;

PROC COPULA;
	VAR y1-y3;
	DEFINE cop normal (corr = parms);
	SIMULATE cop / 
		ndraws = 500
		seed = 1
		outuniform = normal_unifdata;
RUN;
