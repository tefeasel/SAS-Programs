OPTIONS MPRINT MLOGIC MINOPERATOR;

%LET list = ;

/*Key: make sure juris files all have the same naming convention*/
/*Need to update csp and wpc excel files to pull in customers correctly*/

/*Import the macro definitions for the forecast*/
%INCLUDE "" / SOURCE2;
LIBNAME out "";

/*Set the date that is at the end of the SAE model XLS files so they import properly*/
/*filedate2 macro is for any revisions*/
%LET filedate = ;
%LET filedate2 =;

/*Set the date you want to be appended to the end of the baseresout.xls and basecomout.xls.*/
/*This will help to ensure old files are not overwritten*/
%LET filedateout = ;

/*Import monthly lighting shares files so we can calculate light end use below*/
LIBNAME in XLSX "";

DATA lighting;
	SET in.monthlyshares;
RUN;

/**/
/*Residential*/
/**/
%MACRO RES;
%LOCAL i;
%DO i = 1 %TO 15;
   %LET jur = %SCAN(&list, &i);

/*Keep only lighting share for the juris in the current iteration of the loop*/
DATA &jur._light;
    SET lighting (KEEP = year month &jur.);
	RENAME &jur. = light_pct;
RUN;

PROC SORT;
	BY year month;
RUN;

/*Import customer count data*/
PROC IMPORT OUT = &jur._custs (KEEP = year month cr_&jur RENAME = (cr_&jur = custs))
	DATAFILE = ""
	DBMS = xls REPLACE;
RUN;

PROC SORT DATA = &jur._custs;
	BY year month;
RUN;

%IF &jur IN() %THEN %DO;
/*Import the SAE model*/
PROC IMPORT OUT = &jur
	DATAFILE = ""
	DBMS = XLSX REPLACE;
	SHEET = "BX"n;
RUN;

PROC SORT DATA = &jur;
	BY year month;
RUN;

/*Import just the salesperhh variable from SAE model*/
PROC IMPORT OUT = &jur._saleshh (KEEP = year month salesperhh)
	DATAFILE = ""
	DBMS = XLSX REPLACE;
	RANGE = "Data$A1:H700";
RUN;

PROC SORT DATA = &jur._saleshh;
	BY year month;
RUN;
%END;

%ELSE %DO;
/*Import the SAE model*/
PROC IMPORT OUT = &jur
	DATAFILE = ""
	DBMS = XLSX REPLACE;
	SHEET = "BX"n;
RUN;

PROC SORT DATA = &jur;
	BY year month;
RUN;

/*Import just the salesperhh variable from SAE model*/
PROC IMPORT OUT = &jur._saleshh (KEEP = year month salesperhh)
	DATAFILE = ""
	DBMS = XLSX REPLACE;
	RANGE = "Data$A1:H700";
RUN;

PROC SORT DATA = &jur._saleshh;
	BY year month;
RUN;
%END;

/*Merge SAE model, lighting, customer counts, and sales per hh*/
/*Next, the data step will calculate the lighting share, misc. end use, and other end use.*/
/*The goal is to calculate the end use associated with heat, cool, light, other, and, finally, the total KWH.*/
DATA &jur._fcst_res;
	RETAIN year month juris revcls;
	MERGE &jur &jur._light &jur._custs &jur._saleshh;
	BY year month;
	WHERE year >= 1995;
	IF pred = . THEN DELETE;
	juris = "%UPCASE(&jur)";
	revcls = 1;
	light_share = light_pct*(pred-xheat-xcool);
	misc_pred = pred - xheat - xcool - light_share;
	other = salesperhh - pred + misc_pred; 
	***Change month to first forecasted month***;
	IF year > &fcstbegin OR (year = %EVAL(&fcstbegin) AND month GE 1) THEN other = misc_pred; *Sets the other category to be the predicted misc. for the forecast period;
	ELSE other = other;
	Resheat = (custs*xheat)/1000000;
	Rescool = (custs*xcool)/1000000;
	Reslight = (custs*light_share)/1000000;
	Resother = (custs*other)/1000000;
	restotal = resheat + rescool + reslight + resother;
RUN;
%END;
%MEND res;
%RES

/*Merge all the datasets produced by the loop and set any adjustments to residential here*/
/*The adjustements are set to be deducted or added from the other end use category by default*/
/*Data step will recalculate the total if there are any adjustements.*/
/*This dataset can then be used to produce files with the heat, cool, other and total sales (e.g., baseres files)*/
