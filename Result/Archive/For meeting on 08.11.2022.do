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


***************************************
*** scatter plot for salary by gender
***************************************
/*SALARY:

It looks like there are a lot of extreme outliers that are muddying the comparison.  
I suggest that you impose stricter inclusion criteria on data quality.  
To observe gross gender patterns, you can color the dots differently for men and women and overlay two scatter plots using the "if" statement and the "color" commands.*/

gen int_svy3_salary = int(svy3_salary/1000)*1000
gen int_admin3_total_salary_2015 = int(admin3_total_salary_2015/1000)*1000

graph twoway (scatter int_svy3_salary int_admin3_total_salary_2015 if admin3_female==0, msize(tiny) mcolor(navy%60)) (scatter int_svy3_salary int_admin3_total_salary_2015 if admin3_female==1, msize(tiny) mcolor(cranberry%30) ) (lfit int_svy3_salary int_admin3_total_salary_2015 ) , xtitle(True Salary from Admin Data) ytitle(Self-Reported Salary) legend(order(3 "Fitted Line (Not Rstricted)" 1 "Female" 2 "Male")) xline(130000 ,lp(shortdash) lwidth(thin) lcolor(purple)) xlab(0(50000)250000) note("The three reference lines in this pic mark true salary at 130K, and reported salary at 10K and 200K" "We can see extreme outliers are male.") yline(10000 200000,lp(shortdash) lwidth(thin) lcolor(purple)) title(Not Restricted) name(notrestrict)

preserve

keep if int_admin3_total_salary_2015 <= 130000 & int_svy3_salary > 10000 & int_svy3_salary <= 200000

graph twoway (scatter int_svy3_salary int_admin3_total_salary_2015 if admin3_female==0, msize(tiny) mcolor(navy%60)) (scatter int_svy3_salary int_admin3_total_salary_2015 if admin3_female==1, msize(tiny) mcolor(cranberry%30) ) (lfit int_svy3_salary int_admin3_total_salary_2015 if admin3_female==0) (lfit int_svy3_salary int_admin3_total_salary_2015 if admin3_female==1), xtitle(True Salary from Admin Data) ytitle(Self-Reported Salary) legend(order(4 "Fitted Line (Female)" 2 "Female" 3 "Fitted Line (Male)" 1 "Male"))  note("To reduce misleading effect from outliers, I restricted sample to workers"  "who have true salary that is lower than 130K" "and self-reported salary higher than 10K, lower than 200K") name(restrict) title(Restricted)

restore

graph combine notrestrict restrict, xsize(8) title("Scatter Plot for Salary by Gender")

graph export "${output}Salary_Scatter.png",replace

graph drop _all


