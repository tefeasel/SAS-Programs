/*APA Stochastic Monte Carlo*/
PROC IMPORT
  DATAFILE = ''
  OUT = apa
  DBMS = CSV REPLACE;/*TAB is txt identifier*/
  GETNAMES=YES;
RUN;

%MACRO sim (n);

	%DO i = 1 %TO &n;

DATA X_Iter_&i;
	SET APA;
	  /*CREATE RANDOM NUMBERS GENERATOR FIRST*/
	GEN_RAND=RAND('NORMAL',1,.07);                 /*EVERY RUN GENERATES NEW RAND NUMBERS*/
	PRICE_RAND=RAND('NORMAL',1,.25);               /*SCALAR TO VARY PRICE AND GENERATION*/
	WIND_GWH=EXP_VAL_GWH*GEN_RAND;                 /*VARYING GENERATION*/
	CF_PCT=WIND_GWH*1000/CAPACITY_MW/8760;         /*VARYING CF*/
	AV_ENERGY_PRICE=EXP_VAL_FUNDPRICE*PRICE_RAND;  /*VARYING FUND PRICE*/
	AVOIDED_CST_M=AV_ENERGY_PRICE*WIND_GWH/1000*-1; FORMAT  AVOIDED_CST_M   DOLLAR10.2;     /*VARYING AVOIDED COST IN MILLIONS*/
	WIND_CAP_CREDIT=CAPACITY_MW*.05;               /*WIND GETS 5% CAPACITY CREDIT*/
	WIND_CAP_CR_VALUE=CAP_PRICE*WIND_CAP_CREDIT*365/1000000*-1;    /*NEGATIVE MAKES IT A BENEFIT*/

	DELTA_REV_RQ=TOTAL_COST_M+AVOIDED_CST_M+WIND_CAP_CR_VALUE; FORMAT DELTA_REV_RQ DOLLAR10.2;
	NCOE=DELTA_REV_RQ*1000/WIND_GWH;               /*$/MWH VALUE*/

	DROP GEN_STDEV PRICE_STDEV; 
RUN;

PROC SORT; 
	BY YEAR;
RUN;

DATA X2;
	SET X_Iter_&i;
	BY YEAR ;
	RETAIN CUM_PV WindEnergy_PW CapFac WindCst_PW TotalCst_PW AvoidEnergyCst_PW CapPriceMW_PW CapCreditMW_PW CapCreditM_PW Delta_Rev_Rq_PW 0
	  		lvl_windenergy lvl_cap_fac lvl_windenergy_cst lvl_wind_tot_cst lvl_avoid_price lvl_avoid_cst lvl_cap_price lvl_cap_cred_mw lvl_cap_cred_M lvl_delta_rev_rq lvl_ncoe 0;
	  /*CREATE RANDOM NUMBERS GENERATOR FIRST*/
	GEN_RAND=RAND('NORMAL',1,.07);                 /*EVERY RUN GENERATES NEW RAND NUMBERS*/
	PRICE_RAND=RAND('NORMAL',1,.25);               /*SCALAR TO VARY PRICE AND GENERATION*/

	WIND_GWH=EXP_VAL_GWH*GEN_RAND;                 /*VARYING GENERATION*/
	CF_PCT=WIND_GWH*1000/CAPACITY_MW/8760;         /*VARYING CF*/
	AV_ENERGY_PRICE=EXP_VAL_FUNDPRICE*PRICE_RAND;  /*VARYING FUND PRICE*/
	AVOIDED_CST_M=AV_ENERGY_PRICE*WIND_GWH/1000*-1; FORMAT  AVOIDED_CST_M   DOLLAR10.2;     /*VARYING AVOIDED COST IN MILLIONS*/
	WIND_CAP_CREDIT=CAPACITY_MW*.05;               /*WIND GETS 5% CAPACITY CREDIT*/
	WIND_CAP_CR_VALUE=CAP_PRICE*WIND_CAP_CREDIT*365/1000000*-1;    /*NEGATIVE MAKES IT A BENEFIT*/
	DELTA_REV_RQ=TOTAL_COST_M+AVOIDED_CST_M+WIND_CAP_CR_VALUE; FORMAT DELTA_REV_RQ DOLLAR10.2;
	NCOE=DELTA_REV_RQ*1000/WIND_GWH;               /*$/MWH VALUE*/

	CUM_PV + PV_FACTOR;
	/*  First part in the sum part; paranthesis is the product*/
	WindEnergy_PW + (PV_FACTOR*WIND_GWH);
	CapFac + (PV_factor*cf_pct);
	WindCst_PW + (PV_FACTOR*Wind_energy_cst_mwh);
	TotalCst_PW + (PV_FACTOR*Total_Cost_M);
	AvoidEnergyCst_PW + (PV_FACTOR*Avoided_Cst_M);
	CapPriceMW_PW + (PV_FACTOR*Cap_Price);
	CapCreditM_PW + (PV_FACTOR*WIND_CAP_CR_VALUE);
	CapCreditMW_PW + (PV_FACTOR*WIND_CAP_CREDIT);
	Delta_Rev_Rq_PW + (PV_FACTOR*Delta_Rev_Rq);

