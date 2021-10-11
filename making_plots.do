********************************************************************************
*** Making plots
********************************************************************************
*** Main inputs: taxes_master or taxes_master_lite
*** Output: .png files
*** Author: Nicolas Oviedo
*** Original: 02/10/2021
********************************************************************************
*** Set up
********************************************************************************
cls
query memory
set more off

***User Settings***

*User: andres
//global who = "A" 

*User: Nicolas
global who = "N" 

*User: Isaac
//global who = "I" 
********************************************************************************	
* -------------         Paths and Logs            ------------------------------
********************************************************************************
if "$who" == "A"  global pathinit "/Users/jablanco/Dropbox (University of Michigan)/papers_new/LumpyTaxes"
if "$who" == "N"  global pathinit "C:\Users\Ovi\Desktop\R.A"

global output_data "$pathinit/Data/outputs"
global input_data  "$pathinit/Data/inputs"
global figures     "$pathinit/figures/fig_present/Taxes"
global temp_file   "$pathinit/Data/Temp"

cap log close
log using "$temp_file/makingplots.log", append
use "$output_data/taxes_master", clear
*Code may be run using taxes_master_lite.dta as well
 
/*frame copy default grapher
frame change grapher
frame dir
We choose to graph in another Stata frame as to change frames and query the orginial .dta file while generating plots.*/
set scheme plotplain
********************************************************************************
*** Individual Income Tax Rate
********************************************************************************
*replace individual_tr = individual_tr/100
*lab var individual_tr "Personal Income Tax - {&tau}{superscript:p}"

egen pit_p25 = pctile(individual_tr), by(year) p(25)
egen pit_p50 = pctile(individual_tr), by(year) p(50)
egen pit_p75 = pctile(individual_tr), by(year) p(75)

*OECD countries - max. marginal individual income tax rate - percentiles
preserve
collapse (firstnm) pit*, by(year)
tsset year

lab var pit_p25 "25th Percentile"
lab var pit_p50 "50th Percentile"
lab var pit_p75 "75th Percentile"
lab var year "Year"
 
#delim ;
line pit_p25 pit_p50 pit_p75 year if inrange(year,1980,2019), 
lpattern(dot solid dash) lwidth(thick thick thin) lcolor(g1 ..)
name(f1,replace) 
title(Personal Income Tax (t{superscript:p})) 
scheme(s1mono) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2020)) 
yscale(range(20 80)) 
xlabel(1980(10)2020) 
ylabel(20(20)80)
;
#delim cr
//note("Sources: Vegh and Vuletin (2015), OECD Tax Database,  World Tax Database (University of Michigan)") 
gr export "$figures/motivation_pit.png", replace
*Export before closing graph window
qui restore
 
*Selected countries - max. marginal individual income tax rate - percentiles
#delim ;
xtline individual_tr if inrange(year,1980,2019) & inlist(wb_code,"USA","DEU","CHL"), overlay
plot1opts(lwidth(medthick)) plot2opts(lwidth(medthick)) plot3opts(lwidth(medthick))
name(f1c1,replace) 
title(Personal Income Tax (t{superscript:p}))
ytitle("")
scheme(s1color) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(20 80)) 
xlabel(1980(10)2020) 
ylabel(20(20)80)
;
#delim cr
//note("Sources: Vegh and Vuletin(2015), OECD Tax Database,  World Tax Database (University of Michigan)")
gr export "$figures/motivation_pit_selected.png", replace
drop _all
 
/*Raw style: selected countries

#delim ;
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
gr export "$main/output/personal_income_selected_countries.png", replace
#delim cr*/

/*Raw style: OECD

#delim ;
line pit_p25 pit_p50 pit_p75 year if inrange(year,1970,2020),
name(f5,replace)  
title("Personal Income Tax (OECD)",size(medium)) 
scheme(plotplainblind) 
legend(ring(0) col(1) bmargin(20 0 2 0)  region(lpattern(blank)))  
yscale(range(0.2 .80)) 
xscale(range(1980 2016))  
xlabel(1970(10)2020)  
ylabel(0.2(.20).80)
ytitle("{&tau}{superscript:p}",size(medium))
;
gr export "$main/output/personal_income_ocde_percentil.png", replace
#delim cr*/

