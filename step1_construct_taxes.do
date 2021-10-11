********************************************************************************
*** Construct a master panel with tax data
********************************************************************************
*** Main inputs: tax_data, oecd_members.xlsx
*** Additional inputs: veghdata.xlsx, individual_tr_ocde_2000.csv, npv_all_years.csv
*** Output: taxes_master.dta
*** Author: Nicolas Oviedo
*** Original: 02/04/2021
********************************************************************************
*** Set up
********************************************************************************
cls
query memory
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

********************************************************************************	
*** Paths and Logs            
********************************************************************************
if "$who" == "A"  global pathinit "/Users/jablanco/Dropbox (University of Michigan)/papers_new/LumpyTaxes"
if "$who" == "N"  global pathinit "D:\"

global output_data "$pathinit/Data/outputs"
global input_data  "$pathinit/Data/inputs"
global temp_file   "$pathinit/Data/Temp"

cap log close
log using "$temp_file/step1.log", append
use "$output_data/taxes_master", clear

cd "$output_data"
*This step is important. Note that all files will be saved assuming this line has been run
********************************************************************************
*** Generate auxiliary files
********************************************************************************
*Desired countries (aka OECD members)
import excel using "$input_data/oecd_members.xlsx", sheet("oecd_members") firstrow clear
save "$output_data/oecd_members.dta", replace

*Vegh.dta
frame copy default vegh
frame change vegh
import excel "$input_data/veghdata.xlsx", sheet("Data") firstrow  clear
replace vat_tr = . if vat_tr == -999
save veghdata, replace
frame change default
frame drop vegh
*Note: this block converts veghdata.xlsx into a .dta file; block intended for one time use

*Individual tax rate: a dataset based on primary sources to update master
insheet using "$input_data/individual_tr_ocde_2000.csv", clear
rename cou wb_code
drop yea unitcode unit powercode powercodecode referenceperiodcode referenceperiod flagcodes flags
drop if centgov_rates == "PERS_ALL_AMNT" | centgov_rates == "TAX_CRED_AMNT" | centgov_rates == "SURTAX_RATE"
drop if strpos(centralgovernmentpersonalincomet, "Threshold")>0
bysort wb_code year (value) : keep if _n == _N
*Cleanse dataset, keep only highest marginal tax rates
merge 1:1 wb_code year using veghdata, keepusing(individual_tr)
drop if _merge==2
*Consistency check
keep if individual_tr == .
recode individual_tr(13.2=40)
*For Switzerland 2000-02 we compute the sum of federal, cantonal and municipal representative tax rates. 
drop individual_tr _merge
drop centgov_rates centralgovernmentpersonalincomet
rename value individual_tr
save i_itr_ocde2000, replace

********************************************************************************
*** Import Tax Data
********************************************************************************
use "$input_data/tax_data"
compress

********************************************************************************
*** Merge: keep OECD countries
********************************************************************************
merge m:1 wb_code using oecd_members, keepusing(original) keep(match) nogenerate
drop original
save taxes_master, replace
tabulate wb_code

*** Check for global completion
/*tabstat year, by(wb_code) statistics(min max range)
sort wb_code
by wb_code: mdesc
misstable summarize*/

********************************************************************************
*** Personal income tax rate
********************************************************************************
***OCDE 2000-2020****

/*misstable summarize individual_tr if(year>2000)
br wb_code year individual_tr if(year > 1999 & year < 2020 & individual_tr == .) */
*Identify missing values

use taxes_master, clear
merge m:m wb_code year using i_itr_ocde2000, update keepusing(individual_tr)
qui drop _merge
qui save taxes_master, replace
*Update taxes_master

