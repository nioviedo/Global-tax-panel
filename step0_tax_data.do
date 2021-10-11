********************************************************************************
*** Compile taxes raw sources and plots
********************************************************************************
*** Input: veghdata.xlsx, tax foundation cap gains, pwc tax, tax foundation dep
*** Output: tax_data
*** Author: Erin Markiewitz 
*** Edited by: Nicolas Oviedo
*** Original: 10/04/2020
*** This version: 03/23/2021
********************************************************************************
*** Set up
********************************************************************************
clear
set more off

********************
*User Settings
********************
*User: andres
//global who = "A" 

*User: Nicolas
global who = "N" 

*User: Isaac
//global who = "I"

*User: Erin
//global who = "E"

********************************************************************************	
*** Paths and Logs            
********************************************************************************
if "$who" == "E" global pathinit "/Users/erinmarkiewitz/Documents/BlancoBaleyTax/data"
*cd /Users/erinmarkiewitz/Documents/BlancoBaleyTax/data/do_files
if "$who" == "N"  global pathinit "C:\Users\Ovi\Desktop\R.A"

global output_data "$pathinit/Data/outputs"
global input_data  "$pathinit/Data/inputs/Cross country tax data"
global temp_file   "$pathinit/Data/Temp"

cap log close
log using "$temp_file/AEJ_EP_Tables.log", append

cd "$input_data"
*This step is important. Note that all files will be saved assuming this line has been run

********************************************************************************
*** Import Vegh Data
********************************************************************************
import excel "$CorporatePersonalIncome/veghdata.xlsx", sheet("Data") firstrow  clear
replace vat_tr = . if vat_tr == -999
tempfile vdata
save `vdata'

********************************************************************************
*** Import and Label Tax Foundation Capital Gains Data
********************************************************************************
*local tf_data_path = "../inputs/Cross country tax data/CapitalGain/international-tax-competitiveness-index-master/final_data"
local tf_data_path = "$input_data/Cross country tax data/CapitalGain/international-tax-competitiveness-index-master/final_data"

local myfilelist : dir "`tf_data_path'" files"*.csv"

tempfile temp
local inlisst = ""
foreach file of local myfilelist {
	local name = "`tf_data_path'/`file'"
	di "`name'"
	preserve 
	insheet using  "`name'",clear
	destring index_capital_gains ,replace force 
	save `temp',replace
	restore
	append using `temp'
}

keep iso_3 year capital_gains_rate index_capital_gains capital_gains_exemption
ren iso_3 wb_code 
ren index_capital_gains capital_gains_index

lab var capital_gains_rate "capital gains tax rate after any imputation, credit, or offset. no time lag."
lab var capital_gains_index "Whether a country indexes basis for purposes of capital gains tax. No longer in use."
lab var capital_gains_exemption "Percentage of capital gains from foreign investments which are exempted from domestic taxes. No time lag."

drop if wb_code ==""
 
tempfile capgains_data
save `capgains_data'

********************************************************************************
*** Import and Label Capital Gains Data from alternative sources
********************************************************************************
clear all

*import delim "../inputs/Cross country tax data/CapitalGain/capital_gains_alternative_sources.csv",clear
import delim "$inpunt_data/Cross country tax data/CapitalGain/capital_gains_alternative_sources.csv",clear
ren country wb_code
lab var capital_gains_rate_pwc "capital gains tax rate listed in pwc 2019 report."
lab var pwc_index 				"0-no data, 1 - does not contradicts tf, 2 - contradicts tf"
lab var capital_gains_rate_other "capital gains tax rates from other sources"

merge 1:1 wb_code year using `capgains_data', nogen
replace capital_gains_rate = capital_gains_rate_pwc if pwc == 1
replace capital_gains_rate = capital_gains_rate_other if capital_gains_rate_other~=.