********************************************************************************
*** Corporate Income Tax Rate
********************************************************************************
use "$output_data/taxes_master", clear
*replace corporate_tr = corporate_tr/100
*lab var corporate_tr "Corporate Income Tax - t{superscript:c}"

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
//note("Source: Vegh and Vuletin (2015)")
gr export "$figures/motivation_cit.png", replace
qui restore

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
// note("Source: Vegh and Vuletin (2015)")
gr export "$figures/motivation_cit_selected.png", replace

*For publishing
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

*Black and white with Japan
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
note("Source: Vegh and Vuletin (2015)");
#delim cr

*gr export "$figures/bw_cit_selected.png", replace
gr export "C:\Users\Ovi\Desktop\R.A\Corporate taxes are important\bw_cit_selected.png"


drop _all
 
********************************************************************************
*** Capital Gains Tax Rate
********************************************************************************
use "$output_data/taxes_master", clear
*Plot 1998-2020
egen cgt_p25 = pctile(capital_gains_rate), by(year) p(25)
egen cgt_p50 = pctile(capital_gains_rate), by(year) p(50)
egen cgt_p75 = pctile(capital_gains_rate), by(year) p(75)

preserve
collapse (firstnm) cgt*, by(year)
tsset year

replace cgt_p25=. if year<=1997
replace cgt_p75=. if year<=1997

gen re_scale=cgt_p50/cgt_p50[_n+1] if year==1997
egen aux_var=mean(re_scale) if year<=1997
replace cgt_p50=cgt_p50/aux_var  if year<=1997
drop  aux_var re_scale
 
lab var cgt_p25 "25th Percentile"
lab var cgt_p50 "50th Percentile"
lab var cgt_p75 "75th Percentile"
lab var year "Year"

#delim ;
line cgt_p25 cgt_p50 cgt_p75 year if inrange(year,1998,2020),
lpattern(dot solid dash) lwidth(thick thick thin) lcolor(g1 ..)
name(f3,replace) 
title("Capital Gains Tax (t{superscript:g})") 
scheme(s1color) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1998 2019)) 
yscale(range(0 50)) 
xlabel(1998(10)2020) 
ylabel(0(10)50)
;
#delim cr
//note("Main sources: Asen and Bunn (2020) & Spengel et al.(2019)", size(vsmall))
gr export "$figures/motivation_cgt.png", replace
qui restore

*Plot USA DEU CHL
#delim ;
xtline capital_gains_rate if inrange(year,1983,2020) & inlist(wb_code,"USA","DEU","CHL"), overlay
plot1opts(lwidth(medthick)) plot2opts(lwidth(medthick)) plot3opts(lwidth(medthick))
name(f3c3,replace) 
title("Capital Gains Tax (t{superscript:g})") 
ytitle("")
scheme(s1color) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(25 45)) 
xlabel(1980(10)2020) 
ylabel(25(10)45)
;
#delim cr
// note("Main sources: Spengel et al.(2019) & Tax Foundation", size(vsmall))
gr export "$figures/motivation_cgt_selected.png", replace

*Plot selected countries 1960 - 1997 unweighted
use "$output_data/taxes_master", clear

#delim ;
xtline capital_gains_rate if inrange(year,1960,1997) & inlist(wb_code,"USA","DEU","CHL","AUS","CAN","DNK","ESP","ITA","POL"), overlay
name(f3c10,replace) 
title("Capital Gains Tax (t{superscript:g}) 1960-1997") 
ytitle("")
scheme(s1color) 
legend(off)
xscale(range(1960 2000)) 
yscale(range(0 60)) 
xlabel(1960(10)1997) 
ylabel(0(10)60)
addplot(scatter capital_gains_rate year if year==1997, ms(none) mla(wb_code) mlabsize(tiny))
;
#delim cr
// note("Multiple sources (see Online Appendix)", size(vsmall))
gr export "$figures/cgt_1960_1997_unweighted.png", replace

*Plot entire unweighted data panel
use "$output_data/taxes_master", clear
  
egen cgt_p25 = pctile(capital_gains_rate), by(year) p(25)
egen cgt_p50 = pctile(capital_gains_rate), by(year) p(50)
egen cgt_p75 = pctile(capital_gains_rate), by(year) p(75)

