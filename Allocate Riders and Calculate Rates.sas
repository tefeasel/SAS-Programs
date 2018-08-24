OPTIONS SYMBOLGEN LS = 120;

LIBNAME load "";
LIBNAME rev "";
FILENAME riderXL "";

/*Adjust these two macro variables. The others below will update automatically.*/
%LET fcstbegin = "01JAN2017"d;
%LET fcstend = "31DEC2018"d;

%LET startyr = 2017; *Current year;
%LET endyr = 2018; *Following year/last year of revenue forecast;
%LET filter = &fcstbegin <= modate <= "01APR2017"d; *This will determine what time period to use for the allocator - start with it set to: modate GE &fcstbegin,
									 				but once complete calculating initial RR it's best to set it to: &fcstbegin <= modate <= "<insert date>"d so you can replicate results;

/*Now get the allocation of those new riders by kWh share*/
PROC SQL;
    CREATE TABLE new_riders_allocated AS
    SELECT COALESCE(n.juris, l.juris) AS juris,
           n.rid_cat,
           l.revcls,
		   n.ridercat_juris_total,
		   l.kwh/l.juris_kwh AS allocation
    FROM new_riders AS n,
		 (SELECT *,
		 		 SUM(kwh) AS juris_kwh
		  FROM load_annual
		  WHERE year = &endyr
		  GROUP BY juris) AS l
    WHERE n.juris = l.juris
	ORDER BY juris, revcls, rid_cat;
QUIT;

/*Merge the new riders with all of the others*/
PROC SQL;
    CREATE TABLE allocate_final AS
    SELECT *
    FROM allocate
    OUTER UNION CORR
    SELECT *
    FROM new_riders_allocated
    ORDER BY juris, revcls, rid_cat;
QUIT;

/*Calculate revenues based on allocation here; also can override an allocator*/
DATA allocate_final;
    SET allocate_final;

	IF juris = "" AND rid_cat = "" THEN DO;;
        IF revcls = 1 THEN allocation = .7044;
		IF revcls = 2 THEN allocation = .2370;
		IF revcls = 3 THEN allocation = .0571;
		IF revcls = 4 THEN allocation = .0015;
    END;

	IF juris IN() AND rid_cat = "" THEN DO;
		IF revcls = 1 THEN allocation = 1;
		ELSE allocation = 0;
	END;

    rev = ridercat_juris_total*allocation;
RUN;

PROC SQL;
    CREATE TABLE together AS
    SELECT COALESCE(t.juris, a.juris) AS juris,
           COALESCE(t.rid_cat, a.rid_cat) AS rid_cat,
           start,
           end,
		   to_base,
           CASE WHEN t.rid_cat IN (SELECT DISTINCT rid_cat
		   							FROM new_riders_allocated
		   							WHERE juris IN("") AND rid_cat NOT IN("")) THEN t.amt/2 /*Need to divide these by two or else the amount any new Ohio rider will be double counted; if your override an allocater, you don't need to*/
		   		ELSE t.amt
		   END AS amt,
           amt2,
           a.allocation,
           a.revcls
    FROM two AS t, allocate_final AS a
    WHERE t.juris = a.juris AND t.rid_cat = a.rid_cat;
QUIT;

PROC SORT DATA = together;
    BY juris revcls rid_cat start;
RUN;

DATA three;
    SET together;
	IF rid_cat = lag(rid_cat) AND amt = lag(amt) AND amt2 = lag(amt2) AND start = lag(start) AND end = lag(end) THEN DELETE; *This deletes duplicates that result from SQL merging to create together;
    amt = amt*allocation;

/*	Could change amounts here if necessary*/

    amt2 = amt2*allocation;
    amt2 = lag(amt2);
    IF amt2 = . THEN amt2 = 0;
	IF rid_cat NE lag(rid_cat) THEN amt2 = 0; *Helps to ensure riders that don't change get a 0 just because of the order of the dataset;
RUN;

PROC SORT DATA = three;
    BY juris revcls start end rid_cat;
RUN;

PROC MEANS DATA = three NOPRINT NWAY;
	CLASS start rid_cat;
	WHERE juris IN("");
	VAR amt;
	OUTPUT OUT = oh_check SUM=;
RUN;

*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*;
*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*;
*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*;
*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*;

/*Roll-in to base here/Calculate Addition to Base Rate*/
DATA rollin;
	SET three;
	WHERE /*OR*/
		  to_base = 1; *to_base helps to roll a rider in to base when it's amount changes from its previous RR amount.
		  				It can also be used when a "rider" will never be calculated as part of rate relief;

/*	If there is a rider whose end date is equal to the end of the forecast, */
/*	change the end date with if/then logic to the day before if moves to base (usually the last day of the prior month) here*/

RUN;

