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
file open tbl using "${output}Compliance_Tbl2.tex", write replace
file write tbl "\begin{table}[h!]\centering" _n "\caption{Responsiveness to Pension Eligibility}" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n "\label{tbl-compliers}" _n
file write tbl "\begin{tabular}{l*{3}{c}}" _n
file write tbl "\toprule"  _n
file write tbl " & Full Sample & Good Health & Poor Health \\ " _n
file write tbl " & (1) & (2) & (3)  \\ " _n
file write tbl " \midrule " _n


*** OVERALL PROBABILITY OF COMPLIANCE

*First Stage

reg ret admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 $demo, robust
margins, dydx(*) post
sca full_fs_e = _b[admin3_eligible_early_at_svy5]
sca full_fs_n = _b[admin3_eligible_normal_at_svy5]


*P[D=1]
mean ret
sca full_pd1 = _b[ret]

*P[Z=1]
mean admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5
sca full_pz1_e = _b[admin3_eligible_early_at_svy5]
sca full_pz1_n = _b[admin3_eligible_normal_at_svy5]
sca full_N = _N


*** NOW SEPARATELY BY HEALTH STATUS ****
di "svy3_own_health_poor"

forvalues i = 0/1 {

preserve

keep if svy3_own_health_poor == `i'

reg ret admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 $demo, robust
margins, dydx(*) post
sca fs_e_`i' = _b[admin3_eligible_early_at_svy5]
sca fs_n_`i' = _b[admin3_eligible_normal_at_svy5]

*P[D=1]
mean ret
sca pd1_`i' = _b[ret]

*P[Z=1]
mean admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5
sca pz1_e_`i' = _b[admin3_eligible_early_at_svy5]
sca pz1_n_`i' = _b[admin3_eligible_normal_at_svy5]
sca N_`i' = _N

restore
}

global full_pr_com = full_N*full_pd1*full_fs_e*full_pz1_e/full_pd1 + (full_N*(1-full_pd1))*(1-full_pz1_e)*full_fs_e/(1-full_pd1)
global full_pr_alw = full_N*full_pd1*(1-full_fs_e*full_pz1_e/full_pd1)
global full_pr_ne =  (full_N*(1-full_pd1))*(1- (1-full_pz1_e)*full_fs_e/(1-full_pd1))

global pr_com_1 = (N_1*pd1_1)*fs_e_1*pz1_e_1/pd1_1 + (N_1*(1-pd1_1))*(1-pz1_e_1)*fs_e_1/(1-pd1_1)
global pr_alw_1 = (N_1*pd1_1)*(1- fs_e_1*pz1_e_1/pd1_1)
global pr_ne_1 = (N_1*(1-pd1_1))*(1-(1-pz1_e_1)*fs_e_1/(1-pd1_1))

global pr_com_0 = (N_0*pd1_0)*fs_e_0*pz1_e_0/pd1_0 + (N_0*(1-pd1_0))*(1-pz1_e_0)*fs_e_0/(1-pd1_0)
global pr_alw_0 = (N_0*pd1_0)*(1- fs_e_0*pz1_e_0/pd1_0)
global pr_ne_0 = (N_0*(1-pd1_0))*(1-(1-pz1_e_0)*fs_e_0/(1-pd1_0))


file write tbl "N &"  (full_N) "&"  (N_0) "&"  (N_1) "\\" _n
file write tbl "\$P[D=1]\$  &" %4.3f ( full_pd1) "&" %4.3f ( pd1_0) "&" %4.3f (pd1_1 ) "\\" _n
file write tbl "[1em]" _n
file write tbl "\midrule" _n
file write tbl "\multicolumn{4}{l}{\textbf{Early Eligibility Threshold}} \\" _n
file write tbl " \$P[Z^{e}=1]\$  &" %4.3f ( full_pz1_e) "&" %4.3f ( pz1_e_0 ) "&" %4.3f (pz1_e_1 ) "\\" _n
file write tbl " \$P[D_{e_1} > D_{e_0}]\$ &" %4.3f ( full_fs_e) "&" %4.3f ( fs_e_0) "&" %4.3f (fs_e_1 ) "\\" _n
file write tbl "[1em]" _n
file write tbl " Always Takers  &" %4.3f ($full_pr_alw) "&" %4.3f ($pr_alw_0) "&" %4.3f ($pr_alw_1)   "\\"  _n
file write tbl "   &" %4.1f ($full_pr_alw/35.02) "\% &" %4.1f (100*$pr_alw_0/N_0) " \% &" %4.1f (100*$pr_alw_1/N_1)  "\% \\"  _n

file write tbl " Compliers & " %4.3f ($full_pr_com) "&" %4.3f ($pr_com_0) "&" %4.3f ($pr_com_1)   "\\"  _n
file write tbl "   &" %4.1f ($full_pr_com/35.02) "\% &" %4.1f (100*$pr_com_0/N_0) " \% &" %4.1f (100*$pr_com_1/N_1)  "\% \\"  _n

file write tbl " Never Takers & " %4.3f ($full_pr_ne) "&" %4.3f ($pr_ne_0) "&" %4.3f ($pr_ne_1)   "\\"  _n
file write tbl "  &" %4.1f ($full_pr_ne/35.02) "\% &" %4.1f (100*$pr_ne_0/N_0) "\% &" %4.1f (100*$pr_ne_1/N_1)  "\% \\"  _n

global full_pr_com = full_N*full_pd1*full_fs_n*full_pz1_n/full_pd1 + (full_N*(1-full_pd1))*(1-full_pz1_n)*full_fs_n/(1-full_pd1)
global full_pr_alw = full_N*full_pd1*(1-full_fs_n*full_pz1_n/full_pd1)
global full_pr_ne =  (full_N*(1-full_pd1))*(1- (1-full_pz1_n)*full_fs_n/(1-full_pd1))

global pr_com_1 = (N_1*pd1_1)*fs_n_1*pz1_n_1/pd1_1 + (N_1*(1-pd1_1))*(1-pz1_n_1)*fs_n_1/(1-pd1_1)
global pr_alw_1 = (N_1*pd1_1)*(1- fs_n_1*pz1_n_1/pd1_1)
global pr_ne_1 = (N_1*(1-pd1_1))*(1-(1-pz1_n_1)*fs_n_1/(1-pd1_1))

global pr_com_0 = (N_0*pd1_0)*fs_n_0*pz1_n_0/pd1_0 + (N_0*(1-pd1_0))*(1-pz1_n_0)*fs_n_0/(1-pd1_0)
global pr_alw_0 = (N_0*pd1_0)*(1- fs_n_0*pz1_n_0/pd1_0)
global pr_ne_0 = (N_0*(1-pd1_0))*(1-(1-pz1_n_0)*fs_n_0/(1-pd1_0))

file write tbl "[1em]" _n
file write tbl "\midrule" _n
file write tbl "\multicolumn{4}{l}{\textbf{Normal Eligibility Threshold}} \\" _n
file write tbl " \$P[Z^{n}=1]\$  &" %4.3f ( full_pz1_n) "&" %4.3f ( pz1_n_0 ) "&" %4.3f (pz1_n_1 ) "\\" _n
file write tbl " \$P[D_{n_1} > D_{n_0}]\$ &" %4.3f ( full_fs_n) "&" %4.3f ( fs_n_0) "&" %4.3f (fs_n_1 ) "\\" _n
file write tbl "[1em]" _n
file write tbl " Always Takers  &" %4.3f ($full_pr_alw) "&" %4.3f ($pr_alw_0) "&" %4.3f ($pr_alw_1)   "\\"  _n
file write tbl "   &" %4.1f ($full_pr_alw/35.02) "\% &" %4.1f (100*$pr_alw_0/N_0) " \% &" %4.1f (100*$pr_alw_1/N_1)  "\% \\"  _n

file write tbl " Compliers & " %4.3f ($full_pr_com) "&" %4.3f ($pr_com_0) "&" %4.3f ($pr_com_1)   "\\"  _n
file write tbl "   &" %4.1f ($full_pr_com/35.02) "\% &" %4.1f (100*$pr_com_0/N_0) " \% &" %4.1f (100*$pr_com_1/N_1)  "\% \\"  _n

file write tbl " Never Takers & " %4.3f ($full_pr_ne) "&" %4.3f ($pr_ne_0) "&" %4.3f ($pr_ne_1)   "\\"  _n
file write tbl "  &" %4.1f ($full_pr_ne/35.02) "\% &" %4.1f (100*$pr_ne_0/N_0) "\% &" %4.1f (100*$pr_ne_1/N_1)  "\% \\"  _n

file write tbl "\bottomrule"  _n
file write tbl "\end{tabular}\\"  _n
file write tbl "{\footnotesize Notes: Regression estimates are from a linear probability model that includes indicators for own and spouse's health status (where appropriate), gender, marital status, age dummies, years of service, salary, race/ethnicity indicators, number of children, education, and agency type indicators.  See Appendix \ref{app-compliers} for a detailed explanation of how LATE parameters are calculated.}"  _n
file write tbl "\end{table}"  _n

file close tbl
exit
file write tbl "[1em]" _n "\hline \hline" 
file write tbl "\multicolumn{11}{l}{\footnotesize Note that \$P^{Early}(D_1 > D_0) = E[D | Z^{Early}=1, Z^{Normal}, X ] - E[D|Z^{Early}=0, Z^{Normal}, X]$ and \$P^{Normal}(D_1 > D_0) = E[D | Z^{Normal}=1, Z^{Early}, X ] - E[D|Z^{Normal}=0, Z^{Early}, X ]$ }\\" _n
file write tbl "\multicolumn{11}{l}{\footnotesize The sample is derived from the NCRTS dataset and includes $count workers ages 52-65 who were actively employed as of May 2016. See Data Appendix for details on full sample restrictions and variable definitions. }\\" _n
file write tbl "\multicolumn{11}{l}{\footnotesize D is defined as retired in 2017. \$Z^{early}$ indicates eligibility for early retirement benefit; while \$Z^{normal}$ indicates eligibility for normal retirement benefit }\\" _n
file write tbl "\multicolumn{11}{l}{\footnotesize Both early coefficient and normal coefficent controls for own health status, spouse health status, marital status, gender, race, years of services, age, number of kids, salary, occupation, education attainment. }\\" _n
file write tbl "\end{tabular}" _n "}"_n "\end{table}"_n "\end{landscape}" _n "" _n "" _n "" _n "" _n "" _n
file close tbl


exit

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