preserve
collapse (firstnm) cgt*, by(year)
tsset year
/*
replace cgt_p25=. if year<=1997
replace cgt_p75=. if year<=1997

gen re_scale=cgt_p50/cgt_p50[_n+1] if year==1997
egen aux_var=mean(re_scale) if year<=1997
replace cgt_p50=cgt_p50/aux_var  if year<=1997
drop  aux_var re_scale
 */
lab var cgt_p25 "25th Percentile"
lab var cgt_p50 "50th Percentile"
lab var cgt_p75 "75th Percentile"
lab var year "Year"

#delim ;
line cgt_p25 cgt_p50 cgt_p75 year if inrange(year,1980,2020),
lpattern(dot solid dash) lwidth(thick thick thin) lcolor(g1 ..)
name(f3all,replace) 
title("Capital Gains Tax (t{superscript:g})") 
scheme(s1color) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(0 50)) 
xlabel(1980(10)2020) 
ylabel(0(10)50)
;
#delim cr
// note("Main sources: Asen and Bunn (2020) & Spengel et al.(2019)", size(vsmall))
gr export "$figures/cgt_all.png", replace
qui restore

drop _all

********************************************************************************
*** Capital Gains Tax Rate - weighted plots
********************************************************************************
*Weight by capital stock (cn)
gen w =.
local N = _N
foreach i in 1/`N'{
replace w = cn if capital_gains_rate != . in `i'
}
bysort year: egen cn_total = total(w)
gen cn_share = w/cn_total
gen cgt_weight = capital_gains_rate*cn_share
bysort year: egen avg_cgt_cn = total(cgt_weight)
*br wb_code year capital_gains_rate cn_share cgt_weight

lab var cn_total "Sum of capital stock of countries with non missing values for capital gains tax rate"
lab var cn_share "Share of capital stock -among countries with non missing value on capital gains tax rate in that year"
lab var cgt_weight "Capital gains tax rate multiplied by country share of capital stock, among those with reported rates"

/*Plot: weighted by capital stock
Capital gains taxes multiplied by country share of world capital stock in a given year
egen cgt_p25 = pctile(cgt_weight), by(year) p(25)
egen cgt_p50 = pctile(cgt_weight), by(year) p(50)
egen cgt_p75 = pctile(cgt_weight), by(year) p(75)

preserve
drop cgt_weight
collapse (firstnm) cgt*, by(year)
tsset year
lab var avg_cgt_cn "Weighted average capital gains rate tax"

lab var cgt_p25 "25th Percentile"
lab var cgt_p50 "50th Percentile"
lab var cgt_p75 "75th Percentile"
lab var year "Year"

#delim ;
line cgt_p25 cgt_p50 cgt_p75 year if inrange(year,1980,2020),
lpattern(dot solid dash) lwidth(thick thick thin) lcolor(g1 ..)
name(f3allw,replace) 
title("Capital Gains Tax (t{superscript:g}) - Weighted by capital stock") 
scheme(s1color) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(0 10)) 
xlabel(1980(10)2020) 
ylabel(0(1)10)
caption("Capital gains taxes multiplied by country share of world capital stock on a given year", size(tiny))
note("Main sources: Asen and Bunn (2020) & Spengel et al.(2019)", size(vsmall));
#delim cr

gr export "$figures/cgt_all_weighted_cn.png", replace
qui restore*/

*Plot: global average capital gains tax rate, weighted by capital stock
preserve
collapse (firstnm) avg*, by(year)
tsset year
drop if year == 2020

#delim ;
line avg_cgt_cn year if inrange(year,1980,2020),
lwidth(thick)
name(f3avgcn,replace) 
title("Capital Gains Tax (t{superscript:g}) - Average weighted by capital stock") 
scheme(s1color) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(0 50)) 
xlabel(1980(10)2020) 
ylabel(0(10)50)
caption("Global average capital gains tax rate, weighted by capital stock", size(tiny))
note("Main sources: Asen and Bunn (2020) & Spengel et al.(2019)", size(vsmall));
#delim cr

gr export "$figures/cgt_avg_cn.png", replace
qui restore

