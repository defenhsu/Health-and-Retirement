
pre-period 
>> make_admin3

********************************************************************************
*** This file creates the active and retired classifications used at beginning of
*** period under study (as of May 2016)
********************************************************************************
clear
capture log close _all
set more off
pause on

cd "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs"

global date "$S_DATE"
log using "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs\Logs\MakeData_Admin_$date", replace text name("Ariel")
global raw "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\RawData\"
global working "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\WorkingData\"

*============================================================================*
*********************************
** ACTIVES_ALL_MEMBERSHIP_INFO **
*********************************
use "${raw}ACTIVES_ALL_MEMBERSHIP_INFO.dta",clear
admin3

** Some Important Date **
gen svy3date=mdy(05,10,2016) // survey 3 date 
*gen svy5date=mdy(12,01,2017) // survey 5 date  >> delete
gen svy3ageatdate=mdy(3,23,2016) //imputed date ...   ??????????? which one just one date
gen admin3date=mdy(12,31,2015) //admin date release date (memshipe service and salary)
gen adminT=() ==>> figure out ther date 

*replace individual_id=strltrim(individual_id) // trim ==>strltrim // ==> go with merge if needed

** Correct Membership System Information *** ==> add new var >> don't overwrite 
replace mem_retirement_system_code="LGERS" if mem_retirement_system_code=="RDSPF" // RDSPF are also in LGERS
replace mem_retirement_system_code="TSERS" if mem_retirement_system_code=="ORP" // ORP service credit may also be used to determine eligibility for TSERS benefits

count if mem_retirement_system_code== "FRSWPF" & last_contrib_date~="" //why is FRSWPF always have NULL last_contrib_date?
duplicates report individual_id mem_retirement_system_code membership_begin_date 

//*** Last Contributition Date ***//
gen lastcontribdate=date(last_contrib_date, "MDY")
format lastcontribdate %td
egen latest_lastcontribdate=max(lastcontribdate), by(individual_id)
egen first_lastcontribdate=min(lastcontribdate), by(individual_id)
format latest_lastcontribdate %td
format first_lastcontribdate %td
gen lastcontribyear=year(lastcontribdate)
lab var lastcontribdate "Last Contributition Date"
lab var latest_lastcontribdate "Most Recent Last Contributition Date"
lab var first_lastcontribdate "Earliest Last Contributition Date"
note lastcontribdate: using admin data from "ACTIVES_ALL_MEMBERSHIP_INFO"
note latest_lastcontribdate: using admin data from "ACTIVES_ALL_MEMBERSHIP_INFO"


//*** Termination Date ***//
gen termdate=date(termination_date, "MDY")
format termdate %td
egen latest_termdate=max(termdate), by(individual_id)
format latest_termdate %td
gen latest_termyear=year(latest_termdate)
lab var termdate "Termination Date"
label var latest_termdate "Most Recent Termination Date"
label var latest_termyear "Most Recent Termination Year"


//*** Benefit Claim Date ***//
gen benefitdate=date(ba_effective_date, "MDY")
format benefitdate %td
egen latest_badate=max(benefitdate), by(individual_id)
format latest_badate %td
gen latest_bayear=year(latest_badate)
lab var benefitdate "Benefit Claim date"
label var latest_badate "Most Recent Benefit Claim date"
label var latest_bayear "Most recent benefit claim year"


//*** Membership Begin Dates***//
gen membegindate=date(membership_begin_date, "MDY")
format membegindate %td
egen latest_membegindate=max(membegindate), by(individual_id) 
format latest_membegindate %td
bysort individual_id: egen first_membegindate=min(membegindate)
format first_membegindate %td
gen latest_membeginyr=year(latest_membegindate)
lab var membegindate "Membership Begin Date"
label var latest_membegindate "Most Recent Membership Begin Date"
label var latest_membeginyr "Most Recent Membership Begin Year"
lab var first_membegindate "First Membership Begin Date"


