/* This file explore Heterogeneity Response to Eligibility across different observable characteristics */

capture file close _all

include "Step0_SetDirectory"
log using "${log}HR2_REGS_HeteroResponse_$date", replace text name("Ariel") 
*******************************************
use "${working}Admin3_Survey3.dta", clear // using MakeData_Admin3_Survey3.do (June 2022)

tab admin5_status_not_ret
gen not_ret = admin5_status_not_ret
gen ret = 1 - not_ret

lab var admin3_eligible_normal_at_svy5 "Eligible Normal (Full Benefits)" //"Normal Eligible as of December 2017"
lab var admin3_eligible_early_at_svy5 "Eligible Early (Reduced Benefits)" // "Early Eligible as of December 2017"
lab var admin3_eligible_none_at_svy5 "Not Yet Eligible for Benefits" //"Not Eligible as of December 2017"
label var not_ret "Actively Working"
label var svy3_own_health_poor "Poor Own Health"
label var svy3_sphlthpoor "Poor Spouse Health"
label var svy3_married "Married"
label var admin3_female "Female"
label var admin3_atype_school "Public School Employee"
label var admin3_atype_stategovt "State Gov't Employee"
label var admin3_total_salary_10K_2015 "Salary (10K)"
label var svy3_race_black "Black"
label var svy3_race_hisp "Hispanic"
label var svy3_race_other "Other Race"

gen admin3_int_age = int(admin3_age_at_svy3) //truncating age toward 0. Could not skip this step if we want to run peak value py code. Otherwise the merge won't work.
tab admin3_int_age, gen(age)
gen age55 = (inrange(admin3_int_age,55,65))
gen age59 = (inrange(admin3_int_age,59,65))
gen age62 = (inrange(admin3_int_age,62,65))
lab var admin3_age_at_svy3 "Age"
lab var age55 "Age >= 54"
lab var age59 "Age >= 58"
lab var age62 "Age >= 62"


gen admin3_int_yos = int(admin3_yos_at_svy3) //truncating YOS toward 0  Could not skip this step if we want to run peak value py code. Otherwise the merge won't work.
gen yos1 = (inrange(admin3_int_yos,10,50))
gen yos2 = (inrange(admin3_int_yos,20,50))
gen yos3 = (inrange(admin3_int_yos,30,50))
label var admin3_int_yos "YOS"
lab var yos1 "Yos >= 10"
lab var yos2 "Yos >= 20"
lab var yos3 "Yos >= 30"

gen educ1 = (inlist(svy3_educ,1,7,8))
gen educ2 = (inlist(svy3_educ,1,5,6,7,8))
lab var educ1 "EDUC \$\\geq$ Grad"
lab var educ2 "EDUC \$\\geq$ Bachelor"
label var svy3_educ_ba "College Degree"


*** education, num of kid, insurance, life expectation, health important, 
label var svy3_num_kids_12 "1-2 Kids"
label var svy3_num_kids_34 "3+ Kids"

label var svy3_sp_has_hi "Sp Has Ins"
label var svy3_own_has_hi "Has Ins"
label var svy3_acctbal_gt25k "High AcctBal"
label var svy3_wealth_gt25k "High Wealth"
label var svy3_income_gt50K "High Income"

