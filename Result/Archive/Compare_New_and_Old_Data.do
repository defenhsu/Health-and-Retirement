clear
capture log close _all
set more off

cd "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs"
global date "$S_DATE"
log using "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs\Logs\MakeData_Admin3_Survey3_$date", replace text name("Ariel")
global raw "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\RawData\"
global working "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\WorkingData\"
********************************************************************************************
/*This file aim to figure out why there's mismatch between new dataset and original dataset*/
********************************************************************************************

use "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\WorkingData\HealthRet_workingdata_July2021_NOIMP",clear // import original dataset
drop _merge 
 
merge 1:1 individual_id using "${working}Admin3_Survey3.dta", keepusing(indi) // merge with new dataset
**********************************************************************************************
keep if _merge ==1   //first keep individuals who only exist in original dataset  
drop _merge 

keep indi
unique indi

file open tbl using "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\RA\output\compare_result.tex", write replace
file write tbl "There are "(r(unique)) " unique individuals who exist only in original dataset" _n
local remain =r(unique)

merge 1:m individual_id using "${raw}ACTIVES_ALL_MEMBERSHIP_INFO.dta"
gen flag_original = (_merge==3) // flag those who exist only in original dataset, and find out who was dropped and when they are dropped
drop _merge 

unique indi if flag==1

merge m:1 individual_id using "${raw}ACTIVES_PERSON_INFO.dta", keepusing(age gender_code) // 04.06.2016 version
keep if _merge==1 |_merge==3 
drop _merge

unique indi if flag==1

merge m:1 individual_id using "${raw}PERSON_FILE_NEW.dta", keepusing(deceased_ind) // use deceased_ind only. not sure what's new about this new file
keep if _merge==1 |_merge==3 
drop _merge

unique indi if flag==1 

******
// Run MakeData_Admin3_Actives.do first, and find out when the mismatch data is dropped

*** Drop individuals retired as of April 2016 (restrition in MakeData_Admin3_Actives)

	gen admin3_benefitdate=date(ba_effective_date, "MDY")  // benefit claim date
	format admin3_benefitdate %td
	
	gen _retired=(admin3_benefitdate<mdy(04,06,2016))

	replace _retired = 1 if (benefit_account_type_code=="EARLY"|benefit_account_type_code=="SVC") & ba_status_code=="ACTV"
	
	egen admin3_status_retired=max(_retired), by(individual_id) // =1 if retired as of April 2016 
	
	replace admin3_status_retired=1 if individual_id=="P3013713" // P3013713 has no benefit account, membership status retired with no termination type code
	
	drop if admin3_status_retired == 1 
	
	unique indi if flag==1
	
