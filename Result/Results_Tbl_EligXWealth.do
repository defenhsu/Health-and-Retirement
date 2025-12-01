clear
capture log close _all
eststo clear

cd "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs"

global date "$S_DATE"
log using "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs\Logs\Result_Admin3_Svy3_wealth_$date", replace text name("Ariel")
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


********************
*** Table: The Probability of Continued Work by Pension Eligibility Status (Full Interation with Wealth)
********************

global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015"

global pension "admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5"



*** COL 1: Eligibility 

logit admin5_status_not_ret $pension $demo, robust

sum admin5_status_not_ret if e(sample)==1 

estadd scalar ymean = r(mean)

test admin3_eligible_early_at_svy5 = admin3_eligible_normal_at_svy5
estadd scalar pdiff = r(p)
eststo col1


*** Label Wealth Level

lab var svy3_wealth_gt25k "High Wealth (Greater than 25K)"

lab var svy3_wealth_lt25k "Low Wealth (Less than 25K)"


*** Summary Stats

estpost tabstat svy3_wealth_gt25k svy3_wealth_lt25k , statistics(n mean sd min max) columns(statistics)
eststo sum

esttab sum using "${output}Tbl_Wealth_Interact.txt", replace cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") ///
collabels("Count" "Mean" "Std Dev." "Min" "Max") noobs nonumber label title("Summary Stats - Wealth") varwidth(50)


estpost tab svy3_wealth_gt25k 

eststo tabs

esttab tabs using "${output}Tbl_Wealth_Interact.txt", append cell("b pct(fmt(a))")  collab("Freq." "Percent") noobs nonumb mtitle("High Wealth (Greater than 25K) ")



*** COL 2: Eligibility X Wealth

	gen adminsvy3_early_wealth_gt25k = admin3_eligible_early_at_svy5 * svy3_wealth_gt25k 
	lab var adminsvy3_early_wealth_gt25k "Eligible early * High Wealth"
	
	gen adminsvy3_early_wealth_lt25k = admin3_eligible_early_at_svy5*(svy3_wealth_lt25k) 
	lab var adminsvy3_early_wealth_lt25k "Eligible early * Low Wealth"
	
	gen adminsvy3_normal_wealth_gt25k = admin3_eligible_normal_at_svy5*svy3_wealth_gt25k 
	lab var adminsvy3_normal_wealth_gt25k "Eligible normal * High Wealth"
	
	gen adminsvy3_normal_wealth_lt25k = admin3_eligible_normal_at_svy5*(svy3_wealth_lt25k) 
	lab var adminsvy3_normal_wealth_lt25k "Eligible normal * Low Wealth"


global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015 svy3_wealth_gt25k" // add wealth high as control variables
	
global interact "adminsvy3_early_wealth_gt25k adminsvy3_early_wealth_lt25k adminsvy3_normal_wealth_gt25k adminsvy3_normal_wealth_lt25k"

logit admin5_status_not_ret $interact  $demo, robust
eststo col2_m

sum admin5_status_not_ret if e(sample)==1
estadd scalar ymean = r(mean)

test adminsvy3_early_wealth_gt25k = adminsvy3_normal_wealth_gt25k 
estadd scalar pdiff_gt25k = r(p) : col2_m

test adminsvy3_early_wealth_lt25k = adminsvy3_normal_wealth_lt25k 
estadd scalar pdiff_lt25k = r(p) : col2_m

test adminsvy3_early_wealth_gt25k = adminsvy3_early_wealth_lt25k
estadd scalar pearly=r(p) : col2_m

test adminsvy3_normal_wealth_gt25k =adminsvy3_normal_wealth_lt25k
estadd scalar pnorm=r(p) : col2_m


global keep "admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 adminsvy3_early_wealth_gt25k adminsvy3_early_wealth_lt25k adminsvy3_normal_wealth_gt25k adminsvy3_normal_wealth_lt25k svy3_wealth_gt25k svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female "


esttab col1 col2_m  using "${output}Tbl_Wealth_Interact.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01) mtitle("Eligibility" "Eligibility x Wealth") sca("pearly  Early: Low Weath = High Wealth" "pnorm Normal: Low Weath = High Wealth")  order($keep) keep($keep) margin title(Table : The Probability of Continued Work by Pension Eligibility Status - Interacted with Wealth ) varwidth(50)
	
exit

*========================	


/*****************************************************************************
*** Table 2: The Probability of Continued Work by Pension Eligibility Status
****************************************************************************
/*Was generated by HR_Tbl_Baseline*/

*gen admin3_int_age = int(admin3_age)

tab admin3_int_age, gen(age)

global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015"
*global pension "admin3_eligible_early_at_svy3 admin3_eligible_normal_at_svy3 admin5_status_not_ret admin3_eligible_none_at_svy5 admin3_eligible_early_at_svy5 admin3_just_eligible_normal_svy5 admin3_past_eligible_normal_svy5"

