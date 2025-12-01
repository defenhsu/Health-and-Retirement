/* This file generate the "Table of Probability for Compliance" and show compliance probabilities across the own health status, spouse health status */

capture file close _all

include "Step0_SetDirectory"
log using "${log}HR2_REGS_Baseline_$date", replace text name("Ariel") 
*******************************************
use "${working}Admin3_Survey3.dta", clear // using MakeData_Admin3_Survey3.do (June 2022)

tab admin5_status_not_ret
gen not_ret = admin5_status_not_ret
gen ret= 1-not_ret

lab var admin3_eligible_normal_at_svy5 "Eligible Normal (Full Benefits)" //"Normal Eligible as of December 2017"
lab var admin3_eligible_early_at_svy5 "Eligible Early (Reduced Benefits)" // "Early Eligible as of December 2017"
lab var admin3_eligible_none_at_svy5 "Not Yet Eligible for Benefits" //"Not Eligible as of December 2017"
label var not_ret "Actively Working"
*label var elig_early "Elig Early"
*label var elig_norm "Elig Normal"
label var svy3_own_health_poor "Poor Health"
label var svy3_married "Married"
/*label var female "Female"
label var atype_school "Public School Employee"
label var atype_stategovt "State Gov't Employee"
label var total_salary "Salary (10K)"
label var race_blk "Black"
label var race_hisp "Hispanic"
label var race_other "Other Race"
label var educ_ba "College Degree"
label var nkids12 "1-2 Kids"
label var nkids34 "3+ Kids"
label var nkidsmis "Missing Data on Kids"
*/
label var ret "Retired"
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

global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married admin3_female admin3_yos_at_svy3 age2-age13 svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss  svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba svy3_educ_blank admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015"

 
****************************
*** linearity in first stage
****************************

dprobit ret admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 $demo, robust
estadd r(mean)
eststo h

forvalues i = 2 / 5 {
dprobit ret admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 $demo if svy3_own_health == `i', robust
estadd r(mean)
eststo hlt`i'
}

esttab h hlt2 hlt3 hlt4 hlt5 using "${output}tbl_TEMP.csv" ///
, mtitle("All" "Fair" "Good" "Very Good" "Excellent") se(3) b(3) replace label  star(* 0.10 ** 0.05 *** 0.01) ///


* COL 1: ELIGIBILITY ONLY

reg ret admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 $demo, robust
sum ret if e(sample)==1
estadd r(mean)
margins, dydx(*) post
*test elig_early = elig_norm
estadd scalar pdiff = r(p)
eststo col1_m

**** CCM WORK ****
*********************************************
*** COMPLIANCE PROBABILITIES BY HEALTH STATUS 
*********************************************
/** D = Retired
* Among those working, what fraction are compliers with early (or normal) IV
* Among those not working, what fraction are compliers?
*file write tbl " & N & \$P[D=1]$ & \$P[D_1 > D_0]$ & \$P[Z=1]$ & \$P[D_1 > D_0 | D = 1]$ & \$P[D_1 > D_0 | D = 0]$ \\ " _n
*/
file open tbl using "${output}Compliance_Tbl.tex", write replace
file write tbl "\begin{landscape}" _n "\begin{table}[h!]\centering" _n "\caption{Probabilities of Compliance}" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n "\resizebox{\columnwidth}{!}{%" _n
file write tbl "\begin{tabular}{l*{10}{c}}" _n
file write tbl "\hline \hline"  _n
file write tbl " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) & (9) & (10) \\ " _n
file write tbl " &   & Working 2017 & Early Coeff.    & Early Prob.       & \multicolumn{2}{c}{Compliance Probabilities}      & Normal Coeff.    & Normal Prob.       & \multicolumn{2}{c}{Compliance Probabilities}      \\ " _n
file write tbl " & N & \$P[D=1]$    & \$P^{Early}[D_1 > D_0]$ & \$P[Z^{Early}=1]$ & \$P^{Early}[D_1 > D_0 | D = 1]$ & \$P^{Early}[D_1 > D_0 | D = 0]$ & \$P^{Normal}[D_1 > D_0 ]$  & \$P[Z^{Normal}=1]$ & \$P^{Normal}[D_1 > D_0 | D = 1]$ & \$P^{Normal}[D_1 > D_0 | D = 0]$ \\ " _n


