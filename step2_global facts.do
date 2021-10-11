********************************************************************************
*** Global Tax Facts
********************************************************************************
*** Main input: taxes_master.dta
*** Output: various .png figures and .tex tables
*** Author: Nicolas Oviedo
*** Original: 09/24/2021
*** Code: This codes summarizes global CIT facts
********************************************************************************
*** Set up
********************************************************************************
cls
query memory
set more off
set scheme s1color

********************
*User Settings
********************
*User: Andres
*global who = "A" 

*User: Isaac
//global who = "I" 

*User: Nicolas
global who = "N" 

********************************************************************************	
* -------------         Paths and Logs            ------------------------------
********************************************************************************
if "$who" == "N"  {
		global pathinit "D:\Data"
 		global sep = "/"
}

if "$who" == "N"  {
global input_data "${pathinit}${sep}outputs"
global output_data "$pathinit${sep}outputs${sep}macrodata"
global figures "${pathinit}${sep}figures${sep}Taxes${sep}global_facts"
global temp "$pathinit${sep}Temp"
global aux "$pathinit${sep}inputs${sep}aux_files"
global do_files "$pathinit${sep}do_files${sep}taxes${sep}corporate_taxes_importance"
}

capture log close
log using "$temp${sep}global_tax_facts.txt", replace

cd "$input_data"
use taxes_master, clear

********************************************************************************
*** Corporate Income Tax Rate
********************************************************************************
egen cit_p25 = pctile(corporate_tr), by(year) p(25)
egen cit_p50 = pctile(corporate_tr), by(year) p(50)
egen cit_p75 = pctile(corporate_tr), by(year) p(75)

preserve
collapse (firstnm) cit*, by(year)
tsset year

lab var cit_p25 "25th Percentile"
lab var cit_p50 "50th Percentile"
lab var cit_p75 "75th Percentile"
lab var year "Year"

*Main plot
#delim ;
line cit_p25 cit_p50 cit_p75 year if inrange(year,1980,2019),
lpattern(dot solid dash) lwidth(thick thick thin) lcolor(g1 ..)
name(f2,replace) 
title("Corporate Income Tax (t{superscript:c})") 
scheme(s1mono) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(15 55)) 
xlabel(1980(10)2020) 
ylabel(15(20)55)
;
#delim cr
gr export "$figures/motivation_cit.png", replace
qui restore

*Selected countries
#delim ;
xtline corporate_tr if inrange(year,1980,2019) & inlist(wb_code,"USA","DEU","CHL"), overlay
plot1opts(lwidth(medthick)) plot2opts(lwidth(medthick)) plot3opts(lwidth(medthick))
name(f2c2,replace) 
title("Corporate Income Tax (t{superscript:c})") 
ytitle("")
scheme(s1color) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(15 55)) 
xlabel(1980(10)2020) 
ylabel(15(20)55)
;
#delim cr
gr export "$figures/motivation_cit_selected.png", replace

*Selected countries vs OECD
preserve
bysort year: egen oecd_avg = mean(corporate_tr)
replace wb_code = "OECD" if wb_code == "FRA"
replace corporate_tr = oecd_avg if wb_code == "OECD"
label define panelcode 31 "OECD" 86 "USA" 16 "CHL" 22 "DEU", modify
#delim ;
xtline corporate_tr if inrange(year,1980,2019) & inlist(wb_code,"USA","DEU","CHL","OECD"), overlay
plot1opts(lwidth(medthick)) plot2opts(lwidth(medthick)) plot3opts(lwidth(vthick) lcolor(black)) plot4opts(lwidth(medthick))
name(f2c2,replace) 
ytitle("")
scheme(s1color) 
legend(ring(0) col(1) bmargin(70 0 55 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(15 55)) 
xlabel(1980(10)2020) 
ylabel(15(20)55);
#delim cr

gr export "$figures/pub_motivation_cit_selected.png",replace

*Black and white
#delim ;
xtline corporate_tr if inrange(year,1980,2019) & inlist(wb_code,"USA","DEU","CHL"), overlay
plot1opts(lwidth(medthick) lpattern(dash)) plot2opts(lwidth(medthick) lpattern(solid)) 
plot3opts(lwidth(medthick) lpattern(dot)) 
name(f2c2,replace) 
title("Corporate Income Tax (t{superscript:c})") 
ytitle("")
scheme(s1mono) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(15 55)) 
xlabel(1980(10)2020) 
ylabel(15(20)55)
;
#delim cr

gr export "$figures/pub_motivation_cit_bw.png",replace

