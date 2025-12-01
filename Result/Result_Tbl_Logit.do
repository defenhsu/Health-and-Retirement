/* This file generate the "Table of Probability for Compliance by Health Satus and Wealth" and show compliance probabilities across the own health status, spouse health status, and whether saved enough for retirement.
Additionally, this file also generate "Table of Weighted Means by LATE group". 
To make sure the results are rebust to early retirement instrument, we also compare results using different controls and restriction. */

capture file close _all
program drop _all
sca drop _all
cd "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\RA"
include "MakeData\Step0_SetDirectory"
log using "${log}HR1_LOGIT_REG_$date", replace text name("Ariel") 
*******************************************
*** Different contrals and restriction to test robustness ***

local Fuzzy _Fuzzy //  =>  Elig.; no string => Exact Elig
local Z_control  // admin3_eligible_early_at_svy5 => include early elig. as controls; no string=> exclude early elig.
local spouse  //// svy3_sphlthpoor => include spouse health as controls; no string=> exclude spouse health

**************************************************
use "${working}Admin3_Survey3`Fuzzy'.dta", clear // using MakeData_Admin3_Survey3.do (Aug 2023). Data restriction: answered own_health, married and has job classification

if "`Z_control'" == "admin3_eligible_early_at_svy5" {
local control_footnote , early pension eligibility
local file_name BinaryControl`Fuzzy' //_bootstrap_`bootstrap_time'  _NoSP
} 
else {
local control_footnote 
local file_name NoControl`Fuzzy' //_bootstrap_`bootstrap_time'  _NoSP
}
if "`spouse'" == "svy3_sphlthpoor" { 
local spcontrol_footnote own and spouse's health status  
local file_name `file_name'
} 
else {
local spcontrol_footnote own health status  
local file_name `file_name'_NoSp
}

*** Treatment = Retirement
tab admin5_status_not_ret
gen not_working = 1-admin5_status_not_ret
gen D = not_working

*** Instrument = Elig. for Normal Retirement Benefit
gen Z = admin3_eligible_normal_at_svy5
tab Z,m
gen Ze = admin3_eligible_early_at_svy5

*** LABELS
lab var Z "Elig Normal" //"Eligible Normal (Full Benefits)" //"Normal Eligible as of December 2017"
lab var admin3_eligible_early_at_svy5 "Elig Early" //"Eligible Early (Reduced Benefits)" // "Early Eligible as of December 2017"
lab var admin3_eligible_none_at_svy5 "Not Yet Eligible for Benefits" //"Not Eligible as of December 2017"
label var not_working "Not Working"
label var svy3_own_health_poor "Poor Health"
label var svy3_married "Married"
/*label var atype_school "Public School Employee"
label var atype_stategovt "State Gov't Employee"
label var total_salary "Salary (10K)"
label var race_blk "Black"
label var race_hisp "Hispanic"
label var race_other "Other Race"
label var educ_ba "College Degree"
label var nkids12 "1-2 Kids"
label var nkids34 "3+ Kids"*/
label var svy3_educ_blank "Missing Data on Education"
gen admin3_int_age = int(admin3_age_at_svy3) //truncating age toward 0. Could not skip this step if we want to run peak value py code. Otherwise the merge won't work.
gen admin3_int_yos = int(admin3_yos_at_svy3) //truncating YOS toward 0  Could not skip this step if we want to run peak value py code. Otherwise the merge won't work.

tab admin3_int_age, gen(age)
lab var age1 "Age 52"
lab var age2 "Age 53"
lab var age3 "Age 54"
lab var age4 "Age 55"
lab var age5 "Age 56"
lab var age6 "Age 57"
lab var age7 "Age 58"
lab var age8 "Age 59"
lab var age9 "Age 60"
lab var age10 "Age 61"
lab var age11 "Age 62"
lab var age12 "Age 63"
lab var age13 "Age 64"

gen svy3_notenough_money = 1 - svy3_enough_money

global demo `Z_control' svy3_own_health_poor `spouse' admin3_female svy3_married_partner ///
	svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss ///
 svy3_race_black svy3_race_hisp svy3_race_other  ///
 svy3_educ_ba svy3_educ_blank admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015 admin3_yos_at_svy3 ///