**********************
*** Interaction Table
**********************
/*For the regressions, Table 2 - the model is misspecified.  You can either fully interact eligibility with both high and not-high financial literacy OR you can include the main effect and the single interactions eligibility x high. 
 It might be helpful if you wrote out how to interpret the coefficient — the coefficient tells you the effect of what relative to what?



Fully interacted:

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


*********************************************************************************************
*** Table: The Probability of Continued Work by Pension Eligibility Status (Full Interation)
*********************************************************************************************

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

gen sublin_finlit_high = svy3_fin_selfscore 
gen objlin_finlit_high = svy3_num_finq_correct  

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
esttab sum using "${output}fin_interact.txt",replace cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") collabels("Count" "Mean" "Std Dev." "Min" "Max") noobs nonumber label title("Summary Stats - Financial Literacy") varwidth(50) 

	file open tbl using  "${output}fin_interact.txt", write append
	file write tbl ""_n
	file write tbl "******************************************************************"_n
	file write tbl ""_n
	file close tbl

estpost tab subj_finlit_high obj_finlit_high 

eststo tabs

esttab tabs using "${output}fin_interact.txt", append cell("b pct(fmt(a))")  collab("Freq." "Percent") noobs nonumb mtitle("Objective ") title("Financial Literacy Level Tabulate") note("0 : Low ; 1 : High" , "each column represent objective category", "each sub column represent sujective category")

	file open tbl using  "${output}fin_interact.txt", write append
	file write tbl ""_n
	file write tbl "******************************************************************"_n
	file write tbl ""_n
	file close tbl

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

global interact "adminsvy3_early_`i'_highfin adminsvy3_early_`i'_lowfin adminsvy3_normal_`i'_highfin adminsvy3_normal_`i'_lowfin"

logit admin5_status_not_ret $interact  $demo, robust
 

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

global keep "admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 adminsvy3_early_`i'_lowfin adminsvy3_normal_`i'_lowfin adminsvy3_early_`i'_highfin adminsvy3_normal_`i'_highfin svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female "

esttab col1 col2_`i'  using "${output}fin_interact.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01) mtitle("Eligibility" "Eligibility x Financial Literacy") sca("pearly  Early: Low Financial Literacy = High Financial Literacy" "pnorm Normal: Low Financial Literacy = High Financial Literacy") order($keep) keep($keep) margin title(Table: The Probability of Continued Work by Pension Eligibility Status - Interacted with Financial Literacy - `i') varwidth(60) 


	file open tbl using  "${output}fin_interact.txt", write append
	file write tbl ""_n
	file write tbl "******************************************************************"_n
	file write tbl ""_n
	file close tbl
}


********************
*** Wealth
********************

lab var svy3_wealth_gt25k "High Wealth (Greater than 25K)"

lab var svy3_wealth_lt25k "Low Wealth (Less than 25K)"


*** Summary Stats

estpost tabstat svy3_wealth_gt25k svy3_wealth_lt25k , statistics(n mean sd min max) columns(statistics)
eststo sum
esttab sum using "${output}wealth_interact.txt", replace cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") ///
collabels("Count" "Mean" "Std Dev." "Min" "Max") noobs nonumber label title("Summary Stats - Wealth") varwidth(50)


	file open tbl using  "${output}wealth_interact.txt", write append
	file write tbl ""_n
	file write tbl "******************************************************************"_n
	file write tbl ""_n
	file close tbl

estpost tab svy3_wealth_gt25k 

eststo tabs

esttab tabs using "${output}wealth_interact.txt", append cell("b pct(fmt(a))")  collab("Freq." "Percent") noobs nonumb mtitle("High Wealth (Greater than 25K) ")

	file open tbl using  "${output}wealth_interact.txt", write append
	file write tbl ""_n
	file write tbl "******************************************************************"_n
	file write tbl ""_n
	file close tbl


*** COL 2: Eligibility X Wealth

	gen adminsvy3_early_wealth_gt25k = admin3_eligible_early_at_svy5 * svy3_wealth_gt25k //==> elig_earlyxpoor
	lab var adminsvy3_early_wealth_gt25k "Eligible early * High Wealth"
	
	gen adminsvy3_early_wealth_lt25k = admin3_eligible_early_at_svy5*(1-svy3_wealth_gt25k) //==>elig_earlyxgood
	lab var adminsvy3_early_wealth_lt25k "Eligible early * Low Wealth"
	
	gen adminsvy3_normal_wealth_gt25k = admin3_eligible_normal_at_svy5*svy3_wealth_gt25k //==elig_normxpoor
	lab var adminsvy3_normal_wealth_gt25k "Eligible normal * High Wealth"
	
	gen adminsvy3_normal_wealth_lt25k = admin3_eligible_normal_at_svy5*(1-svy3_wealth_gt25k) //==>elig_normxgood
	lab var adminsvy3_normal_wealth_lt25k "Eligible normal * Low Wealth"
	
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


global keep "admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 adminsvy3_early_wealth_gt25k adminsvy3_early_wealth_lt25k adminsvy3_normal_wealth_gt25k adminsvy3_normal_wealth_lt25k svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female "


esttab col1 col2_m  using "${output}wealth_interact.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01) mtitle("Eligibility" "Eligibility x Wealth") sca("pearly  Early: Low Weath = High Wealth" "pnorm Normal: Low Weath = High Wealth")  order($keep) keep($keep) margin title(Table : The Probability of Continued Work by Pension Eligibility Status - Interacted with Wealth ) varwidth(50)


*******************************************
*** Overlaping Hist Procrast v.s Engage
******************************************

/*1. For the number of reminders by number of missing responses, you cannot see the density with this style chart.  
You might try an overlapping histogram where you have 4 different bars for each group of "number of reminders" 
and show the distribution (probably best by count than percentage) of the number of missing responses.  
But, I'm not sure what a negative missing response means?
*/

