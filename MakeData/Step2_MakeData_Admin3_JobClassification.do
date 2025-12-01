******************************************************************************************************
*** This file creates job and agency classifications using admin data from April 2016 and March 2014 ***
******************************************************************************************************

include "Step0_SetDirectory"
log using "${log}MakeData_Admin3_JobClassification_$date", replace text name("Ariel")

********************************************************************************
*** job classification from April 2016, Survey 3
********************************************************************************

use "${raw}ACTIVES_WORK_HISTORY_CORRECTED.dta", clear // 04.06.2016 version

*** Keep the latest salary year 

destring salary_year, replace ignore("NULL")

bysort individual_id: egen maxyr=max(salary_year)

keep if salary_year==maxyr 

tab salary_year
duplicates report indi


*** Keep main jobs with highest salary

destring total_salary, replace ignore("NUL") // Note: I use salary here just to select the main job and to remove duplicates. salary variables are officially defined in MakeData_Admin3_Salary.do

bysort individual_id salary_year: egen maxsal=max(total_salary)

gen round_total_salary=round(total_salary)
gen round_maxsal=round(maxsal)

keep if round_maxsal==round_total_salary  // 


*** Define Agency Classification

duplicates report indi
drop if job_classification =="NULL"
duplicates drop indi, force

gen agency_classification=.
replace agency_classification=1 if agency_classification_code=="CITY"
replace agency_classification=2 if agency_classification_code=="COUNTY"
replace agency_classification=3 if agency_classification_code=="PUBSCH"
replace agency_classification=4 if strpos(agency_classification_cod, "GENGOV")
replace agency_classification=5 if agency_classification_code=="DOT"
replace agency_classification=6 if agency_classification_code~="" & agency_classification==.

label define agency_class 1 "City" 2 "County" 3 "Public School" 4 "General government" 5 "DOT" 6 "Other"
label values agency_classification agency_class 

tab agency_classification_code agency_classification 


*** Define Job Classification

rename job_classification job_classification_code
gen job_classification=.
replace job_classification=1 if job_classification_code== "SHP Trooper" | job_classification_code== "Wildlife Officer" | job_classification_code=="Police Officer" | job_classification_code== "Wildlife Officer" | job_classification_code== "Public Safety Officer" | job_classification_code== "Rescue Worker" |  job_classification_code=="Protective Services (Non-Certified)" | job_classification_code== "Revenue Enforcement Officer" | job_classification_code=="Sheriff" |  job_classification_code=="ABC Officer" | job_classification_code=="Deputy Sheriff" | job_classification_code=="Jailer (Certified)" | job_classification_code=="Local Firefighters"
replace job_classification=2 if job_classification_code=="Administrative" | job_classification_code== "Educational Executives" | job_classification_code== "Educational Management" /| job_classification_code== "Government Officials" | job_classification_code== "University and Community College Executives" | job_classification_code== "University and Community College Management" 
replace job_classification=3 if job_classification_code== "Education Professionals"
replace job_classification=4 if job_classification_code== "Educational Administrative Support Personnel" | job_classification_code== "Educational Support Personnel"
replace job_classification=5 if job_classification_code== "Health Care Professionals"
replace job_classification=6 if job_classification_code=="Professionals"
replace job_classification=7 if job_classification_code=="Skilled Labor" | job_classification_code=="Technical and Trades"
replace job_classification=8 if job_classification_code=="Social Service Professionals"
replace job_classification=9 if job_classification_code=="University Agricultural (AG)Extension" | job_classification_code=="University and Community College Professionals"
label define jclass 1 "Safety/Rescue officers" 2 "Executives,Management and Government Officials" 3 "Education Professionals" 4 "Educational Support Personnel" 5 "Health Care Professionals"  6 "Professionals" 7 "Trades and technical" 8 "Social Service Professionals" 9 "University"
label values job_classification jclass

keep individual_id agency_classification job_classification
renvars agency_classification-job_classification, prefix(admin3_)

note admin3_job_classification: Generated from admin data from April 2016(pre-survey3 admin data) 
note admin3_agency_classification: Generated form admin data from April 2016(pre-survey3 admin data) 

save "${working}Admin3_JobClassification", replace