********************************************************************************
*** CIT - weighted averages
********************************************************************************
use taxes_master, clear

lab var corporate_tr "Corporate Income Tax (t{superscript:c})"
/*
lab var individual_tr "Personal Income Tax (t{superscript:p})"
lab var capital_gains_rate "Capital Gains Tax (t{superscript:g})"
lab var pdv_tot_p "Depreciation Allowance ({&xi}{superscript:d}/({&xi}{superscript:d} + r))"
lab var t_d_new  "PDV of Depreciation Allowance (t{superscript:d})"
*/

*Weight by capital stock (cn)
foreach var in corporate_tr{
     gen w_`var' =.
     local N = _N
     foreach i in 1/`N'{
		replace w_`var' = cn if `var' != . in `i'
     }
     bysort year: egen cn_total_`var' = total(w_`var')
     gen cn_share_`var' = w_`var'/cn_total_`var'
     gen weight_`var' = `var'*cn_share_`var'
     bysort year: egen avg_`var'_cn = total(weight_`var'), missing
	 
	lab var cn_total_`var' "Sum of capital stock of countries with non missing values for `var'"
	lab var cn_share_`var' "Share of capital stock among countries with non missing value on `var' in that year"
	lab var weight_`var' "`var' rate multiplied by country share of capital stock, among those with reported rates"
	
	local varlabel : variable label `var'
		
	preserve
	collapse (firstnm) avg_`var'_cn, by(year)
	lab var avg_`var'_cn "Weighted average rate"
	tsset year
	drop if year == 2020
	gen i_`avg' = round(avg_`var'_cn, 5)
	summ i_`avg'

	#delim ;
	line avg_`var'_cn year if inrange(year,1980 ,2020),
	lwidth(thick)
	name(f`var',replace) 
	title("`varlabel'") 
	scheme(s1color) 
	legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
	xscale(range(1980 2019)) 
	yscale(range(`r(min)' `r(max)')) 
	xlabel(1980(10)2020) 
	ylabel(`r(min)'(10)`r(max)')
	;
	#delim cr
	gr export "$figures/`var'_avg_cn.png", replace
	qui restore
}

*Weight by gdp
foreach var in corporate_tr{
	gen u_`var' =.
	local N = _N
	foreach i in 1/`N'{
		replace u_`var' = cgdpo if `var' != . in `i'
	}
	bysort year: egen cgdpo_total_`var' = total(u_`var')
	gen cgdpo_share_`var' = u_`var'/cgdpo_total_`var'
	gen cgdpo_weight_`var' = `var'*cgdpo_share_`var'
	bysort year: egen avg_`var'_gdpo = total(cgdpo_weight_`var'), missing
	
	lab var cgdpo_total_`var' "Sum of real gdp of countries with non missing values for `var'"
	lab var cgdpo_share_`var' "Share of real gdp among countries with non missing value on `var' in that year"
	lab var cgdpo_weight_`var' "`var' multiplied by country share of gdp, among those with reported rates"
	
	local varlabel : variable label `var'
		
	preserve
	collapse (firstnm) avg_`var'_gdpo, by(year)
	lab var avg_`var'_gdpo "Weighted average rate"
	tsset year
	drop if year == 2020
	gen i_`avg' = round(avg_`var'_gdpo, 5)
	summ i_`avg'

	#delim ;
	line avg_`var'_gdpo year if inrange(year,1980 ,2020),
	lwidth(thick) lcolor(lavender)
	name(f`var',replace) 
	title("`varlabel'") 
	scheme(s1color) 
	legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
	xscale(range(1980 2019)) 
	yscale(range(`r(min)' `r(max)')) 
	xlabel(1980(10)2020) 
	ylabel(`r(min)'(10)`r(max)')
	;
	#delim cr
	gr export "$figures/`var'_avg_gdp.png", replace
	qui restore
}

********************************************************************************
*** Importance of CIT
********************************************************************************
*** Summary statistics for 2018 ***
do "$do_files/plots_corporate_taxes.do"

*** Time series plots ***
use "$input_data/corporate_taxes_importance/tax_profit_1950_2020", clear

collapse(mean) PIGDP TAXGDP TAXPER TAXPI, by(year)
keep if year > 1980
ds year, not
foreach var in `r(varlist)'{
replace `var' = `var'*100
}
lab var PIGDP "Gross profits over GDP (%)"
lab var TAXGDP "CIT revenue as % of GDP"
lab var TAXPER "CIT revenue as % of total taxation"
lab var TAXPI "CIT revenue over gross profits (%)"

line PIGDP year, lcolor(blue)
gr export "$figures/PIGDP.png", replace
line TAXGDP year, lcolor(red)
gr export "$figures/TAXGDP.png", replace
line TAXPER year, lcolor(green)
gr export "$figures/TAXPER.png", replace
line TAXPI year, lcolor(purple)
gr export "$figures/TAXPI.png", replace

********************************************************************************
*** Z (on the fly)
********************************************************************************
use taxes_master, clear

gen z = t_d/(corporate_tr/100)
lab var z "Adjusted pdv without computing CIT"
egen z_p25 = pctile(z), by(year) p(25)
egen z_p50 = pctile(z), by(year) p(50)
egen z_p75 = pctile(z), by(year) p(75)

collapse (firstnm) z_p*, by(year)
lab var z_p25 "25th Percentile"
lab var z_p50 "50th Percentile"
lab var z_p75 "75th Percentile"
lab var year "Year"

#delim ;
line z_p25 z_p50 z_p75 year if inrange(year,1980,2019),
lpattern(dot solid dash) lwidth(thick thick thin)
name(z1,replace) 
title("Adjusted pdv (z)") 
scheme(s1color) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(.60 .90)) 
xlabel(1980(10)2020) 
ylabel(.60 (.05).90)
;
#delim cr

gr export "$figures/z.png", replace

********************************************************************************
*** CIT dispersion
********************************************************************************
use taxes_master, clear

*** Interquartile range ***
egen cit_p25 = pctile(corporate_tr), by(year) p(25)
egen cit_p50 = pctile(corporate_tr), by(year) p(50)
egen cit_p75 = pctile(corporate_tr), by(year) p(75)
gen iq_range = cit_p75 - cit_p25

collapse (firstnm) cit* iq_range, by(year)
tsset year
lab var iq_range "Interquartile range"
lab var year "Year"

#delim ;
line iq_range year if inrange(year,1980,2019),
lpattern(dot solid dash) lwidth(thick thick thin) lcolor(g1 ..)
name(v1,replace) 
title("Corporate Income Tax (t{superscript:c} dispersion)") 
scheme(s1mono) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(0 20)) 
xlabel(1980(10)2020) 
ylabel(0(2)20)
;
#delim cr

gr export "$figures/dispersion_cit_iqrange.png", replace

*** Variance ***
use taxes_master, clear

egen cit_sd = sd(corporate_tr), by(year)
egen cit_avg = mean(corporate_tr), by(year)
collapse (firstnm) cit*, by(year)
tsset year
lab var cit_sd "CIT standard deviation"
lab var cit_avg "CIT average"
lab var year "Year"
gen cit_cv=cit_sd/cit_avg
lab var cit_cv "CIT variation coefficient"

#delim ;
line cit_cv year if inrange(year,1980,2019),
lpattern(dot solid dash) lwidth(thick thick thin) lcolor(g1 ..)
name(v1,replace) 
title("Corporate Income Tax (t{superscript:c}) dispersion") 
scheme(s1mono) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(0.15 0.40)) 
xlabel(1980(10)2020) 
ylabel(0.15(0.05)0.40)
;
#delim cr

gr export "$figures/dispersion_cit_sd.png", replace

*** Kelly skewness ***
use taxes_master, clear

egen cit_p10 = pctile(corporate_tr), by(year) p(10)
egen cit_p50 = pctile(corporate_tr), by(year) p(50)
egen cit_p90 = pctile(corporate_tr), by(year) p(90)

gen s_k = (cit_p90 + cit_p10 - 2*cit_p50)/(cit_p90 - cit_p10)
collapse (firstnm) cit* s_k, by(year)
lab var s_k "Kelly skewness coefficient"
lab var year "Year"
twoway connected s_k year
gr export "$figures/dispersion_kelly.png", replace

histogram s_k
gr export "$figures/dispersion_kelly_histogram.png", replace

********************************************************************************
*** Distribution rates
********************************************************************************
use taxes_master, clear
lab var corporate_tr "CIT rate"	

local years "1960 1980 2000 2018"
local colores "teal ltblue olive_teal ebblue"
forvalues t=1/4{
	local color = word("`colores'", `t')
	local yr = real(word("`years'", `t'))
	histogram corporate_tr if year == `yr', bin(5) frequency color(`color') gap(5) ytitle("Countries")
	gr export "$figures/distribution_`yr'.png"
}

