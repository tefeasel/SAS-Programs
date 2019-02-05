LIBNAME '';

DATA lags;
	SET lags;
	ind1 = lag1(col3);
	ind2 = lag2(col3);
	ind3 = lag3(col3);
	ind4 = lag4(col3);
	ind5 = lag5(col3);
	ind6 = lag6(col3);
	ind7 = lag7(col3);
	ind8 = lag8(col3);
	ind9 = lag9(col3);
	ind10 = lag10(col3);
	ind11 = lag11(col3);
	ind12 = lag12(col3);
	ind13 = lag13(col3);

	com1 = lag(col2);
	com2 = lag2(col2);
	com3 = lag3(col2);
	com4 = lag4(col2);
	com5 = lag5(col2);
	com6 = lag6(col2);
	com7 = lag7(col2);
	com8 = lag8(col2);
	com9 = lag9(col2);
	com10 = lag10(col2);
	com11 = lag11(col2);
	com12 = lag12(col2);
	com13 = lag13(col2);

	res1 = lag(col1);
	res2 = lag2(col1);
	res3 = lag3(col1);
	res4 = lag4(col1);
	res5 = lag5(col1);
	res6 = lag6(col1);
	res7 = lag7(col1);
	res8 = lag8(col1);
	res9 = lag9(col1);
	res10 = lag10(col1);
	res11 = lag11(col1);
	res12 = lag12(col1);
	res13 = lag13(col1);
RUN;

PROC EXPAND DATA = lags OUT = lags2 METHOD = none;
   ID modate;
   convert col1 = RES   / transout=(movave 12);
   convert col2 = COM   / transout=(movave 12);
   convert col3 = IND   / transout=(movave 12);
run;

PROC VARMAX DATA =  PLOTS = impulse;
/*	WHERE modate GE "01JUL2009"d;*/
	MODEL col2 col3 / p = 3 dftest dif = (col2(12) col3(12)) noint;
/*	CAUSAL group1 = (col3) group2 = (col1);*/
/*	CAUSAL group1 = (col3) group2 = (col2);*/
/*	CAUSAL group1 = (col3) group2 = (col1 col2);*/
/*	CAUSAL group1 = (col2) group2 = (col1);*/
/*	CAUSAL group1 = (col1) group2 = (col2);*/
RUN;

PROC AUTOREG DATA = ;
	MODEL col3 = / stationarity = (adf = 1);
RUN;

PROC AUTOREG DATA = ;
	MODEL col2 = ind1 ind2 / nlag=(1 2);
RUN;

%dftest(aep4, col3, dif = (0), dlag = 1, ar = 1, outstat = df);

proc print data = df noobs;
run;

data _null_; file print;
	pvalue = symget('dftest');
	put pvalue;
run;

PROC REG DATA =;
	WHERE year GE 2000;
	MODEL col1 = res1 com1; 
RUN;
QUIT;