save `capgains_data', replace

********************************************************************************
*** Import and Label Tax Foundation Depreciation Data
********************************************************************************
*import delimited "../inputs/cost_recovery_data.csv", clear 
import delimited "$input_data/cost_recovery_data.csv", clear 
ren country wb_code
merge 1:1 wb_code year using `vdata', nogen
merge 1:1 wb_code year using `capgains_data', nogen
lab var taxdepbuildtype "SL-line;DB-geo;DB or SL-geo switch line;SL2-changing line;initialDB: geo w/ init."
lab var taxdepmachtype "SL-line;DB-geo;DB or SL-geo switch line;SL2-changing line;initialDB: geo w/ init."
lab var taxdepintangibltype "SL-line;DB-geo;DB or SL-geo switch line;SL2-changing line;initialDB: geo w/ init."
lab var taxdeprbuilddb "If DB/DB or SL, then dep rate; If SL2, then the first applicable dep rate."
lab var taxdeprmachdb "If DB/DB or SL, then dep rate; If SL2, then the first applicable dep rate."
lab var taxdeprintangibldb "If DB/DB or SL, then dep rate; If SL2, then the first applicable dep rate."
lab var taxdeprintangiblsl "If SL, then dep rate; If SL2, then the second applicable dep rate."
lab var taxdeprmachsl "If SL, then dep rate (machines); If SL2, then the second applicable dep rate."
lab var taxdeprbuildsl "If SL, then dep rate (buildings); If SL2, then the second applicable dep rate."
lab var taxdeprintangiblsl "If SL, then dep rate (intagibles); If SL2, then the second applicable dep rate."
lab var taxdeprbuildtimedb "Years the first rate is applicable (buildings)."
lab var taxdepmachtimedb "Years the first rate is applicable (machines)."
lab var taxdepintangibltimedb "Years the first rate is applicable (intangibles)."
lab var taxdepintangibltimesl "Years the second rate is applicable (intangibles)."
lab var taxdepmachtimesl "Years the second rate is applicable (machines)."
lab var taxdeprbuildtimesl "Years the second rate is applicable (buildings)."
lab var eatr "Effective average tax rate"
lab var emtr "Effective marginal tax rate"
lab var inventoryval "LIFO/avg/FIFO. If mult. options, optimal is chosen by rank 1)LIFO,2) avg,3)FIFO."


ren taxdeprbuildtimedb taxdepbuildtimedb
ren taxdeprbuildtimesl taxdepbuildtimesl


********************************************************************************
*** Import and Apply Country Codes
********************************************************************************
preserve
*import delimited "../inputs/country_codes.csv", clear 
import delimited "$input_data/country_codes.csv", clear 
keep official_name_en iso31661alpha3 iso31661numeric
ren iso31661alpha3 wb_code
ren iso31661numeric iso_num
tempfile country_codes
save `country_codes'
restore

********************************************************************************
*** Merge Data
********************************************************************************
merge m:1 wb_code using `country_codes',nogen keep(3)
drop country 
ren official_name_en country
encode wb_code, gen(panelcode)
xtset panelcode year
order wb_code year vat_tr corporate_tr individual_tr

********************************************************************************
*** Define Samples and Subsamples 
********************************************************************************
gen tpfd = 0
replace tpfd = 1  if  inlist(country, "Australia" ,"Austria", "Brazil", "Canada","China","Czech Rep.", "Denmark", "France", "Greece")
replace tpfd = 1  if  inlist(country, "Germany", "India" ,"Ireland", "Italy", "Japan", "Korea", "Luxembourg", "Mexico", "Poland") 
replace tpfd = 1  if  inlist(country, "Portugal", "Spain", "Turkey", "United Kingdom of Great Britain and Northern Ireland", "United States of America")

gen afe = 0
replace afe = 1 if  inlist(country, "Australia" ,"Austria","Canada", "Denmark", "France", "Germany","Ireland", "Italy", "Japan" )
replace afe = 1 if  inlist(country,  "Spain","United Kingdom of Great Britain and Northern Ireland", "United States of America", "Luxembourg")


gen europe = 0
replace europe = 1 if  inlist(country, "Austria","Czech Rep.", "Denmark", "France", "Greece", "Germany", "Ireland", "Italy", "Luxembourg")
replace europe = 1  if  inlist(country,  "Poland", "Portugal", "Spain", "Turkey", "United Kingdom of Great Britain and Northern Ireland", "United States of America")

replace corporate_tr = . if corporate_tr == -999
replace individual_tr = . if individual_tr == -999

gen oecd = 0
replace oecd = 1 if inlist(wb_code, "ARG", "AUS", "AUT", "BEL", "BIH", "BRA","CAN" , "CHE", "CHL")
replace oecd = 1 if inlist(wb_code, "CHN", "CHZ", "DEU", "DNK", "ESP", "EST","FIN", "FRA", "GBR")
replace oecd = 1 if inlist(wb_code, "GRC", "HUN", "IDN", "IND", "IRL", "ISL", "ISR", "ITA", "JPN")
replace oecd = 1 if inlist(wb_code, "KOR", "LTU", "LUX", "LVA", "MEX", "NLD", "NOR", "NZL")
replace oecd = 1 if inlist(wb_code, "POL", "PRT", "RUS", "SAU", "SRB", "SVK", "SVN", "SWE", "TUR")
replace oecd = 1 if inlist(wb_code, "UKR", "USA", "ZAF")

********************************************************************************
*** Compute Present Discounted Value of Depreciation Allowances
********************************************************************************
local mach_w    = .4391081
local build_w   = .4116638
local intan_w   = .1492281
local disc_rate = 0.075
local mach_dep  = 0.11
local build_dep = 0.03
local intan_dep = .15
local dep_rate  = `build_w' * `build_dep' + `mach_w' * `mach_dep' + `intan_w'  * `intan_dep'


local vlist = "build mach intangibl"
foreach iv of local vlist {

* rename odd depreciation systems
replace taxdep`iv'type = "SL2" if taxdep`iv'type =="SL3"
replace taxdep`iv'type = "initialDB" if taxdep`iv'type =="DB DB SL"
replace taxdep`iv'type = substr(taxdep`iv'type,1,3) if wb_code == "CZE" | wb_code == "SVK"


