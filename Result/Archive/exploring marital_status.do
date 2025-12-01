clear
capture log close _all
set more off
pause on

cd "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs"

global date "$S_DATE"
log using "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs\Logs\MakeData_Survey_$date", replace text name("Ariel")
global raw "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\RawData\"
global working "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\WorkingData\"


*************************
use "${raw}PERSON_FILE_NEW.dta", clear

keep indi age gender_code marital_status
renvars age gender_code marital_status, postf(_new)

merge 1:1 indi using "${raw}ACTIVES_PERSON_INFO.dta", keepusing(indi pr age gender_code marital_status)
drop _merge 


destring age_new,replace force

gen diff = age_new-age 

su diff

tab marital_status_new marital_status,m
tab gender_code_new gender_code,m

merge 1:1 pr using "${raw}s3_actives_analysis.dta", keepusing(mstat S3marital_status)

keep if _merge==3
drop _merge

lab var marital_status "Admin (ACTIVES_PERSON_INFO)"
lab var marital_status_new "Admin(PERSON_FILE_NEW)"

tab mstat S3marital_status,m
tab S3marital_status marital_status,m
tab S3marital_status marital_status_new,m





twoway (histogram age_new ,  width(0.6) ) ///        
       (histogram age ,width(0.6) fcolor(none) lcolor(black)) ///   
	   ,legend(order(1 "PERSON_FILE_NEW" 2 "ACTIVES_PERSON_INFO" )) title(Age) 
graph export age.png, replace