file write tbl "There are "(`remain'-r(unique)) " unique individuals was dropped when I drop individuals retired as of April 2016 in MakeData_Admin3_Actives.do." _n
local remain =r(unique)


*** Keep active workers with Active Membership 

	/*Actives: 
	--Active membership status code*/

	keep if membership_status_code=="ACTV" 	
	
	unique indi if flag==1

	
*** Keep TSERS or LGERS

	bysort individual_id: egen admin3_tsers=max(mem_retirement_system_code=="TSERS"|mem_retirement_system_code=="ORP")
	bysort individual_id: egen admin3_lgers=max(mem_retirement_system_code=="LGERS"|mem_retirement_system_code=="RDSPF")
	
	keep if mem_retirement_system_code=="TSERS"|mem_retirement_system_code=="ORP" | mem_retirement_system_code=="LGERS"|mem_retirement_system_code=="RDSPF"

	unique indi if flag==1
	
	*drop if admin3_tsers==1 & admin3_lgers==1 // we delete the restriction "drop people with both TSERS or LGERS" in June 2022, please refer to notes for details

	
*** Drop law enforcement, firefighters

	drop if  last_plan_code=="STL" | last_plan_code=="LOCL" | last_plan_code=="LOCF" | last_plan_code=="RESG"

	unique indi if flag==1

*** Keep workers aged 50 to 70

	keep if inrange(age,50,70)
	
	unique indi if flag==1
	
*** Drop indi. claiming disability or other benefit types (non-regular)

	gen _other=(benefit_account_type_code=="OTHER" ) 
	
	egen admin3_status_other=max(_other), by(individual_id)
	
	drop if admin3_status_other == 1	
	
	unique indi if flag==1

*** Drop data with unidentified gender

	drop if gender_code=="U"	
	
	unique indi if flag==1
	
	
*** Drop individuals deceased as of April 2016

	destring deceased_ind, replace
	drop if deceased_ind==1
	
	unique indi if flag==1

*** Drop individuals/ memberships with missing contribution dates

    gen admin3_lastcontribdate=date(last_contrib_date, "MDY")
	format admin3_lastcontribdate %td

	drop if admin3_lastcontribdate ==.	
	
	unique indi if flag==1
	
	
*** Keep individuals first hired before 3/4/2014

	gen admin3_membegindate=date(membership_begin_date, "MDY")
	format admin3_membegindate %td	
	
	bysort indi: egen admin3_first_hire_date = min(admin3_membegindate) 
	
	keep if admin3_first_hire_date <= mdy(03,04,2014)	
	
	unique indi if flag==1

	
*** Drop individuals with last contribution year before 2014 in April 2016 data	
 
	gen admin3_lastcontribyear=year(admin3_lastcontribdate)
	 
	bysort indi: egen admin3_latest_lastcontribyear = max(admin3_lastcontribyear)

	drop if admin3_latest_lastcontribyear<2014
	
	unique indi if flag==1
	
file write tbl "There are "(`remain'-r(unique)) " unique individuals was dropped when I drop individuals with last contribution year before 2014 in April 2016 data" _n
local remain =r(unique)

*file close tbl
	

/*** Drop individuals with last contribution year before 2014 in April 2016 data	
 
	gen admin3_lastcontribyear=year(admin3_lastcontribdate)
	 
	bysort indi: egen admin3_latest_lastcontribyear = max(admin3_lastcontribyear)

	drop if admin3_latest_lastcontribyear<2014

	unique indi if flag==1 //dropped 8
	
file write tbl "There are "(`remain'-r(unique)) " unique individuals was dropped when I drop individuals with last contribution year before 2014 in April 2016 data in MakeData_Admin3_Actives.do." _n
file write tbl "" _n	


merge m:1 individual_id using "${working}Admin3_YOS", nonotes // generated by Makedata_Admin3_YOS, using 04.06.2016 pre-survey3 admin data
keep if _merge==3
drop _merge

gen admin3_age_at_svy3 = age + ((mdy(05,10,2016)-mdy(03,23,2016))/365.25) // age information are recorded as of 3.23.2016 in admin data. Please refer to notes for detail
lab var admin3_age_at_svy3 "Age as of Survey 3" // First day of fielding survey 3  : 05/10/2016

gen admin3_age_at_svy5 = age + ((mdy(12,01,2017)-mdy(03,23,2016))/365.25)
lab var admin3_age_at_svy5 "Age as of Survey 5" // Survey 5 : 12/01/2016


gen admin3_yos_at_svy3 = admin3_yos_sum_adj + ((mdy(05,10,2016)-mdy(12,31,2015))/365.25) // yos are recorded at the end of 2015 in admin data.
lab var admin3_yos_at_svy3 "YOS as of Survey 3" 

gen admin3_yos_at_svy5 = admin3_yos_sum_adj + ((mdy(12,01,2017)-mdy(12,31,2015))/365.25) 
lab var admin3_yos_at_svy5 "YOS as of Survey 5"

	keep if inrange(admin3_age_at_svy3,52,65) //keep if inrange(admin3_age_at_svy3,52,64)

	drop if admin3_yos_at_svy3 < 5 

exit*/
************************************************************************************************

use "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\WorkingData\HealthRet_workingdata_July2021_NOIMP",clear
drop _merge 
 
merge 1:1 individual_id using "${working}Admin3_Survey3.dta", keepusing(indi)

keep if _merge ==2 //now keep individuals who only exist in new dataset
drop _merge
keep indi 

unique indi 

file write tbl "There are "(r(unique)) " unique individuals who exist only in new dataset" _n
local remain =r(unique)


merge 1:m individual_id using "${raw}ACTIVES_ALL_MEMBERSHIP_INFO.dta"
gen flag_new = (_merge==3) // flag those who exist only in new dataset, and find out who was dropped and when they are dropped
drop _merge 

unique indi if flag==1


*** Correct membership system ifnormation ***
	replace mem_retirement_system_code="LGERS" if mem_retirement_system_code=="RDSPF"
	replace mem_retirement_system_code="TSERS" if mem_retirement_system_code=="ORP"

	gen membegindate=date(membership_begin_date, "YMD###")
	format membegindate %td

	gen memstatusdate=date(membership_status_date, "YMD###")
	format memstatusdate %td

*** Indicator for multiple memberships
	duplicates tag individual_id, gen(tag)
	gen multimem_2016=tag>=1
	drop tag
	codebook indiv

*** Drop closed, closed retired, and inactive memberships
	drop if membership_status_code~="ACTV" //& membership_status_code~="CLOSRET"
	codebook indiv
	duplicates tag individual_id, gen(tag)
	tab tag  // check duplicate individuals
	drop tag

*** Merge with person file to add age and gender information
	merge m:1 individual_id using "${raw}ACTIVES_PERSON_INFO.dta", keepusing(gender_code age)
	label var age "Age as of admin date (March 23, 2016)"
	keep if _merge==1 |_merge==3 
	drop _merge	
	
	unique indi if flag==1
	


*** Calculate age as of S3 data
	gen ageatsvy_2016=age + ((mdy(05,10,2016)-mdy(03,23,2016))/365.25)
	label var ageatsvy "Age as of survey date (May 10,2016)"

*** merge with active or retired classifcations
*** Stata code file: S3_Prep_Active_Retired_AP
	merge m:1 individual_id using  "${working}Active Retired.dta", keepusing(active retired termactive termretired otherdisab)
	keep if _merge==1 | _merge==3
	drop _merge	
	
	unique indi if flag==1
	

*** Keep TSERS or LGERS memberships only
	keep if mem_retirement_system_code=="LGERS" | mem_retirement_system_code=="TSERS" 
	
	unique indi if flag==1
	
	codebook indiv

*** Drop law enforcement, firefighters
	drop if  last_plan_code=="STL" | last_plan_code=="LOCL" | last_plan_code=="LOCF" | last_plan_code=="RESG"
	codebook indiv

	unique indi if flag==1 //***************
	
file write tbl "There are "(`remain'-r(unique)) " unique individuals was dropped when original code drop law enforcement, firefighters in 1.HR_makedata_admin_survey.do." _n
local remain =r(unique)
	

*** Drop if retired prior to S3 date
	gen benefitdate_2016=date(ba_effective_date, "MDY")
	format benefitdate %td
	count if benefitdate<mdy(05,10,2016)

	gen _prev=benefitdate<mdy(05,10,2016)
	bysort individual_id: egen prev_ret=max(_prev)
	drop if prev_ret==1
	
	unique indi if flag==1
	
	drop _prev
	codebook indiv


*** Drop individuals with both TSERS and LGERS memberships
	bysort individual_id: egen tsers=max(mem_retirement_system_code=="TSERS")
	bysort individual_id: egen lgers=max(mem_retirement_system_code=="LGERS")
	count if tsers==1 & lgers==1
	drop if tsers==1 & lgers==1
	
	unique indi if flag==1
	
	codebook indiv

*** Indicator for individuals who had a break in service between 2 memberships
	sort indiv membership_status_code
	by individual_id: gen laterbegin=membegindate[_n-1]
	format laterbegin %td

	gen diff_dates=(laterbegin-memstatusdate)/30
	count if abs(diff_dates)<3
	count if diff_dates>0 & diff_dates<3

	gen _break=diff_dates>=3 & laterbegin~=.
	by individual: egen brk_svc=max(_break)
	drop _break

*** Age at first hire, calculated based on earliest membership begin date
	by individual_id: egen lastmembegindate=max(membegindate)
	by individual_id: egen firstmembegindate=min(membegindate)
	format firstmembegindate %td

	gen ageatdate=age
	gen ageathire_first_adj=age -((ageatdate-firstmembegindate)/365.25)
	label var ageathire_first_adj "Age at hire- first membership(adjusted)"

*** Drop duplicates
	sort indiv membership_status_code
	egen tag=tag(individual)
	tab tag 
	keep if tag==1 
	drop tag
	
	unique indi if flag==1
	
	
*** Merge YOS (imputed)
	merge 1:1 indiv using "${working}YOS_imputed_2016.dta"  // since imputed YOS is not defined in this file, so original data for some inividual was deletd, but still exist in my data
	keep if _merge==3
	drop _merge
	
	unique indi if flag==1
	
file write tbl "There are "(`remain'-r(unique)) " unique individuals was dropped when original code merge imputed YOS and drop unmatched data in 1.HR_makedata_admin_survey.do." _n
local remain =r(unique)
	

*** Merge YOS (actual)

	merge 1:1 individual_id using "${working}YOS_actual_2016.dta"
	keep if _merge==3
	
	unique indi if flag==1
	
	drop _merge
	
*** Merge last contribtion date from updated S5 admin release
*** This is the dataset Siyan put into dropbox, I'm not sure of the source file
	merge 1:1 individual_id using "${raw}s5_population_lastcontrib_13.dta"
	keep if _merge==3
	
	unique indi if flag==1
	
	drop _merge

*** Merge job classificatopns from S1 admin data (S3 job classification data incomplete)
	merge 1:1 individual_id using "${working}s1_job_classification.dta", keepusing(individual job_classification agency_classification) 
	keep if _merge==3
	
	unique indi if flag==1
	
	drop _merge
	
	merge 1:1 individual_id using "${working}s3_job_classification.dta", keepusing(agency_classification)
	keep if _merge==3
	
	unique indi if flag==1
	
	drop _merge

*** Merge salary data S3 admin data
	merge 1:1 indiv using "${working}salary_2015.dta"
	keep if _merge==3
	
	unique indi if flag==1
	
	drop _merge

*** Drop individuals with discrepancies in last contribution date between S3 and S5 admin data
	gen contribmth=mofd(s5_lastcontribdate)
	format contribmth %tm

	drop if contribmth==.
	drop if contribmth<ym(2016, 4)
	
	unique indi if flag==1


	gen terminated=s5_lastcontribdate<mdy(12,01,2017)
	tab terminated
	
	rename terminated ret
	gen not_ret=1-ret
	label var not_ret "Actively working in Dec 2017"
	

/*** Calculate financial incentive 1 (eligibility) 
*** NO IMPUTED YOS
	drop age
	gen age=int(ageatsvy_2016)
	gen yos=int(yos_2016_adj)   //(imputed_yos_2016)

	include "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\HR_MakeData\0_6.Eligibility.do  "
	renvars eligible_early eligible_normal\ early_eligible_s3 normal_eligible_s3
	drop age yos-normal_objretage yrsuntil50and20yos-early_objretage eligibleyrs-retyrs_positive 

	gen s3tos5_years=(mdy(12,01,2017)-mdy(05,10,2016))/365.25
	gen ageatsurvey5=int(ageatsvy_2016) + int(s3tos5_years)
	gen yos=int(yos_2016_adj) + int(s3tos5_years) //replace yos_adj_2016 instead of imputed_yos_2016
	gen age=(ageatsurvey5)


	include "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\HR_MakeData\0_6.Eligibility.do  "
	drop eligible_early eligible_normal
	gen early_eligible_s5=ageatsurvey5>=int(early_objretage)  //changed this to int//
	gen normal_eligible_s5= ageatsurvey5>=int(normal_objretage) //changed this to int//
	
	
	
	merge 1:1 individual_id age yos using "${working}NPV.dta"
	keep if _merge==3
	
	unique indi if flag==1
	drop _merge


	qui destring npv*, replace ignore("*")
	gen NPVcurrentage=.
	forvalues i=50/100{
	replace NPVcurrentage=npv`i' if age==`i'
	}

	egen peakvalue=rowmax(npv50-npv100)  //This occurs at normal eligibility//
	gen postnormal=0

	forvalues i=50/99 {
	local j=`i'+1
	replace postnormal=npv`j' if int(normal_objretage)==`i'
	replace postnormal=npv`j' if age==`i' & postnormal==. & normal_eligible_s5==1
	}


	replace peakvalue=postnormal if normal_eligible_s5==1 //For those past normal eligibility, keep PDV of working another year//
	drop npv*

	merge 1:1 individual_id age yos using "${working}NPV_terminated.dta", keepusing(indiv npv60)
	keep if _merge==3
	drop _merge

	qui destring npv60, replace ignore("*")
	replace NPVcurrent=npv60 if early_eligible_s5==0
	sum peakvalue

	gen peakdiff=peakvalue-NPVcurrent
	sum peakdiff
	sum peakdiff, det

	//replace peakdiff=r(p95) if peakdiff>=r(p95)  //Top code 5% peakdiff 
	replace peakdiff=peakdiff/10000
	label var peakdiff "Peak value incentive(0000's)"
	gen peakdiffa = peakdiff*10000*/
	
*** Age and Yos restrictions
	count
	keep if ageatsvy_2016>=50
	
	unique indi if flag==1 //**************
	
	
	keep if ageatsvy_2016<=65
	count
	
	unique indi if flag==1
	
	drop if yos_2016_adj<5
	count
unique indi if flag==1

	
*** merge with survey variables

	merge 1:1 pr_membership_id using "${raw}s3_actives_analysis.dta"
	keep if _merge ==3

unique indi if flag==1
	
file write tbl "There are "(`remain'-r(unique)) " unique individuals was dropped when original code merge with s3_actives_analysis.dt and only keep matched data in 1.HR_makedata_admin_survey.do." _n
local remain =r(unique)


	drop if own_health_blank==1
	
		unique indi if flag==1

file write tbl "There are "(`remain'-r(unique)) " unique individuals was dropped when original code drop people who didn't respond the own health question." _n
local remain =r(unique)
	
	unique pr_ if flag==1
	drop if S3educ==9
	unique pr_ if flag==1
	
	drop if own_health==0
	unique pr_ if flag==1
	
	drop if (_expected_claim_ben_date==.) & expected_claim_ben_date~="Don't know"
	unique pr_ if flag==1 //***
file write tbl "There are "(`remain'-r(unique)) " unique individuals was dropped when original code drop people who don't know their expected_claim_ben_date." 
local remain =r(unique)
	
	drop if (S3marital==1 | S3marital==2) & spouse_health_blank==1 
	unique pr_ if flag==1
	

file close tbl
exit
	// it just have something to do with the restriction in analysis file
	
************************************************************
** Compare Eligibility

use "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\WorkingData\HealthRet_workingdata_July2021_NOIMP",clear // import original dataset
drop _merge 
 
merge 1:1 individual_id using "${working}Admin3_Survey3.dta"
keep if _merge ==3

/*keep indi admin3_eligible_normal_at_svy3 admin3_eligible_normal_at_svy5 admin3_eligible_early_at_svy3 admin3_eligible_early_at_svy5 ///
elig_early_s3 elig_norm_s3 elig_early elig_norm ///
admin5_status_not_ret not_ret admin3_age_at_svy3 admin3_age_at_svy5 admin3_yos_at_svy3 admin3_yos_at_svy5*/

compare admin3_eligible_early_at_svy3 elig_early_s3
compare admin3_eligible_early_at_svy5 elig_early
compare admin3_eligible_normal_at_svy3 elig_norm_s3
compare admin3_eligible_normal_at_svy5 elig_norm
compare admin5_status_not_ret not_ret


su ageatsvy_2016 admin3_age_at_svy3 //entirely the same 
su yos_2016_adj admin3_yos_at_svy3 //entirely the same 
su yos admin3_yos_at_svy5 
su ageatsurvey5 admin3_age_at_svy5 


gen admin3_age_at_svy5_int = int(admin3_age_at_svy3) + int((mdy(12,01,2017)-mdy(05,10,2016))/365.25)
gen admin3_yos_at_svy5_int = int(admin3_yos_at_svy3)+ int((mdy(12,01,2017)-mdy(05,10,2016))/365.25) //==> might only keep svy5 eventually

su yos admin3_yos_at_svy5_int 
su ageatsurvey5 admin3_age_at_svy5_int 

gen diff_int_age = admin3_age_at_svy5_int-admin3_age_at_svy5
gen diff_int_yos = admin3_yos_at_svy5_int-admin3_yos_at_svy5

su diff_int*


**************************************
*** Eligible for Normal Retirement 
**************************************

foreach x in   svy5 { 

di "`x'"

gen yos_over30_at`x' = (30 <= (admin3_yos_at_`x'_int + 1)) // 3month window for fuzzy eligibility

gen yos_over25_age_60_at`x' =  (25 <= (admin3_yos_at_`x'_int + 1)) & (admin3_age_at_`x'_int+1) >=60

gen yos_over5_age_65_at`x' = (5 <= (admin3_yos_at_`x'_int + 1)) & (admin3_age_at_`x'_int+1) >=65 

gen admin3_elig_normal_at_`x'_int = max(yos_over30_at`x', yos_over25_age_60_at`x', yos_over5_age_65_at`x')

}



drop yos_over30_at* yos_over25_age_60_at* yos_over5_age_65_at* 


**************************************
*** Eligible for Early Retirement 
**************************************

foreach x in   svy5 { 

di "`x'"

gen yos_over20_age_50_at`x' =  (20 <= (admin3_yos_at_`x'_int + 1)) & (admin3_age_at_`x'_int+1) >=50

gen yos_over5_age_60_at`x' = (5 <= (admin3_yos_at_`x'_int + 1)) & (admin3_age_at_`x'_int+1) >=60 