PROC SQL;
	CREATE TABLE rollin2 AS
	SELECT rollin.*, load_annual.*,
		   amt/kwh AS add_to_base_rate
	FROM rollin, 
		 load_annual
	WHERE load_annual.year = &endyr AND rollin.juris = load_annual.juris AND rollin.revcls = load_annual.revcls;
QUIT;

PROC SORT;
	BY juris revcls start end rid_cat;

DATA rollin_rates (KEEP = juris revcls begin rollin_rate);
	SET rollin2;
	BY juris revcls start end rid_cat;
	IF to_base = 1 THEN begin = start;
	ELSE begin = end + 1;
    DO i = revcls to revcls by revcls;
        IF first.juris AND first.start THEN total = 0;
            total + add_to_base_rate;
        IF last.start THEN OUTPUT;
        IF last.revcls THEN total = 0;
    END;
    FORMAT total DOLLAR25.2 begin MMDDYY9.;
	RENAME total = rollin_rate;
RUN;

PROC SORT DATA = rollin_rates;
	BY juris begin revcls;
RUN;

*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*;
*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*;
*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*;
*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*;

/*Replicate the data tabs, calculating post fcst adjusted rates and everything*/
DATA riders (DROP = i);
    SET three;
	WHERE to_base = 0; *this is so riders that should be considered base never enter the RR calculation;
    BY juris revcls start end rid_cat;
    DO i = revcls to revcls by revcls;
        IF first.juris AND first.start THEN total = 0;
            total + amt + amt2;
        IF last.start THEN OUTPUT;
        IF last.revcls THEN total = 0;
    END;
    FORMAT total DOLLAR25.2;
RUN;

/*Verify numbers tie to Excel data for a particular juris*/
PROC MEANS DATA = riders NWAY SUM;
	CLASS start;
	VAR total;
	WHERE juris = "";
RUN;

/*Merge load and riders to get add factor*/
PROC SQL;
    CREATE TABLE rate_relief AS
    SELECT COALESCE(r.juris, l.juris) AS juris,
           COALESCE(r.revcls, l.revcls) AS revcls,
           start,
		   end,
           total,
           kwh,
           ((total/kwh)) AS rr_rate
    FROM riders AS r,
         load_annual AS l
    WHERE (r.juris = l.juris) AND (r.revcls = l.revcls) AND l.year = &endyr
    ORDER BY juris, revcls, start;
QUIT;

/*Create a final data set with base rates and rate relief rate*/
DATA base;
	SET rev.total_billed_and_unbilled;
	WHERE year LE &endyr;
	trate = (tbase/tkwh)*1000;
	date = mdy(month, 1, year);
    IF juris = "" AND revcls =  THEN revcls = ;
RUN;

PROC SQL;
	CREATE TABLE final_rates AS
	SELECT b.year,
		   b.month,
		   b.date,
		   COALESCE(rr.juris, b.juris) AS juris,
		   COALESCE(rr.revcls, b.revcls) AS revcls,
		   b.trate,
		   b.tbase,
		   b.tbaserr,
		   rr.rr_rate,
		   rr.start AS rr_start,
		   b.tkwh/1000 AS tkwh,
		   b.kwh/1000 AS kwh
	FROM base AS b
	LEFT JOIN rate_relief AS rr
	ON b.juris = rr.juris AND b.revcls = rr.revcls AND rr.start <= b.date
	WHERE b.year <= &endyr
	ORDER BY juris, year, month, revcls;
QUIT;

PROC SQL;
	CREATE TABLE final_rates2 AS
	SELECT final_rates.*,
		   rollin_rates.rollin_rate,
		   rollin_rates.begin
	FROM final_rates AS f
	LEFT JOIN rollin_rates AS r
	ON f.juris = r.juris AND f.revcls = r.revcls AND r.begin <= f.date
	WHERE f.year <= &endyr
	ORDER BY juris, year, month, revcls, rr_start DESC, begin DESC;
QUIT;

/*This will clean up any duplicates, and always pick up the most recent applicable rate relief or base rate roll-in*/
PROC SORT DATA = final_rates2 OUT = final_rates2 NODUPKEY;
	BY juris year month revcls;
RUN;

PROC SORT DATA = final_rates2;
	BY juris revcls year month;
RUN;

/*Clean up and create a final data set*/
DATA final_clean;
	SET final_rates2;
	IF rollin_rate = . THEN rollin_rate = 0;
	IF rr_rate = . THEN rr_rate = 0;
	IF juris = "OPC" AND revcls = 5.2 THEN rr_rate = 0;
	bprice = trate;
	bpricerr = ((trate) - rr_rate);
	brev = bprice*tkwh;
	brevrr = bpricerr*tkwh;
