clear
capture log close _all
eststo clear

cd "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs"

global date "$S_DATE"
log using "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs\Logs\Meeting08.02.22_$date", replace text name("Ariel")
global raw "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\RawData\"
global working "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\WorkingData\"
global output "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\RA\output\"
*********************************************************************************************************

use "${working}Admin3_Survey3.dta", clear // using MakeData_Admin3_Survey3.do (June 2022)

lab var admin3_eligible_normal_at_svy5 "Eligible Normal (Full Benefits)" //"Normal Eligible as of December 2017"
lab var admin3_eligible_early_at_svy5 "Eligible Early (Reduced Benefits)" // "Early Eligible as of December 2017"
lab var admin3_eligible_none_at_svy5 "Not Yet Eligible for Benefits" //"Not Eligible as of December 2017"

gen admin3_int_age = int(admin3_age_at_svy3)

gen admin3_int_yos = int(admin3_yos_at_svy3)

tab admin3_int_age, gen(age)

/****************************************************************************
*** Financial Literacy
****************************************************************************

global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015"
global pension "admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5"


*** COL 1: Eligibility 

logit admin5_status_not_ret $pension $demo, robust

sum admin5_status_not_ret if e(sample)==1 //We can use e(sample) to generate predicted values only for those cases used to estimate the model
estadd scalar ymean = r(mean)

test admin3_eligible_early_at_svy5 = admin3_eligible_normal_at_svy5
estadd scalar pdiff = r(p)
eststo col1_m


*** COL 2: Eligibility X Financial Literacy

gen subj_finlit_high = svy3_fin_selfscore_high 
gen obj_finlit_high = svy3_finq_all_correct  

gen finlit_true_high = (svy3_fin_selfscore_high ==1 & svy3_finq_all_correct==1)
gen finlit_fake_high = (svy3_fin_selfscore_high ==1 & svy3_finq_all_correct==0)
gen finlit_true_low = (svy3_fin_selfscore_high ==0 & svy3_finq_all_correct==0)
gen finlit_fake_low = (svy3_fin_selfscore_high ==0 & svy3_finq_all_correct==1) 

gen true_finlit_high = finlit_true_high  
replace true_finlit_high =. if finlit_fake_high==1 | finlit_fake_low==1
*gen arro_finlit_high = finlit_fake_high

gen subs_finlit_high = svy3_fin_selfscore 
gen objs_finlit_high = svy3_num_finq_correct  


estpost tabstat finlit_true_high subj_finlit_high obj_finlit_high svy3_fin_selfscore svy3_num_finq_correct , statistics(n mean sd min max) columns(statistics)
eststo col1
esttab col1 using "${output}Meeting08.02.22.txt",replace cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") ///
collabels("Count" "Mean" "Std Dev." "Min" "Max") noobs nonumber label title("Summary Stats - Financial Literacy")

	file open tbl using  "${output}Meeting08.02.22.txt", write append
	file write tbl ""_n
	file write tbl "******************************************************************"_n
	file write tbl ""_n
	file close tbl


local class true subj obj subs objs

foreach i of local class {

	gen adminsvy3_early_`i'_highfin = admin3_eligible_early_at_svy5 * `i'_finlit_high //==> elig_earlyxpoor
	lab var adminsvy3_early_`i'_highfin "Eligible early * High Financial Literacy"
		
	gen adminsvy3_normal_`i'_highfin = admin3_eligible_normal_at_svy5*`i'_finlit_high //==elig_normxpoor
	lab var adminsvy3_normal_`i'_highfin "Eligible normal * High Financial Literacy"
	
logit admin5_status_not_ret adminsvy3_early_`i'_highfin  adminsvy3_normal_`i'_highfin  $demo, robust
 
sum admin5_status_not_ret if e(sample)==1
estadd scalar ymean = r(mean)

test adminsvy3_early_`i'_highfin = adminsvy3_normal_`i'_highfin 
estadd scalar pdiff_highfin = r(p)


eststo col2_`i'

global keep "admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 adminsvy3_early_`i'_highfin  adminsvy3_normal_`i'_highfin svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female "

esttab col1_m col2_`i'  using "${output}Meeting08.02.22.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) ///
	mtitle("Eligibility" "Eligibility x Financial Literacy") sca("ymean Mean of Dep Var" "pdiff Early = Normal" ///
	"pdiff_highfin High Financial Literacy: Early = Normal")  ///
	 order($keep) keep($keep) margin ///
	title(Table 2: The Probability of Continued Work by Pension Eligibility Status - Interacted with Financial Literacy - `i')
	
	
	file open tbl using  "${output}Meeting08.02.22.txt", write append
	file write tbl ""_n
	file write tbl "******************************************************************"_n
	file write tbl ""_n
	file close tbl
		
}


****************************************************************************
*** Wealth
****************************************************************************

estpost tabstat svy3_wealth_gt25k svy3_wealth_lt25k , statistics(n mean sd min max) columns(statistics)
eststo col1
esttab col1 using "${output}Meeting08.02.22.txt",append cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") ///
collabels("Count" "Mean" "Std Dev." "Min" "Max") noobs nonumber label title("Summary Stats - Wealth")



*** COL 2: Eligibility X Wealth

	gen adminsvy3_early_wealth_gt25k = admin3_eligible_early_at_svy5 * svy3_wealth_gt25k //==> elig_earlyxpoor
	lab var adminsvy3_early_wealth_gt25k "Eligible early * High Wealth"
	
	
	gen adminsvy3_normal_wealth_gt25k = admin3_eligible_normal_at_svy5*svy3_wealth_gt25k //==elig_normxpoor
	lab var adminsvy3_normal_wealth_gt25k "Eligible normal * High Wealth"
	

logit admin5_status_not_ret adminsvy3_early_wealth_gt25k  adminsvy3_normal_wealth_gt25k   $demo, robust
 

sum admin5_status_not_ret if e(sample)==1
estadd scalar ymean = r(mean)

test adminsvy3_early_wealth_gt25k = adminsvy3_normal_wealth_gt25k 
estadd scalar pdiff_wealth_gt25k = r(p)


eststo col2_m


esttab col1_m col2_m  using "${output}Meeting08.02.22.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01) ///original file: tbl_reg1
	mtitle("Eligibility" "Eligibility x Wealth") sca("ymean Mean of Dep Var" "pdiff Early = Normal" ) varwidth(50) ///
	 order(admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5  ///
	adminsvy3_early_wealth_gt25k  adminsvy3_normal_wealth_gt25k   ///
	svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female) ///
	keep(admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5  ///
	adminsvy3_early_wealth_gt25k  adminsvy3_normal_wealth_gt25k  ///
	svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female) margin ///
	title("Table : The Probability of Continued Work by Pension Eligibility Status - Interacted with Wealth ") //notes(High Wealth: Greater than 25K)
	
	
	file open tbl using  "${output}Meeting08.02.22.txt", write append
	file write tbl ""_n
	file write tbl "******************************************************************"_n
	file write tbl ""_n
	file close tbl

	
**********************
*** Scatter Plot
*********************

gen int_svy3_salary = int(svy3_salary/1000)*1000
gen int_admin3_total_salary_2015 = int(admin3_total_salary_2015/1000)*1000


graph twoway (lfit int_svy3_salary int_admin3_total_salary_2015) (scatter int_svy3_salary int_admin3_total_salary_2015, msize(vsmall)) , xtitle(True Salary from Admin Data) ytitle(Self-Reported Salary)  legend(order(1 "Fitted Line" 2 "Data Point"))

graph export "${output}Salary_Scatter.png",replace

graph twoway (lfit svy3_sd_num_miss_dk svy3_num_reminder) (scatter svy3_sd_num_miss_dk svy3_num_reminder, msize(vsmall)) , xtitle(Number of Reminder) ytitle(Number of Missing Response)  legend(order(1 "Fitted Line" 2 "Data Point"))

graph export "${output}Procrast_Engage_Scatter.png",replace

*graph twoway (lfit svy3_fin_selfscore svy3_num_finq_correct) (scatter svy3_fin_selfscore svy3_num_finq_correct, msize(vsmall)) , xtitle(Number of Correct ANswer) ytitle(Self-Reported Score)  legend(order(1 "Fitted Line" 2 "Data Point"))
*/
******************************************************************
*** Do people predict their financial literacy levels correctly??
******************************************************************