//*** Membership Status Dates***//
gen memstatusdate=date(membership_status_date, "MDY")
format memstatusdate %td
egen latest_memstatusdate=max(memstatusdate), by(individual_id) 
format latest_memstatusdate %td
gen latest_memstatusyr=year(latest_memstatusdate)
label var memstatusdate "Membership Status Date"
label var latest_memstatusdate "Most Recent Membership Status Date"
label var latest_memstatusyr "Most Recent Membership Status Year"


/*Actives: 
--Active membership status code
--Null benefit status code
--Null termination code */

//*** Active : Active Membership and Not Claiming A Benefit ***//
gen _active=1 if (membership_status_code=="ACTV" & ba_status_code=="" & termination_type_code=="")
egen active=mean(_active), by(individual_id)
label var active "Active"


/*Retired	
--Active Benefit status code
--Early/Normal Benefit account type code
-- Claimed benefit from TSERS and LGERS	
*/

//*** Retired : Actively Claiming A Regular Benefit (Early/Normal) ***///
gen _retired=1 if (benefit_account_type_code=="EARLY"|benefit_account_type_code=="SVC") & ba_status_code=="ACTV"
replace _retired=. if mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="LGERS"
egen retired=mean(_retired), by(individual_id)
label var retired "Retired"


/*
Claimed other benefit	
--Other/Refund Benefit account type code
*/

//*** Claiming Non-Regular Benefit ***///
gen _other=1 if (benefit_account_type_code=="OTHER" | benefit_account_type_code=="ATR")
egen otherdisab=mean(_other), by(individual_id)
label var otherdisab "Claiming Non-Regular Benefit"


//*** Terminated (Not Retired) ***///
gen _dv=1 if membership_status_code=="ACTV" & termination_type_code~="" & ba_status_code==""
egen defvested=mean(_dv),by(individual_id)
label var defvested "Terminated (Not Retired)"


/*Terminated retired	
-Active membership account
-Non-null termination code
-Null benefit status code
-Termination date 2014-2016
-Termination and last
 contribution date within +/- 30 days
*/

//*** Terminated Retired ***///
gen diff_dates=termdate-lastcontribdate //compare termination date and contribution date
replace diff_dates=abs(diff_dates)

gen _termretired=1 if membership_status_code=="ACTV" & termination_type_code~="" & ba_status_code=="" & (year(lastcontribdate)>=2014 & lastcontribdate~=.) & diff_dates<=30 & lastcontribdate==termdate // using most recent termination date
egen termretired=mean(_termretired), by(individual_id)
lab var termretired "Terminated Retired"


/*Terminated Actives: 
-Non-null Termination Code
-Active membership status code
-Non-null termination code
-Null benefit status code
-Termination date before 2014/ after 2016  
OR Termination and last contribution date more than 30 days apart 
OR Last contribution date in December 2015*/

//*** Terminated Active ***/// 
gen _termactive=1 if  membership_status_code=="ACTV" & termination_type_code~="" & ba_status_code=="" & ((year(lastcontribdate)<2014 | diff_dates>30 ) & lastcontribdate==termdate) 
replace _termactive=1 if membership_status_code=="ACTV" & termination_type_code~="" & ba_status_code=="" & lastcontribdate>=mdy(12, 1, 2015)
egen termactive=mean(_termactive), by(individual_id)
lab var termactive "Terminated Active"


*Note: 1 individual with a non-null termination code but no active membership is unclassified. 
*Since their most recent termination date is before 2014, classify these as terminated retired
codebook individual_id if defvested==1 & termretired==. & termactive==. & otherdisab==. & active==. & retired==.
list termdate if defvested==1 & termretired==. & termactive==. & otherdisab==. & active==. & retired==.
replace termretired=1 if defvested==1 & termretired==. & termactive==. & otherdisab==. & active==. & retired==.