gen admin3_elig_early_at_`x'_int = max(yos_over20_age_50_at`x', yos_over5_age_60_at`x')

}


drop yos_over20_age_50_at* yos_over5_age_60_at* 

replace admin3_elig_early_at_svy5_int=0 if admin3_elig_normal_at_svy5_int ==1 & admin3_elig_early_at_svy5_int==1

compare admin3_elig_early_at_svy5_int elig_early
compare admin3_elig_normal_at_svy5_int elig_norm

*list yos admin3_yos_at_svy5_int ageatsurvey5 admin3_age_at_svy5_int admin3_elig_early_at_svy5_int elig_early admin3_elig_normal_at_svy5_int elig_norm admin3_eligible_early_at_svy5 admin3_eligible_normal_at_svy5 if admin3_elig_early_at_svy5_int~=elig_early



/*************************
//============== compare YOS from 2 dataset
use "${working}Admin3_Eligibility_Svy3_Svy5", clear


merge m:1 individual_id using "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\WorkingData\YOS_actual_2016" 
keep if _merge==3 // YOS_actual_2016 has more observation since in my file I only keep state government membership
drop _merge


compare admin3_yos_at_svy3 yos_2016_adj


/*list indi admin3_yos_at_svy3 yos_2016_adj if admin3_yos_at_svy3~=yos_2016_adj

        +--------------------------------+
        | indivi~d   admin3..   yos_20~j |
        |--------------------------------|
113632. |  P547501   22.27526   31.77526 |
130851. |  P777534   11.02536   17.35866 |
153344. |  P996720   31.85866   34.77536 |
        +--------------------------------+

	   
	   
list indi membership_total_service yos_2016_adj svc_overlap_2016 admin3_yos_sum_adj admin3_date_overlap admin3_multi_mem if indi == "P547501" | indi == "P777534" | indi == "P996720"

        +----------------------------------------------------------------------------+
        | indivi~d   m~tota~e   yos_20~j   svc~2016   admin3..   admin3~p   admin~em |
        |----------------------------------------------------------------------------|
117348. |  P547501        9.5   31.77526          0    21.9166          1          1 |
117349. |  P547501          .   31.77526          0    21.9166          1          1 |
117350. |  P547501    21.9166   31.77526          0    21.9166          1          1 |
135213. |  P777534          6   17.35866          0    10.6667          1          1 |
135214. |  P777534      .3333   17.35866          0    10.6667          1          1 |
        |----------------------------------------------------------------------------|
135215. |  P777534    10.6667   17.35866          0    10.6667          1          1 |
158547. |  P996720     2.9167   34.77536          0       31.5          1          1 |
158548. |  P996720          .   34.77536          0       31.5          1          1 |
158549. |  P996720       31.5   34.77536          0       31.5          1          1 |
        +----------------------------------------------------------------------------+*/