********************************************************************************
*** Reforms
********************************************************************************
use taxes_master, clear

keep wb_code year corporate_tr iso_num
order wb_code iso_num year corporate_tr

*** 1. Identify reforms ***

*Identify CIT Reforms
xtset iso_num year
gen reform = .
bysort iso_num: gen reform_size = corporate_tr - l.corporate_tr
replace reform = 1 if reform_size ~= 0 & reform_size ~=.
replace reform = 0 if reform_size == 0

*Determine spell
by iso_num (year), sort: gen tot_reforms = sum(reform == 1)
by iso_num tot_reforms (year), sort: gen start_year = year[1]
by iso_num tot_reforms (year): gen end_year = year[_N]
gen duration = end_year - start_year
replace duration = . if reform ~= 1

*** 2. Global statistics ***
egen global_reforms = total(reform), by(year) missing
egen size_reforms = total(reform_size), by(year) missing
gen avg_size_reforms = size_reforms/global_reforms
egen spell = total(duration), by(year) missing
gen avg_spell = spell/global_reforms

*Scatter: duration vs size
preserve
drop if duration == .
lab var reform_size "Reform size"
lab var duration "Duration"
scatter reform_size duration, mcolor(mint) ytitle("Reform size")|| lfit reform_size duration, lcolor(dkgreen) legend(off)
gr export "$figures/scatter_duration_size.png", replace
restore

