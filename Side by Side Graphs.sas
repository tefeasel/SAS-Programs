DATA labels;
    LENGTH text $1;
    RETAIN xsys ysys '2' hsys '3' function 'label' position '2' style '"swissx"';
    SET lgraph (rename=(bprice=y));
    WHERE year IN(2016 2017) AND month IN(2 3 4 5 10);
    text = cat(month);
RUN;

GOPTIONS FTEXT=swissx HTEXT=0.8;
SYMBOL1; SYMBOL2; SYMBOL3; SYMBOL4;SYMBOL5;SYMBOL6; SYMBOL7; SYMBOL8; SYMBOL9;
AXIS1 LABEL=(ANGLE=090 'Avg Base Rate Forecast');
AXIS2 LABEL=(' ');
LEGEND1 LABEL=none;

*Volume graph;
%MACRO GRAPHS1 (n= );

  %LOCAL i;

  GOPTIONS GOUTMODE = replace;

  %DO i = 1 %TO &n;

    %LET rotate = %SYSEVALF(90 * &i/&n);
    %LET tilt   = %SYSEVALF(90 * &i/&n);

PROC GPLOT DATA = lgraph;
  BY juris revcls;
  PLOT bprice*x = legend / VAXIS = axis1 HAXIS = axis2 GRID LEGEND = legend1 CFRAME = lightgray;
       SYMBOL1  V='0'           C=green           I=none        /*pointlabel = ("#month" c=black)*/;
       SYMBOL2  v='1'           C=blue            I=none        /*pointlabel = ("#month" c=black)*/;
       SYMBOL3  v='2'           C=orange          I=none        /*pointlabel = ("#month" c=black)*/;
       SYMBOL4  v='3'           C=yellow          I=none        /*pointlabel = ("#month" c=black)*/;
       SYMBOL5  v='4'           C=cyan            I=none        /*pointlabel = ("#month" c=black)*/;
       SYMBOL6  v='5'           C=red          	  I=none		pointlabel = ("#month" c=black);
       SYMBOL7  v='6'           C=brown           I=none        pointlabel = ("#month" c=black);
/*       SYMBOL8  v=dot           C=red             i=none		/*pointlabel = ("#month" c=black)*/;
       SYMBOL8  v=dot           C=purple          I=none        /*pointlabel = ("#month" c=black)*/;       
	TITLE1 "#BYVAL(juris) #BYVAL(revcls)...";
RUN; 
QUIT;
%END;
%MEND GRAPHS1;

*****************************************************************;
**********  Create Righthand Graph (Chronological) **************;
*****************************************************************;
DATA rgraph;
	SET master;
	WHERE year ge 2013;
	IF juris IN() AND revcls =  THEN DELETE;
	DATE=mdy(month,1,year); 
	FORMAT date MONYY5.;
RUN;

PROC SORT;
	BY juris revcls year month datatype ;
RUN;

*36 Month graph;
%MACRO GRAPHS2 (n= );

  %LOCAL i;

  GOPTIONS GOUTMODE = APPEND;

  %DO i = 1 %TO &n;

    %LET rotate = %SYSEVALF(90 * &i/&n);
    %LET tilt   = %SYSEVALF(90 * &i/&n);

PROC GPLOT DATA = rgraph;
	BY juris revcls;
	PLOT bprice*date = datatype / vaxis=axis1 HAXIS = axis2 GRID LEGEND = legend1 CFRAME = lightgray;
       	SYMBOL1  V = dot           C = blue            I = join        /*pointlabel=("#month" c=black)*/;
       	SYMBOL2  V = star          C = green           I = join        /*pointlabel=("#month" c=black)*/;
       	SYMBOL3  V = square        C = red             I = join        /*pointlabel=("#month" c=black)*/;
	   	SYMBOL4  V = diamond       C = orange          I = join        /*pointlabel=("#month" c=black)*/;
	TITLE1 "#BYVAL(juris) #BYVAL(revcls) Average Base Price" ;
RUN; 
QUIT;

%END;
%MEND GRAPHS2;

*Reset so graphs takes up whole page rather than limiting its size to previous specifications;
GOPTIONS RESET = ALL;
LEGEND1 LABEL = NONE;

*GREPLAY MACRO - This matches graphs by jurisdiction and revcls. Must change second %eval gplot # in order to match graphs. Simply go to 
work -> gseg and find where second set of graphs start and enter that number. For example, the first set of graphs are GPLOT to GPLOT51. 
Thus, this code matches GPLOT to GPLOT52, GPLOT1 to GPLOT53, and so forth. Can be adapted to add more output by a) changing template 
and b) adding TREPLAY statements and adjusting eval statement for any additional
TREPLAYs;

%MACRO MATCH (m= );

  %LOCAL i counter;

  %LET gplot = 0;
  %LET gplot74 = 74;

%DO i = 1 %to &m; 
PROC GREPLAY igout=work.gseg tc=work.tmplt nofs;
	TEMPLATE = hz1;
	TREPLAY
		1: gslide
		%LET gplot = %EVAL (&gplot+1);
        2: &gplot
        %LET gplot74 = %EVAL (&gplot74+1);
        3: &gplot74;
    RUN;
	QUIT;
%END;
%MEND MATCH;

%GRAPHS1 (n=1); *Keep at n=1 to do one graph per jurisdiction & revcls;
%GRAPHS2 (n=1);	*Same as above;

PROC GSLIDE GOUT = work.gseg;
	TITLE JUSTIFY = center "....by Volume and Month";
	FOOTNOTE " ";
RUN;
QUIT;

PROC GREPLAY IGOUT = work.gseg GOUT = work.gseg TC = work.tmplt NOFS;
	TDEF hz1 DES = 'Two Horizontal Panels'

		1/ulx=0 uly=100
		urx=100 ury=100
		llx=0 lly=0
		lrx=100 lry=0

		2/ulx=0 uly=90
		urx=50 ury=90
		llx=0 lly=10
		lrx=50 lry=10

		3/ulx=50 uly=90
		urx=100 ury=90
		llx=50 lly=10
		lrx=100 lry=10;
RUN;
QUIT;

%MATCH (m=74); *m should equal the number of pairs you want, or the number where the second set of plots starts;
