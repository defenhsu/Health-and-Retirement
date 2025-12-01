clear
capture log close _all
eststo clear

cd "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs"

global date "$S_DATE"
log using "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs\Logs\Result_Admin3_Svy3_Baseline_$date", replace text name("Ariel")
global raw "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\RawData\"
global working "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\WorkingData\"
global output "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\RA\output\"
*********************************************************************************************************
use "${working}Admin3_Survey3.dta", clear // using MakeData_Admin3_Survey3.do (June 2022)

gen admin3_int_age = int(admin3_age_at_svy3)

gen admin3_int_yos = int(admin3_yos_at_svy3)

tab admin3_int_age, gen(age)


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
*** salary estimate mistake ==> Run a regression on gender, and then include the non-cognitive and financial literacy measures in the regression
**********************************************************************************

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


preserve

global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015 svy3_num_reminder svy3_sd_num_miss_dk "

gen salary_estimate_mistake = (int(svy3_salary/1000) - int(admin3_total_salary_2015/1000))*1000

keep if inrange(svy3_salary,10000,200000)
keep if inrange(admin3_total_salary_2015,0,130000)

reg salary_estimate_mistake  $demo  sublin_finlit_high // use subjective financial literacy as control variable

eststo col

esttab col using "${output}Salary_Estimate_Mistake.txt", replace lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) mtitle(Est Mistake) ///
 order( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk sublin_finlit_high _cons) ///
	keep( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk sublin_finlit_high _cons)

restore


******************************************************************
*** Do people predict their financial literacy levels correctly??
******************************************************************

global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015 svy3_num_reminder svy3_sd_num_miss_dk"

logit obj_finlit_high subj_finlit_high $demo  

eststo col

esttab col using "${output}Meeting08.02.22.txt", replace lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) mtitle("Objective") ///
 order(subj_finlit_high admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk _cons) ///
	keep(subj_finlit_high admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk _cons)


*******************************************************************************************
*** Is the difference between responding rate really drived by gender? Or is it occupation?
***==> run regression and control for occupation 
********************************************************************************************

logit svy3_answer_salary $demo  sublin_finlit_high

eststo col

esttab col using "${output}Meeting08.02.22.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) mtitle("Answer Salary") ///
 order( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk sublin_finlit_high _cons) ///
	keep( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_num_reminder svy3_sd_num_miss_dk sublin_finlit_high _cons)


*********************************************
*** Who are procrastinating? Male or female?
*********************************************
global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015  svy3_sd_num_miss_dk"


logit svy3_need_reminder  $demo  sublin_finlit_high
eststo col
esttab col using "${output}Meeting08.02.22.txt", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)  varwidth(50) ///
 order( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_sd_num_miss_dk sublin_finlit_high _cons) ///
keep( admin3_female svy3_race_black svy3_married_partner svy3_educ_ba admin3_atype_school svy3_sd_num_miss_dk sublin_finlit_high _cons)
	



