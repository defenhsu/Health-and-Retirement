clear
capture log close _all
eststo clear

cd "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs"

global date "$S_DATE"
log using "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs\Logs\Explore_Survey_Behaviour_$date", replace text name("Ariel")
global raw "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\RawData\"
global working "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\WorkingData\"
global output "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\RA\output\"
*********************************************************************************************************
/*In this file I try to answer some question regarding people's behaviour using survey response*/

use "${working}Admin3_Survey3.dta", clear // using MakeData_Admin3_Survey3.do (June 2022)

lab var admin3_eligible_normal_at_svy5 "Eligible Normal (Full Benefits)" //"Normal Eligible as of December 2017"
lab var admin3_eligible_early_at_svy5 "Eligible Early (Reduced Benefits)" // "Early Eligible as of December 2017"
lab var admin3_eligible_none_at_svy5 "Not Yet Eligible for Benefits" //"Not Eligible as of December 2017"

gen admin3_int_age = int(admin3_age_at_svy3)

gen admin3_int_yos = int(admin3_yos_at_svy3)

tab admin3_int_age, gen(age)


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


***************************************
*** scatter plot for salary by gender
***************************************
/*SALARY:

It looks like there are a lot of extreme outliers that are muddying the comparison.  ==> impose stricter inclusion criteria on data quality.  
To observe gross gender patterns ==> color the dots differently for men and women and overlay two scatter plots using the "if" statement and the "color" commands.*/

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


**********************************************************************************	
*** Salary Estimate Mistake
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
	
	
******************************************************************
*** Do people predict their financial literacy levels correctly??
******************************************************************

global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015 svy3_num_reminder svy3_sd_num_miss_dk"

logit obj_finlit_high subj_finlit_high $demo  

eststo col

esttab col using "${output}Meeting08.02.22.txt", replace lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) mtitle("Objective") ///
 order(subj_finlit_high admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk) ///
	keep(subj_finlit_high admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk)


*******************************************
*** Overlaping Hist Procrast v.s Engage
******************************************

/*1. For the number of reminders by number of missing responses ==> cannot see the density with this style chart.  
==> try an overlapping histogram where we have 4 different bars for each group of "number of reminders" 
and show the distribution (probably best by count than percentage) of the number of missing responses.  
Note that there's negative missing response, because I normalized missing response
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