***OCDE '90***
/*Source: https://www.bus.umich.edu/otpr/otpr/default.asp
Raw files were .xls but internally html. Fixed manually.*/
drop _all
local tf_data_path = "$input_data\raw_individual_tr"
*local tf_data_path = "C:\Users\Ovi\Desktop\R.A\input\raw_individual_tr"
local myfilelist : dir "`tf_data_path'" files"*.xls"
tempfile cumulator
quietly save `cumulator', emptyok
foreach file of local myfilelist {
	local name = "`tf_data_path'/`file'"
	di "`name'"
	import excel "$input_data/raw_individual_tr/`file'", clear
	drop in 1/2
    nrow
	drop if _n > 1
    ren A country
    ren _* yr*
    reshape long yr, i(country) j(year)
    ren yr individual_tr
    local ccode = substr("`file'",15,3)
    display "`ccode'"
    gen wb_code = "`ccode'"
    move wb_code year
	sort wb_code year
    append using `cumulator'	
    quietly save `cumulator', replace
}	
*Create a tempfile consolidating all new data
move wb_code country
replace wb_code = strupper(wb_code)
qui compress
save `cumulator', replace
*Cleanse it
/*merge 1:1 wb_code year using taxes_master, keepusing(individual_tr)
*br if inlist(wb_code, "POL", "SVK", "IRL", "ISL", "NLD", "EST", "ISR")
consistency check */
use taxes_master, clear
merge 1:1 wb_code year using `cumulator', update keepusing(individual_tr)
*Update master
capture drop _merge
qui save taxes_master, replace
*SVK 1998-1999 does not include the temporary surtax on highest incomes