//*** TSERS/LGERS Indicator ***//
gen _tslg=mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="LGERS"
bysort individual_id: egen multi_tslg =total(_tslg)
gen multimem_tslg= (multi_tslg>1 & multi_tslg<.)
lab var _tslg "TSERS or LGERS"
lab var multimem_tslg "Mutliple Membership in TSERS/LGERS"
bysort indi: egen ts_num=count(mem_retirement_system_code) if mem_retirement_system_code== "TSERS"
bysort indi: egen lg_num=count(mem_retirement_system_code) if mem_retirement_system_code== "LGERS"

bysort indi: egen mem_count=count(mem_retirement_system_code)
gen ts_only =(mem_count==ts_num) if multimem_tslg >= 1
gen lg_only =(mem_count==lg_num) if multimem_tslg >= 1

tab ts_only lg_only

gen ts_or_lg_only =(ts_only==1 | lg_only==1)
lab var ts_or_lg_only "TSERS or LGERS (Not Both)"
note ts_or_lg_only: The sample is restricted to active workers who were members of TSERS or LGERS, but not both. 



** Do we need an indicator for ACT_TSLG_ONLY??



//*** Indicator for Multiple Memberships**//
duplicates tag individual_id, gen(tag)
gen multimem=(tag>=1)
drop tag
lab var multimem "Indicator for Multiple Memberships"


//*** Indicator for individuals who had a break in service between 2 memberships ***//
	
	sort indiv membership_status_code
	by individual_id: gen laterbegin=membegindate[_n-1]
	format laterbegin %td

	gen diff_dates_2=(laterbegin-memstatusdate)/30
	count if abs(diff_dates_2)<3
	count if diff_dates_2>0 & diff_dates_2<3

	gen _break=diff_dates_2>=3 & laterbegin~=.
	by individual: egen brk_svc=max(_break)
	lab var brk_svc "had a break in service between 2 memberships"

	
//*** Individual has an Active/Retired/Transferred TSERS account ***///
gen _tsers=mem_retirement_system_code=="TSERS" & (membership_status_code=="ACTV" | membership_status_code=="CLOSRET" | membership_status_code=="CLOSTRANS")
egen tsers=max(_tsers), by(individual_id)
label var tsers "Individual has an Active/Retired/Transferred TSERS account" 

gen _lgers=mem_retirement_system_code=="LGERS" & (membership_status_code=="ACTV" | membership_status_code=="CLOSRET" | membership_status_code=="CLOSTRANS")
egen lgers=max(_lgers), by(individual_id)
label var lgers "Individual has an Active/Retired/Transferred LGERS account" 


**********
destring membership_total_service membership_contributory_service membership_other_servic, replace ignore("NULL")

//*** Years of Service, Current Membership ***//
merge 1:1 pr_membership_id using "${raw}ACTIVES_PERSON_INFO.dta", keepusing(pr_membership_id age)
gen current_mem =(_merge==3)

gsort indi membegindate  -membership_total_service
/*egen current_mem = tag(indi) if (membership_status_code=="ACTV" | membership_status_code=="CLOSRET" ) 

gen yos_2016_curr=membership_total_service if current_mem==1
gen contrib_yos_2016_curr = membership_contributory_service if current_mem==1*/


gen _yos_curr=membership_total_service if current_mem==1 //_merge==3
gen _contrib_yos_curr=membership_contributory_service if current_mem==1 // _merge==3

bysort individual_id: egen yos_2016_curr=mean(_yos_curr)
bysort individual_id: egen contrib_yos_2016_curr=mean(_yos_curr)

label var yos_2016_curr "Years of service- current membership"
label var contrib_yos_2016_curr "Contrib years of service- current membership"

gen yos_svy3_curr=yos_2016_curr - ((admin3date-svy3date)/365.25) 
gen contrib_yos_svy3_curr=contrib_yos_2016_curr - ((admin3date-svy3date)/365.25) 