*** Summary Stats

lab var svy3_sd_num_miss_dk "Number of Missing Response(Standardized)"
lab var svy3_num_reminder "Number of Reminder"

estpost tabstat svy3_sd_num_miss_dk svy3_num_reminder , statistics(n mean sd min max) columns(statistics)
eststo sum
esttab sum using "${output}engage_procast.txt", replace cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") ///
collabels("Count" "Mean" "Std Dev." "Min" "Max") noobs nonumber label title("Summary Stats") varwidth(50)


	file open tbl using  "${output}engage_procast.txt", write append
	file write tbl ""_n
	file write tbl "******************************************************************"_n
	file write tbl ""_n
	file close tbl
	


estpost tab svy3_num_reminder 

eststo tabs

esttab tabs using "${output}engage_procast.txt", append cell("b pct(fmt(a))")  collab("Freq." "Percent") noobs nonumb mtitle("Number of Reminder")

	file open tbl using  "${output}engage_procast.txt", write append
	file write tbl ""_n
	file write tbl "******************************************************************"_n
	file write tbl ""_n
	file close tbl


twoway (histogram svy3_sd_num_miss_dk if svy3_num_reminder==0, color(red%30) width(0.5)  freq) ///        
       (histogram svy3_sd_num_miss_dk if svy3_num_reminder==1, color(green%30)  width(0.5)  freq) ///
	   (histogram svy3_sd_num_miss_dk if svy3_num_reminder==2, color(blue%30) width(0.5)  freq) ///
	   (histogram svy3_sd_num_miss_dk if svy3_num_reminder==3, fcolor(none) lcolor(black)  width(0.5) freq) ///
       ,legend(order(1 "0" 2 "1" 3 "2" 4 "3" ) title("Number of Reminders",size(small))) xtitle("Number of Missing Response") title("Histogram for Number of Missing Response") subtitle("By Number of Reminders") 
	   
graph export "${output}engage_hist_by_procast.png",replace	  



**************************
*** From Previous Meeting 
**************************
******************************************************************
*** Do people predict their financial literacy levels correctly??
******************************************************************

global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015 svy3_num_reminder svy3_sd_num_miss_dk"

logit obj_finlit_high subj_finlit_high $demo  

eststo col

esttab col using "${output}Meeting08.02.22.txt", replace lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) mtitle("Objective") ///
 order(subj_finlit_high admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk) ///
	keep(subj_finlit_high admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk)

*******************************************************************************************
*** Is the difference between responding rate really drived by gender? Or is it occupation?
***==> run regression and control for occupation 
********************************************************************************************

logit svy3_answer_salary $demo  sublin_finlit_high

eststo col

esttab col using "${output}Meeting08.02.22.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) mtitle("Answer Salary") ///
 order( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk sublin_finlit_high) ///
	keep( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk sublin_finlit_high)

*********************************************
*** Who are procrastinating? Male or female?
*********************************************
global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015  svy3_sd_num_miss_dk"


logit svy3_need_reminder  $demo  sublin_finlit_high
eststo col
esttab col using "${output}Meeting08.02.22.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) ///
 order( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_sd_num_miss_dk sublin_finlit_high) ///
keep( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_sd_num_miss_dk sublin_finlit_high)
	

**********************************************************************************	
*** salary estimate mistake
**********************************************************************************
preserve

global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015 svy3_num_reminder svy3_sd_num_miss_dk"

gen salary_estimate_mistake = (int(svy3_salary/1000) - int(admin3_total_salary_2015/1000))*1000

keep if inrange(svy3_salary,10000,200000)
keep if inrange(admin3_total_salary_2015,0,130000)

reg salary_estimate_mistake  $demo  sublin_finlit_high 

eststo col

esttab col using "${output}Meeting08.02.22.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) mtitle(Est Mistake) ///
 order( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk sublin_finlit_high) ///
	keep( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk sublin_finlit_high)

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