global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015 svy3_num_reminder svy3_sd_num_miss_dk"

logit svy3_finq_all_correct svy3_fin_selfscore_high $demo  
tab svy3_finq_all_correct svy3_fin_selfscore_high
eststo col
esttab col using "${output}Meeting08.02.22.txt", replace lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) ///
 order(svy3_fin_selfscore_high admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk) ///
	keep(svy3_fin_selfscore_high admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk)

*******************************************************************************************
*** Is the difference between responding rate really drived by gender? Or is it occupation?
***==> run regression and control for occupation 
********************************************************************************************

logit svy3_answer_salary $demo  svy3_num_finq_correct
eststo col
esttab col using "${output}Meeting08.02.22.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) ///
 order( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk svy3_num_finq_correct) ///
	keep( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk svy3_num_finq_correct)

*********************************************
*** Who are procrastinating? Male or female?
*********************************************
global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015  svy3_sd_num_miss_dk"


logit svy3_need_reminder  $demo  svy3_num_finq_correct
eststo col
esttab col using "${output}Meeting08.02.22.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) ///
 order( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_sd_num_miss_dk svy3_num_finq_correct) ///
keep( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_sd_num_miss_dk svy3_num_finq_correct)
	

**********************************************************************************	
*** salary estimate mistake
**********************************************************************************
preserve