/******* Legacy codes ***************
tab admin3_int_age, gen(age)
global demo "svy3_own_health_poor svy3_sphlthpoor svy3_married_partner admin3_female age2-age13 admin3_int_yos svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015"

reg svy3_finq_all_correct svy3_fin_selfscore_high $demo  
eststo col
esttab col ,  lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)


gen int_svy3_salary = int(svy3_salary/1000)*1000
gen int_admin3_total_salary_2015 = int(admin3_total_salary_2015/1000)*1000

graph twoway (lfit int_svy3_salary int_admin3_total_salary_2015) (scatter int_svy3_salary int_admin3_total_salary_2015, msize(vsmall)) , xtitle(True Salary from Admin Data) ytitle(Self-Reported Salary)  legend(order(1 "Fitted Line" 2 "Data Point"))


graph twoway (lfit svy3_sd_num_miss_dk svy3_num_reminder) (scatter svy3_sd_num_miss_dk svy3_num_reminder, msize(vsmall)) , xtitle(Number of Reminder) ytitle(Number of Missing Response)  legend(order(1 "Fitted Line" 2 "Data Point"))



logit svy3_answer_salary $demo
eststo col
esttab col,  lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)

logit svy3_need_reminder $demo
eststo col
esttab col,  lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)


*** Define "salary estimate mistake" as the reported salary minus the true salary

gen salary_estimate_mistake = (int(svy3_salary/1000) - int(admin3_total_salary_2015/1000))*1000

keep if inrange(svy3_salary,0,200000)
keep if inrange(admin3_total_salary_2015,0,200000)

*** Run a regression of the mistake on gender, and then include the non-cognitive and financial literacy measures in the regression

reg salary_estimate_mistake admin3_female svy3_fin_overconf svy3_engage svy3_procrast

esttab using "${output}salary_respond.csv", replace lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)


reg salary_estimate_mistake admin3_female svy3_fin_selfscore svy3_engage svy3_procrast // which one is a better proxy for fin lit?

esttab using "${output}salary_respond.csv", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)


reg salary_estimate_mistake admin3_female svy3_finquestion_correct svy3_engage svy3_procrast

esttab using "${output}salary_respond.csv", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)



*** Run a regression of the indicator (whether this person answer question regarding salary) on gender, and then include the non-cognitive and financial literacy measures in the regression

logit svy3_answer_salary admin3_female svy3_fin_overconf svy3_engage svy3_procrast

esttab using "${output}salary_respond.csv", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)


logit svy3_answer_salary admin3_female svy3_fin_selfscore svy3_engage svy3_procrast // which one is a better proxy for fin lit?

esttab using "${output}salary_respond.csv", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)


logit svy3_answer_salary admin3_female svy3_finquestion_correct svy3_engage svy3_procrast

esttab using "${output}salary_respond.csv", append lab se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)



bysort admin3_female: su salary_estimate_mistake , detail
exit

/****************
*** Conclusion
****************
 - women earn less than man by around 10,000
 - 2/3 of the respondants are female
 - female are more willing to respond to survey as well as salary question 
 ==> only 639 male answer the salary question while there is 1,813 woman did so 
 ==> only 64% male answer the salary question while there is 70% woman did so
 
- both man and women overestimate salary on average, but man overestimate more in terms of amount when we look at median and overall distribution and regression results
==> about 69% women overestimate salary; about 85% man overestimate salary

----------------------------
                      (1)   
             salary_est~e   
----------------------------
admin3_fem~e     -264.966   
                (527.513)   

svy3_fin_o~f      359.362   
                (517.446)   

svy3_engag~t     1498.104** 
                (716.921)   

svy3_procr~t      461.180   
                (466.791)   

_cons           -3193.069***
                (500.703)   
----------------------------
N                    2452   
----------------------------
Standard errors in parentheses
* p<0.10, ** p<0.05, *** p<0.01



- it seems that the higher the fin lit is, the more people overestimate
- the more engagement people have in the survey, the more people overestimate
- the more people procrastinate, the more people overestimate*/


