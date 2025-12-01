/************************************************************************************************************************ 
This file identifies the actives using Administrative Data release at 04.06.2016 ==> pre-survey 
************************************************************************************************************************/

include "Step0_SetDirectory"
log using "${log}MakeData_Admin3_Actives_$date", replace text name("Ariel") 

***********************************************
*** Merging files of Admin Data from Survey 3 (pre-survey)
***********************************************

use "${raw}ACTIVES_ALL_MEMBERSHIP_INFO.dta",clear // 04.06.2016 version

merge m:1 individual_id using "${raw}ACTIVES_PERSON_INFO.dta", keepusing(age gender_code) // 04.06.2016 version
keep if _merge==1 |_merge==3 
drop _merge

merge m:1 individual_id using "${raw}PERSON_FILE_NEW.dta", keepusing(deceased_ind) // use deceased_ind only. 
keep if _merge==1 |_merge==3 
drop _merge

**********************************
/*** Restrictions for base sample 
**********************************

- Not retired as of April 2016 (Active Benefit Account and Claim Benefit)
- Active Membership 
- TSERS or LGERS
- Drop law enforcement, firefighters
- Workers aged 50 to 70 ==> might need to further restricted to 52 to 64 
- Drop indi. claiming disability or other benefit types(non-regular) as of April 2016 
- Drop data with unidentified gender 
- Drop individuals deceased as of April 2016
- Drop individuals/memberships with missing contribution dates
- First hired before 3/4/2014
- Drop individuals with last contribution year before 2014 in April 2016 data==> keep for now, but could be skipped since we only need to keep active workers

**********************************/

*** Drop individuals retired as of April 2016 

	/*Retired
	--Has claimed benefits as of April.06.2016 
	--Active Benefit status code
	--Early/Normal Benefit account type code */

	gen admin3_benefitdate=date(ba_effective_date, "MDY")  // benefit claim date
	format admin3_benefitdate %td
	
	gen _retired=(admin3_benefitdate<mdy(04,06,2016))

	replace _retired = 1 if (benefit_account_type_code=="EARLY"|benefit_account_type_code=="SVC") & ba_status_code=="ACTV"
	
	egen admin3_status_retired=max(_retired), by(individual_id) // =1 if retired as of April 2016 
	
	replace admin3_status_retired=1 if individual_id=="P3013713" // P3013713 has no benefit account, membership status retired with no termination type code
	
	drop if admin3_status_retired == 1 
	
	
*** Keep active workers with Active Membership 

	/*Actives: 
	--Active membership status code*/

	keep if membership_status_code=="ACTV" 	

	
*** Keep TSERS or LGERS

	bysort individual_id: egen admin3_tsers=max(mem_retirement_system_code=="TSERS"|mem_retirement_system_code=="ORP")
	bysort individual_id: egen admin3_lgers=max(mem_retirement_system_code=="LGERS"|mem_retirement_system_code=="RDSPF")
	
	keep if mem_retirement_system_code=="TSERS"|mem_retirement_system_code=="ORP" | mem_retirement_system_code=="LGERS"|mem_retirement_system_code=="RDSPF"

	*drop if admin3_tsers==1 & admin3_lgers==1 // we delete the restriction "drop people with both TSERS or LGERS" in June 2022, please refer to notes for details

	
*** Drop law enforcement, firefighters

	drop if  last_plan_code=="STL" | last_plan_code=="LOCL" | last_plan_code=="LOCF" | last_plan_code=="RESG"
	

*** Keep workers aged 50 to 70

	keep if inrange(age,50,70)
	
	
*** Drop indi. claiming disability or other benefit types (non-regular)

	gen _other=(benefit_account_type_code=="OTHER" ) 
	
	egen admin3_status_other=max(_other), by(individual_id)
	
	drop if admin3_status_other == 1	
	

*** Drop data with unidentified gender

	drop if gender_code=="U"	
	
	
*** Drop individuals deceased as of April 2016

	destring deceased_ind, replace
	drop if deceased_ind==1
	

*** Drop individuals/ memberships with missing contribution dates

    gen admin3_lastcontribdate=date(last_contrib_date, "MDY")
	format admin3_lastcontribdate %td

	drop if admin3_lastcontribdate ==.	
	
	
*** Keep individuals first hired before 3/4/2014

	gen admin3_membegindate=date(membership_begin_date, "MDY")
	format admin3_membegindate %td	
	
	bysort indi: egen admin3_first_hire_date = min(admin3_membegindate) 
	
	keep if admin3_first_hire_date <= mdy(03,04,2014)	

	
*** Drop individuals with last contribution year before 2014 in April 2016 data	
 
	gen admin3_lastcontribyear=year(admin3_lastcontribdate)
	 
	bysort indi: egen admin3_latest_lastcontribyear = max(admin3_lastcontribyear)

	drop if admin3_latest_lastcontribyear<2014
	

*** Reshape dataset into wide form using time of last contribustion date as subobservation (since last contribustion date could be good proxy of membership end date)
 
	gsort indi -admin3_lastcontribdate // using admin3_lastcontribdate 
	bysort indi: gen admin3_mem_order = _n
	
	duplicates tag indi, gen(admin3_multi_mem)
	
	tab admin3_mem_order  admin3_multi_mem
	
	keep individual_id-deceased_ind admin3_multi_mem admin3_mem_order admin3_lastcontribdate admin3_tsers admin3_lgers
	
	reshape wide pr_membership_id-deceased_ind admin3_multi_mem admin3_lastcontribdate admin3_tsers admin3_lgers, i(individual_id) j(admin3_mem_order)


*** Attach notes regarding dataset created by this do file to resulting dta file

