******************************************************************************************************
*** This file creates job and agency classifications using admin data from March 2014 and April 2016 ***
******************************************************************************************************
clear
capture log close _all
set more off

cd "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs"

global date "$S_DATE"
log using "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs\Logs\Job_Classification_$date", replace text name("Ariel")
global raw "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\RawData\"
global working "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\WorkingData\"
*****************************
use "${raw}\salary_history_admin", clear // admin data from March 2014

destring salary_year, replace ignore("NULL")
tab salary_year if job_classification ~= "NULL",m
drop if salary_year==.
gsort indi -salary_year
collapse (firstnm) job_classification , by(indi salary_year)

destring total_salary, replace ignore("NULL")
bysort individual_id: egen maxsal=max(total_salary)
keep if maxsal==total_salary
replace total_salary=round(total_salary)
replace maxsal=round(maxsal)

duplicates drop individual_id, force
tab agency_classification
tab job_classification

rename job_classification job_classification_code


gen job_classification=.
replace job_classification=1 if job_classification_code== "SHP Trooper" | job_classification_code== "Wildlife Officer" | job_classification_code=="Police Officer" |/*
*/ job_classification_code== "Wildlife Officer" | job_classification_code== "Public Safety Officer" | job_classification_code== "Rescue Worker" |  /*
*/ job_classification_code=="Protective Services (Non-Certified)" | job_classification_code== "Revenue Enforcement Officer" | job_classification_code=="Sheriff" | /*
*/ job_classification_code=="ABC Officer" | job_classification_code=="Deputy Sheriff" | job_classification_code=="Jailer (Certified)" | job_classification_code=="Local Firefighters"
replace job_classification=2 if job_classification_code=="Administrative" | job_classification_code== "Educational Executives" | job_classification_code== "Educational Management" /*
*/ | job_classification_code== "Government Officials" | job_classification_code== "University and Community College Executives" | job_classification_code== "University and Community College Management" 
replace job_classification=3 if job_classification_code== "Education Professionals"
replace job_classification=4 if job_classification_code== "Educational Administrative Support Personnel" | job_classification_code== "Educational Support Personnel"
replace job_classification=5 if job_classification_code== "Health Care Professionals"
replace job_classification=6 if job_classification_code=="Professionals"
replace job_classification=7 if job_classification_code=="Skilled Labor" | job_classification_code=="Technical and Trades"
replace job_classification=8 if job_classification_code=="Social Service Professionals"
replace job_classification=9 if job_classification_code=="University Agricultural (AG)Extension" | job_classification_code=="University and Community College Professionals"
label define jclass 1 "Safety/Rescue officers" 2 "Executives,Management and Government Officials" 3 "Education Professionals" 4 "Educational Support Personnel" 5 "Health Care Professionals" /*
*/ 6 "Professionals" 7 "Trades and technical" 8 "Social Service Professionals" 9 "University"
label values job_classification jclass

keep individual_id job_classification agency_num
renvars job_classification /job_classification_2014

note job_classification_2014: Admin data from April 2014, Survey 1
note : agency classification codes are all "NULL" ==> drop it

save "${working}\s1_job_classification_$S_DATE", replace

********************************************************************************
*** S3 job classification
********************************************************************************
use "${raw}ACTIVES_WORK_HISTORY_CORRECTED.dta", clear
codebook individual_id

destring salary_year, replace ignore("NULL")
bysort individual_id: egen maxyr=max(salary_year)
keep if salary_year==maxyr // keep the latest salary year

destring total_salary, replace ignore("NULL")
bysort individual_id: egen maxsal=max(total_salary)
keep if maxsal==total_salary
replace total_salary=round(total_salary)
replace maxsal=round(maxsal)

duplicates drop individual_id, force
tab agency_classification
tab job_classification

keep individual_id agency_num agency_classification_code employee_category job_classification

gen agency_classification=.
replace agency_classification=1 if agency_classification_code=="CITY"
replace agency_classification=2 if agency_classification_code=="COUNTY"
replace agency_classification=3 if agency_classification_code=="PUBSCH"
replace agency_classification=4 if strpos(agency_classification_cod, "GENGOV")
replace agency_classification=5 if agency_classification_code=="DOT"
replace agency_classification=6 if agency_classification_code~="" & agency_classification==.

label define agency_class 1 "City" 2 "County" 3 "Public School" 4 "General government" 5 "DOT" 6 "Other"
label values agency_classification agency_class 

tab agency_classification

rename job_classification job_classification_code
gen job_classification=.
replace job_classification=1 if job_classification_code== "SHP Trooper" | job_classification_code== "Wildlife Officer" | job_classification_code=="Police Officer" |/*
*/ job_classification_code== "Wildlife Officer" | job_classification_code== "Public Safety Officer" | job_classification_code== "Rescue Worker" |  /*
*/ job_classification_code=="Protective Services (Non-Certified)" | job_classification_code== "Revenue Enforcement Officer" | job_classification_code=="Sheriff" | /*
*/ job_classification_code=="ABC Officer" | job_classification_code=="Deputy Sheriff" | job_classification_code=="Jailer (Certified)" | job_classification_code=="Local Firefighters"
replace job_classification=2 if job_classification_code=="Administrative" | job_classification_code== "Educational Executives" | job_classification_code== "Educational Management" /*
*/ | job_classification_code== "Government Officials" | job_classification_code== "University and Community College Executives" | job_classification_code== "University and Community College Management" 
replace job_classification=3 if job_classification_code== "Education Professionals"
replace job_classification=4 if job_classification_code== "Educational Administrative Support Personnel" | job_classification_code== "Educational Support Personnel"
replace job_classification=5 if job_classification_code== "Health Care Professionals"
replace job_classification=6 if job_classification_code=="Professionals"
replace job_classification=7 if job_classification_code=="Skilled Labor" | job_classification_code=="Technical and Trades"
replace job_classification=8 if job_classification_code=="Social Service Professionals"
replace job_classification=9 if job_classification_code=="University Agricultural (AG)Extension" | job_classification_code=="University and Community College Professionals"
label define jclass 1 "Safety/Rescue officers" 2 "Executives,Management and Government Officials" 3 "Education Professionals" 4 "Educational Support Personnel" 5 "Health Care Professionals" /*
*/ 6 "Professionals" 7 "Trades and technical" 8 "Social Service Professionals" 9 "University"
label values job_classification jclass

keep individual_id agency_num agency_classification job_classification
renvars agency_classification job_classification\ agency_classification_2016 job_classification_2016

note job_classification_2016: Admin data from May 2016, Survey 3

save "${working}s3_job_classification_$S_DATE", replace




*===================================================================
merge 1:1 indi using "${working}s1_job_classification_$S_DATE",force
count if _merge ==1 
count if _merge ==1 & job_classification_2016 ~=. & job_classification_2014 ==.
count if _merge ==1 & job_classification_2016 ==. & job_classification_2014 ==.
count if _merge ==2 
count if _merge ==2 & job_classification_2014 ~=. & job_classification_2016 ==.
count if _merge ==2 & job_classification_2014 ==. & job_classification_2016 ==.

gen job_classification = job_classification_2016
replace job_classification = job_classification_2014 if job_classification_2016 ==. & job_classification_2014<.

rename agency_classification_2016 agency_classification

keep individual_id agency_num job_classification agency_classification

save "${working}job_classification_$S_DATE", replace

log close _all


