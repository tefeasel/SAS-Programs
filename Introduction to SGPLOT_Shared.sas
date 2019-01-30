/*Date: 10/12/2018*/
/*Title: Introduction to PROC SGPLOT*/

/*What is PROC SGPLOT?: Introduced in SAS 9.2 SGPLOT, SGSCATTER, SGPANEL, etc. are new proceedures
to produce high-quality graphs in relatively few lines of code. SGPLOT produces 16 different types of graphs. It creates
one or more graphs and overlays them on a shared set of axes.*/

/*Differences from traditional SAS/GRAPH:*/
/*	- graphs are produces in standard image files (PNG, JPEG, etc.) instead of being saved to a SAS catalog*/
/*	- graphs are viewed in standard viewers (e.g., web browser) instead of the graph window*/
/*	- GOPTIONS have no effect*/

/*Sources/References: */
/*http://support.sas.com/resources/papers/proceedings10/154-2010.pdf*/
/*https://support.sas.com/rnd/app/ODSGraphics/TipSheet_SGPLOT.pdf*/
/*http://support.sas.com/documentation/cdl/en/grstatproc/62603/HTML/default/viewer.htm#sgplot-ov.htm*/

/*Set HTML Settings*/
ODS HTML ON;

/*Set libname and path for images*/
LIBNAME sasusers ""; *Set where the data imported on line 25 and 229 are located;
ODS LISTING GPATH = ""; *Set where graphs should be saved;

DATA graph;
	SET sasusers.income_data;
	WHERE year le 2017;
	RENAME nominal_juris_median_hh_inc = hh_inc
		   nominal_state_median_hh_inc = state_hh_inc;
RUN;

PROC PRINT DATA = graph(OBS = 10) NOOBS;
RUN;

/*Basic syntax*/
/*Histogram*/
PROC SGPLOT DATA = graph;
	HISTOGRAM hh_inc;
RUN;

/*Time Series*/
PROC SGPLOT DATA = graph;
	WHERE juris = "APV";
	SERIES x = year y = rev_per_cust;
RUN;

/*Spaghetti Plot*/
PROC SGPLOT DATA = graph;
	SERIES x = year y = gwh / GROUP = juris;
RUN;

/*Scatter Plot*/
PROC SGPLOT DATA = graph;
	SCATTER x = cust y = rev ;
RUN;

/*Bar*/
PROC SGPLOT DATA = graph;
	WHERE juris = "APV";
	VBAR year / RESPONSE = hh_inc;
RUN;

PROC SGPLOT DATA = graph;
	WHERE juris = "APV";
	HBAR year / RESPONSE = hh_inc;
RUN;

/*Box plot (or use HBOX)*/
PROC SGPLOT DATA = graph;
	VBOX hh_inc / CATEGORY = juris;
RUN;

/*Other options: ellipse, density, dot, loess, regression, step, needle, etc.*/

/*Titles, labels, formatting*/
PROC SGPLOT DATA = graph;
	WHERE juris = "APV";
	SERIES x = year y = rev_per_cust;
	TITLE "APV Revenue Per Customer";
	XAXIS LABEL = "Year";
	YAXIS LABEL = "Revenue Per Customer (Nominal)";
	FORMAT rev_per_cust DOLLAR8.2;
RUN;

/*Going just a little beyond the basics for histogram, bar, time series, and scatter plots*/

/*Overlay histogram with kernel density plot*/
PROC SGPLOT DATA = graph;
	HISTOGRAM hh_inc;
	DENSITY hh_inc / TYPE = kernel; 
	TITLE "Histogram with Density Kernel";
	TITLE2 "Type can only be kernel or normal";
RUN;

/*Order matters*/
PROC SGPLOT DATA = graph;
	DENSITY hh_inc / TYPE = normal;
	HISTOGRAM hh_inc; 
	TITLE "Histogram with normal";
	TITLE2 "Order matters - now the kernel is hidden";
RUN;

/*Time Series - Add A Reference Line*/
PROC SGPLOT DATA = graph;
	WHERE juris = "APV";
	SERIES x = year y = rev_per_cust;
	TITLE "APV Revenue Per Customer";
	XAXIS LABEL = "Year";
	YAXIS LABEL = "Revenue Per Customer (Nominal)";
	FORMAT rev_per_cust DOLLAR8.2;
	REFLINE 2015;
RUN;

/*Notice it didn't work - refline defaults to the y-axis*/
PROC SGPLOT DATA = graph;
	WHERE juris = "APV";
	SERIES x = year y = rev_per_cust;
	TITLE "APV Revenue Per Customer";
	XAXIS LABEL = "Year";
	YAXIS LABEL = "Revenue Per Customer (Nominal)";
	FORMAT rev_per_cust DOLLAR8.2;
	REFLINE 2015 / AXIS = x;