gen salary_estimate_mistake = (int(svy3_salary/1000) - int(admin3_total_salary_2015/1000))*1000

keep if inrange(svy3_salary,10000,200000)
keep if inrange(admin3_total_salary_2015,0,130000)

reg salary_estimate_mistake  $demo  svy3_num_finq_correct
eststo col
esttab col using "${output}Meeting08.02.22.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) ///
 order( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk svy3_num_finq_correct) ///
	keep( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk svy3_num_finq_correct)

restore
	
*******************************************************************************
*** Run a quick calculation of the racial / ethnic distribution in our data
*******************************************************************************

gen race =.
replace race=1 if svy3_race_white==1
replace race=2 if svy3_race_hisp==1
replace race=3 if svy3_race_black==1
replace race=4 if race==.

label define race_lab 1 "White" 2 "Hisp" 3 "Black" 4"Other"
label values  race race_lab

graph bar (count), over(race) blabel(bar, format(%9.1g))

graph export "${output}Race_Hist.png",replace

graph drop _all

tab race,m

tab race admin3_eligible_early_at_svy5 
tab rac admin3_eligible_normal_at_svy5

***********
*** Black
***********
*** COL 1: Eligibility 

preserve

keep if race ==3

logit admin5_status_not_ret admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 $demo, robust

sum admin5_status_not_ret if e(sample)==1 //We can use e(sample) to generate predicted values only for those cases used to estimate the model
estadd scalar ymean = r(mean)

*margins, dydx(*) post

test admin3_eligible_early_at_svy5 = admin3_eligible_normal_at_svy5
estadd scalar pdiff = r(p)
eststo col1_m

*** COL 2: Eligibility X Own Health

	gen adminsvy3_interact_early_poor = admin3_eligible_early_at_svy5 * svy3_own_health_poor //==> elig_earlyxpoor
	lab var adminsvy3_interact_early_poor "Eligible early * Poor health"
	
	gen adminsvy3_interact_early_good = admin3_eligible_early_at_svy5*(1-svy3_own_health_poor) //==>elig_earlyxgood
	lab var adminsvy3_interact_early_good "Eligible early * Good health"
	
	gen adminsvy3_interact_normal_poor = admin3_eligible_normal_at_svy5*svy3_own_health_poor //==elig_normxpoor
	lab var adminsvy3_interact_normal_poor "Eligible normal * Poor health"
	
	gen adminsvy3_interact_normal_good = admin3_eligible_normal_at_svy5*(1-svy3_own_health_poor) //==>elig_normxgood
	lab var adminsvy3_interact_normal_good "Eligible normal * Good health"

logit admin5_status_not_ret adminsvy3_interact_early_poor adminsvy3_interact_normal_poor  adminsvy3_interact_early_good adminsvy3_interact_normal_good $demo, robust
 
margins, dydx(*) post

sum admin5_status_not_ret if e(sample)==1
estadd scalar ymean = r(mean)

test adminsvy3_interact_early_poor = adminsvy3_interact_normal_poor 
estadd scalar pdiff_poor = r(p)

test adminsvy3_interact_early_good = adminsvy3_interact_normal_good 
estadd scalar pdiff_good = r(p)

test adminsvy3_interact_early_poor = adminsvy3_interact_early_good
estadd scalar pearly=r(p)

test adminsvy3_interact_normal_poor =adminsvy3_interact_normal_good
estadd scalar pnorm=r(p)

eststo col2_m