/*  Create macro &pv_factor to help calculate the levelized line in excel*/
		IF last.year THEN DO;
		 CALL SYMPUT('pv_factor', cum_pv);
		END;
RUN;

DATA _NULL_;
	SET x2;
	BY year;
/* Create levelized numbers*/
	lvl_windenergy = windenergy_pw/&pv_factor;
	lvl_cap_fac = (capfac/&pv_factor);
	lvl_wind_tot_cst = (totalcst_pw/&pv_factor);
	lvl_windenergy_cst = (lvl_wind_tot_cst/lvl_windenergy)*1000;
	lvl_avoid_cst = (AvoidEnergyCst_PW/&pv_factor);
	lvl_avoid_price = (-lvl_avoid_cst/lvl_windenergy)*1000;
	lvl_cap_price = (CapPriceMW_PW/&pv_factor);
	lvl_cap_cred_mw = (CapCreditMW_PW/&pv_factor);
	lvl_cap_cred_m = (-lvl_cap_cred_mw*lvl_cap_price*365)/1000000;
	lvl_delta_rev_rq = (delta_rev_rq_pw/&pv_factor);
	lvl_ncoe = (lvl_delta_rev_rq/lvl_windenergy)*1000;

	IIIIIIII = LEFT(PUT(&i, 8.)); *Creates a variable that equals the loop interation value. Put converts a numeric (&i) to character.;
							  	  *This is then used below to create n macro variables; 
								  *Number of "I" on left hand side and below should correspond to length specified in put;

		IF last.year THEN DO;
		 	CALL SYMPUT('ncoe'||IIIIIIII, lvl_ncoe);
		END;

%put &ncoe1 &ncoe2 &ncoe7 &ncoe99 &ncoe101;

	DROP GEN_STDEV PRICE_STDEV; 
RUN;

%END;

DATA final;
	%DO draw = 1 %TO &n;
		draw = &draw;
		ncoe = &&ncoe&draw;
	OUTPUT;
	%END;
RUN;

%MEND sim;

/*Set n equal to the number of draws you want - It can be up to 8 digits without adjusting the code*/
/*It takes about 90 seconds to run 1000 iterations*/
/*It will take about 10-15 minutes to run 5000 iterations*/
/*Anything more is probably best run overnight*/
/*If running more than 500 iterations, best to suppress the log below:*/

/*options nonotes nosource nosource2 errors=0;*/
%SIM (101);

TITLE1 "Summary Statistics from Monte Carlo Simulation of Net Cost of Energy";
PROC MEANS DATA = final MIN MAX STD MEAN;
	VAR ncoe;
RUN;