label var yos_svy3_curr "Years of service- current membership, as of svy3"
label var contrib_yos_svy3_curr "Contrib years of service- current membership , as of svy3"

drop _merge

preserve 
duplicates drop indi, force

keep individual_id yos_* contrib_yos_*
tempfile s3_ageathire_curr
save `s3_ageathire_curr'

restore
preserve

//*** YOS, all active and retired memberships, for TSERS/LGERS/CJRS/LRS ***//

duplicates report individual_id mem_retirement_system_code membership_begin_date
gsort indi -membership_total_service
*duplicates drop individual_id mem_retirement_system_code membership_begin_date, force

drop if membership_status_code~="ACTV" & membership_status_code~="CLOSRET"    
keep if mem_retirement_system_code=="CJRS" | mem_retirement_system_code=="LGERS" | mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="LRS"
replace membership_other_service=0 if membership_other_service==.
replace membership_other_service=round(membership_other_service, 0.01)


duplicates tag individual_id, gen(tag)
tab tag
sort individual_id

by individual_id: egen yos_2016_sum=total(membership_total_service)
by individual_id: egen maxyos=max(membership_total_service)
by individual_id: egen contrib_yos_2016_sum=total(membership_contributory_service)
by individual_id: egen maxcontribyos=max(membership_contributory_service)
gen _bftdate=date(ba_effective_date, "MDY")

by individual_id: egen last_membegindate_2=max(membegindate)
by individual_id: egen first_contribdat_2=min(lastcontribdate)

gen svc_overlap_2016= tag==1 & first_contribdat_2>last_membegindate_2

gen yos_2016_adj=yos_2016_sum
replace yos_2016_adj=maxyos if svc_overlap_2016==1

gen contrib_yos_2016_adj=contrib_yos_2016_sum
replace contrib_yos_2016_adj=maxcontribyos if svc_overlap_2016==1 

by individual_id: egen ba_yos_2016_sum=total(ba_total_service)
by individual_id: egen ba_maxyos=max(ba_total_service)
gen ba_yos_2016_adj=ba_yos_2016_sum
replace ba_yos_2016_adj=ba_maxyos if svc_overlap_2016

gen yos_svy3_sum =yos_2016_sum - ((admin3date-svy3date)/365.25) 
gen yos_svy3_adj =yos_2016_adj - ((admin3date-svy3date)/365.25) 
gen contrib_yos_svy3_sum =contrib_yos_2016_sum - ((admin3date-svy3date)/365.25) 
gen contrib_yos_svy3_adj =contrib_yos_2016_adj - ((admin3date-svy3date)/365.25) 

label var yos_2016_sum "YOS, all active and retired memberships"
label var yos_2016_adj  "YOS, all active and retired adjusted for dates overlap"
label var contrib_yos_2016_sum "Contri. YOS, all active and retired memberships"
label var contrib_yos_2016_adj  "Contri. YOS, all active and retired adjusted for dates overlap"
label var yos_svy3_sum "YOS, all active and retired memberships, as of svy3 date"
label var yos_svy3_adj  "YOS, all active and retired adjusted for dates overlap, as of svy3 date"
label var contrib_yos_svy3_sum "Contri. YOS, all active and retired memberships, as of svy3 date"
label var contrib_yos_svy3_adj  "Contri. YOS, all active and retired adjusted for dates overlap, as of svy3 date"

gen ba_yos_svy3_sum =ba_yos_2016_sum - ((admin3date-svy3date)/365.25) 
gen ba_yos_svy3_adj =ba_yos_2016_adj - ((admin3date-svy3date)/365.25) 

gsort indi -membership_total_service
duplicates drop indi,force

merge 1:1 individual_id using `s3_ageathire_curr'
keep if _merge==2 | _merge==3
drop _merge 



*************************
** ACTIVES_PERSON_INFO **
*************************
merge 1:1 individual_id using "${raw}ACTIVES_PERSON_INFO.dta"
keep if _merge==1 |_merge==3 
drop _merge