*** OVERALL PROBABILITY OF COMPLIANCE

*First Stage

reg ret admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 $demo, robust
margins, dydx(*) post
sca fs_e = _b[admin3_eligible_early_at_svy5]
sca fs_n = _b[admin3_eligible_normal_at_svy5]


*P[D=1]
mean ret
sca pd1 = _b[ret]

*P[Z=1]
mean admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5
sca pz1_e = _b[admin3_eligible_early_at_svy5]
sca pz1_n = _b[admin3_eligible_normal_at_svy5]
sca N = _N


di N
di pd1 //P[D=1]
di fs_e //P^{Early}[D_1 > D_0]
di pz1_e //P[Z^{Early}=1]
di fs_e*pz1_e/pd1 // Prob of Compliance for Early Retirement
di (1-pz1_e)*fs_e/(1-pd1) 
di fs_n //P^{Normal}[D_1 > D_0]
di pz1_n //P[Z^{Normal}=1]
di fs_n*pz1_n/pd1 // Prob of Compliance for Normal Retirement
di (1-pz1_n)*fs_n/(1-pd1) 


file write tbl "\hline \\" _n  //"[1em] " _n
file write tbl "Full Sample & " (N) " & " %4.3f (pd1) " & " %4.3f (fs_e) " & " %4.3f (pz1_e) " & " %4.3f (fs_e*pz1_e/pd1) " & " %4.3f ((1-pz1_e)*fs_e/(1-pd1)) 
file write tbl "& " %4.3f (fs_n) " & " %4.3f (pz1_n) " & " %4.3f (fs_n*pz1_n/pd1) " & " %4.3f ((1-pz1_n)*fs_n/(1-pd1)) " \\" _n
file write tbl "[1em] " _n "\hline \\" _n //"[1em] " _n

file write tbl " & \multicolumn{10}{c}{By Own Health Status}\\" _n "[1em] " _n


*** NOW SEPARATELY BY HEALTH STATUS ****
di "svy3_own_health_poor"

forvalues i = 0/1 {

preserve

keep if svy3_own_health_poor == `i'

reg ret admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 $demo, robust
margins, dydx(*) post
sca fs_e = _b[admin3_eligible_early_at_svy5]
sca fs_n = _b[admin3_eligible_normal_at_svy5]

*P[D=1]
mean ret
sca pd1 = _b[ret]

*P[Z=1]
mean admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5
sca pz1_e = _b[admin3_eligible_early_at_svy5]
sca pz1_n = _b[admin3_eligible_normal_at_svy5]
sca N = _N

if `i' == 1 {
	file write tbl "Poor & " (N) " & " %4.3f (pd1) " & " %4.3f (fs_e) " & " %4.3f (pz1_e) " & " %4.3f (fs_e*pz1_e/pd1) " & " %4.3f ((1-pz1_e)*fs_e/(1-pd1)) 
file write tbl "& " %4.3f (fs_n) " & " %4.3f (pz1_n) " & " %4.3f (fs_n*pz1_n/pd1) " & " %4.3f ((1-pz1_n)*fs_n/(1-pd1)) " \\" _n
}
else {
	file write tbl "Good & " (N) " & " %4.3f (pd1) " & " %4.3f (fs_e) " & " %4.3f (pz1_e) " & " %4.3f (fs_e*pz1_e/pd1) " & " %4.3f ((1-pz1_e)*fs_e/(1-pd1)) 
file write tbl "& " %4.3f (fs_n) " & " %4.3f (pz1_n) " & " %4.3f (fs_n*pz1_n/pd1) " & " %4.3f ((1-pz1_n)*fs_n/(1-pd1)) " \\" _n
}

restore
}

file write tbl "[1em] " _n " & \multicolumn{10}{c}{By Own Health Rating}\\" _n "[1em] " _n