esttab col1_m col2_m  using "${output}Meeting08.02.22.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) ///original file: tbl_reg1
	mtitle("Eligibility" "Eligibility x Own Health") sca("ymean Mean of Dep Var" "pdiff Early = Normal" ///
	"pdiff_poor Poor Health: Early = Normal" "pdiff_good Good Health: Early = Normal" ///
	"pearly  Early: Poor Health = Good Health " "pnorm Normal: Poor Health = Good Health") ///
	 order(admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5  ///
	adminsvy3_interact_early_poor adminsvy3_interact_normal_poor  adminsvy3_interact_early_good adminsvy3_interact_normal_good ///
	svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female) ///
	keep(admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5  ///
	adminsvy3_interact_early_poor adminsvy3_interact_normal_poor  adminsvy3_interact_early_good adminsvy3_interact_normal_good ///
	svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female) margin ///
	addn("Notes: Data are from the NCRTS active workers in April 2016, see Table 1 for details.  The dependent variable is actively working as of December 2017." ///
	"A full list of covariates is provided in Appendix Table **** and includes years of service, race, education, number of children, type of public employer, salary, and age dummies.") ///
	title(Table 2: The Probability of Continued Work by Pension Eligibility Status - Black)


restore




***********
*** White
***********
*** COL 1: Eligibility 

preserve

keep if race ==1

logit admin5_status_not_ret admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 $demo, robust

sum admin5_status_not_ret if e(sample)==1 //We can use e(sample) to generate predicted values only for those cases used to estimate the model
estadd scalar ymean = r(mean)

*margins, dydx(*) post

test admin3_eligible_early_at_svy5 = admin3_eligible_normal_at_svy5
estadd scalar pdiff = r(p)
eststo col1_m

*** COL 2: Eligibility X Own Health

	gen adminsvy3_interact_early_poor = admin3_eligible_early_at_svy5 * svy3_own_health_poor //==> elig_earlyxpoor
	lab var adminsvy3_interact_early_poor "Eligible early * Poor health"
	
	gen adminsvy3_interact_early_good = admin3_eligible_early_at_svy5*(1-svy3_own_health_poor) //==>elig_earlyxgood
	lab var adminsvy3_interact_early_good "Eligible early * Good health"
	
	gen adminsvy3_interact_normal_poor = admin3_eligible_normal_at_svy5*svy3_own_health_poor //==elig_normxpoor
	lab var adminsvy3_interact_normal_poor "Eligible normal * Poor health"
	
	gen adminsvy3_interact_normal_good = admin3_eligible_normal_at_svy5*(1-svy3_own_health_poor) //==>elig_normxgood
	lab var adminsvy3_interact_normal_good "Eligible normal * Good health"

logit admin5_status_not_ret adminsvy3_interact_early_poor adminsvy3_interact_normal_poor  adminsvy3_interact_early_good adminsvy3_interact_normal_good $demo, robust
 
margins, dydx(*) post

sum admin5_status_not_ret if e(sample)==1
estadd scalar ymean = r(mean)

test adminsvy3_interact_early_poor = adminsvy3_interact_normal_poor 
estadd scalar pdiff_poor = r(p)

test adminsvy3_interact_early_good = adminsvy3_interact_normal_good 
estadd scalar pdiff_good = r(p)

test adminsvy3_interact_early_poor = adminsvy3_interact_early_good
estadd scalar pearly=r(p)

test adminsvy3_interact_normal_poor =adminsvy3_interact_normal_good
estadd scalar pnorm=r(p)

eststo col2_m


esttab col1_m col2_m  using "${output}Meeting08.02.22.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) ///original file: tbl_reg1
	mtitle("Eligibility" "Eligibility x Own Health") sca("ymean Mean of Dep Var" "pdiff Early = Normal" ///
	"pdiff_poor Poor Health: Early = Normal" "pdiff_good Good Health: Early = Normal" ///
	"pearly  Early: Poor Health = Good Health " "pnorm Normal: Poor Health = Good Health") ///
	 order(admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5  ///
	adminsvy3_interact_early_poor adminsvy3_interact_normal_poor  adminsvy3_interact_early_good adminsvy3_interact_normal_good ///
	svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female) ///
	keep(admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5  ///
	adminsvy3_interact_early_poor adminsvy3_interact_normal_poor  adminsvy3_interact_early_good adminsvy3_interact_normal_good ///
	svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female) margin ///
	addn("Notes: Data are from the NCRTS active workers in April 2016, see Table 1 for details.  The dependent variable is actively working as of December 2017." ///
	"A full list of covariates is provided in Appendix Table **** and includes years of service, race, education, number of children, type of public employer, salary, and age dummies.") ///
	title(Table 2: The Probability of Continued Work by Pension Eligibility Status - White)


restore