label var age "Age as of Admin Data Release Date"


//***  Age as of Survey Date ***///
gen ageatsvy_2016=age + ((mdy(05,10,2016)-mdy(03,23,2016))/365.25)
label var ageatsvy "Age as of Survey Date"


//*** Age at Hire- First Membership ***//
gen ageathire_first=age - ((svy3ageatdate-first_membegindate)/365.25)
label var ageathire_first "Age at Hire- First Membership"
/* *** Age at first hire, calculated based on earliest membership begin date
	by individual_id: egen lastmembegindate=max(membegindate)
	by individual_id: egen firstmembegindate=min(membegindate)
	format firstmembegindate %td

	gen ageatdate=age
	gen ageathire_first_adj=age -((ageatdate-firstmembegindate)/365.25)
	label var ageathire_first_adj "Age at hire- first membership(adjusted)"*/
	

//*** Age at Hire- Current Membership ***//
gen ageathire_curr=age - ((svy3ageatdate-membegindate)/365.25)
label var ageathire_curr "Age at Hire- Current Membership"


keep individual_id yos* svc_overlap_2016 multimem ba_yos_2016_sum ba_yos_2016_adj contrib_* age* gender_code marital_status
save "${working}\YOS_actual_2016_$date", replace

gen female=gender_code=="F"

restore


*********************
** PERSON_FILE_NEW **
*********************
merge m:1 individual_id using "${raw}PERSON_FILE_NEW.dta", keepusing(individual_id deceased_ind)
keep if _merge==3
drop _merge



//** Hierarchy of classification: Other/disability, Retired, Terminated Retired, Terminated Active, Active **//

local actret "active termactive termretired defvested"
foreach x of local actret{
replace `x'=0 if retired==1
replace `x'=0 if `x'==.
}

replace termactive=0 if termretired==1 		//Individuals with termination date in Dec 2015 or later, classify as terminated retired//
replace active=0 if termactive==1 | termretired==1
replace retired=0 if otherdisab==1
replace termactive=0 if otherdisab==1
replace termretired=0 if otherdisab==1
replace active=0 if otherdisab==1
replace otherdisab=0 if otherdisab==.
replace retired=1 if individual_id=="P3013713" //No benefit account, membership status retired with no termination type code
replace retired=0 if retired==.
tablist active retired termactive termretired otherdisab

/*local deps "latest_lastcontribdate first_lastcontribdate latest_termdate latest_termyear latest_badate latest_bayear latest_membegindate firstmembegindate latest_membeginyr latest_memstatusdate latest_memstatusyr active activetslg retired otherdisab defvested multimem ts_or_lg_only termretired termactive tsers lgers yos_2016_curr contrib_yos_2016_curr yos_2016_sum yos_2016_adj ageatsvy_2016 ageathire_first yos_mem contrib_yos_mem"

foreach x of varlist `deps' {
bysort indi: egen mean_`x' =  mean(`x')

gen _pure_dup_`x' = (mean_`x' == `x')

bysort indi: egen pure_dup_`x' = mean(_pure_dup_`x')
replace pure_dup_`x' = 0 if pure_dup_`x' < 1
}

su pure*/

*duplicates drop indi, force
***********************
** MEMBERSHIP_DETAIL **
***********************
preserve
use "${raw}MEMBERSHIP_DETAIL.dta",clear
keep individual_id last_pay_date retirement_plan_code

//** Most Recent Last Pay Date **//

gen lpdate=date(last_pay_date, "MDY")
format lpdate %td
egen latest_lpdate=max(lpdate), by(individual_id)
format latest_lpdate %td
gen latest_lpyear=year(lpdate)
gen latest_lpmonth=month(lpdate)
lab var lpdate "last pay date (Detail File)"
label var latest_lpdate "Most recent last pay date"
label var latest_lpyear "Most recent last pay year"
label var latest_lpmonth "Most recent last pay month"
note latest_lpdate: generated from MEMBERSHIP_DETAIL
note latest_lpyear: generated from MEMBERSHIP_DETAIL
note latest_lpmonth: generated from MEMBERSHIP_DETAIL