*Weight by real gdp (cgdpo)
use "$output_data/taxes_master", clear
gen u =.
local N = _N
foreach i in 1/`N'{
replace u = cgdpo if capital_gains_rate != . in `i'
}
bysort year: egen cgdpo_total = total(u)
gen cgdpo_share = u/cgdpo_total
gen cgdpo_weight = capital_gains_rate*cgdpo_share
bysort year: egen avg_cgt_gdpo = total(cgdpo_weight)

lab var cgdpo_total "Sum of real gdp of countries with non missing values for capital gains tax rate"
lab var cgdpo_share "Share of real gdp among countries with non missing value on capital gains tax rate in that year"
lab var cgdpo_weight "Capital gains tax rate multiplied by country share of gdp, among those with reported rates"

/*Plot: weighted by capital stock
Capital gains taxes multiplied by country share of world gdp on a given year*/
/*egen cgt_p25 = pctile(cgdpo_weight), by(year) p(25)
egen cgt_p50 = pctile(cgdpo_weight), by(year) p(50)
egen cgt_p75 = pctile(cgdpo_weight), by(year) p(75)

preserve
drop cgdpo_weight
collapse (firstnm) cgt*, by(year)
tsset year

lab var cgt_p25 "25th Percentile"
lab var cgt_p50 "50th Percentile"
lab var cgt_p75 "75th Percentile"
lab var year "Year"

#delim ;
line cgt_p25 cgt_p50 cgt_p75 year if inrange(year,1980,2020),
lpattern(dot solid dash) lwidth(thick thick thin) lcolor(g1 ..)
name(f3allwgdp,replace) 
title("Capital Gains Tax (t{superscript:g}) - Weighted by gdp") 
scheme(s1color) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(0 10)) 
xlabel(1980(10)2020) 
ylabel(0(1)10)
caption("Capital gains taxes multiplied by country share of world gdp on a given year", size(tiny))
note("Main sources: Asen and Bunn (2020) & Spengel et al.(2019)", size(vsmall));
#delim cr

gr export "$figures/cgt_all_weighted_gdp.png", replace
qui restore*/

*Plot: global average capital gains tax rate, weighted by capital stock
preserve
collapse (firstnm) avg*, by(year)
tsset year
drop if year == 2020
lab var avg_cgt_gdpo "Weighted average capital gains rate tax"