RUN;

/*Change reference line attributes*/
PROC SGPLOT DATA = graph;
	WHERE juris = "APV";
	SERIES x = year y = rev_per_cust;
	TITLE "APV Revenue Per Customer";
	XAXIS LABEL = "Year";
	YAXIS LABEL = "Revenue Per Customer (Nominal)";
	FORMAT rev_per_cust DOLLAR8.2;
	REFLINE 2015 / AXIS = x LINEATTRS = (COLOR = red PATTERN = 2) LABEL = "Label Here";
RUN;

/*Refline for ranges are a bit more difficult - use a block statement with block = some binary variable in your dataset*/

/*Similarly change line attributes*/
PROC SGPLOT DATA = graph;
	WHERE juris = "APV";
	SERIES x = year y = rev_per_cust / LINEATTRS = (COLOR = red THICKNESS = 3);
	TITLE "APV Revenue Per Customer";
	XAXIS LABEL = "Year";
	YAXIS LABEL = "Revenue Per Customer (Nominal)";
	FORMAT rev_per_cust DOLLAR8.2;
	REFLINE 2015 / AXIS = x LINEATTRS = (COLOR = black);
RUN;

/*Add markers*/
PROC SGPLOT DATA = graph;
	WHERE juris = "APV";
	SERIES x = year y = rev_per_cust / LINEATTRS = (COLOR = red THICKNESS = 3) MARKERS;
	TITLE "APV Revenue Per Customer";
	XAXIS LABEL = "Year";
	YAXIS LABEL = "Revenue Per Customer (Nominal)";
	FORMAT rev_per_cust DOLLAR8.2;
	REFLINE 2015 / AXIS = x LINEATTRS = (COLOR = black);
RUN;

/*Change markers and Change Line Transparency*/
PROC SGPLOT DATA = graph;
	WHERE juris = "APV";
	SERIES x = year y = rev_per_cust / LINEATTRS = (COLOR = red THICKNESS = 3) MARKERS MARKERATTRS = (SIZE = 7 COLOR = black SYMBOL = "CircleFilled");
/*	You can also change the marker type with symbol = */
	TITLE "APV Revenue Per Customer";
	XAXIS LABEL = "Year";
	YAXIS LABEL = "Revenue Per Customer (Nominal)";
	FORMAT rev_per_cust DOLLAR8.2;
	REFLINE 2015 / AXIS = x LINEATTRS = (COLOR = black);
RUN;

/*Add second axis and Data labels*/
PROC SGPLOT DATA = graph;
	WHERE juris = "APV";
	SERIES x = year y = rev_per_cust / LINEATTRS = (COLOR = red THICKNESS = 3) DATALABEL = rev_per_cust; *Just add datalabel and the variable you want to have labeled;
	SERIES x = year y = gwh / Y2AXIS LINEATTRS = (COLOR = blue THICKNESS = 3);
	TITLE "APV Revenue Per Customer";
	XAXIS LABEL = "Year";
	YAXIS LABEL = "Revenue Per Customer (Nominal)";
	Y2AXIS LABEL = "GWh";
	FORMAT rev_per_cust DOLLAR9.2;
	REFLINE 2015 / AXIS = x LINEATTRS = (COLOR = black);
RUN;

/*Adjust Legend, adjust tick marks, and adjust text*/
PROC SGPLOT DATA = graph;
	WHERE juris = "APV";
	SERIES x = year y = rev_per_cust / LINEATTRS = (COLOR = red THICKNESS = 3) LEGENDLABEL = "Revenue/Cust."; 
	SERIES x = year y = gwh / Y2AXIS LINEATTRS = (COLOR = blue THICKNESS = 3);
	TITLE "APV Revenue Per Customer and GWH";
	KEYLEGEND / NOBORDER; *You can also control the legend position here;
	XAXIS LABEL = "Year" VALUES = (2010 to 2016 by 2) LABELATTRS = (COLOR=green FAMILY=arial Size = 14pt Weight= bold);
/*	You can do the same for titles, just use titleattrs=*/
	YAXIS LABEL = "Revenue Per Customer (Nominal)" MINOR;
	Y2AXIS LABEL = "GWh" MINOR;
	FORMAT rev_per_cust DOLLAR8.2;
	REFLINE 2015 / AXIS = x LINEATTRS = (COLOR = black);
RUN;