/*
Return to Work (RTW)
Identify individuals who have more than one retirement account in TSERS/LGERS:
Individuals who had retired, returned to work, and retired again will have more than one benefit account.

LOCRS	LGERS retirees who has RTW at a LGERS employer in a position that does not require membership in LGERS and is subject to the earnable allowance.
STRS	TSERS retiree who has RTW at a TSERS employer in a position that does not require membership in TSERS and is subject to the earnable allowance
STRE	TSERS retiree who is working at a TSERS employer in a position that does not require membership in TSERS and is exempt from the earnable allowance. This includes teachers who returned to work before 10/2009 and nursing instructors.
*/

gen _rtwcode=1 if retirement_plan_code=="STRE" | retirement_plan_code=="STRS" | retirement_plan_code=="LOCRS" | retirement_plan_code=="LOCROD"
egen RTW=mean(_rtwcode), by(individual_id)
label var RTW "RTW code"
note RTW: generated from MEMBERSHIP_DETAIL

duplicates drop indi, force

tempfile lpdate
save `lpdate'

restore

merge m:1 individual_id using `lpdate', keepusing(retirement_plan_code latest_lpdate latest_lpyear latest_lpmonth)
keep if _merge==1 | _merge==3
drop _merge

*save "${working}Active Retired(Detailed)_$S_DATE", replace

*keep individual_id latest_lastcontribdate first_lastcontribdate latest_termdate latest_termyear latest_badate latest_bayear latest_membegindate firstmembegindate latest_membeginyr latest_memstatusdate latest_memstatusyr active retired otherdisab defvested termretired termactive _tslg multimem_tslg ts_or_lg_only multimem tsers lgers age gender_code marital_status 

save "${working}Active Retired (Admin)_$S_DATE", replace


preserve
**************************
** ACTIVES_WORK_HISTORY **
**************************
use "${raw}ACTIVES_WORK_HISTORY.dta", clear
keep if salary_year=="2015"

collapse (sum) total_salary, by(individual)
lab var total_salary "Salary (Admin)"
rename total_salary total_salary_admin

save "${working}salary_2015.dta", replace
restore

merge m:1 individual_id using "${working}salary_2015.dta"
drop _merge

merge m:1 individual_id using "${working}\YOS_actual_2016_$date"
drop _merge

save "${working}Active Retired (Admin)_$S_DATE", replace



//*** Eligibility ***///
gen years_service = yos_2016_adj  // is it yos_2016_curr or yos_2016_sum we are using		
gen contrib_years_service = contrib_yos_2016_adj

**** Calculate expected retirement age based on age and years of service ****
*** Objective retirement age ***


//***normal retirement ***///

gen yrsuntil30= 30-(years_service) if (mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="LGERS")
gen yrsuntil60and25yos= max((60- ageatsvy_2016),(25-(years_service))) if (mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="LGERS")
gen yrsuntil65and5yos=max((65- ageatsvy_2016),(5-contrib_years_service)) if (mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="LGERS")
gen yrsuntil55and5yos=max((55- ageatsvy_2016),(5-(years_service))) if (mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="LGERS")


gen objretyrs=min(yrsuntil30, yrsuntil60and25yos, yrsuntil65and5yos)
replace objretyrs=min(objretyrs, yrsuntil55and5yos) if last_plan_code=="STL" | last_plan_code=="LOCL" //Law enforcement officers refer LGERS LEO handbook//
gen normal_objretage=ageatsvy_2016 + objretyrs
replace normal_objretage=normal_objretage-3/12 // 3month window for fuzzy eligibility
gen eligible_normal=(objretyrs-(3/12))<=0
label var eligible_normal "Eligible for full benefit"