*** COL 1: Eligibility 

logit admin5_status_not_ret admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 $demo, robust

sum admin5_status_not_ret if e(sample)==1 //We can use e(sample) to generate predicted values only for those cases used to estimate the model
estadd scalar ymean = r(mean)

*margins, dydx(*) post

test admin3_eligible_early_at_svy5 = admin3_eligible_normal_at_svy5
estadd scalar pdiff = r(p)
eststo col1_m

*** COL 2: Eligibility X Wealth

	gen adminsvy3_early_wealth_gt25k = admin3_eligible_early_at_svy5 * svy3_wealth_gt25k //==> elig_earlyxpoor
	lab var adminsvy3_early_wealth_gt25k "Eligible early * High Wealth"
	
	gen adminsvy3_early_wealth_lt25k = admin3_eligible_early_at_svy5*(1-svy3_wealth_gt25k) //==>elig_earlyxgood
	lab var adminsvy3_early_wealth_lt25k "Eligible early * Low Wealth"
	
	gen adminsvy3_normal_wealth_gt25k = admin3_eligible_normal_at_svy5*svy3_wealth_gt25k //==elig_normxpoor
	lab var adminsvy3_normal_wealth_gt25k "Eligible normal * High Wealth"
	
	gen adminsvy3_normal_wealth_lt25k = admin3_eligible_normal_at_svy5*(1-svy3_wealth_gt25k) //==>elig_normxgood
	lab var adminsvy3_normal_wealth_lt25k "Eligible normal * Low Wealth"

logit admin5_status_not_ret adminsvy3_early_wealth_gt25k adminsvy3_early_wealth_lt25k adminsvy3_normal_wealth_gt25k adminsvy3_normal_wealth_lt25k  $demo, robust
 
*margins, dydx(*) post

sum admin5_status_not_ret if e(sample)==1
estadd scalar ymean = r(mean)

test adminsvy3_early_wealth_gt25k = adminsvy3_normal_wealth_gt25k 
estadd scalar pdiff_wealth_gt25k = r(p)

test adminsvy3_early_wealth_lt25k = adminsvy3_normal_wealth_lt25k 
estadd scalar pdiff_wealth_lt25k = r(p)

test adminsvy3_early_wealth_gt25k = adminsvy3_early_wealth_lt25k
estadd scalar pearly=r(p)

test adminsvy3_normal_wealth_gt25k =adminsvy3_normal_wealth_lt25k
estadd scalar pnorm=r(p)

eststo col2_m


esttab col1_m col2_m  using "${output}Tbl_EligXWealth.csv", replace lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01) ///original file: tbl_reg1
	mtitle("Eligibility" "Eligibility x Wealth") sca("ymean Mean of Dep Var" "pdiff Early = Normal" ///
	"pdiff_wealth_gt25k High Wealth: Early = Normal" "pdiff_wealth_lt25k Low Weath: Early = Normal" ///
	"pearly  Early: Low Weath = High Wealth" "pnorm Normal: Low Weath = High Wealth") ///
	 order(admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5  ///
	adminsvy3_early_wealth_gt25k adminsvy3_early_wealth_lt25k adminsvy3_normal_wealth_gt25k adminsvy3_normal_wealth_lt25k  ///
	svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female) ///
	keep(admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5  ///
	adminsvy3_early_wealth_gt25k adminsvy3_early_wealth_lt25k adminsvy3_normal_wealth_gt25k adminsvy3_normal_wealth_lt25k ///
	svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female) margin ///
	title("Table : The Probability of Continued Work by Pension Eligibility Status - Interacted with Wealth ") //notes(High Wealth: Greater than 25K)

	
*==========================

	exit
	
*** COL 2: Eligibility X Account Balance

	gen adminsvy3_early_acctbal_gt25k = admin3_eligible_early_at_svy5 * svy3_acctbal_gt25k //==> elig_earlyxpoor
	lab var adminsvy3_early_acctbal_gt25k "Eligible early * High Account Balance"
	
	gen adminsvy3_early_acctbal_lt25k = admin3_eligible_early_at_svy5*svy3_acctbal_lt25k //==>elig_earlyxgood
	lab var adminsvy3_early_acctbal_lt25k "Eligible early * Low Account Balance"
	
	gen adminsvy3_normal_acctbal_gt25k = admin3_eligible_normal_at_svy5*svy3_acctbal_gt25k //==elig_normxpoor
	lab var adminsvy3_normal_acctbal_gt25k "Eligible normal * High Account Balance"
	
	gen adminsvy3_normal_acctbal_lt25k = admin3_eligible_normal_at_svy5*svy3_acctbal_lt25k //==>elig_normxgood
	lab var adminsvy3_normal_acctbal_lt25k "Eligible normal * Low Account Balance"

logit admin5_status_not_ret adminsvy3_early_acctbal_gt25k adminsvy3_early_acctbal_lt25k adminsvy3_normal_acctbal_gt25k adminsvy3_normal_acctbal_lt25k  $demo, robust
 