#delim ;
line avg_cgt_gdpo year if inrange(year,1980,2020),
lwidth(thick)
name(f3avgcn,replace) 
title("Capital Gains Tax (t{superscript:g}) - Average weighted by real GDP") 
scheme(s1color) 
legend(ring(0) col(1) bmargin(70 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(0 50)) 
xlabel(1980(10)2020) 
ylabel(0(10)50)
caption("Global average capital gains tax rate, weighted by real gdp", size(tiny))
note("Main sources: Asen and Bunn (2020) & Spengel et al.(2019)", size(vsmall));
#delim cr

gr export "$figures/cgt_avg_gdp.png", replace
qui restore

********************************************************************************
*** Depreciation allowance
********************************************************************************
/*Plot weighted (by an asset's estimated share in the economy) average of net present value calculation
of capital allowances for three types of asset (bulidings, machines, intangibles). Measures the percentage
of total investment (present value cost) that a business can recover through the tax code via depreciation
on a typical investment.*/

use "$output_data/taxes_master", clear

egen dep_p25 = pctile(pdv_tot_p), by(year) p(25)
egen dep_p50 = pctile(pdv_tot_p), by(year) p(50)
egen dep_p75 = pctile(pdv_tot_p), by(year) p(75)

preserve
collapse (firstnm) dep*, by(year)
tsset year

lab var dep_p25 "25th Percentile"
lab var dep_p50 "50th Percentile"
lab var dep_p75 "75th Percentile"
lab var year "Year"

#delim ;
line dep_p25 dep_p50 dep_p75 year if inrange(year,1980,2019),
lpattern(dot solid dash) lwidth(thick thick thin) lcolor(g1 ..)
name(f4,replace) 
title("Depreciation Allowance ({&xi}{superscript:d}/({&xi}{superscript:d} + r))") 
scheme(s1mono) 
legend(ring(0) col(1) bmargin(80 0 10 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(40 80)) 
xlabel(1980(10)2020) 
ylabel(40(20)80)
note("Source: Tax Foundation");
#delim cr

gr export "$main/output/motivation_dep.png", replace

qui restore

*Selected countries*
#delim ;
xtline pdv_tot_p if inrange(year,1980,2019) & inlist(wb_code,"USA","DEU","CHL"), overlay
plot1opts(lwidth(medthick)) plot2opts(lwidth(medthick)) plot3opts(lwidth(medthick))
name(f4c4,replace) 
title("PDV of Depreciation Allowance ({&xi}{superscript:d}/({&xi}{superscript:d} + r))")
ytitle("")
scheme(s1color) 
legend(ring(0) col(1) bmargin(80 0 10 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(40 80)) 
xlabel(1980(10)2020) 
ylabel(40(20) 80)
note("Source: Tax Foundation");
#delim cr

gr export "$main/output/motivation_dep_selected.png", replace

drop _all

********************************************************************************
*** t_d
********************************************************************************
*Plot t_d
use "$output_data/taxes_master", clear

egen t_d_p25 = pctile( t_d_new), by(year) p(25)
egen t_d_p50 = pctile( t_d_new), by(year) p(50)
egen t_d_p75 = pctile( t_d_new), by(year) p(75)

preserve
collapse (firstnm) t_d_p*, by(year)
tsset year

lab var t_d_p25 "25th Percentile"
lab var t_d_p50 "50th Percentile"
lab var t_d_p75 "75th Percentile"
lab var year "Year"

*Plot t_d
#delim ;
line t_d_p25 t_d_p50 t_d_p75 year if inrange(year,1980,2019),
lpattern(dot solid dash) lwidth(thick thick thin) lcolor(g1 ..)
name(f999,replace) 
title("PDV of Depreciation Allowance (t{superscript:d})") 
scheme(s1mono) 
legend(ring(0) col(1) bmargin(80 0 40 0)  region(lpattern(blank)))  
xscale(range(1980 2019)) 
yscale(range(10 40)) 
xlabel(1980(10)2019) 
ylabel(10(10)40)
;
#delim cr
// note("Source: Tax Foundation")
gr export "$figures/motivation_td.png", replace

quietly restore

use "$output_data/taxes_master", clear
preserve
replace t_d = t_d*100
*t_d for selected countries
#delim ;
xtline t_d if inrange(year,1980,2019) & inlist(wb_code,"USA","DEU","CHL"), overlay
plot1opts(lwidth(medthick)) plot2opts(lwidth(medthick)) plot3opts(lwidth(medthick))
name(f999c0,replace) 
title("PDV of Depreciation Allowance (t{superscript:d})") 
ytitle("")
scheme(s1color) 
legend(ring(0) col(1) bmargin(80 0 50 0)  region(lpattern(blank)))  
xscale(range(1980 2020)) 
yscale(range(10 40)) 
xlabel(1980(10)2019) 
ylabel(10(10) 40)
;
#delim cr
//note("Source: Tax Foundation")
gr export "$figures/motivation_td_selected.png", replace

drop _all

********************************************************************************
*** Weighted averages
********************************************************************************
use "$output_data/taxes_master", clear
	
lab var individual_tr "Personal Income Tax (t{superscript:p})"
lab var corporate_tr "Corporate Income Tax (t{superscript:c})"
lab var capital_gains_rate "Capital Gains Tax (t{superscript:g})"
lab var pdv_tot_p "Depreciation Allowance ({&xi}{superscript:d}/({&xi}{superscript:d} + r))"
lab var t_d_new  "PDV of Depreciation Allowance (t{superscript:d})"

*Weight by capital stock (cn)
foreach var in individual_tr corporate_tr capital_gains_rate pdv_tot_p t_d_new{
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
//caption("`varlabel' for OECD countries, weighted by capital stock", size(tiny))
//note("Main sources: Asen and Bunn (2020) & Spengel et al.(2019)", size(vsmall))

*Weight by gdp
foreach var in individual_tr corporate_tr capital_gains_rate pdv_tot_p t_d_new{
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
// caption("`varlabel' for OECD countries, weighted by GDP", size(tiny))
// note("Main sources: Asen and Bunn (2020) & Spengel et al.(2019)", size(vsmall))