***Switzerland 1990-1999***
*Vegh and Vuletin (2015) data on CHE is not consistent. In particular, it only takes into account federal taxes in the '90 while including sub-national ones aftewards
*We take the representative sub-central rate and combine it with highest marginal federal income tax rate
drop _all
local mysheets 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999
tempfile cumulator
quietly save `cumulator', emptyok
foreach sheetname of local mysheets {
	import excel "$input_data/raw_individual_tr_ocde_1981/Table-I.2-1981-1999.xlsx", sheet(`sheetname') clear
	drop in 1/9
    missings dropvars, force
    ren A country
    replace country = country[_n-1] if country =="" 
    keep if(country=="Switzerland" & C=="S (P)/S(F)/L(F)")
    drop E G K M O
    gen wb_code = "CHE"
    move wb_code country
    gen year = `sheetname'
    move year C
    append using `cumulator'	
    quietly save `cumulator', replace
}	
*Create a tempfile consolidating CHE data on representative subnational (cantonal + municipal) marginal tax rate
drop if year == .
drop L
move I C
ren I individual_tr
drop C
destring individual_tr, replace
compress
*Cleanse it
replace individual_tr=individual_tr + 11.5
*We add the marginal the maximum federal tax rate, 11.5, constant along the decade
save `cumulator', replace
use taxes_master, clear
capture drop _merge
replace individual_tr = . if wb_code == "CHE" & year > 1989 & year < 2000 
merge 1:1 wb_code year using `cumulator', update keepusing(individual_tr)
*Update master
capture drop _merge
qui save taxes_master, replace

********************************************************************************
*** Corporate income tax rate
********************************************************************************
/*misstable summarize corporate_tr if(year>2000)
br wb_code year corporate_tr if(corporate_tr == .)*/

*No changes made to Vegh data

********************************************************************************
*** Capital gains tax rate
********************************************************************************
*Canada
replace capital_gains_rate = capital_gains_rate_pwc if wb_code == "CAN" 
*We keep ZEW-PWC data which is consistently based on Ontario capital gains rates

drop _all
local mysheets 1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999
tempfile cumulatorcan
quietly save `cumulatorcan', emptyok
foreach sheetname of local mysheets {
*import excel "./raw_individual_tr_ocde_1981/Table-I.2-1981-1999.xlsx", sheet(`sheetname') clear
import excel "$input_data/raw_individual_tr_ocde_1981/Table-I.2-1981-1999.xlsx", sheet(`sheetname') clear
drop in 1/9
   missings dropvars, force
   ren A country
   replace country = country[_n-1] if country =="" 
   keep if(country=="Canada*" & C=="ST")
   drop C E G K M O
   gen wb_code = "CAN"
   move wb_code country
   gen year = `sheetname'
   order wb_code year country I
   append using `cumulatorcan'
   quietly save `cumulatorcan', replace
}
qui save `cumulatorcan', replace
drop L
replace country = "Canada"
ren I ontario_tr
destring ontario_tr, replace
merge 1:1 wb_code year using veghdata, keepusing(individual_tr)
drop if _merge==2
drop _merge
gen capital_gains_rate = individual_tr + ontario_tr
replace capital_gains_rate = capital_gains_rate/2 if year < 1990
replace capital_gains_rate = capital_gains_rate*0.75 if year < 2000 & year > 1989
save `cumulatorcan', replace
use taxes_master, clear
replace capital_gains_rate = . if wb_code == "CAN" & year < 2000 
merge 1:1 wb_code year using `cumulatorcan', update keepusing(capital_gains_rate)
*Update master
capture drop _merge
qui save taxes_master, replace

replace capital_gains_rate = (individual_tr+20)*0.67 if year == 2000 & wb_code == "CAN"
*Assuming same PIT in Ontario as 1999
replace capital_gains_rate = 23.21 if year > 2000 & year < 2005 & wb_code == "CAN"
*Assuming same PIT implicit in PWC data

*France
replace capital_gains_rate = capital_gains_rate_pwc if wb_code == "FRA" 
*We keep ZEW-PWC data on grounds on completion and consistency with other sources

*Germany
replace capital_gains_rate = capital_gains_rate_pwc if wb_code == "DEU" & year < 2009

replace capital_gains_rate = individual_tr/100 if wb_code == "DEU" & year > 1979  & year < 1998
/*Following Dell (2007) and Bartels & Jenderny (2015), we code German capital gains tax rate as the top marginal personal income tax rate.
Up to 2001, many capital gains were tax exempted. However, by adopting this criterion, we keep consistency with ZEW-PWC data, where top-rate
shareholder with substantial participation is computed. Take into account that thresholds and definition of "substantial participation" vary
thoroughout the decades.*/

*Ireland 2009-2020
replace capital_gains_rate_other = 25 if wb_code == "IRL" & year > 2008 & year < 2012
replace capital_gains_rate_other = 30 if wb_code == "IRL" & year > 2011 & year < 2014
replace capital_gains_rate = capital_gains_rate_other if wb_code == "IRL" & year > 2008 & year < 2014
replace capital_gains_rate = capital_gains_rate_pwc if wb_code == "IRL" & year > 1997 & year < 2009
/*Capital gains rates from ZEW-PWC report for Ireland since 2009 are inconsistent with other sources, so we use official rates.
Source: https://www.revenue.ie/en/gains-gifts-and-inheritance/transfering-an-asset/how-to-calculate-cgt.aspx */

*Japan
replace capital_gains_rate = capital_gains_rate_pwc if wb_code == "JPN" & year < 2014
replace capital_gains_rate = 0 if wb_code == "JPN" & year < 1989
replace capital_gains_rate = 26 if wb_code == "JPN" & year > 1988 & year < 2003
replace capital_gains_rate = 26 if wb_code == "JPN" & year > 2002 & year < 2005
*Historical data based on Japan Ministry of Finance, Shoven (1989) and Moriguchi & Saez (2010)

*Luxembourg
replace capital_gains_rate = capital_gains_rate_pwc if wb_code == "LUX" 
*We keep ZEW-PWC data; Tax Foundation data reports 0% rates due to exemptions to non-substantial shareholdings

*Slovakia
replace capital_gains_rate = capital_gains_rate_pwc if wb_code == "SVK"
*We keep ZEW-PWC data as Tax Foundation codes 0%, rate only applicable if asset is hold +20 years

replace capital_gains_rate = capital_gains_rate*100 if capital_gains_rate < 1

*Australia
replace capital_gains_rate = individual_tr if wb_code == "AUS" & year > 1985 & year < 2000
replace capital_gains_rate = individual_tr/2 if wb_code == "AUS" & year > 1999 & year < 2020

*New Zealand
replace capital_gains_rate = 0 if wb_code == "NZL"
*Following Fraser Institute report

*Denmark
replace capital_gains_rate = 0 if year > 1969 & year <1993 & wb_code == "DNK"
replace capital_gains_rate = 40 if year > 1992 & year < 1998 & wb_code == "DNK"
*Following Kleven & Schultz (2014) and Atkinson & Søgaard (2013) on share income tax

*Poland
replace capital_gains_rate = 40 if year > 1991 & year <1994 & wb_code == "POL"
replace capital_gains_rate = 45 if year > 1993 & year < 1997 & wb_code == "POL"
replace capital_gains_rate = 44 if year == 1997 & wb_code == "POL"
*Following Becker et al. (2013)

*Spain
replace capital_gains_rate = 0 if year < 1973 & wb_code == "ESP"
replace capital_gains_rate = 15 if year > 1972 & year < 1978 & wb_code == "ESP"
replace capital_gains_rate = individual_tr if year > 1977 & year < 1991 & wb_code == "ESP"
replace capital_gains_rate = 20 if year > 1995 & year < 1998 & wb_code == "ESP"
*Following de Leon Cabetas (2005)
replace capital_gains_rate = 37.3 if year > 1992 & year < 1997 & wb_code == "ESP"
*Following Becker et al. (2013)

*Italy
replace capital_gains_rate = 0 if year > 1973 & year < 1991 & wb_code == "ITA"
replace capital_gains_rate = 21.9 if year == 1991 & wb_code == "ITA"
replace capital_gains_rate = 23.4 if year > 1991 & year < 1996 & wb_code == "ITA"
replace capital_gains_rate = 22.2 if year < 1998 & year > 1995 & wb_code == "ITA"
*Following Alworth et al (2003) and Giuso (1994)

save taxes_master, replace

*Historical data for France
tempfile pv
save `pv', emptyok
import excel "$input_data/CapitalGain/pv.xlsx", clear
drop A D-Z
drop in 1/4
ren B year
ren C rate
destring(year),replace
destring(rate), replace
replace rate = rate*100
save `pv', replace

tempfile prelevement
save `prelevement', emptyok
import excel "$input_data/CapitalGain/cgt_france_prelevements.xlsx", firstrow clear
save `prelevement', replace
use `pv', clear
merge 1:1 year using `prelevement', keepusing (total)

sort year
replace rate = 16 if year == 1994
replace total = 0 if year < 1987
gen capital_gains_rate = rate + total
gen wb_code = "FRA"
move wb_code year
drop _merge
drop if year > 1997
save `pv', replace

use taxes_master, clear
merge 1:1 wb_code year using `pv', update keepusing(capital_gains_rate) nogenerate
replace capital_gains_rate = 0 if wb_code == "FRA" & year < 1979

save taxes_master, replace

********************************************************************************
*** Depreciation allowance
********************************************************************************
*insheet using ./depreciation_tax_foundation/cost_recovery_data.csv, clear
insheet using "$input_data/depreciation_tax_foundation/npv_all_years.csv", clear
ren iso_3 wb_code
move wb_code year
move country year
replace waverage = "" if waverage == "NA"
destring(waverage), replace
save npv_all_years, replace

use taxes_master, clear
merge 1:1 wb_code year using npv_all_years, keepusing(waverage)
drop if _merge == 2
gen check = pdv_tot - waverage
*Contrasting in-house calculations with Tax Foundation outputs

drop check waverage _merge

/*USA 1983-1986 
Depreciation method for machinery was originally wrongly coded*/

replace taxdepmachtimesl = 4 if wb_code == "USA" & year > 1982 & year < 1987

local iv mach
local disc_rate = 0.075
local mach_w    = .4391081
local build_w   = .4116638
local intan_w   = .1492281
local disc_rate = 0.075
local mach_dep  = 0.11
local build_dep = 0.03
local intan_dep = .15
local dep_rate  = `build_w' * `build_dep' + `mach_w' * `mach_dep' + `intan_w'  * `intan_dep'
replace pdv_sl2_mach = ((taxdepr`iv'db*(1+`disc_rate'))/`disc_rate')*(1-(1^taxdep`iv'timedb)/(1+`disc_rate')^taxdep`iv'timedb) + ((taxdepr`iv'sl*(1+`disc_rate'))/`disc_rate')*(1-(1^taxdep`iv'timesl)/(1+`disc_rate')^taxdep`iv'timesl) / (1+`disc_rate')^taxdep`iv'timedb if wb_code == "USA" & year > 1982 & year < 1987
replace pdv_`iv' = pdv_slita_`iv' + pdv_dbsl2_`iv' + pdv_idb_`iv' + pdv_db_`iv' + pdv_sl2_`iv' + pdv_czk_`iv' +pdv_sl_`iv' if wb_code == "USA" & year > 1982 & year < 1987
replace pdv_tot = `mach_w' *pdv_mach + `build_w' *pdv_build + `intan_w' *pdv_intangibl if wb_code == "USA" & year > 1982 & year < 1987
replace geo_dep_tot = pdv_tot*(`disc_rate'+ `dep_rate') if wb_code == "USA" & year > 1982 & year < 1987
replace geo_dep_mach = pdv_mach*(`disc_rate'+ `mach_dep') if wb_code == "USA" & year > 1982 & year < 1987
replace dgeo_dep_tot = geo_dep_tot-geo_dep_tot[_n-1] if wb_code == "USA" & year > 1982 & year < 1987

*Redoing USA calculations for 2002-2017. Calculations for machinery were originally misguided.

local mach_w    = .4391081
local build_w   = .4116638
local intan_w   = .1492281
local disc_rate = 0.075
local mach_dep  = 0.11
local build_dep = 0.03
local intan_dep = .15
*Declare local variables
local dep_rate  = `build_w' * `build_dep' + `mach_w' * `mach_dep' + `intan_w'  * `intan_dep'
replace pdv_tot = `mach_w' *pdv_mach + `build_w' *pdv_build + `intan_w' *pdv_intangibl if wb_code == "USA"
local vlist = "mach"
foreach iv of local vlist {
replace pdv_dbsl2_`iv' = ((taxdepr`iv'db+(taxdepr`iv'sl/((1+`disc_rate')^taxdep`iv'timedb))/taxdep`iv'timesl )*(1+`disc_rate'))/(`disc_rate' + (taxdepr`iv'db+(taxdepr`iv'sl/((1+`disc_rate')^taxdep`iv'timedb))/taxdep`iv'timesl)) if taxdep`iv'type == "DB or SL" & wb_code == "USA"
}
local iv mach
replace pdv_`iv' = pdv_slita_`iv' + pdv_dbsl2_`iv' + pdv_idb_`iv' + pdv_db_`iv' + pdv_sl2_`iv' + pdv_czk_`iv' +pdv_sl_`iv' if wb_code == "USA" & year > 2001
*Recompute pdv for machinery
replace pdv_mach = pdv_mach * .7 + .3 if wb_code == "USA" & year==2002
replace pdv_mach = pdv_mach * .7 + .3 if wb_code == "USA" & year==2003
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year==2004
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year==2008
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year==2009
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year==2010
replace pdv_mach = pdv_mach *  0 +  1 if wb_code == "USA" & year==2011
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year==2012
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year==2013
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year==2014
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year==2015
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year==2016
replace pdv_mach = pdv_mach * .5 + .5 if wb_code == "USA" & year==2017
*Adjust pdv for machinery 2002-2017 taking into account capital bonus
replace pdv_tot = `mach_w' *pdv_mach + `build_w' *pdv_build + `intan_w' *pdv_intangibl if wb_code == "USA" & year > 2001
*Recalculate pdv
replace geo_dep_tot = pdv_tot*(`disc_rate'+ `dep_rate') if wb_code == "USA" & year > 2001
replace geo_dep_mach = pdv_mach*(`disc_rate'+ `mach_dep') if wb_code == "USA" & year > 2001
replace dgeo_dep_tot = geo_dep_tot-geo_dep_tot[_n-1] if wb_code == "USA" & year > 2001
*Update geometric rates

/*Italy 1998-2007: machinery and buildings were treated as if following a special depreciation rate in Tax Foundation procedures.
However, final pdv are computed using a SL equivalent scheme with a rate of 0.125. We hereby replicate the same criterion, following
Bordignon et al. (1998).*/

local mach_w    = .4391081
local build_w   = .4116638
local intan_w   = .1492281
local disc_rate = 0.075
local mach_dep  = 0.11
local build_dep = 0.03
local intan_dep = .15
local dep_rate  = `build_w' * `build_dep' + `mach_w' * `mach_dep' + `intan_w'  * `intan_dep'
local vlist = "build mach"
foreach iv of local vlist {
	replace pdv_sl_`iv' = ((taxdepr`iv'sl*(1+`disc_rate'))/`disc_rate')*(1-(1^(1/taxdepr`iv'sl)/(1+`disc_rate')^(1/taxdepr`iv'sl))) if wb_code == "ITA" & year > 1997 & year < 2008
	replace pdv_slita_`iv' =  0 if wb_code == "ITA" & year > 1997 & year < 2008
}
foreach iv of local vlist {
replace pdv_`iv' = pdv_slita_`iv' + pdv_dbsl2_`iv' + pdv_idb_`iv' + pdv_db_`iv' + pdv_sl2_`iv' + pdv_czk_`iv' +pdv_sl_`iv' if wb_code == "ITA" & year > 1997 & year < 2008
replace pdv_tot = `mach_w' *pdv_mach + `build_w' *pdv_build + `intan_w' *pdv_intangibl if wb_code == "ITA" & year > 1997 & year < 2008
}
foreach iv of local vlist {
replace geo_dep_tot = pdv_tot*(`disc_rate'+ `dep_rate') if wb_code == "ITA" & year > 1997 & year < 2008
replace geo_dep_mach = pdv_mach*(`disc_rate'+ `mach_dep') if wb_code == "ITA" & year > 1997 & year < 2008
replace dgeo_dep_tot = geo_dep_tot-geo_dep_tot[_n-1] if wb_code == "ITA" & year > 1997 & year < 2008
}

/*This (pdv_tot_p) is the percentage of the present value cost that a business can write off over the life of a 
typical asset. It is a weighted average of pdv of machinery, building and intangible assets */
gen pdv_tot_p = pdv_tot * 100
move pdv_tot_p geo_dep_tot
lab var pdv_tot_p "Present Discounted Value of dep allowance as percentage"

*Computing t^d
preserve
replace corporate_tr = corporate_tr/100
replace individual_tr = individual_tr/100
replace capital_gains_rate = capital_gains_rate/100
gen xi_d = .
label var xi_d "Rate that would result in same pdv if declining balance was used"
local r = 0.075 //real rate = 0.055 + inflation = .02
*Assumed rate of return when computing pdv
replace xi_d = pdv_tot*`r'/(1 - pdv_tot) if pdv_tot != .
gen t_d = .
replace t_d = corporate_tr * xi_d / (`r'*(1-individual_tr)/(1-capital_gains_rate) + xi_d)
tempfile formerge
save `formerge', replace
restore
merge 1:1 wb_code year using `formerge', keepusing(xi_d t_d) nogenerate

label var t_d "Adjusted present value of depreciation"
*br wb_code year pdv_tot individual_tr corporate_tr capital_gains_rate xi_d t_d

save taxes_master, replace

*New t_d
preserve
replace corporate_tr = corporate_tr/100
replace individual_tr = individual_tr/100
replace capital_gains_rate = capital_gains_rate/100
gen xi_d_new = .
label var xi_d_new "Rate that would result in same pdv if declining balance was used with r = 0.04"
local r = 0.04
*Assumed real rate of return when computing pdv
replace xi_d_new = pdv_tot*`r'/(1 - pdv_tot) if pdv_tot != .
gen t_d_new = .
replace t_d_new = corporate_tr * xi_d_new / (`r' + xi_d_new)
tempfile formerge
save `formerge', replace
restore
merge 1:1 wb_code year using `formerge', keepusing(xi_d_new t_d_new) nogenerate

label var t_d_new "Adjusted depreciation rate with r=0.04"
replace t_d_new = t_d_new*100

save taxes_master, replace
********************************************************************************
*** Update Chilean data
********************************************************************************
/* Here we update values on VAT, personal income and corporate rates for Chile using
an in-house constructed dataset. See Online Appendix for details and sources*/
capture drop _merge
tempfile chilemerge
save `chilemerge', emptyok
import excel using "$input_data/chile_taxes.xlsx", firstrow clear
save `chilemerge', replace
use taxes_master, clear
merge 1:1 wb_code year using `chilemerge', update replace keepusing(vat_tr individual_tr corporate_tr)
drop _merge

save taxes_master, replace

********************************************************************************
*** PWT weights
********************************************************************************
*Merge with Penn World Table data to generate weighted series
tempfile penn
save `penn', emptyok
use "$input_data/pwt100",clear
ren countrycode wb_code
*append using `penn'	
quietly save `penn', replace
use taxes_master, clear
merge 1:1 wb_code year using `penn', keepusing(cn cgdpo)
drop if _merge == 2
drop _merge

save taxes_master, replace

********************************************************************************
*** Export summary statistics
********************************************************************************
label var individual_tr "\$t^p\$"
label var corporate_tr "\$t^c\$"
label var capital_gains_rate "\$t^g\$"
label var t_d "\$t^d\$"

summ individual_tr corporate_tr capital_gains_rate t_d
estpost tabstat individual_tr corporate_tr capital_gains_rate t_d, listwise statistics(count mean sd min max) columns(statistics)
esttab . using a.tex, cells("count mean sd min max") nonum noobs label replace addnotes("Summary statistics for main taxes")

********************************************************************************
*** Chilean tax panel
********************************************************************************
use taxes_master, clear
drop if wb_code ~= "CHL"
drop xi_* t_*
ren wb_code countrycode

save chile_taxes, replace
/*
*Get internal rate of return from PWT
capture ren wb_code countrycode
merge 1:1 countrycode year using "$input_data/pwt100", keepusing(irr)
drop if _merge == 2
drop _merge
*/

*Get nominal rate
local tf_data_path = "$input_data\depreciation_chile"
local myfilelist : dir "`tf_data_path'" files"*.xls"
tempfile chile
quietly save `chile', emptyok
foreach file of local myfilelist{
	local name = substr("`file'", 12, 4)
	import excel "$input_data/depreciation_chile/`file'",clear
	drop in 1/3
	foreach var of varlist _all{
		local value = `var'[1]
		local vname = strtoname(`"`value'"')
		rename `var' date`vname'
		label var date`vname' `"`value'"'
	}
	drop in 1
	drop dateIndicator_Code dateIndicator_Name
	ren dateCountry_Name country
	ren dateCountry_Code countrycode
	drop if countrycode ~= "CHL"
	reshape long date,  i(countrycode) j(year,string)
	drop in 1
	ren date `name'
	replace year = substr(year, 2, 4)
	destring(year), replace
	destring(`name'), replace
	drop if `name' == .
	replace `name' = `name'/100
	append using `chile'
	qui save `chile', replace
}
collapse (firstnm) countrycode lend totl, by(year)
lab var lend "Nominal interest rate"
lab var totl "Annual inflation rate"
qui save `chile', replace
use chile_taxes, clear
merge 1:1 countrycode year using `chile', keepusing(lend totl) nogenerate
ren countrycode wb_code
gen r = lend - totl

qui save chile_taxes, replace

/*
*Get inflation rate
tempfile chileinflation
save `chileinflation', emptyok
import excel using "$input_data/API_FP.CPI.TOTL.ZG_DS2_en_excel_v2_2445767.xls", clear
drop in 1/3
foreach var of varlist _all{
	local value = `var'[1]
    local vname = strtoname(`"`value'"')
    rename `var' date`vname'
    label var date`vname' `"`value'"'
}
drop in 1
drop dateIndicator_Code dateIndicator_Name
ren dateCountry_Name country
ren dateCountry_Code countrycode
drop if countrycode ~= "CHL"
reshape long date,  i(countrycode) j(year,string)
drop in 1
ren date inflation
replace year = substr(year, 2, 4)
destring(year), replace
destring(inflation), replace
drop if inflation == .
replace inflation = inflation/100
save `chileinflation', replace

use chile_taxes, clear
merge 1:1 countrycode year using `chileinflation', keepusing(inflation) nogenerate
gen i = irr + inflation
ren countrycode wb_code
*/

*Recomputing t^d using actual Chilean nominal rate
preserve
replace corporate_tr = corporate_tr/100
replace individual_tr = individual_tr/100
replace capital_gains_rate = capital_gains_rate/100
gen xi_d = .
label var xi_d "Rate that would result in same pdv if declining balance was used"
replace xi_d = pdv_tot*lend/(1 - pdv_tot) if pdv_tot != .
gen t_d = .
replace t_d = corporate_tr * xi_d / (lend*(1-individual_tr)/(1-capital_gains_rate) + xi_d)
tempfile formerge
save `formerge', replace
restore
merge 1:1 wb_code year using `formerge', keepusing(xi_d t_d) nogenerate

save chile_taxes, replace
********************************************************************************
*** A lite version taxes_master
********************************************************************************
*Keep only final variables
use taxes_master, clear

drop taxdepbuildtype-capital_gains_rate_other
drop capital_gains_index-capital_gains_exemption
drop tpfd-pdv_tot
drop geo_dep_tot-dgeo_dep_tot
drop xi_d_new-cn

drop iso_num pdv_tot_p
order panelcode wb_code country year corporate_tr individual_tr capital_gains_rate xi_d t_d vat_tr

compress

label data "A compact version of global panel of taxes, ready to infer global taxation facts"

save taxes_master_facts_ready, replace