/************************************************************************************************************************ 
This file creates salary using Administrative Data release at 04.06.2016 ==> pre-survey3 
Output of this file:  individual_id , admin3_total_salary_2015

Input of this file: individual , total_salary (keep salary_year == 2015)
************************************************************************************************************************/

include "Step0_SetDirectory"
log using "${log}MakeData_Admin3_Salary_$date", replace text name("Ariel")

*************************************************************************************************
use "${raw}ACTIVES_WORK_HISTORY.dta", clear //04.06.2016 version


*** Keep jobs got paid in 2015 only

keep if salary_year=="2015"


*** Sum over all salaries from 2015 jobs for every individuals

collapse (sum) total_salary, by(individual)

gen round_total_salary=round(total_salary,0.01) // The original data is rounded to two decimal places. However, generate admin3_total_salary_2015 directly with total_salary would lead to unobservable discrepancy between admin3_total_salary_2015 and total_salary, so we need this step to fix it.
gen admin3_total_salary_2015=round_total_salary 

lab var admin3_total_salary_2015 "Total Salary 2015 (Admin 3)"

gen admin3_total_salary_10K_2015 = admin3_total_salary_2015/10000
lab var admin3_total_salary_10K_2015 "Salary (10K)"


*** Keep relevant variables

keep indi admin3_total_salary_10K_2015 admin3_total_salary_2015


*** Attach notes regarding dataset created by this do file to resulting dta file. 

note: This file creates total salary for jobs got paid in 2015 using administrative data release at 04.06.2016 ==> pre-survey 
note: Raw data used to creates this file: ACTIVES_WORK_HISTORY.dta(04.06.2016) 
note: Do file used to creates this file: MakeData_Admin3_Salary.do


save "${working}Admin3_Salary.dta", replace

log close _all