list indi admin3_yos admin3_yos_at_svy3 yos_2016_adj if indi == "P3446506"

---------------------------------------------------------




use "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\WorkingData\HealthRet_workingdata_July2021_NOIMP",clear
drop _merge 
 
merge 1:1 individual_id using "${working}Admin3_Survey3.dta", keepusing(indi)

keep if _merge ==1 
drop _merge
keep indi


	merge 1:1 individual_id using "${working}Admin3_Actives"
	gen flag = (_merge==3) 
	drop _merge
	
	unique indi if flag==1


	merge 1:1 individual_id using "${working}Admin3_Eligibility_Svy3_Svy5" // generated by Makedata_Admin3_Eligibility, using 04.06.2016 pre-survey3 admin data
	keep if _merge==3 // the only unmatched individual, P3051121, his membership is either withdrawed or with missing YOS==> drop it, only keep matched data  
	drop _merge
	unique indi if flag==1
	
	
*** Merge job and agency classification (S3 job classification data incomplete, so merge s1 and s3 job classification for more complete job classification) 

	merge 1:1 individual_id using "${working}Admin1_3_JobClassification" // generated by Makedata_Admin3_JobClassification, using pre-survey3 and pre-survey1 admin data
	keep if _merge==3
	drop _merge
	unique indi if flag==1

	
*** Merge salary data 

	merge 1:1 indiv using "${working}Admin3_salary.dta" // generated by Makedata_Admin3_Salary, using pre-survey3 admin data
	
	keep if _merge==3
	drop _merge
	unique indi if flag==1
	
	
*** Merge last contribtion date from updated S5 admin release(April 2018) 

	merge 1:1 individual_id using "${raw}s5_population_lastcontrib_13.dta", keepusing(s5_lastcontribdate) //This is the dataset Siyan put into dropbox, I'm not sure of the source file
	keep if _merge==3
	drop _merge
	unique indi if flag==1
	
	list indi if flag ==1
	
/*	   +----------+
       | indivi~d |
       |----------|
36299. | P3446506 |
       +----------+*/



	keep if inrange(admin3_age,52,65) //keep if inrange(admin3_age_at_svy3,52,65) yos defined differently??
	unique indi if flag==1 

	drop if admin3_yos < 5 //here lose last 1
	unique indi if flag==1
