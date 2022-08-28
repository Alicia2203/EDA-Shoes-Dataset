/* ANALYTICS ENGINEERING GROUP ASSIGNMENT (SAS Enterprise Guide) */

/**************************** Accessing Data ****************************/
%LET inpath=C:\Users\User\Documents\My SAS Files\AE Assignment\Input;
%LET outpath=C:\Users\User\Documents\My SAS Files\AE Assignment\Output;
LIBNAME AECW "C:\Users\User\Documents\My SAS Files\AE Assignment\Output";
OPTIONS validvarname=v7;

PROC IMPORT datafile="&inpath\Men shoe prices.csv"  
	DBMS=CSV
	OUT= AECW.MenShoe_Import 
	REPLACE;
	guessingrows=max;
RUN;

/***************************Exploring data*****************************/
proc contents data=AECW.MenShoe_Import varnum;
Run;

proc print data=AECW.MenShoe_Import (firstobs=2 obs=5);
Run;

/**************************Data Preparation*****************************/

* Extract meaningful variables for analysis;
data AECW.MenShoe_UsefulVar;
	set AECW.MenShoeImport;
	price = round(mean(prices_amountMin, prices_amountMax),1);
	brand = UPCASE(brand); * Standardize brand name to capital letter;
	keep id brand prices_currency prices_amountMin prices_amountMax price;
run;

* Remove adjacent rows that are entirely duplicated.;
proc sort data=AECW.MenShoe_UsefulVar out=AECW.MenShoe_NoDups 
	nodupkey;
	by _all_;
run;

* Check the Frequency count for variable price_currency;
title "Frequency count for variable price_currency (before cleaning)";
proc freq data=AECW.MenShoe_NoDups nlevels;
	tables prices_currency / missing nocum nopercent;
run;

* Check the Frequency count for variable brand;
title "Frequency count for variable brand";
proc freq data =AECW.MenShoe_NoDups nlevels;
  tables brand/ missing nocum nopercent  
				out=MenBrand_freq10(where=(count>10));
run;

	
data AECW.MenShoe_Clean;
	set AECW.menshoe_nodups;

	* Clean oberservations which data has been read incorrectly in the price column;
		if id = "AVpe7ZLiLJeJML43yglY" then price = 119.79;
		else if id = "AVpe_F4BilAPnD_xSaI2" then price = 107.00;
		else if id = "AVpfEARPilAPnD_xUHSz" then price = 115.00;
		else if id = "AVpfKcs1LJeJML433u4w" then price = 114.87;
		else if id = "AVpfOiTgLJeJML435E6A" then price = 23.59;
		else if id = "AVpfPK_lLJeJML435Sc7" then price = 35.95;
		else if id = "AVpfQ9yKilAPnD_xYbdx" then price = 225.10;
		else if id = "AVpfUpYgLJeJML437D0P" then price = 35.99;
		else if id = "AVpfVOiALJeJML437Pu_" then price = 147.95;
		else if id = "AVpfYJenilAPnD_xaslU" then price = 94.99;
		else if id = "AVpfgGRcilAPnD_xc4DZ" then price = 225.10;
		else if id = "AVpfvrnKLJeJML43C9KK" then price = 225.10;
		else if id = "AVpfyWi1LJeJML43DuW5" then price = 118.36;
		else if id = "AVpfzZbh1cnluZ0-rkRN" then price = 163.99;
		else if id = "AVpgCgp6ilAPnD_xmcuZ" then price = 125.99;

		price = round(price,1);

    * Standardise the prices to USD as there contains several currencies
     (based on 13th November 2021 conversion rate);
	if prices_currency in ("USD","AUD","CAD","EUR","GBP") then 
		do;
			if prices_currency = "AUD" then price = round((price * 0.73),1);
			else if prices_currency = "CAD" then price = round((price * 0.8),1);
			else if prices_currency = "EUR" then price = round((price * 1.15),1);
			else if prices_currency = "GBP" then price = round((price * 1.34),1);
			prices_currency = "USD"; *now all price currency is in USD;
		end; 
	else prices_currency = .;

	* Selectively clean Popular Brand Names;
	if brand = " " or brand in ("UNBRAND", "UNBRANDED/GENERIC") then brand = "UNBRANDED";
	else if brand in ("N I K E", "NIKE - KOBE", "NIKE AIR JORDAN", "NIKE AIR JORDAN I",
					  "NIKE GOLF", "NIKE JORDAN FUTURE LOW", "NIKE LUNARGLIDE 7", "NIKE SB")
					  then brand = "NIKE";
	else if brand in ("LAUREN RALPH LAUREN","RALPH LAUREN PURPLE LABEL", "RALPH LAUREN RLX",
					  "RALPH LAUREN RRL" ,"RALPH LAUREN YACHT", "RLX RALPH LAUREN")
 					  then brand = "RALPH LAUREN";
	else if brand = "PUMA SAFETY SHOES" then brand = "PUMA";
	else if brand = "WOLVERINE" then brand = "WOLVERINE WORLDWIDE";
	else if brand = "HUGO BY HUGO BOSS"  then brand = "BOSS HUGO BOSS";
	else if brand = "ACADEMIE GEAR"  then brand = "ACADEMIE";
	else if brand in ( "ALEXANDERS", "ALEXANDER" ) then brand = "ALEXANDER MCQUEEN";

* Check the Frequency count for variable price_currency again after cleaning;
title "Frequency count for variable price_currency (after cleaning)";
proc freq data=AECW.MenShoe_Clean;
	tables prices_currency / missing nocum nopercent;
run;
title;

* Sort the data by descending prices;
proc sort data=AECW.MenShoe_Clean out= AECW.MenShoe_sortbyprice;
	by descending price;
run;

/**************************Data Output********************************/

* Output cleaned dataset as a csv file;
ODS CSVALL FILE="&outpath/MenShoe_Clean.csv";
proc print data=AECW.MenShoe_Clean noobs;
	var id brand price;
run;
ODS CSVALL CLOSE;