*margins, dydx(*) post

sum admin5_status_not_ret if e(sample)==1
estadd scalar ymean = r(mean)

test adminsvy3_early_acctbal_gt25k = adminsvy3_normal_acctbal_gt25k 
estadd scalar pdiff_acctbal_gt25k = r(p)

test adminsvy3_early_acctbal_lt25k = adminsvy3_normal_acctbal_lt25k 
estadd scalar pdiff_acctbal_lt25k = r(p)

test adminsvy3_early_acctbal_gt25k = adminsvy3_early_acctbal_lt25k
estadd scalar pearly=r(p)

test adminsvy3_normal_acctbal_gt25k =adminsvy3_normal_acctbal_lt25k
estadd scalar pnorm=r(p)

eststo col2_m


esttab col1_m col2_m  using "${output}Tbl_EligXWealth.csv", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01) ///original file: tbl_reg1
	mtitle("Eligibility" "Eligibility x acctbal") sca("ymean Mean of Dep Var" "pdiff Early = Normal" ///
	"pdiff_acctbal_gt25k Greater than 25K: Early = Normal" "pdiff_acctbal_lt25k Less than 25K: Early = Normal" ///
	"pearly  Early: Less than 25K = Greater than 25K" "pnorm Normal: Less than 25K = Greater than 25K") ///
	 order(admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5  ///
	adminsvy3_early_acctbal_gt25k adminsvy3_early_acctbal_lt25k adminsvy3_normal_acctbal_gt25k adminsvy3_normal_acctbal_lt25k  ///
	svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female) ///
	keep(admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5  ///
	adminsvy3_early_acctbal_gt25k adminsvy3_early_acctbal_lt25k adminsvy3_normal_acctbal_gt25k adminsvy3_normal_acctbal_lt25k ///
	svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female) margin ///
	title("Table : The Probability of Continued Work by Pension Eligibility Status - Interacted with Account Balance ")
	
*=================================	
	
	
*** COL 2: Eligibility X Income

	gen adminsvy3_early_income_gt50K = admin3_eligible_early_at_svy5 * svy3_income_gt50K //==> elig_earlyxpoor
	lab var adminsvy3_early_income_gt50K "Eligible early * High Income"
	
	gen adminsvy3_early_income_lt50K = admin3_eligible_early_at_svy5*svy3_income_lt50K //==>elig_earlyxgood
	lab var adminsvy3_early_income_lt50K "Eligible early * Low Income"
	
	gen adminsvy3_normal_income_gt50K = admin3_eligible_normal_at_svy5*svy3_income_gt50K //==elig_normxpoor
	lab var adminsvy3_normal_income_gt50K "Eligible normal * High Income"
	
	gen adminsvy3_normal_income_lt50K = admin3_eligible_normal_at_svy5*svy3_income_lt50K //==>elig_normxgood
	lab var adminsvy3_normal_income_lt50K "Eligible normal * Low Income"

logit admin5_status_not_ret adminsvy3_early_income_gt50K adminsvy3_early_income_lt50K adminsvy3_normal_income_gt50K adminsvy3_normal_income_lt50K  $demo, robust
 
*margins, dydx(*) post

sum admin5_status_not_ret if e(sample)==1
estadd scalar ymean = r(mean)

test adminsvy3_early_income_gt50K = adminsvy3_normal_income_gt50K 
estadd scalar pdiff_income_gt50K = r(p)

test adminsvy3_early_income_lt50K = adminsvy3_normal_income_lt50K 
estadd scalar pdiff_income_lt50K = r(p)

test adminsvy3_early_income_gt50K = adminsvy3_early_income_lt50K
estadd scalar pearly=r(p)

test adminsvy3_normal_income_gt50K =adminsvy3_normal_income_lt50K
estadd scalar pnorm=r(p)

eststo col2_m


esttab col1_m col2_m  using "${output}Tbl_EligXWealth.csv", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01) ///original file: tbl_reg1
	mtitle("Eligibility" "Eligibility x Income") sca("ymean Mean of Dep Var" "pdiff Early = Normal" ///
	"pdiff_income_gt50K High Income: Early = Normal" "pdiff_income_lt50K Low Income: Early = Normal" ///
	"pearly  Early: Low Income = High Income" "pnorm Normal: Low Income = High Income") ///
	 order(admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5  ///
	adminsvy3_early_income_gt50K adminsvy3_early_income_lt50K adminsvy3_normal_income_gt50K adminsvy3_normal_income_lt50K  ///
	svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female) ///
	keep(admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5  ///
	adminsvy3_early_income_gt50K adminsvy3_early_income_lt50K adminsvy3_normal_income_gt50K adminsvy3_normal_income_lt50K ///
	svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female) margin ///
	title(Table 2: The Probability of Continued Work by Pension Eligibility Status - Interacted with Income)
