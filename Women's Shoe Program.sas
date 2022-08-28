/* ANALYTICS ENGINEERING GROUP ASSIGNMENT (SAS Enterprise Guide) */

/****************************** Accessing Data ***************************/
%LET inpath=C:\Users\User\Documents\My SAS Files\AE Assignment\Input;
%LET outpath=C:\Users\User\Documents\My SAS Files\AE Assignment\Output;
LIBNAME AECW "C:\Users\User\Documents\My SAS Files\AE Assignment\Output";
OPTIONS validvarname=v7;

data AECW.WomenShoe_import;
	%let _EFIERR_ = 0;

	infile "&inpath\Women shoe prices.csv" delimiter=',' MISSOVER DSD firstobs=2;
	informat id $20.;
	informat asins $100.;
	informat brand $40.;
	informat categories $500.;
	informat colors $450.;
	informat count $1.;
	informat dateAdded B8601DZ35.;
	informat dateUpdated B8601DZ35.;
	informat descriptions $25522.;
	informat dimension $37.;
	informat ean best32.;
	informat features $2056.;
	informat flavors $1.;
	informat imageURLs $3160.;
	informat isbn $1.;
	informat keys $558.;
	informat manufacturer $35.;
	informat manufacturerNumber $94.;
	informat merchants $891.;
	informat name $279.;
	informat prices_amountMin $45.;
	informat prices_amountMax $26.;
	informat prices_availability $20.;
	informat prices_color $54.;
	informat prices_condition $16.;
	informat prices_count $5.;
	informat prices_currency $30.;
	informat prices_dateAdded $52.;
	informat prices_dateSeen $24.;
	informat prices_flavor $22.;
	informat prices_isSale $86.;
	informat prices_merchant $62.;
	informat prices_offer $101.;
	informat prices_returnPolicy $8237.;
	informat prices_shipping $109.;
	informat prices_size $36.;
	informat prices_source $83.;
	informat prices_sourceURLs $360.;
	informat prices_warranty $109.;
	informat quantities $124.;
	informat reviews $29683.;
	informat sizes $240.;
	informat skus $995.;
	informat sourceURLs $17314.;
	informat upc $109.;
	informat websiteIDs $109.;
	informat weight $85.;
	format id $20.;
	format asins $100.;
	format brand $40.;
	format categories $500.;
	format colors $450.;
	format count $1.;
	format dateAdded B8601DZ35.;
	format dateUpdated B8601DZ35.;
	format descriptions $25522.;
	format dimension $37.;
	format ean best12.;
	format features $2056.;
	format flavors $1.;
	format imageURLs $3160.;
	format isbn $1.;
	format keys $558.;
	format manufacturer $35.;
	format manufacturerNumber $94.;
	format merchants $891.;
	format name $279.;
	format prices_amountMin $45.;
	format prices_amountMax $26.;
	format prices_availability $20.;
	format prices_color $54.;
	format prices_condition $16.;
	format prices_count $5.;
	format prices_currency $30.;
	format prices_dateAdded $52.;
	format prices_dateSeen $24.;
	format prices_flavor $22.;
	format prices_isSale $86.;
	format prices_merchant $62.;
	format prices_offer $101.;
	format prices_returnPolicy $8237.;
	format prices_shipping $109.;
	format prices_size $36.;
	format prices_source $83.;
	format prices_sourceURLs $360.;
	format prices_warranty $109.;
	format quantities $124.;
	format reviews $29683.;
	format sizes $240.;
	format skus $995.;
	format sourceURLs $17314.;
	format upc $109.;
	format websiteIDs $109.;
	format weight $85.;
	input   id  $
	        asins  $
	        brand  $
	        categories  $
	        colors  $
	        count  $
	        dateAdded 
			dateUpdated 
			descriptions  $
	        dimension  $
	        ean 
			features  $
	        flavors  $
	        imageURLs  $
	        isbn  $
	        keys  $
	        manufacturer  $
	        manufacturerNumber  $
	        merchants  $
	        name  $
	        prices_amountMin  $
	        prices_amountMax  $
	        prices_availability  $
	        prices_color  $
	        prices_condition  $
	        prices_count  $
	        prices_currency  $
	        prices_dateAdded  $
	        prices_dateSeen  $
	        prices_flavor $
			prices_isSale  $
	        prices_merchant  $
	        prices_offer  $
	        prices_returnPolicy  $
	        prices_shipping  $
	        prices_size  $
	        prices_source  $
	        prices_sourceURLs  $
	        prices_warranty  $
	        quantities  $
	        reviews  $
	        sizes  $
	        skus  $
	        sourceURLs  $
	        upc  $
	        websiteIDs $
	        weight  $;

	if _ERROR_ then
		call symputx('_EFIERR_', 1);