/*	nfrr = base_rate + rr_rate;*/
	rr_amt = tkwh*rr_rate;
	FORMAT rr_amt brev brevrr DOLLAR25.2;
	KEEP year month juris revcls trate brev brevrr tkwh rr_rate rollin_rate bprice bpricerr rr_amt;
	LABEL bprice = "Bill. & Accr. NFRR Price"
		  bpricerr = "Bill. & Accr. Base Price, with roll ins"
		  trate = "Bill. & Accr. NFRR (same as bprice)"
		  rr_rate = "Rate Relief Rate"
		  tkwh = "Booked Sales"
		  rollin_rate = "Rates to roll in/out base"
		  rr_amt = "Total RR $"
		  brev = "Bill. & Accr. NFRR $"
		  brevrr = "Bill. & Accr. Base $";
RUN;

/*Replicate rate change rate tab*/
DATA rate_changes;
	SET final_clean (KEEP = juris revcls date rr_rate);
	FORMAT date MONYY5.;
RUN;

PROC TRANSPOSE DATA = rate_changes OUT = rate_change_rate (DROP = _name_);
	BY juris revcls;
	VAR rr_rate;
	ID date;
RUN;

PROC PRINT DATA = rate_change_rate NOOBS;
	BY juris;
	WHERE revcls LE 4;
	VAR juris revcls mar17 apr17 may17 jun17 jul17 aug17 sep17 oct17 nov17 dec17
		jan18 feb18 mar18 apr18 may18 jun18 jul18 aug18 sep18 oct18 nov18 dec18;
	SUMBY juris;
RUN;

/*This will verify the rider totals are the same in the rate assumptions spreadsheet*/
PROC SORT DATA = rate_relief OUT = rr;
	BY juris start;
RUN;

DATA rr;
	SET rr;
	IF juris IN("") THEN juris = "OH";

PROC SORT DATA = rr OUT = rr;
	BY juris start;
RUN;

PROC MEANS DATA = rr NWAY NOPRINT;
	BY juris start;
	VAR total;
	OUTPUT OUT = checkrr SUM = ;
RUN;

/*Create a spreadsheet that we can use to copy and paste riders*/
PROC SORT DATA = load_annual OUT = fcstkwh;
	BY juris revcls;
	WHERE year = &endyr;
RUN;

PROC SORT DATA = three OUT = three_nodups NODUPKEY;
	BY juris revcls rid_cat start end;
RUN;

DATA ui_riders_ohio;
	MERGE three_nodups fcstkwh;
	BY juris revcls;
	WHERE juris IN("");
	IF to_base = 0;
	juris = "OH";
RUN;

PROC MEANS DATA = ui_riders_ohio NWAY NOPRINT;
	CLASS juris revcls rid_cat start end;
	VAR amt kwh;
	OUTPUT OUT = ui_riders_ohio2 SUM=;
RUN;

DATA ui_riders_ohio3;
	SET ui_riders_ohio2;
	year = 2018;
	rate = amt/kwh;
RUN;

DATA ui_riders (KEEP = year month juris revcls rid_cat start end rate);
	MERGE three_nodups fcstkwh;
	BY juris revcls;
	IF to_base = 0; 
	rate = amt/kwh;
RUN;

DATA ui_riders_combined (KEEP = year month juris revcls rid_cat start end rate);
	SET ui_riders ui_riders_ohio3;
	WHERE juris NOT IN("");
RUN;

PROC SORT DATA = ui_riders_combined;
	BY juris revcls start rid_cat;
	WHERE start NE . AND revcls LE 4;
RUN;

DATA ui_riders2 (KEEP = juris revcls modate rid_cat rate);
	SET ui_riders_combined;
	BY juris revcls start rid_cat;
    DO i = 0 TO INTCK('month', start, end);
		modate = INTNX('month', start, i, 'b');
	OUTPUT;
	END;
	FORMAT modate MONYY5.;
RUN;

PROC SQL NOPRINT;
	SELECT DISTINCT modate
/*	Create macro variable dates to preserve ordering of dates once transposed*/
	INTO :dates SEPARATED BY " " 
	FROM ui_riders2
	ORDER BY modate;
QUIT;

PROC SORT DATA = ui_riders2;
	BY juris rid_cat revcls;

PROC TRANSPOSE DATA = ui_riders2 OUT = ui_riders3 (DROP = _name_);
	BY juris rid_cat revcls;
	VAR rate;
	ID modate;
RUN;

DATA otherind;
	SET ui_riders3;
	BY juris rid_cat;
	WHERE juris NOT IN("");
	IF rid_cat = "" THEN DELETE;
	IF first.rid_cat;
	ARRAY dates _numeric_;
	DO OVER dates;
		dates = 0;
	END;
	revcls = 3.9;
RUN;

DATA rider_template;
	RETAIN juris revcls rid_cat &dates;
	SET ui_riders3 otherind;
	IF revcls = 22 THEN DELETE;
RUN;

PROC SORT DATA = rider_template OUT = rider_template;
	BY juris rid_cat revcls;
RUN;

LIBNAME xl XLSX "";

/*
DATA xl.rr2017;
	SET rider_template;
RUN;