forvalues i = 2/5 {

preserve

** AMONG THOSE NOT YET ELIGIBLE FOR NORMAL BENEFITS, WHAT ARE THE STATS -- AND THEN FOR THOSE 

keep if svy3_own_health == `i'

reg ret admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 $demo, robust
margins, dydx(*) post
sca fs_e = _b[admin3_eligible_early_at_svy5]
sca fs_n = _b[admin3_eligible_normal_at_svy5]

*P[D=1]
mean ret
sca pd1 = _b[ret]

*P[Z=1]
mean admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5
sca pz1_e = _b[admin3_eligible_early_at_svy5]
sca pz1_n = _b[admin3_eligible_normal_at_svy5]
sca N = _N

if `i' == 1 {
	file write tbl "Poor & " (N) " & " %4.3f (pd1) " & " %4.3f (fs_e) " & " %4.3f (pz1_e) " & " %4.3f (fs_e*pz1_e/pd1) " & " %4.3f ((1-pz1_e)*fs_e/(1-pd1)) 
	file write tbl "& " %4.3f (fs_n) " & " %4.3f (pz1_n) " & " %4.3f (fs_n*pz1_n/pd1) " & " %4.3f ((1-pz1_n)*fs_n/(1-pd1)) " \\" _n
}
else if `i' == 2 {
	file write tbl "Fair & " (N) " & " %4.3f (pd1) " & " %4.3f (fs_e) " & " %4.3f (pz1_e) " & " %4.3f (fs_e*pz1_e/pd1) " & " %4.3f ((1-pz1_e)*fs_e/(1-pd1)) 
	file write tbl "& " %4.3f (fs_n) " & " %4.3f (pz1_n) " & " %4.3f (fs_n*pz1_n/pd1) " & " %4.3f ((1-pz1_n)*fs_n/(1-pd1)) " \\" _n
	
}
else if `i' == 3 {
	file write tbl "Good & " (N) " & " %4.3f (pd1) " & " %4.3f (fs_e) " & " %4.3f (pz1_e) " & " %4.3f (fs_e*pz1_e/pd1) " & " %4.3f ((1-pz1_e)*fs_e/(1-pd1)) 
	file write tbl "& " %4.3f (fs_n) " & " %4.3f (pz1_n) " & " %4.3f (fs_n*pz1_n/pd1) " & " %4.3f ((1-pz1_n)*fs_n/(1-pd1)) " \\" _n
}
else if `i' == 4 {
	file write tbl "Very Good & " (N) " & " %4.3f (pd1) " & " %4.3f (fs_e) " & " %4.3f (pz1_e) " & " %4.3f (fs_e*pz1_e/pd1) " & " %4.3f ((1-pz1_e)*fs_e/(1-pd1)) 
	file write tbl "& " %4.3f (fs_n) " & " %4.3f (pz1_n) " & " %4.3f (fs_n*pz1_n/pd1) " & " %4.3f ((1-pz1_n)*fs_n/(1-pd1)) " \\" _n
}
else {
	file write tbl "Excellent & " (N) " & " %4.3f (pd1) " & " %4.3f (fs_e) " & " %4.3f (pz1_e) " & " %4.3f (fs_e*pz1_e/pd1) " & " %4.3f ((1-pz1_e)*fs_e/(1-pd1)) 
	file write tbl "& " %4.3f (fs_n) " & " %4.3f (pz1_n) " & " %4.3f (fs_n*pz1_n/pd1) " & " %4.3f ((1-pz1_n)*fs_n/(1-pd1)) " \\" _n
}

restore

}

di "svy3_sphlthpoor"

file write tbl "[1em] " _n " & \multicolumn{10}{c}{By Spouse Health Status}\\" _n "[1em] " _n


forvalues i = 0/1 {

preserve

keep if svy3_sphlthpoor == `i'

reg ret admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 $demo, robust
margins, dydx(*) post
sca fs_e = _b[admin3_eligible_early_at_svy5]
sca fs_n = _b[admin3_eligible_normal_at_svy5]

*P[D=1]
mean ret
sca pd1 = _b[ret]

*P[Z=1]
mean admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5
sca pz1_e = _b[admin3_eligible_early_at_svy5]
sca pz1_n = _b[admin3_eligible_normal_at_svy5]
sca N = _N

