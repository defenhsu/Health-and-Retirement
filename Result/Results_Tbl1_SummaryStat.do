/*This file generate summary statistics for our data. Older version of code that generate summary stat would be file "HR_TBL1_MEANS"*/

include "Step0_SetDirectory"
log using "${log}Result_Admin3_Svy3_Baseline_SummaryStat_$date", replace text name("Ariel")

*********************************************************************************************************

use "${working}Admin3_Survey3.dta", clear // using MakeData_Admin3_Survey3.do (September 2022)

********************************
*** Table 1: Summary Statistics 
********************************

*** Creating labels for tables

lab var admin3_eligible_normal_at_svy5 "Eligible Normal (Full Benefits)" //"Normal Eligible as of December 2017"
lab var admin3_eligible_early_at_svy5 "Eligible Early (Reduced Benefits)" // "Early Eligible as of December 2017"
lab var admin3_eligible_none_at_svy5 "Not Yet Eligible for Benefits" //"Not Eligible as of December 2017"

*** Generating table and export 

gen admin3_int_age = int(admin3_age_at_svy3)

gen admin3_int_yos = int(admin3_yos_at_svy3)

lab var admin3_int_age "Age as of Survey 3" //"Normal Eligible as of December 2017"
lab var admin3_int_yos "Yos as of Survey 3" // "Early Eligible as of December 2017"

global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female admin3_int_age admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015"
global pension "admin3_eligible_early_at_svy3 admin3_eligible_normal_at_svy3 admin5_status_not_ret admin3_eligible_none_at_svy5 admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5"

count
global count = r(N)

estpost tabstat  $demo $pension  , statistics(mean sd count min max) columns(statistics)
eststo means1


esttab means1 using "${output}Tbl1_Sum_Stat.tex", replace ///original file: tbl1.csv
cells("mean(fmt(3)) sd(fmt(3)) min max") collabels("Mean" "SD" "MIN" "MAX") noobs label nonumber ///
title(Summary Statistics) refcat(svy3_own_health_poor "Measured May 2016" admin5_status_not_ret "Measured December 2017", nolabel) ///
postfoot(\hline\hline)

file open tbl using "${output}Tbl1_Sum_Stat.tex", write append
file write tbl "\multicolumn{5}{l}{\footnotesize  Notes: The sample is derived from the NCRTS dataset and includes $count workers ages 52-65  }\\" _n
file write tbl "\multicolumn{5}{l}{\footnotesize  \quad  \quad  \quad  \quad  who were actively employed as of May 2016. See Data Appendix for details on full }\\" _n
file write tbl "\multicolumn{5}{l}{\footnotesize  \quad  \quad  \quad  \quad  sample restrictions and variable definitions.}\\" _n
file write tbl "\end{tabular}" _n "\end{table}"_n 
file close tbl 

log close _all