***************************************
/*** Legacy code ***********************

(stats without restriction)
. tab gender_code

                      4 X |      Freq.     Percent        Cum.
--------------------------+-----------------------------------
                        F |      2,998       70.41       70.41
                        M |      1,260       29.59      100.00
--------------------------+-----------------------------------
                    Total |      4,258      100.00

					
====================================

(stats without restriction)
-> gender_code = F

    Variable      |        Obs        Mean    Std. Dev.       Min        Max
------------------+---------------------------------------------------------
svy3_long_lag     |      2,998    .0383589    .1920932          0          1
svy3_num_reminder |      2,998    .6684456    .9332824          0          3
svy3_num_missing  |      2,998    95.29119    15.14405         59        176
svy3_fin_score    |      2,998    4.435624    1.284267          0          7
svy3_finqu~t      |      2,998    .3335557    .4715617          0          1
------------------+---------------------------------------------------------
 svy3_salary      |      2,066    52840.26    23558.76          0     209000

-------------------------------------------------------------------------------
-> gender_code = M

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
svy3_long_~g |      1,260    .0269841    .1621013          0          1
svy3_num_r~r |      1,260    .6222222     .915916          0          3
svy3_num_m~g |      1,260    90.48016    13.34501         62        176
svy3_fin_s~e |      1,260    4.807143    1.180372          0          7
svy3_finqu~t |      1,260    .5761905    .4943571          0          1
-------------+---------------------------------------------------------
 svy3_salary |        808    65911.99    31655.58         25     290000

 
 
======================
64% man respond salary question; 68%woman respond salary question  

-> gender_code = F

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
salary_est~e |      2,061   -2818.327     9887.67  -153463.5   71596.68
admin~y_2015 |      2,987    53807.03    22425.37   13478.05   217245.5
 svy3_salary |      2,061    52883.83    23535.19          0     209000

-----------------------------------------------------------------------------------------------------------------------------
-> gender_code = M

    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
salary_est~e |        806    -2945.24    15894.71    -140879   240643.2
admin~y_2015 |      1,255    69016.52     32091.7   17881.16   405961.3
 svy3_salary |        806    65993.66    31634.97         25     290000



===============
 people who overestimate salary (without restriction )
-----------------------------------------------------------------------------------------------------------------------------
-> gender_code = F
  1,463 ==> 0.71
-----------------------------------------------------------------------------------------------------------------------------
-> gender_code = M
  692 ==> 0.85

 people who overestimate salary (with restriction )
 -----------------------------------------------------------------------------------------------------------------------------
-> admin3_female = 0
  540
-----------------------------------------------------------------------------------------------------------------------------
-> admin3_female = 1
  1,253

============
reg with no restriction

----------------------------
                      (1)   
             salary_est~e   
----------------------------
admin3_fem~e      -93.596   
                (499.092)   

svy3_fin_o~f      867.885*  
                (501.829)   

svy3_engag~t     1383.787** 
                (671.333)   

svy3_procr~t      499.624   
                (450.695)   

_cons           -3403.831***
                (466.857)   
----------------------------
N                    2867   
----------------------------
Standard errors in parentheses
* p<0.10, ** p<0.05, *** p<0.01
  
  
  
 =================
 summary without restriction
 
 -> Male

                   salary_estimate_mistake
-------------------------------------------------------------
      Percentiles      Smallest
 1%    -58888.06        -140879
 5%    -13327.83      -121580.3
10%    -8425.219      -118763.5       Obs                 806
25%    -4213.711      -116979.9       Sum of Wgt.         806

50%    -1373.439                      Mean           -2945.24
                        Largest       Std. Dev.      15894.71
75%     442.9609       41999.04
90%     3356.789          43936       Variance       2.53e+08
95%     5843.961       52307.68       Skewness       1.241039
99%      22439.5       240643.2       Kurtosis       92.28157


 
 
-> Female

                   salary_estimate_mistake
-------------------------------------------------------------
      Percentiles      Smallest
 1%    -46480.39      -153463.5
 5%    -12332.52      -136262.9
10%    -8245.453        -120478       Obs               2,061
25%        -4263      -67102.53       Sum of Wgt.       2,061

50%     -1596.73                      Mean          -2818.327
                        Largest       Std. Dev.       9887.67
75%         19.5       47772.16
90%         2150       49101.37       Variance       9.78e+07
95%      4539.98       53546.74       Skewness      -4.627986
99%     19396.82       71596.68       Kurtosis       65.11493





 
 
 ********************



reg salary_estimate_mistake admin3_female svy3_fin_selfscore svy3_finquestion_correct svy3_engagement svy3_procrast

esttab, se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)


reg salary_estimate_mistake admin3_female svy3_fin_selfscore svy3_finquestion_correct svy3_num_reminder svy3_long_lag svy3_num_missing

esttab, se(3) b(3)  star(* 0.10 ** 0.05 *** 0.01)