*Plot
preserve
collapse(firstnm) global_reforms avg_size_reforms avg_spell, by(year)
lab var global_reforms "Number of reforms"
lab var avg_size_reforms "Average size of reforms"
lab var avg_spell "Average reform spell"
#delim ;
twoway bar global_reforms year ||
line avg_size_reforms avg_spell year
;
#delim cr
gr export "$figures/cit_reforms_global.png", replace
restore

*Save summary table
egen size_dispersion = sd(reform_size), by(year)
replace size_dispersion = round(size_dispersion/avg_size_reforms, 0.01)
lab var size_dispersion "Reform size dispersion"
egen spell_dispersion = sd(duration), by(year)
replace spell_dispersion = round(spell_dispersion/avg_spell, 0.01)
lab var spell_dispersion "Reform spell dispersion"

replace  avg_size_reforms = round(avg_size_reforms, 0.01)
replace  avg_spell = round(avg_spell, 0.01)
estpost tabstat global_reforms avg_size_reforms size_dispersion avg_spell spell_dispersion, by(year)
esttab . using global_cit_reforms.tex, cells("global_reforms(label(`:var lab global_reforms')) avg_size_reforms(label(`:var lab avg_size_reforms')) size_dispersion(label(`:var lab size_dispersion')) avg_spell(label(`:var lab avg_spell')) spell_dispersion(label(`:var lab spell_dispersion'))") ///
noobs nomtitle nonumber varlabels(`e(labels)') varwidth(20) replace sfmt(%9.0fc %9.2fc %9.3fc) compress

*** 3. Time distribution of reforms ***
gen decade = .
replace decade = 1960 if year < 1970
replace decade = 1970 if year > 1969 & year < 1980
replace decade = 1980 if year > 1979 & year < 1990
replace decade = 1990 if year > 1989 & year < 2000
replace decade = 2000 if year > 1999 & year < 2010
replace decade = 2010 if year > 2009

preserve
collapse(sum) global_reforms, by(decade)
graph bar (firstnm) global_reforms, over(decade) bar(1, color(erose)) ytitle("CIT reforms per decade")
gr export "$figures/reforms_decades_.png", replace
restore

*** 4.Country statistics ***
*--------
*Inaction
*--------

egen cty_reforms = total(reform), by(wb_code) //Total number of reforms by country
egen cty_tau = total(duration), by(wb_code) //Total duration of reforms (inaction) by country
gen e_tau = cty_tau/cty_reforms // Expected inaction
egen var_tau = sd(duration), by(wb_code)
replace var_tau = var_tau * var_tau // Inaction dispersion

preserve
collapse (firstnm) e_tau var_tau, by(wb_code)
drop if e_tau == .
replace var_tau = 0 if var_tau == .
lab var e_tau "Expected inaction"
lab var var_tau "Inaction variance"

//Adding average
summarize e_tau
local m=round(r(mean),0.01)
set obs 38
replace wb_code = "OECD" in 38
replace e_tau = `m' in 38
separate e_tau, by(wb_code == "OECD")
//Plot expected inaction of reforms
#delim;
graph bar e_tau e_tau1,
nofill over(wb_code, sort(e_tau) descending label(angle(90))) ytitle("Expected inaction of reforms") bar(1,color(midgreen)) bar(2,color(black))
legend(off)
;
#delim cr
*graph bar (firstnm) e_tau, over(wb_code, sort(e_tau) descending label(angle(90))) ytitle("Expected inaction of reforms")
gr export "$figures/expected_inaction.png", replace

//Adding typical variance
summarize var_tau
local m=round(r(mean),0.01)
set obs 38
replace wb_code = "OECD" in 38
replace var_tau = `m' in 38
separate var_tau, by(wb_code == "OECD")

#delim;
graph bar var_tau var_tau1,
nofill over(wb_code, sort(var_tau) descending label(angle(90))) ytitle("Dispersion of inaction") bar(1,color(purple)) bar(2,color(gs2))
legend(off)
;
#delim cr

*graph dot var_tau, over(wb_code) ytitle("Dispersion of inaction")
gr export "$figures/inaction_variance.png", replace
restore

*-----------
*Reform size
*-----------

egen tamano_reforma = total(reform_size), by(wb_code) //Total reform size by country
gen e_delta_cit = tamano_reforma/cty_reforms // Average size of reforms
egen var_delta_cit = sd(reform_size), by(wb_code) // Reform variance
replace var_delta_cit = var_delta_cit * var_delta_cit

preserve
collapse (firstnm) e_delta_cit var_delta_cit, by(wb_code)
drop if e_delta_cit == .
replace var_delta_cit = 0 if var_delta_cit == .
lab var e_delta_cit "Expected size of reforms"
lab var var_delta_cit "Variation in reform size"
//Adding average
summarize e_delta_cit
local m=round(r(mean),0.01)
set obs 38
replace wb_code = "OECD" in 38
replace e_delta_cit = `m' in 38
separate e_delta_cit, by(wb_code == "OECD")
//Plot expected size of reform
#delim;
graph bar e_delta_cit e_delta_cit1,
nofill over(wb_code, sort(e_delta_cit) descending label(angle(90))) ytitle("Expected size of reforms") bar(1,color(emidblue)) bar(2,color(black))
legend(off)
;
#delim cr
gr export "$figures/expected_reform_size.png", replace

//Adding typical variance
summarize var_delta_cit
local m=round(r(mean),0.01)
set obs 38
replace wb_code = "OECD" in 38
replace var_delta_cit = `m' in 38
separate var_delta_cit, by(wb_code == "OECD")
//Plot variance
#delim;
graph bar var_delta_cit var_delta_cit1,
nofill over(wb_code, sort(var_delta_cit) descending label(angle(90))) ytitle("Variation in reform size") bar(1,color(lavender)) bar(2,color(gs3))
legend(off)
;
#delim cr
*graph dot var_delta_cit, over(wb_code) ytitle("Variation in reform size") marker(1,mcolor(emidblue))
gr export "$figures/reform_size_variance.png", replace
restore

*** 5.By cohort ***
// Identify cohorts
by iso_num: gen flag = 1 if corporate_tr ~= .
by iso_num: gen counter = sum(flag ==1)
by iso_num: gen cohort_flag = 1 if counter == 1
gen cohort = year/10 if cohort_flag == 1
replace cohort = (floor(cohort))*10
drop flag - cohort_flag
by iso_num: egen avg_cohort = total(cohort)
drop cohort
ren avg_cohort cohort
drop if cohort == 0 // Drop countries with no cit data

foreach coh in 1960 1970 1980 1990{
	preserve
	keep if cohort == `coh'
	egen global_reforms = total(reform), by(year) missing
	egen size_reforms = total(reform_size), by(year) missing
	gen avg_size_reforms = size_reforms/global_reforms
	egen spell = total(duration), by(year) missing
	gen avg_spell = spell/global_reforms
	collapse(firstnm) global_reforms avg_size_reforms avg_spell, by(year)
	lab var global_reforms "Number of reforms"
	lab var avg_size_reforms "Average size of reforms"
	lab var avg_spell "Average reform spell"
	#delim ;
	twoway bar global_reforms year ||
	line avg_size_reforms avg_spell year,
	name(f`coh', replace)
	;
	#delim cr
	gr export "$figures/cit_reforms_`coh'.png", replace
	replace  avg_size_reforms = round(avg_size_reforms, 0.01)
	replace  avg_spell = round(avg_spell, 0.01)
	estpost tabstat global_reforms avg_size_reforms avg_spell, by(year) 
	esttab . using cit_reforms_cohort_`coh'.tex, cells("global_reforms(label(`:var lab global_reforms')) avg_size_reforms(label(`:var lab avg_size_reforms')) avg_spell(label(`:var lab avg_spell'))" ) ///
	noobs nomtitle nonumber varlabels(`e(labels)') varwidth(20) drop(Total) replace
	restore
}

