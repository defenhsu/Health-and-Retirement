clear
capture log close _all
eststo clear

cd "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs"

global date "$S_DATE"
log using "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs\Logs\Het_by_Race_$date", replace text name("Ariel")
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