run;

/**********************************Exploring data***************************/
proc contents data=AECW.WomenShoe_Import varnum;
Run;


/*********************************Data Preparation**************************/

* Extract meaningful variables for analysis;
data AECW.WomenShoe_UsefulVar;
	set AECW.WomenShoe_import;
/*	if prices_amountMin = ifc(missing(compress(prices_amountMin,,'d')),,.)*/
	price = round(mean(prices_amountMin, prices_amountMax),1);
	brand = UPCASE(brand);
	keep id brand prices_currency prices_amountMin prices_amountMax price;
run;

* Remove adjacent rows that are entirely duplicated.;
proc sort data=AECW.WomenShoe_UsefulVar out=AECW.WomenShoe_NoDups 
	nodupkey dupout= AECW.WomenShoe_Dups;
	by _all_;
run;

* Check the Frequency count for variable brand and price_currency;
title "Frequency count for variable brand";
proc freq data=AECW.WomenShoe_NoDups nlevels;
	tables brand / missing nocum nopercent;
run;

title "Frequency count for variable price_currency before cleaning";
proc freq data=AECW.WomenShoe_NoDups nlevels;
	tables prices_currency / missing nocum nopercent;
run;

* Check the Frequency count for variable brand with count larger than 10;
proc freq data =AECW.WomenShoe_NoDups;
  tables brand/ missing nocum nopercent noprint out=WomenShoeBrand_freq(where=(count>10));
run;

data AECW.WomenShoe_Clean;
	set AECW.WomenShoe_nodups;

    * Standardise the prices to USD as there contains several currencies
     (based on 13th November 2021 conversion rate);
	if prices_currency in ("USD","AUD","CAD","EUR","GBP") then 
		do;
			if prices_currency = "AUD" then price = round((price * 0.73),1);
			else if prices_currency = "CAD" then price = round((price * 0.8),1);
			else if prices_currency = "EUR" then price = round((price * 1.15),1);
			else if prices_currency = "GBP" then price = round((price * 1.34),1);
			prices_currency = "USD"; *now all price currency is USD;
		end; 
	else prices_currency = .;

	* Selectively clean Popular Brand Names;
	if brand = " " or brand in ("UNBRAND", "UNBRANDED/GENERIC", "UNBRNADED") then brand = "UNBRANDED";
	else if brand in ("LAUREN RALPH LAUREN", "RALPH BY RALPH LAUREN", "RALPH","LAUREN BY RALPH LAUREN")
 					  then brand = "RALPH LAUREN";
  	else if brand in ("MICHAEL MICHAEL KORS","MICAHEL KORS") THEN brand = "MICHAEL KORS";
    else if brand in ("PLEASER SHOES","PLEASEREUSA") THEN brand = "PLEASER";
	else if brand = "ADIDAS ORIGINALS" then brand = "ADIDAS";
	else if brand = "CHARLES BY CHARLES DAVID" then brand = "CHARLES DAVID";
	else if brand = "EASY SPIRIT E360" then brand = "EASY SPIRIT";
	else if brand = "ELLIE" then brand = "ELLIE SHOES";
	else if brand = "TAHARI BY ASL" then brand = "TAHARI ASL";

* Check the Frequency count for variable price_currency again after cleaning;
title "Frequency count for variable price_currency after cleaning";
proc freq data=AECW.WomenShoe_Clean;
	tables prices_currency / missing nocum nopercent;
run;
title;

* Sort the data by descending prices;
proc sort data=AECW.WomenShoe_Clean out= AECW.WomenShoe_sortbyprice;
	by descending price;
run;

/*******************************Data Output*****************************************/
* Output cleaned dataset as a csv file;
ODS CSVALL FILE="&outpath/WomenShoe_clean.csv";
proc print data=AECW.WomenShoe_Clean noobs;
	var id brand price;
run;
ODS CSVALL CLOSE;

/*proc means data=aecw.womenshoe_clean max;*/
/*	var price;*/
/*run;*/