global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married admin3_female admin3_yos_at_svy3 age2-age13 svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss  svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba svy3_educ_blank admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015"

 
*********************************************
*** Range of Unobserved Net Cost of Treatment
*********************************************
*** Let D be retirement 

	* Compute P(D = 1 | Z^{Early} =0, X) ==> Prob of Treatment in the Control Group
	quietly su ret if admin3_eligible_early_at_svy5 ==0 & admin3_eligible_normal_at_svy5 == 0 
	global p_always  = `r(mean)'
		
	* Compute P(D = 1 | Z^{Early} =1, X) ==> Prob of Treatment in the Intervention Group 1 (Early Retirement)
	quietly su ret if admin3_eligible_early_at_svy5 ==1 & admin3_eligible_normal_at_svy5 == 0
	global p_complier_early = `r(mean)'

	* Compute P(D = 1 | Z^{Normal} =1, X) ==> Prob of Treatment in the Intervention Group 2 (Normal Retirement)
	quietly su ret if admin3_eligible_normal_at_svy5 ==1 & admin3_eligible_early_at_svy5 ==0
	global p_complier_normal = `r(mean)'
	
	di $p_complier_early-$p_always " & " $p_complier_normal-$p_complier_early //using Kowalski(2021)
	di "p_always " $p_always " p_complier_early " $p_complier_early " p_complier_normal " $p_complier_normal 

*First Stage

logit ret admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5  $demo, robust
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

file open tbl using "${output}Hetero_Response_Tbl.tex", write replace
file write tbl "\begin{table}[h!]\centering" _n "\caption{Probabilities of Compliance - Compare}" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" 
file write tbl "\begin{tabular}{l*{9}{c}}" _n
file write tbl "\hline \hline"  _n
file write tbl " & (1) & (2)  \\ " _n
file write tbl " & Early Coeff.   & Normal Coeff.    \\ " _n
file write tbl " & \$P^{Early}[D_1 > D_0]$ & \$P^{Normal}[D_1 > D_0 ]$  \\ " _n

file write tbl "\hline \\" _n  //"[1em] " _n
file write tbl "Abadie (2003) & " %4.3f (fs_e) " & "  %4.3f (fs_n) " \\" _n
file write tbl "Kowalski (2021) & " %4.3f ($p_complier_early-$p_always) " & "  %4.3f ($p_complier_normal-$p_complier_early ) " \\" _n
file write tbl "[1em]" _n "\hline \hline" _n "\end{tabular}" _n  "\end{table}" _n "" _n "" _n "" _n "" _n "" _n


******************************
renvars admin3_female admin3_age_at_svy5 admin3_int_yos admin3_total_salary_10K_2015 , presub(admin3_  )
renvars svy3_own_health_poor svy3_sphlthpoor svy3_married svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba svy3_num_kids_12 svy3_num_kids_34 svy3_sp_has_hi svy3_own_has_hi svy3_acctbal_gt25k svy3_wealth_gt25k svy3_income_gt50K, presub(svy3_  )
rename own_health_poor ownhlthpoor
rename total_salary_10K_2015 salary

local D	"ret"
gen Z = (admin3_eligible_early_at_svy5 == 1)
replace Z = 2 if  (admin3_eligible_normal_at_svy5 == 1)
local statsvars "female age_at_svy5 int_yos salary ownhlthpoor sphlthpoor married race_black race_hisp race_other educ1 educ2 educ_ba num_kids_12 num_kids_34 own_has_hi sp_has_hi" //acctbal_gt25k wealth_gt25k income_gt50K

file write tbl "%\begin{landscape}" _n "\begin{table}[h!]\centering" _n "\caption{Hetero Response}" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n "\resizebox{\columnwidth}{!}{%" _n
file write tbl "\begin{tabular}{l*{8}{c}}" _n
file write tbl "\hline \hline"  _n
file write tbl " & \multicolumn{5}{c}{Means} & \multicolumn{3}{c}{Diff.}  \\ " _n
file write tbl " \cmidrule(lr){2-6}\cmidrule(lr){7-9}  \\ " _n
file write tbl " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8)  \\ " _n
file write tbl " &      & Always  & Early       & Normal    & Never   &          &         &          \\ " _n
file write tbl " &  All &  Takers & Compliers   & Compliers & Takers  &  (2)-(3) & (3)-(4) & (4)-(5)  \\ " _n
file write tbl "\hline \\" _n 

include "Result/Bootstrap"

file write tbl "\hline " _n "Observations   & 3595 & 216 & 410 & 866 & 2103 &    &    & \\"

file write tbl "\hline \hline" _n 
file write tbl "\end{tabular}" _n "}"_n "\end{table}"_n "%\end{landscape}" _n 
file close tbl

log close _all
exit


/*
tab svy3_own_health, gen(own_health)
lab var own_health1 "Poor"
lab var own_health2 "Fair"
lab var own_health3 "Good"
lab var own_health4 "Very Good"
lab var own_health5 "Excellent"


tab svy3_spouse_health, gen(sp_health)
lab var sp_health1 "Sp Poor"
lab var sp_health2 "Sp Fair"
lab var sp_health3 "Sp Good"
lab var sp_health4 "Sp Very Good"
lab var sp_health5 "Sp Excellent"