note: This file identifies the actives using administrative data release at 04.06.2016 ==> pre-survey 
note: Raw data used to creates this file: ACTIVES_ALL_MEMBERSHIP_INFO.dta, ACTIVES_PERSON_INFO.dta(04.06.2016) and PERSON_FILE_NEW.dta
note: Do file used to creates this file: MakeData_Admin3_Actives.do
note:  {break} ///
Restrictions for base sample:  {break} ///
 {space 2} {break} ///
- Not retired as of April 2016 (Active Benefit Account and Claim Benefit) {break} ///
- Active Membership  {break} ///
- TSERS or LGERS {break} ///
- Drop law enforcement, firefighters {break} ///
- Workers aged 50 to 70 ==> might need to further restricted to 52 to 64  {break} ///
- Drop indi. claiming disability or other benefit types(non-regular) as of April 2016  {break} ///
- Drop data with unidentified gender  {break} ///
- Drop individuals deceased as of April 2016 {break} ///
- Drop individuals/memberships with missing contribution dates {break} ///
- First hired before 3/4/2014 {break} ///
- Drop individuals with last contribution year before 2014 in April 2016 data==> keep for now, but could be skipped since we only need to keep active workers {break} ///
 {space 2}
note: the postfix number in variable names stands for the order of the membership each variables refer to 
note:  {break} ///
///
Survey 3 timeline:  {break} ///
 {space 2} {break} ///
Sun 5/10	 First day of fielding survey  {break} ///
Tue 5/17	 Reminder sent to benefit claimants, with date of first drawing {break} ///
Wed 5/18	 Reminder sent to actives, with date of first drawing {break} ///
Mon 5/23	 First iPad drawing  {break} ///
Tue 5/31	 Reminders sent to all groups, announcing iPad winners {break} ///
Tue 6/8	 	 Reminder sent to all groups, with date of second drawing {break} ///
Fri 6/10	 Second iPad drawing 


*** Save dataset with all membership

save "${working}Admin3_Actives_keep_all_membership", replace

keep if (mem_retirement_system_code1=="TSERS"|mem_retirement_system_code1=="ORP" | mem_retirement_system_code1=="LGERS"|mem_retirement_system_code1=="RDSPF")


*** Keeping the most recent membership/ removing duplicates

keep indi *1

renvars _all, postsub(1 )


note replace _dta in 5: This file only keeps the most recent membership

save "${working}Admin3_Actives", replace

log close _all

exit


/************** Legacy codes ***************

This file creates the active and retired classifications using Administrative Data release at 04.06.2016 ==> pre-survey 

*** Restrictions for base sample previously
**********************************

- TSERS or LGERS, not both 
- not retired as of April 2016 ==> not yet claiming benefits and active
- workers aged 50 to 70 ==> might need to further restricted to 52 to 64 
- drop indi. claiming disability or other benefit types(non-regular) as of April 2016 
- first hired before 3/4/2014
- pay period ending on or after 12/01/2013: meaning valid contributions on or after 12/01/2013 ==> delete this restriction since we only need to keep active workers
- drop individuals/memberships with missing contribution dates
- drop individuals with last contribution year before 2014 in April 2016 data==> skip for now since we only need to keep active workers
- drop data with unidentified gender 
- drop individuals deceased as of April 2016
- Remove duplicate memberships ==> keep the current membership ==> need to be improve

- Drop individuals missing in April 2016 data release ==> merge March 2014 Data(Master) with April 2016 Data(Using) and drop _merge ==2
 ==>> don't have survey1 admin data==> skip it
- Drop law enforcement, firefighters ==> it seems this code is for survey 2 not for survey 3
	drop if last_plan_code=="STL" | last_plan_code=="LOCL" | last_plan_code=="LOCF" // | last_plan_code=="RESG"


*** Keep invidual have pay period ending on or after 12/01/2013 
 
     gen lastcontribdate=date(last_contrib_date, "MDY")
	 format lastcontribdate %td
	 
	 bysort indi: egen latest_lastcontribdate = max(lastcontribdate)

     keep if latest_lastcontribdate>= mdy(12,01,2013)
	 
	 
*** Drop individuals with last contribution year before 2014 in April 2016 data	

	gen lastcontribyear=year(lastcontribdate)
	
	drop if lastcontribyear<2014
	
	duplicates  report indi membership_begin_date



*** Drop individuals retired as of April 2016 

	/*Retired
	--Has claimed benefits as of April.06.2016 
	--Active Benefit status code
	--Early/Normal Benefit account type code */

	gen admin3_benefitdate=date(ba_effective_date, "MDY")  // benefit claim date
	format admin3_benefitdate %td
	
	gen _retired=(admin3_benefitdate<mdy(04,06,2016))

	replace _retired = 1 if (benefit_account_type_code=="EARLY"|benefit_account_type_code=="SVC") & ba_status_code=="ACTV"
	
	egen admin3_status_retired=max(_retired), by(individual_id) //retired as of April 2016 
	
	replace admin3_status_retired=1 if individual_id=="P3013713" //No benefit account, membership status retired with no termination type code
	
	drop if admin3_status_retired == 1 
	
	
*** Keep active workers with Active Membership in TSERS and ORP and Not Claiming A Benefit

	/*Actives: 
	--Active membership status code
	--Null benefit status code
	--Null termination code */

	gen _active= (membership_status_code=="ACTV") & (mem_retirement_system_code=="TSERS"|mem_retirement_system_code=="ORP" | mem_retirement_system_code=="LGERS"|mem_retirement_system_code=="RDSPF") //& ba_status_code=="" & termination_type_code==""

	egen admin3_status_active=max(_active), by(individual_id)

	label var admin3_status_active "Active"
	
	tab admin3_status_active admin3_status_retired
	
	keep if admin3_status_active ==1	