********************************************************************************
*** job classification from March 2014, Survey 1
********************************************************************************
use "${raw}salary_history_admin", clear //  March 2014 version (before survey 1 date, April 1,2014)

destring salary_year, replace ignore("NULL")
bysort individual_id: egen maxyr=max(salary_year)
keep if salary_year==maxyr // keep the latest salary year

tab salary_year

duplicates report indi

destring total_salary, replace ignore("NUL") // Note: I use salary here just to select the main job and to remove duplicates. salary variables are officially defined in MakeData_Admin3_Salary.do
bysort individual_id salary_year: egen maxsal=max(total_salary)
gen round_total_salary=round(total_salary)
gen round_maxsal=round(maxsal)
keep if round_maxsal==round_total_salary // keep main job with highest salary

duplicates report indi

drop if job_classification =="NULL"
duplicates drop indi, force

tab job_classification
rename job_classification job_classification_code

gen job_classification=.
replace job_classification=1 if job_classification_code== "SHP Trooper" | job_classification_code== "Wildlife Officer" | job_classification_code=="Police Officer" | job_classification_code== "Wildlife Officer" | job_classification_code== "Public Safety Officer" | job_classification_code== "Rescue Worker" |  job_classification_code=="Protective Services (Non-Certified)" | job_classification_code== "Revenue Enforcement Officer" | job_classification_code=="Sheriff" | job_classification_code=="ABC Officer" | job_classification_code=="Deputy Sheriff" | job_classification_code=="Jailer (Certified)" | job_classification_code=="Local Firefighters"
replace job_classification=2 if job_classification_code=="Administrative" | job_classification_code== "Educational Executives" | job_classification_code== "Educational Management" | job_classification_code== "Government Officials" | job_classification_code== "University and Community College Executives" | job_classification_code== "University and Community College Management" 
replace job_classification=3 if job_classification_code== "Education Professionals"
replace job_classification=4 if job_classification_code== "Educational Administrative Support Personnel" | job_classification_code== "Educational Support Personnel"
replace job_classification=5 if job_classification_code== "Health Care Professionals"
replace job_classification=6 if job_classification_code=="Professionals"
replace job_classification=7 if job_classification_code=="Skilled Labor" | job_classification_code=="Technical and Trades"
replace job_classification=8 if job_classification_code=="Social Service Professionals"
replace job_classification=9 if job_classification_code=="University Agricultural (AG)Extension" | job_classification_code=="University and Community College Professionals"
label define jclass 1 "Safety/Rescue officers" 2 "Executives,Management and Government Officials" 3 "Education Professionals" 4 "Educational Support Personnel" 5 "Health Care Professionals" 6 "Professionals" 7 "Trades and technical" 8 "Social Service Professionals" 9 "University"
label values job_classification jclass

tab agency_classification,m //agency classification codes are all "NULL" ==> drop it

keep individual_id job_classification 
renvars job_classification / admin1_job_classification

note admin1_job_classification: Admin data from March 2014, for Survey 1(April 1,2014) sample 

save "${working}Admin1_JobClassification", replace


*** S3 job classification data incomplete, so merge s1 and s3 job classification for more complete job classification
	
merge 1:1 individual_id using "${working}Admin3_JobClassification"
drop _merge
	
gen admin3_job_classification_adj = admin3_job_classification
replace admin3_job_classification = admin1_job_classification if admin3_job_classification==. & admin1_job_classification<.

*** Keep relevant variables
keep individual_id admin3_agency_classification admin3_job_classification_adj
	

*** Attach notes regarding dataset created by this do file to resulting dta file.
	
note: This file creates job and agency classifications using admin data from April 2016(pre-survey3 admin data) and March 2014(pre-survey1 admin data)
note: S3 job classification data is incomplete, so merge s1 and s3 job classification for more complete job classification
note: Raw data used to creates this file: ACTIVES_WORK_HISTORY_CORRECTED.dta(04.06.2016) and salary_history_admin.dta (March 2014)
note: Do file used to creates this file: MakeData_Admin3_JobClassification.do
note admin3_job_classification_adj: Generated form admin data from April 2016 and March 2014.  
note admin3_job_classification_adj: Since S3 job classification data incomplete, so fill missing s3 job classification with s1 job classification.  

save "${working}Admin1_3_JobClassification", replace

log close _all
