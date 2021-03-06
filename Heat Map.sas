PROC GPROJECT DATA = MAPS.COUNTY OUT = APCOMAP;
	ID STATE COUNTY;
	WHERE STATE IN (47 51 54);
RUN;
QUIT;

PROC GREMOVE DATA = APCOMAP OUT = STATES;
	BY STATE;
	ID STATE COUNTY;
RUN;
QUIT;

DATA STATES;
  SET STATES;
  BY STATE;
  RETAIN FLAG NUM 0;

  /* RESET THE FLAG VALUE FOR EACH STATE */
  IF FIRST.STATE THEN DO;
     FLAG=0;
     NUM=0;
  END;

  /* SET THE FLAG VALUE WHEN X AND Y ARE MISSING */
  IF X=. AND Y=. THEN DO;
    FLAG=1;
    NUM + 1;
    DELETE;
  END;

  /* INCREMENT THE SEGMENT VALUE */
  IF FLAG=1 THEN SEGMENT + NUM;
  DROP FLAG NUM;
RUN;

DATA ANNO_OUTLINE;
  LENGTH FUNCTION COLOR $8;
  RETAIN XSYS YSYS '2' WHEN 'A' COLOR 'BLACK' SIZE 2;
  DROP XSAVE YSAVE;

  SET STATES;
  BY STATE SEGMENT;

  /* MOVE TO THE FIRST COORDINATE */
  IF FIRST.SEGMENT THEN FUNCTION='POLY';
   
  /* DRAW TO EACH SUCCESSIVE COORDINATE */
  ELSE FUNCTION='POLYCONT';
  OUTPUT;
RUN;

ODS LISTING;
GOPTIONS RESET=GLOBAL NOBORDER ;
PATTERN1 C=LIGHTGREEN ;
PATTERN2 C=VERYLIGHTYELLOW ;
PATTERN3 C=VERYLIGHTRED ;
PATTERN4 C=DARKRED ;
LEGEND1 LABEL=NONE VALUE =(HEIGHT = 2.5PCT);

PROC GMAP MAP=APCOMAP DATA=MAP ANNO = ANNO_OUTLINE UNIFORM ALL ;
ID STATE COUNTY ;
TITLE1 H=3   "HEAT MAP 2021" ;
TITLE2 H=2 "(SHARE OF MEDIAN HOUSEHOLD INCOME)" ;

FOOTNOTE1 H=1 J=L "(INCL.)" ;
CHORO BILLSHARE / CDEFAULT=LIGHTGRAY COUTLINE=BLACK LEGEND=LEGEND1
              MIDPOINTS=(.02 .03 .04 .05) RANGE LEGEND=LEGEND1 COUTLINE = GRAY;
FORMAT BILLSHARE PERCENT8.1 ;
RUN ;
QUIT ;
ODS LISTING CLOSE;
