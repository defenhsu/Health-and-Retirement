clear
capture log close _all
eststo clear

cd "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs"

global date "$S_DATE"
log using "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs\Logs\Result_Admin3_Svy3_fin_$date", replace text name("Ariel")
global raw "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\RawData\"
global working "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\WorkingData\"
global output "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\RA\output\"
*********************************************************************************************************

use "${working}Admin3_Survey3.dta", clear // using MakeData_Admin3_Survey3.do (June 2022)

lab var admin3_eligible_normal_at_svy5 "Eligible Normal (Full Benefits)" //"Normal Eligible as of December 2017"
lab var admin3_eligible_early_at_svy5 "Eligible Early (Reduced Benefits)" // "Early Eligible as of December 2017"
lab var admin3_eligible_none_at_svy5 "Not Yet Eligible for Benefits" //"Not Eligible as of December 2017"

gen admin3_int_age = int(admin3_age_at_svy3) //truncating age toward 0. Could not skip this step if we want to run peak value py code. Otherwise the merge won't work.

gen admin3_int_yos = int(admin3_yos_at_svy3) //truncating YOS toward 0  Could not skip this step if we want to run peak value py code. Otherwise the merge won't work.

tab admin3_int_age, gen(age)


*********************************************************************************************
*** Table: The Probability of Continued Work by Pension Eligibility Status (Full Interation with Financial Literacy)
*********************************************************************************************

/*Fully interacted:

a Eligibility early x low fin

b Eligibility norm x low fin

c Eligibility early x high fin

d Eligibility norm x high fin

— need to test equality of coefficients (a == c and b == d)?



Single interactions:

A Eligibility early 

B Eligibility normal

C Eligibility early x high fin

D Eligibility normal x high fin

A is effect of early eligibility for low fin lit and C is the differential effect between low and high fin.
*/


global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015"

global pension "admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5"


*** COL 1: Eligibility 

logit admin5_status_not_ret $pension $demo, robust

sum admin5_status_not_ret if e(sample)==1 

estadd scalar ymean = r(mean)

test admin3_eligible_early_at_svy5 = admin3_eligible_normal_at_svy5
estadd scalar pdiff = r(p)
eststo col1


*** Define Financial Literacy

gen subj_finlit_high = svy3_fin_selfscore_high //subjective financial literacy
gen obj_finlit_high = svy3_finq_all_correct  // objective financial literacy
gen com_finlit_high = svy3_finlit_compound // answer coumpound question right 
gen inf_finlit_high = svy3_finlit_inflation   // answer inflation question right 
gen sto_finlit_high = svy3_finlit_stock   // answer stock question right 

gen sublin_finlit_high = svy3_fin_selfscore  //subjective financial literacy - linear
gen objlin_finlit_high = svy3_num_finq_correct    // objective financial literacy -linear

lab var subj_finlit_high "Financial selfScore higher than 5 out of 7"
lab var obj_finlit_high "Answer all ainancial question right"
lab var com_finlit_high "Answer coumpound question right "
lab var inf_finlit_high "Answer inflation question right"
lab var sto_finlit_high "Answer stock question right "
lab var sublin_finlit_high "Financial selfscore"
lab var objlin_finlit_high "Financial question answered correct"


*** Summary Stats

estpost tabstat subj_finlit_high obj_finlit_high com_finlit_high inf_finlit_high sto_finlit_high sublin_finlit_high objlin_finlit_high, statistics(n mean sd min max) columns(statistics)
eststo sum

esttab sum using "${output}Tbl_Fin_Interact.txt",replace cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") collabels("Count" "Mean" "Std Dev." "Min" "Max") noobs nonumber label title("Summary Stats - Financial Literacy") varwidth(50) 

estpost tab subj_finlit_high obj_finlit_high 
eststo tabs

esttab tabs using "${output}Tbl_Fin_Interact.txt", append cell("b pct(fmt(a))")  collab("Freq." "Percent") noobs nonumb mtitle("Objective ") title("Financial Literacy Level Tabulate") note("0 : Low ; 1 : High" , "each column represent objective category", "each sub column represent sujective category")


***COL 2: Eligibility X Financial Literacy

local class subj obj sublin objlin com inf sto 

foreach i of local class {

	gen adminsvy3_early_`i'_highfin = admin3_eligible_early_at_svy5 * `i'_finlit_high 
	lab var adminsvy3_early_`i'_highfin "Eligible early * High Financial Literacy"
	
	gen adminsvy3_early_`i'_lowfin = admin3_eligible_early_at_svy5*(1-`i'_finlit_high) 
	lab var adminsvy3_early_`i'_lowfin "Eligible early * Low Financial Literacy"
	
	gen adminsvy3_normal_`i'_highfin = admin3_eligible_normal_at_svy5*`i'_finlit_high 
	lab var adminsvy3_normal_`i'_highfin "Eligible normal * High Financial Literacy"
	
	gen adminsvy3_normal_`i'_lowfin = admin3_eligible_normal_at_svy5*(1-`i'_finlit_high) 
	lab var adminsvy3_normal_`i'_lowfin "Eligible normal * Low Financial Literacy"


global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015 `i'_finlit_high svy3_wealth_gt25k" // add financial literacy high and wealth high as control variables

global interact "adminsvy3_early_`i'_highfin adminsvy3_early_`i'_lowfin adminsvy3_normal_`i'_highfin adminsvy3_normal_`i'_lowfin"

logit admin5_status_not_ret $interact  $demo , robust
 
sum admin5_status_not_ret if e(sample)==1
estadd scalar ymean = r(mean)

test adminsvy3_early_`i'_highfin = adminsvy3_normal_`i'_highfin 
estadd scalar pdiff_highfin = r(p)

test adminsvy3_early_`i'_lowfin = adminsvy3_normal_`i'_lowfin 
estadd scalar pdiff_lowfin = r(p)

test adminsvy3_early_`i'_highfin = adminsvy3_early_`i'_lowfin
estadd scalar pearly=r(p)

test adminsvy3_normal_`i'_highfin =adminsvy3_normal_`i'_lowfin
estadd scalar pnorm=r(p)

eststo col2_`i'

global keep "admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 adminsvy3_early_`i'_lowfin adminsvy3_normal_`i'_lowfin adminsvy3_early_`i'_highfin adminsvy3_normal_`i'_highfin `i'_finlit_high svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female "

esttab col1 col2_`i'  using "${output}Tbl_Fin_Interact.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01) mtitle("Eligibility" "Eligibility x Financial Literacy") sca("pearly  Early: Low Financial Literacy = High Financial Literacy" "pnorm Normal: Low Financial Literacy = High Financial Literacy") order($keep) keep($keep) margin title(Table: The Probability of Continued Work by Pension Eligibility Status - Interacted with Financial Literacy - `i') varwidth(60) 

}