//*** early retirement ***///
gen yrsuntil50and20yos=max((50- ageatsvy_2016),(20-years_service)) if (mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="LGERS")
gen yrsuntil60and5yos=max((60- ageatsvy_2016),(5-contrib_years_service)) if (mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="LGERS")
gen yrsuntil50and15yos=max((50- ageatsvy_2016),(15-(years_service))) if (mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="LGERS")
gen early_yrsuntil55and5yos=max((55- ageatsvy_2016),(5-(years_service))) if (mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="LGERS")

gen early_objretyrs=min(yrsuntil50and20yos, yrsuntil60and5yos)
replace early_objretyrs=min(early_objretyrs, yrsuntil50and15yos) if last_plan_code=="STL" | last_plan_code=="LOCL" 
replace early_objretyrs=min(early_objretyrs, early_yrsuntil55and5yos) if last_plan_code=="LOCF" | last_plan_code=="RESG" 

gen early_objretage=ageatsvy_2016 + early_objretyrs
replace early_objretage=early_objretage-3/12 // 3month window for fuzzy eligibility

gen eligible_early=(early_objretyrs-(3/12))<=0

gen eligibleyrs=min(objretyrs,early_objretyrs)
gen eligible_ret=(eligibleyrs-(3/12)<=0)
label var eligible_ret "Eligible for reduced benefit"


gen retyrs_positive=eligibleyrs
replace retyrs_positive=0 if (eligibleyrs-(3/12))<0	
	
	
	gen s3tos5_years=(mdy(12,01,2017)-mdy(05,10,2016))/365.25
	gen ageatsurvey5=int(ageatsvy_2016) + int(s3tos5_years)
	gen yos=int(yos_2016_adj) + int(s3tos5_years) //replace yos_adj_2016 instead of imputed_yos_2016
	replace age=(ageatsurvey5)


	gen early_eligible_s5=ageatsurvey5>=int(early_objretage)  //changed this to int//
	gen normal_eligible_s5= ageatsurvey5>=int(normal_objretage) //changed this to int//
	replace early_eligible_s5=1 if normal_eligible_s5==1 & early_eligible_s5==0

	
//*** 	Years since eligibility  ***//
	
gen yearssinceelig=normal_eligible_s5*(age-normal_objretage)
label var yearssinceelig "Years since eligibility"


save "${working}Active Retired_Eligibility (Admin)_$S_DATE", replace



***** Data Restriction *******

gsort indi -membership_total_service
duplicates drop indi,force	



*** This is the dataset Siyan put into dropbox, I'm not sure of the source file
	merge 1:1 individual_id using "${raw}s5_population_lastcontrib_13.dta"
	keep if _merge==3
	drop _merge


*** Drop individuals with discrepancies in last contribution date between S3 and S5 admin data
	gen contribmth=mofd(s5_lastcontribdate)
	format contribmth %tm

	drop if contribmth==.
	drop if contribmth<ym(2016, 4)


	replace total_salary=total_salary/10000
	gen totalsalary2=total_salary^2
	
	label var totalsalary2 "Total salary (2015) ^2"
	*label var female "Female"


//*** Terminated - not working after Dec 2017 ***//
	gen terminated=s5_lastcontribdate<mdy(12,01,2017)
	tab terminated
		*rename terminated ret
		
		
//*** Actively working in Dec 2017 ***//
	gen not_ret=1-terminated //gen not_ret=1-ret
	label var not_ret "Actively working in Dec 2017"
	

*** Merge job classificatopns from S1 admin data (S3 job classification data incomplete)
	merge 1:1 individual_id using "${working}job_classification_$S_DATE", keepusing(individual job_classification agency_classification) 
	keep if _merge==3
	drop _merge



	
	save "${working}HR_admin_$date.dta", replace
	
	
****************************
** Data restriction
****************************
*use "${working}HR_admin_$date.dta",clear