/*Turn off border and Save graph*/
ODS GRAPHICS / IMAGENAME = "final_time_series" NOBORDER;
/*Control image size with width= height= image_dpi= after the forward slash*/
PROC SGPLOT DATA = graph ;
	WHERE juris = "APV";
	SERIES x = year y = rev_per_cust / LINEATTRS = (COLOR = red THICKNESS = 3) LEGENDLABEL = "Revenue/Cust."; 
	SERIES x = year y = gwh / Y2AXIS LINEATTRS = (COLOR = blue THICKNESS = 3);
	TITLE "APV Revenue Per Customer and GWH";
	KEYLEGEND / NOBORDER; *You can also control the legend position here;
	XAXIS LABEL = "Year" VALUES = (2010 to 2016 by 2);
/*	You can do the same for titles, just use titleattrs=*/
	YAXIS LABEL = "Revenue Per Customer (Nominal)" MINOR;
	Y2AXIS LABEL = "GWh" MINOR;
	FORMAT rev_per_cust DOLLAR8.2;
	REFLINE 2015 / AXIS = x LINEATTRS = (COLOR = black);
RUN;
*************************************************************************;

/*Overlapping bar chart*/
PROC SGPLOT DATA = graph;
	WHERE year = 2016;
	VBAR juris / RESPONSE = hh_inc FILLATTRS = (COLOR = blue) LEGENDLABEL = "Jurisdiction" ;
	VBAR juris / RESPONSE = state_hh_inc FILLATTRS = (COLOR = red) BARWIDTH = .5 TRANSPARENCY = .3 LEGENDLABEL = "State";
	REFLINE 51314 / AXIS = y LABEL = "US" LINEATTRS = (COLOR=black);
	TITLE "Median Household Income in 2016";
	YAXIS LABEL = "Median Household Income";
	XAXIS LABEL = "Jurisdiction";
RUN;

DATA peaks;
	SET sasusers.peak_low_high;
	month = mdy(month, 1, 2017);
	FORMAT month MONNAME3.;
RUN;

/*Chart with table of data*/
TITLE "PSO Monthly Peaks, 2017 vs. Historical";
/*Used the following as the basis: /*https://blogs.sas.com/content/graphicallyspeaking/2011/11/23/sgplot-with-axis-aligned-statistics-columns/*/
PROC SGPLOT DATA = peaks NOAUTOLEGEND;
	BAND y = month lower = peak_min upper = peak_max / TRANSPARENCY = .6;
	SCATTER x = peak_max17 y = month / MARKERATTRS = (symbol = circlefilled color = red);
	SCATTER y = month x = peak_min / MARKERATTRS = (symbol = circlefilled size = 11)
		DATASKIN = sheen FILLEDOUTLINEDMARKERS;
	SCATTER y = month x = peak_max / MARKERATTRS = (symbol = circlefilled size = 11)
		DATASKIN = sheen FILLEDOUTLINEDMARKERS;
	YAXISTABLE peak_max17 / LABEL LOCATION = inside POSITION = left;
	YAXISTABLE  peak_date peak_max / LABEL LOCATION = inside POSITION = right;
	XAXIS DISPLAY = (nolabel) GRID;
	YAXIS DISPLAY = (nolabel noticks) COLORBANDS=odd;
	FORMAT peak_max17 peak_max peak_min COMMA9.1;
	LABEL peak_max17 = "'17 Peak" peak_max = "Peak" peak_date = "Hist. Peak Date";
RUN;

/*Overlay bar chart and line graph*/
PROC SGPLOT DATA = peaks;
	VBAR month / RESPONSE = peak_max STAT = sum NOSTATLABEL TRANSPARENCY = .6;
	VLINE month / RESPONSE = peak_max17 STAT = sum NOSTATLABEL y2axis LINEATTRS = (COLOR = red THICKNESS = 2);
	FORMAT peak_max17 peak_max COMMA9.1;
	LABEL peak_max17 = "'17 Peak" peak_max = "Hist. Peak" month = "Month";
RUN;

/*Try to sync y-axes*/
PROC SGPLOT DATA = peaks;
	VBAR month / RESPONSE = peak_max STAT = sum NOSTATLABEL TRANSPARENCY = .4;
	VLINE month / RESPONSE = peak_max17 STAT = sum NOSTATLABEL y2axis LINEATTRS = (COLOR = red THICKNESS = 2);
	FORMAT peak_max17 peak_max COMMA9.1;
	LABEL peak_max17 = "'17 Peak" peak_max = "Hist. Peak" month = "Month";
	YAXIS  min=0 max=4500;
    Y2AXIS min=0 max=4500;
RUN;

/*Gallery of examples:*/
/*https://support.sas.com/sassamples/graphgallery/PROC_SGPLOT.html*/