* Present Discounted Value of Straight Line Depreciation
gen pdv_sl_`iv' = 0
replace pdv_sl_`iv' = ((taxdepr`iv'sl*(1+`disc_rate'))/`disc_rate')*(1-(1^(1/taxdepr`iv'sl)/(1+`disc_rate')^(1/taxdepr`iv'sl))) if taxdep`iv'type == "SL"
replace pdv_sl_`iv' =  0 if taxdepr`iv'sl ==0 & taxdep`iv'type == "SL"

* Present Discounted Value of Straight Line Depreciation (w/ 2 rates)
gen pdv_sl2_`iv' = 0
replace pdv_sl2_`iv' = ((taxdepr`iv'db*(1+`disc_rate'))/`disc_rate')*(1-(1^taxdep`iv'timedb)/(1+`disc_rate')^taxdep`iv'timedb) ///
					 + ((taxdepr`iv'sl*(1+`disc_rate'))/`disc_rate')*(1-(1^taxdep`iv'timesl)/(1+`disc_rate')^taxdep`iv'timesl) / (1+`disc_rate')^taxdep`iv'timedb if taxdep`iv'type == "SL2"

* Present Discounted Value of Decreasing Base Depreciation
gen pdv_db_`iv' = 0
replace pdv_db_`iv' = (taxdepr`iv'db*(1+`disc_rate'))/(`disc_rate'+taxdepr`iv'db) if taxdep`iv'type == "DB"

* Present Discounted Value of Decreasing Base Depreciation w/ initial allowance
gen pdv_idb_`iv' = 0
replace pdv_idb_`iv' = taxdepr`iv'db + ((taxdepr`iv'sl*(1+`disc_rate'))/(`disc_rate'+taxdepr`iv'sl)*(1-taxdepr`iv'db))/(1+`disc_rate') if taxdep`iv'type == "initialDB"

* Present Discounted Value of Decreasing Base Depreciation that switches to straight line during lifespan
gen pdv_dbsl2_`iv' = 0
replace pdv_dbsl2_`iv' = ((taxdepr`iv'db+(taxdepr`iv'sl/((1+`disc_rate')^taxdep`iv'timedb))/taxdep`iv'timesl )*(1+`disc_rate'))/(`disc_rate' + (taxdepr`iv'db+(taxdepr`iv'sl/((1+`disc_rate')^taxdep`iv'timedb))/taxdep`iv'timesl)) if taxdep`iv'type == "DB or SL"


* Present Discounted Value of Special Italian Regime Straight Line Depreciation 
gen pdv_slita_`iv' = 0
replace pdv_slita_`iv' =  taxdepr`iv'sl + (((taxdepr`iv'sl *2)*(1+`disc_rate'))/`disc_rate')*(1-(1^(2)/(1+`disc_rate')^(2)))/(1+`disc_rate') ///
                       + ((taxdepr`iv'sl *(1+`disc_rate'))/`disc_rate')*(1-(1^(taxdep`iv'timesl-3)/(1+`disc_rate')^(taxdep`iv'timesl-3)))/(1+`disc_rate')^3 if taxdep`iv'type == "SLITA"

}

	
local N = _N 
foreach iv of local vlist {
	gen pdv_czk_`iv' = 0
	forvalues i = 1/`N' {
		if taxdep`iv'type[`i'] == "CZK"{
			local value = 1
			local years = round(((1/taxdepr`iv'db[`i'])-1))
			
			di `years'
			forvalues x = 0/`years' {
				if `x' == 0 {
					replace pdv_czk_`iv' = pdv_czk_`iv'[`i'] + taxdepr`iv'db[`i'] in `i'
					local value = `value' - taxdepr`iv'db[`i']
				}
				else {
					replace pdv_czk_`iv' = pdv_czk_`iv'[`i']  + (((`value'*2)/((1/taxdepr`iv'db[`i'])-`x'+1))/(1+`disc_rate')^`x') in `i'
					local value = `value' - ((`value'*2)/((1/taxdepr`iv'db[`i'])-`x'+1)) in `i'
				}
			}
		}
	}
}

foreach iv of local vlist {
gen pdv_`iv' = pdv_slita_`iv' + pdv_dbsl2_`iv' + pdv_idb_`iv' + pdv_db_`iv' + pdv_sl2_`iv' + pdv_czk_`iv' +pdv_sl_`iv'

replace pdv_slita_`iv' = . if pdv_slita_`iv' == 0 & taxdep`iv'type ==""
replace pdv_dbsl2_`iv' = . if pdv_dbsl2_`iv' == 0 & taxdep`iv'type ==""
replace pdv_idb_`iv'   = . if pdv_idb_`iv'   == 0 & taxdep`iv'type ==""
replace pdv_db_`iv'    = . if pdv_db_`iv'    == 0 & taxdep`iv'type ==""
replace pdv_sl2_`iv'   = . if pdv_sl2_`iv'   == 0 & taxdep`iv'type ==""
replace pdv_sl_`iv'    = . if pdv_sl_`iv'    == 0 & taxdep`iv'type ==""
replace pdv_czk_`iv'   = . if pdv_czk_`iv'   == 0 & taxdep`iv'type ==""
replace pdv_`iv'       = . if taxdep`iv'type ==""

*In 2000, Estonia moved to a cash-flow type business tax - all allowances need to be coded as 1
replace pdv_`iv' = 1 if wb_code == "EST" & year>=2000

*In 2018, Latvia moved to a cash-flow type business tax - all allowances need to be coded as 1
replace pdv_`iv' = 1 if wb_code == "LVA" & year>=2018
}

*In fall 2018, Canada introduced full expensing for machinery
replace pdv_mach = 1 if wb_code == "CAN" & year>=2018

*Adjust for USA Bonus Depreciation Following Tax Foundation approach
replace pdv_mach = pdv_mach * .7 + .3 if wb_code == "USA" & year>=2002
replace pdv_mach = pdv_mach * .7 + .3 if wb_code == "USA" & year>=2003
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year>=2004
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year>=2008
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year>=2009
replace pdv_mach = pdv_mach *  0 +  1 if wb_code == "USA" & year>=2010
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year>=2011
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year>=2012
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year>=2013
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year>=2014
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year>=2015
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year>=2016
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year>=2017
replace pdv_mach = pdv_mach *  0 +  1 if wb_code == "USA" & year>=2018
replace pdv_mach = pdv_mach *  0 +  1 if wb_code == "USA" & year>=2019

gen pdv_tot = `mach_w' *pdv_mach + `build_w' *pdv_build + `intan_w' *pdv_intangibl

gen geo_dep_tot = pdv_tot*(`disc_rate'+ `dep_rate')
gen geo_dep_mach = pdv_mach*(`disc_rate'+ `mach_dep')
gen geo_dep_build = pdv_build*(`disc_rate'+ `build_dep')
gen geo_dep_intan = pdv_intangibl*(`disc_rate'+ `intan_dep')


gen dgeo_dep_tot = geo_dep_tot-l.geo_dep_tot

********************************************************************************
*** label variables 
********************************************************************************
lab var wb_code "World Bank Code"
lab var year "Calendar Year"
lab var country "Country Name"
lab var panelcode "Country Code for Panel"
lab var tpfd "Countries in IMF tax database - Binary"
lab var afe "Advanced Foreign Economies - Binary" 
lab var europe "European Economies - Binary" 
lab var oecd "OECD Economies - Binary" 
lab var pdv_sl_build "Present Discounted Value of SL dep allowance - Buildings (if applicable)" 
lab var pdv_sl2_build "Present Discounted Value of SL2 dep allowance - Buildings (if applicable)" 
lab var pdv_db_build "Present Discounted Value of DB dep allowance - Buildings (if applicable)" 
lab var pdv_idb_build "Present Discounted Value of IDB dep allowance - Buildings (if applicable)" 
lab var pdv_dbsl2_build "Present Discounted Value of DB SL2 dep allowance - Buildings (if applicable)" 
lab var pdv_slita_build "Present Discounted Value of SL-Italy dep allowance - Buildings (if applicable)" 

lab var pdv_sl_mach "Present Discounted Value of SL dep allowance - Machines (if applicable)" 
lab var pdv_sl2_mach "Present Discounted Value of SL2 dep allowance - Machines (if applicable)" 
lab var pdv_db_mach "Present Discounted Value of DB dep allowance - Machines (if applicable)" 
lab var pdv_idb_mach "Present Discounted Value of IDB dep allowance - Machines (if applicable)" 
lab var pdv_dbsl2_mach "Present Discounted Value of DB SL2 dep allowance - Machines (if applicable)" 
lab var pdv_slita_mach "Present Discounted Value of SL-Italy dep allowance - Machines (if applicable)" 

lab var pdv_sl_intangibl "Present Discounted Value of SL dep allowance - Intangibles (if applicable)" 
lab var pdv_sl2_intangibl "Present Discounted Value of SL2 dep allowance - Intangibles (if applicable)" 
lab var pdv_db_intangibl "Present Discounted Value of DB dep allowance - Intangibles (if applicable)" 
lab var pdv_idb_intangibl "Present Discounted Value of IDB dep allowance - Intangibles (if applicable)" 
lab var pdv_dbsl2_intangibl "Present Discounted Value of DB SL2 dep allowance - Intangibles (if applicable)" 
lab var pdv_slita_intangibl "Present Discounted Value of SL-Italy dep allowance - Intangibles (if applicable)" 

lab var pdv_czk_build "Present Discounted Value of CZE/SVK dep allowance - Buildings (if applicable)" 
lab var pdv_czk_mach "Present Discounted Value of CZE/SVK dep allowance - Machines (if applicable)" 
lab var pdv_czk_intangibl "Present Discounted Value of CZE/SVK dep allowance - Intangibles (if applicable)" 

lab var pdv_build "Present Discounted Value of dep allowance - Buildings (if applicable)" 
lab var pdv_mach "Present Discounted Value of dep allowance - Machines (if applicable)" 
lab var pdv_intangibl "Present Discounted Value of dep allowance - Intangibles (if applicable)" 
lab var pdv_tot "Present Discounted Value of dep allowance - Total" 

lab var geo_dep_tot "Implied geometric dep allowance - Total" 
lab var geo_dep_build "Implied geometric dep allowance - Buildings (if applicable)" 
lab var geo_dep_mach "Implied geometric dep allowance - Machines (if applicable)" 
lab var geo_dep_intan "Implied geometric dep allowance - Intangibles (if applicable)" 
lab var dgeo_dep_tot "Change in implied geometric dep allowance - Total" 

********************************************************************************
*** save data set 
********************************************************************************
*save ../outputs/tax_data.dta, replace
save "$output_data/tax_data.dta" replace

/*
********************************************************************************
*** Plot 3 Countries (USA/DEU/CHL) figure
********************************************************************************
replace corporate_tr  = corporate_tr/100
replace individual_tr = individual_tr/100
replace vat_tr = vat_tr/100

lab var geo_dep_tot "Depreciation Allowance - {&xi}{superscript:d}"
lab var corporate_tr "Corporate Income Tax - {&tau}{superscript:c}"
lab var individual_tr "Personal Income Tax - {&tau}{superscript:p}"


#delim ;
 xtline geo_dep_tot if inrange(year,1970,2020) & inlist(wb_code,"USA","DEU","CHL"), overlay
name(f3c1,replace) 
title("Depreciation Allowance", size(medium)) 
scheme(plotplainblind) 
legend(off)  
ytitle({&xi}{superscript:d},size(large) angle(90))
xscale(range(1970 2020)) 
xlabel(1970(10)2020) 
yscale(range(0.06 .12))
ylabel(0.06(.01) .12)
ttitle("Year", size(medium))
;
gr export ../figures/motivation_igd_3countries.png, replace;


xtline corporate_tr if inrange(year,1970,2020) & inlist(wb_code,"USA","DEU","CHL"), overlay
name(f3c2,replace) 
title("Corporate Income Tax", size(medium)) 
legend(off)  
scheme(plotplainblind) 
xscale(range(1970 2016)) 
yscale(range(0.1 .80)) 
ttitle("Year", size(medium))
ytitle({&tau}{superscript:c},size(large) angle(180))
xlabel(1970(10)2020) 
ylabel(0.1(.1).80)
;

gr export ../figures/motivation_cit_3countries.png, replace;

xtline individual_tr if inrange(year,1970,2020) & inlist(wb_code,"USA","DEU","CHL"), overlay
name(f3c3,replace)  
title("Personal Income Tax", size(medium)) 
ytitle({&tau}{superscript:p},size(large) angle(180))
scheme(plotplainblind) 
legend(ring(0) col(3) bmargin(20 0 2 0)  region(style(none) lpattern(blank)) size(small))  
yscale(range(0.1 .80)) 
ttitle("Year", size(medium))
xscale(range(1980 2016))  
xlabel(1970(10)2020)  
ylabel(0.1(.1).80)
;
gr export ../figures/motivation_pit_3countries.png, replace;

gr combine f3c3 f3c2 f3c1, 
ysize(8) 
xsize(14) 
imargin(zero)
col(3);
gr export ../figures/motivation_3p_3countries.eps, replace;
gr export ../figures/motivation_3p_3countries.pdf, replace;


#delim cr


********************************************************************************
*** Define Samples and Subsamples for OECD Depreciation allowances figure
********************************************************************************
preserve
egen gdm_p25 = pctile(geo_dep_mach) if oecd==1, by(year) p(25)
egen gdm_p50 = pctile(geo_dep_mach) if oecd==1, by(year) p(50)
egen gdm_p75 = pctile(geo_dep_mach) if oecd==1, by(year) p(75)
egen gdb_p25 = pctile(geo_dep_build) if oecd==1, by(year) p(25)
egen gdb_p50 = pctile(geo_dep_build) if oecd==1, by(year) p(50)
egen gdb_p75 = pctile(geo_dep_build) if oecd==1, by(year) p(75)
egen gdi_p25 = pctile(geo_dep_intan) if oecd==1, by(year) p(25)
egen gdi_p50 = pctile(geo_dep_intan) if oecd==1, by(year) p(50)
egen gdi_p75 = pctile(geo_dep_intan) if oecd==1, by(year) p(75)
egen gd_p25  = pctile(geo_dep_tot) if oecd==1, by(year) p(25)
egen gd_p50  = pctile(geo_dep_tot) if oecd==1, by(year) p(50)
egen gd_p75  = pctile(geo_dep_tot) if oecd==1, by(year) p(75)
egen pdv_p25 = pctile(pdv_tot) if oecd==1, by(year) p(25)
egen pdv_p50 = pctile(pdv_tot) if oecd==1, by(year) p(50)
egen pdv_p75 = pctile(pdv_tot) if oecd==1, by(year) p(75)



egen cit_p25 = pctile(corporate_tr) if oecd==1, by(year) p(25)
egen cit_p50 = pctile(corporate_tr) if oecd==1, by(year) p(50)
egen cit_p75 = pctile(corporate_tr) if oecd==1, by(year) p(75)

egen pit_p25 = pctile(individual_tr) if oecd==1, by(year) p(25)
egen pit_p50 = pctile(individual_tr) if oecd==1, by(year) p(50)
egen pit_p75 = pctile(individual_tr) if oecd==1, by(year) p(75)

egen vat_p25 = pctile(vat_tr) if oecd==1, by(year) p(25)
egen vat_p50 = pctile(vat_tr) if oecd==1, by(year) p(50)
egen vat_p75 = pctile(vat_tr) if oecd==1, by(year) p(75)

keep if oecd ==1

collapse (firstnm) pd* gd* pit* cit* vat* ,by(year)
tsset year

lab var cit_p25 "25th Percentile"
lab var cit_p50 "50th Percentile"
lab var cit_p75 "75th Percentile"
lab var pit_p25 "25th Percentile"
lab var pit_p50 "50th Percentile"
lab var pit_p75 "75th Percentile"
lab var vat_p25 "25th Percentile"
lab var vat_p50 "50th Percentile"
lab var vat_p75 "75th Percentile"
lab var gdm_p25 "25th Percentile"
lab var gdm_p50 "50th Percentile"
lab var gdm_p75 "75th Percentile"
lab var gdb_p25 "25th Percentile"
lab var gdb_p50 "50th Percentile"
lab var gdb_p75 "75th Percentile"
lab var gdi_p25 "25th Percentile"
lab var gdi_p50 "50th Percentile"
lab var gdi_p75 "75th Percentile"
lab var gd_p25 "25th Percentile"
lab var gd_p50 "50th Percentile"
lab var gd_p75 "75th Percentile"
lab var pdv_p25 "25th Percentile"
lab var pdv_p50 "50th Percentile"
lab var pdv_p75 "75th Percentile"
lab var year "Year"

********************************************************************************
*** Plot  OECD Depreciation allowances figure
********************************************************************************
#delim ;

line gdm_p25 gdm_p50 gdm_p75 year if inrange(year,1990,2020),
name(f1g,replace) 
title("Implied Geometric Depreciation Allowance (OECD) - Machines") 
scheme(plotplainblind) 
xscale(range(1990 2020)) 
xlabel(1990(10)2020) 
legend(col(3)) 
;

line gdb_p25 gdb_p50 gdb_p75 year if inrange(year,1990,2020),
name(f2g,replace) 
title("Implied Geometric Depreciation Allowance (OECD) - Buildings") 
scheme(plotplain) 
xscale(range(1990 2020)) 
xlabel(1990(10)2020) 
legend(col(3)) 
;


line gdi_p25 gdi_p50 gdi_p75 year if inrange(year,1990,2020),
name(f3g,replace) 
title("Implied Geometric Depreciation Allowance (OECD) - Intangibles") 
scheme(plotplainblind) 
xscale(range(1990 2020)) 
xlabel(1990(10)2020)
legend(col(3)) 
;

line gd_p25 gd_p50 gd_p75 year if inrange(year,1990,2020),
name(f4g,replace) 
title("Depreciation Allowance (OECD)",size(medium)) 
scheme(plotplainblind) 
xscale(range(1970 2020)) 
legend(off)
xlabel(1970(10)2020) 
yscale(range(0.09 .12))
ylabel(0.09 (.01) .12)  
ytitle("{&xi}{superscript:d}",size(medium))
;
gr export ../figures/motivation_igd.png, replace;


line pdv_p25 pdv_p50 pdv_p75 year if inrange(year,1990,2020),
name(f5g,replace) 
title("Present Discounted Value of Depreciation Allowance (OECD)") 
scheme(plotplainblind) 
legend(col(3)) 
xscale(range(1990 2020)) 
xlabel(1990(10)2020) ;
gr export ../figures/motivation_pdv.png, replace;



line cit_p25 cit_p50 cit_p75 year if inrange(year,1970,2020),
name(f3,replace) 
title("Corporate Income Tax (OECD)",size(medium)) 
scheme(plotplainblind) 
xscale(range(1970 2016)) 
yscale(range(0.2 .80)) 
legend(off)
xlabel(1970(10)2020) 
ylabel(0.2(.20).80)
ytitle("{&tau}{superscript:c}",size(medium));
gr export ../figures/motivation_cit.png, replace;


line vat_p25 vat_p50 vat_p75 year if inrange(year,1980,2020),
name(f4,replace)  
title("Value-Added Tax (OECD)",size(medium)) 
scheme(plotplainblind) 
yscale(range(0.2 .60)) 
legend(off)
xscale(range(1980 2016))  
xlabel(1980(10)2020)  
ylabel(0.2(.20).80);

line pit_p25 pit_p50 pit_p75 year if inrange(year,1970,2020),
name(f5,replace)  
title("Personal Income Tax (OECD)",size(medium)) 
scheme(plotplainblind) 
legend(ring(0) col(1) bmargin(20 0 2 0)  region(lpattern(blank)))  
yscale(range(0.2 .80)) 
xscale(range(1980 2016))  
xlabel(1970(10)2020)  
ylabel(0.2(.20).80)
ytitle("{&tau}{superscript:p}",size(medium));
gr export ../figures/motivation_pit.png, replace;

gr combine f3 f5 f4g, 
ysize(8) 
xsize(14) 
imargin(zero)
col(3);
gr export ../figures/motivation_3p_oecd.eps, replace;
gr export ../figures/motivation_3p_oecd.pdf, replace;


#delim cr
restore
/*
********************************************************************************
*** Define Samples and Subsamples for IMF figure
********************************************************************************
preserve
egen cit_mean = mean(corporate_tr) if tpfd==1, by(year afe) 
egen pit_mean = mean(individual_tr) if tpfd==1, by(year afe) 
egen vat_mean = mean(vat_tr) if tpfd==1, by(year afe) 

collapse (firstnm) pit_mean cit_mean vat_mean ,by(afe year)
xtset afe year

lab var pit_mean "Personal"
lab var cit_mean "Corporate"
lab var vat_mean "Value-Added"
lab var year "Year"

********************************************************************************
*** Plot figure from IMF paper
********************************************************************************
#delim ;

line pit_mean cit_mean vat_mean  year if afe ==1  & inrange(year,1970,2020),
name(f1,replace) 
title("Advanced Economies") 
scheme(s1color) 
legend(off) 
xscale(range(1970 2016)) 
yscale(range(0 80)) 
xlabel(1970(10)2020) 
ylabel(0(20)80);

line pit_mean cit_mean vat_mean year if afe ==0  & inrange(year,1980,2020),
name(f2,replace)  
title("Emerging Economies") 
scheme(s1color) 
legend(ring(0) col(1) bmargin(84 0 65 0)  region(lpattern(blank)))  
yscale(range(0 80)) 
xscale(range(1980 2016))  
xlabel(1980(10)2020)  
ylabel(0(20)80);

gr combine f1 f2, 
l1title("Tax Rate (Percent)") 
title(Tax Rates in Advance and Emerging Market Economies) 
ysize(4) 
xsize(9) 
ycom  
note(
"Note: Each series plots the average tax rate of a specific base within a given year across advanced and emerging market economies respectfully, using data originally compiled by"  
"          Vegh and Vuletin (2015). They sourced their data from WDI and World Tax Database with additions from localalities and consultancies. The personal income tax measure here is"
"          the highest marginal personal income tax rate. The corporate tax measure is the maximum corporate income tax rate. Their value-added tax measure is the VAT standard tax rate." 
,size(small));

gr export ../figures/motivation_fig1.png, replace;
#delim cr

restore

********************************************************************************
*** Define Samples and Subsamples for Europe CIT figure
********************************************************************************
preserve
egen cit_p25 = pctile(corporate_tr) if europe==1, by(year) p(25)
egen cit_p50 = pctile(corporate_tr) if europe==1, by(year) p(50)
egen cit_p75 = pctile(corporate_tr) if europe==1, by(year) p(75)

egen vat_p25 = pctile(vat_tr) if europe==1, by(year) p(25)
egen vat_p50 = pctile(vat_tr) if europe==1, by(year) p(50)
egen vat_p75 = pctile(vat_tr) if europe==1, by(year) p(75)
keep if europe ==1

collapse (firstnm) cit* vat* ,by(year)
tsset year

lab var cit_p25 "25th Percentile"
lab var cit_p50 "50th Percentile"
lab var cit_p75 "75th Percentile"
lab var vat_p25 "25th Percentile"
lab var vat_p50 "50th Percentile"
lab var vat_p75 "75th Percentile"
lab var year "Year"

********************************************************************************
*** Plot figure from IMF paper
********************************************************************************
#delim ;

line cit_p25 cit_p50 cit_p75 year if inrange(year,1970,2020),
name(f3,replace) 
title("Corporate Income") 
scheme(s1color) 
legend(off) 
xscale(range(1970 2016)) 
yscale(range(0 60)) 
xlabel(1970(10)2020) 
ylabel(0(20)60);

line vat_p25 vat_p50 vat_p75 year if inrange(year,1980,2020),
name(f4,replace)  
title("Value-Added") 
scheme(s1color) 
legend(ring(0) col(1) bmargin(84 0 65 0)  region(lpattern(blank)))  
yscale(range(0 60)) 
xscale(range(1980 2016))  
xlabel(1980(10)2020)  
ylabel(0(20)60);

gr combine f3 f4, 
l1title("Tax Rate (Percent)") 
title(Corporate Income and Value-Added Tax Rates across European Economies) 
ysize(4) 
xsize(9) 
ycom  
note(
"Note: Each series plots the 25th, 50th, and 75th percentile of tax rates of a specific base within a given year across European economies, using data originally compiled by"  
"          Vegh and Vuletin (2015). They sourced their data from WDI and World Tax Database with additions from localalities and consultancies. The corporate tax measure is"
"          the maximum corporate income tax rate. Their value-added tax measure is the VAT standard tax rate." 
,size(small));

gr export ../figures/motivation_fig2.png, replace;

#delim cr

restore


cap log close