*** Keep TSERS or LGERS memberships only
	keep if mem_retirement_system_code=="LGERS" | mem_retirement_system_code=="TSERS" 
	codebook indiv

*** Drop law enforcement, firefighters
	drop if  last_plan_code=="STL" | last_plan_code=="LOCL" | last_plan_code=="LOCF" | last_plan_code=="RESG"
	codebook indiv

	
*** Drop if retired prior to S3 date
	gen benefitdate_2016=date(ba_effective_date, "MDY")
	format benefitdate %td
	count if benefitdate<mdy(05,10,2016)

	gen _prev=benefitdate<mdy(05,10,2016)
	bysort individual_id: egen prev_ret=max(_prev)
	drop if prev_ret==1
	drop _prev
	codebook indiv


*** Drop individuals with both TSERS and LGERS memberships
*	bysort individual_id: egen tsers=max(mem_retirement_system_code=="TSERS")
*	bysort individual_id: egen lgers=max(mem_retirement_system_code=="LGERS")
	count if tsers==1 & lgers==1
	drop if tsers==1 & lgers==1
	codebook indiv

*** Age and Yos restrictions
	count
	keep if ageatsvy_2016>=50
	count
	keep if ageatsvy_2016<=65
	count
	drop if yos_2016_adj<5	
	
	save "${working}HR_admin_$date.dta", replace	
	
log close _all



	
/* *For this paper, the sample is restricted to active workers who were between ages 50 and 64 as of April 2016 and who were members of TSERS or LGERS, but not both. In addition, we exclude individuals who were hired prior to age 22 and who had less than 5 years of service in April 2016. To create our final analysis sample, we merge the administrative records with responses to a survey of active employees fielded in April 2016. /

To create the initial dataset, RSD provided administrative data covering local and state government workers who contributed (or had a contribution made by their employer on their behalf) to TSERS or LGERS for a pay period ending on or after 12/1/2013.   Additionally, workers had to be aged 50 to 85 (we further restricted the sample to be younger than age 70), first hired before 3/4/2014, not retired from TSERS or LGERS as of March 2014, and not on long-term disability at any point prior to 2/2/2014.
•	Restrictions on person file: 
The file contains information about all individuals who made a contribution (or had a contribution made by their employer on their behalf) for a pay period ending on or after 12/1/2013 who also meet the following criteria: 
 	1.  Age >=50 and <86
	2. Were first hired before 3/4/2014. 
	3.  Have not retired from TSERS or LGERS, or gone out on long-term disability at any point prior to 2/2/2014.  
A) Individuals who have retired from another system are not excluded
B) Individuals who received a refund from TSERS or LGERS are not excluded





1.	Use Membership_All_Info file. Keep observations with active or retired membership status codes.
2.	Create an indicator for active membership with retirement systems other than TSERS and LGERS. For this, the individual must have an active membership with a null termination code and last contribution date in Nov or Dec 2015 or last contribution date is missing.
3.	After creating an indicator for other retirement system codes, keep observations with retirement system code TSERS or LGERS.
4.	Define retired as actively claiming a regular benefit. (benefit_account_type_code=="EARLY"| benefit_account_type_code=="SVC") & ba_status_code=="ACTV"
5.	Define two types of active employees- contributing and non-contributing. Those not contributing have a missing last contribution date, missing membership contributory service, but have an active membership with null/blank benefit status code.
6.	For each individual_id, create an indicator for TSERS, LGERS or both.
7.	Individuals who are classified as active and retired by above definitions and also have most recent membership begin date in 2014 or after are classified as RTW.
active==1 & retired==1 & membeginyr>=2014 & membeginyr~=.
8.	Individuals who are return to work and additionally only have a membership in either TSERS or LGERS but not both, are classified as rehired retirees. 







log close _all
*======================================*


note matrial m=married, s=single/divorced/widowed,h=head of household, MAR=married, WID=widowed, u=unknown