age2 age3 age4 age5 age6 age7 age8 age9 age10 age11 age12 age13

 su $demo
 
**************
***Programs***
**************

// Logit Regression //

program logit_reg, rclass

args sample

logit D Z $demo, robust
estadd ysumm
margins, dydx(*) post
estadd scalar pdiff = r(p)
estadd ysumm
eststo logit_`sample'

end




// Output //

*** Table 1 ***
file open tbl using "${output}Tbl_Logit_`file_name'.tex", write replace //_`time'
file write tbl "\begin{table}[h!]\centering" _n "\caption{Logit Regression Model, Marginal Effects}" _n "\label{tbl-logit}" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n "\resizebox{\linewidth}{!}{%" _n
file write tbl "\begin{tabular}{l*{5}{c}}" _n
file write tbl "\toprule"  _n
file write tbl " &Full   & Good   &  Poor    & Saved   &  Not    \\ " _n
file write tbl " &Sample & Health &  Health  & Enough  & Enough  \\ " _n
file write tbl " & (1)   & (2a) & (2b) & (3a) & (3b) \\ " _n
file close tbl

logit_reg full

local result logit_full 

foreach v in svy3_own_health_poor  svy3_notenough_money { //svy3_sphlthpoor => Spouse Health is excluded since September 2023
forvalues n = 0/1 {
preserve
keep if `v' == `n' & `v' <. 
logit_reg `v'`n'

local result `result' logit_`v'`n'
restore
}
}

di "`result'"

esttab `result' using "${output}Tbl_Logit_`file_name'.tex", append ///_`time'
	lab b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) keep(Z $demo) order(Z $demo) noomit obs nobase nogap nomtitles nonumbers fragment

file open tbl using "${output}Tbl_Logit_`file_name'.tex", write append //_`time'	
file write tbl "\bottomrule" _n "\end{tabular}\\" _n "}" _n
file write tbl  "\\{\footnotesize Notes: Regression estimates are parallel to Table \ref{tbl-compliers}.  Coefficients are marginal effects from a Logit model that includes indicators for `spcontrol_footnote', gender, marital status, age dummies, years of service`control_footnote', salary, race/ethnicity indicators, number of children, education, and agency type indicators.}" _n
file write tbl "\end{table}" _n
file close tbl	

log close _all 
exit 


/* \begin{table}[]
    \caption{Logit Regression Model, Marginal Effects}
    \label{tab:app}
\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}

    \begin{center}
   \begin{tabular}{l*{7}{c}}
\toprule
&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}&\multicolumn{1}{c}{(7)}\\
                    &\multicolumn{1}{c}{Full}&\multicolumn{1}{c}{Good Health}&\multicolumn{1}{c}{Poor Health}&\multicolumn{1}{c}{Sp Good}&\multicolumn{1}{c}{Sp Poor}&\multicolumn{1}{c}{Saved Enough}&\multicolumn{1}{c}{Not Enough}\\
\hline
Elig Early          &       0.114\sym{***}&       0.120\sym{***}&       0.085         &       0.102\sym{***}&       0.121         &       0.147\sym{***}&       0.083\sym{**} \\
                    &     (0.028)         &     (0.029)         &     (0.114)         &     (0.034)         &     (0.100)         &     (0.047)         &     (0.034)         \\
[1em]
Elig Normal         &       0.286\sym{***}&       0.299\sym{***}&       0.143         &       0.244\sym{***}&       0.305\sym{**} &       0.334\sym{***}&       0.240\sym{***}\\
                    &     (0.035)         &     (0.036)         &     (0.160)         &     (0.044)         &     (0.122)         &     (0.059)         &     (0.043)         \\
\midrule
Observations        &        3502         &        3284         &         218         &        2209         &         331         &        1371         &        2117         \\
\bottomrule
\end{tabular}
\end{center}
{\footnotesize Notes: Regression estimates are parallel to Table \ref{tbl-compliers}.  Coefficients are marginal effects from a Logit model that includes indicators for own and spouse's health status (where appropriate), gender, marital status, age dummies, years of service, salary, race/ethnicity indicators, number of children, education, and agency type indicators.  }
\end{table}*/