if `i' == 1 {
	file write tbl "Poor & " (N) " & " %4.3f (pd1) " & " %4.3f (fs_e) " & " %4.3f (pz1_e) " & " %4.3f (fs_e*pz1_e/pd1) " & " %4.3f ((1-pz1_e)*fs_e/(1-pd1)) 
	file write tbl "& " %4.3f (fs_n) " & " %4.3f (pz1_n) " & " %4.3f (fs_n*pz1_n/pd1) " & " %4.3f ((1-pz1_n)*fs_n/(1-pd1)) " \\" _n
}
else {
	file write tbl "Good & " (N) " & " %4.3f (pd1) " & " %4.3f (fs_e) " & " %4.3f (pz1_e) " & " %4.3f (fs_e*pz1_e/pd1) " & " %4.3f ((1-pz1_e)*fs_e/(1-pd1)) 
	file write tbl "& " %4.3f (fs_n) " & " %4.3f (pz1_n) " & " %4.3f (fs_n*pz1_n/pd1) " & " %4.3f ((1-pz1_n)*fs_n/(1-pd1)) " \\" _n
}

restore

}



file write tbl "[1em]" _n "\hline \hline" 
file write tbl "\multicolumn{11}{l}{\footnotesize Note that \$P^{Early}(D_1 > D_0) = E[D | Z^{Early}=1, Z^{Normal}, X ] - E[D|Z^{Early}=0, Z^{Normal}, X]$ and \$P^{Normal}(D_1 > D_0) = E[D | Z^{Normal}=1, Z^{Early}, X ] - E[D|Z^{Normal}=0, Z^{Early}, X ]$ }\\" _n
file write tbl "\multicolumn{11}{l}{\footnotesize The sample is derived from the NCRTS dataset and includes $count workers ages 52-65 who were actively employed as of May 2016. See Data Appendix for details on full sample restrictions and variable definitions. }\\" _n
file write tbl "\multicolumn{11}{l}{\footnotesize D is defined as retired in 2017. \$Z^{early}$ indicates eligibility for early retirement benefit; while \$Z^{normal}$ indicates eligibility for normal retirement benefit }\\" _n
file write tbl "\multicolumn{11}{l}{\footnotesize Both early coefficient and normal coefficent controls for own health status, spouse health status, marital status, gender, race, years of services, age, number of kids, salary, occupation, education attainment. }\\" _n
file write tbl "\end{tabular}" _n "}"_n "\end{table}"_n "\end{landscape}" _n "" _n "" _n "" _n "" _n "" _n
file close tbl




*****************************
*** Alternative Summary Stats
*****************************
** AMONG THOSE NOT YET ELIGIBLE FOR NORMAL BENEFITS, WHAT ARE THE STATS -- AND THEN FOR THOSE 

lab var admin3_eligible_SS_at_svy5 "Eligible Social Security Benefits" 

global demo "ret svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female admin3_int_age admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015"
global pension "admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 admin3_eligible_none_at_svy5 admin3_eligible_SS_at_svy5"


estpost tabstat ret $demo, statistics(n mean semean) columns(statistics)
eststo col1

estpost tabstat ret $demo if admin3_eligible_normal_at_svy5 ==1 , statistics(n mean semean) columns(statistics)
eststo col2

estpost tabstat ret $demo if admin3_eligible_early_at_svy5 ==1 , statistics(n mean semean) columns(statistics)
eststo col3

estpost tabstat ret $demo if admin3_eligible_SS_at_svy5 ==1 , statistics(n mean semean) columns(statistics)
eststo col4

estpost tabstat ret $demo if admin3_eligible_none_at_svy5 ==1 , statistics(n mean semean) columns(statistics)
eststo col5

lab var admin3_int_age "Age as of Survey 5" //"Normal Eligible as of December 2017"
lab var admin3_int_yos "Yos as of Survey 5" 


esttab col1 col2 col3 col4 col5 using "${output}Compliance_Tbl.tex", append ///
main(mean 3) aux(semean 3) nostar unstack nogaps label ///
title(Table 1: Summary Statistics) mtitles("Full Sample" "Elig. Normal" "Elig. Early" "Elig. SS" "Elig. None") ///
note(Notes: The sample is derived from the NCRTS dataset and includes workers ages 52-65 who were actively employed as of May 2016. ///
See Data Appendix for details on full sample restrictions and variable definitions.)




log close _all
exit


