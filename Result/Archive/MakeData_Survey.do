clear
capture log close _all
set more off
pause on

cd "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs"

global date "$S_DATE"
log using "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs\Logs\MakeData_Survey_$date", replace text name("Ariel")
global raw "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\RawData\"
global working "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\WorkingData\"

****************************
** Data restriction
****************************
use "${working}HR_admin_$date.dta",clear


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

merge 1:1 pr_membership_id using "${raw}s3_actives_analysis.dta"

	****************************************************************************
	*** MSM variables code
	****************************************************************************
	keep if _merge==3
	drop if own_health_blank==1
	*drop age

	
//*** Good health ***//
	gen own_health_good=own_health>=3
	label var own_health_good "Good health"


	***** REDEFINE ELIGIBILITY ****
	*** Eligibility at Survey 5
	gen elig_early = early_eligible_s5 * (1-normal_eligible_s5)
	lab var elig_early "Eligible for reduced but not full benefits"

	gen elig_norm = normal_eligible_s5 
	lab var elig_norm "Eligible for full benefits"
	
	gen elig_norm_yrs = (ageatsurvey5 - normal_objretage + 0.75) * normal_eligible_s5
	tab elig_norm_yrs normal_eligible_s5
	tab elig_early elig_norm, row col cell

	gen elig_early_yrs = (ageatsurvey5 - early_objretage + 0.75) * elig_early
	tab elig_early_yrs elig_early


	gen elig_early_s3 = eligible_ret == 1 & eligible_normal == 0
	gen elig_norm_s3 = eligible_normal


	** Main eligibility classifications ***
	** Define newly eligible between s3 and s5
	
	gen elig_none = elig_early == 0 & elig_norm == 0
	gen elig_early_new = elig_early*(1-eligible_ret)
	gen elig_norm_new = elig_norm*(1-eligible_normal)

	tab elig_norm_yrs eligible_normal
	gen elig_passednormal = (elig_norm == 1 & eligible_normal == 1)
	gen elig_passednormxpoor = elig_passednormal*own_health_poor
	gen elig_passednormxgood = elig_passednormal*(1-own_health_poor)

	gen elig_passedearly = (elig_early == 1 & eligible_ret == 1)

	gen elig_status = 1*elig_early + 1*(elig_passedearly) + ///
	3*elig_norm + 1*(elig_passednormal)

	//tab elig_early_yrs elig_status
	//tab elig_norm_yrs elig_status

	tab elig_status
	tab elig_status not_ret, row col cell missing

	mean elig_*_s3 elig_early elig_norm elig_norm_yrs elig_passed*
	mean elig_norm_yrs if elig_passednormal == 1

	gen ageatbegin=int(ageatsvy_2016)
	label var ageatbegin "Age as of April 2016"
	
	gen yosatbegin=int(yos_2016_adj)
	label var yosatbegin "YOS as of April 2016"
	
	tab ageatbegin elig_early_s3
	tab yosatbegin elig_early_s3
	


	drop yearssinceelig
	gen yearssinceelig=normal_eligible_s5*(ageatsurvey5-normal_objretage)
	tab yearssinceelig eligible_normal
	
	gen new_normal_eligible_s5 = (normal_eligible_s5 == 1)*(eligible_normal == 0)
	gen past_normal_eligible_s5 = (normal_eligible_s5 == 1)*(eligible_normal == 1)


    gen yos2 = yosatbegin^2
		
	*************************************************
	**  MATCHING EXISTING RESULTS                ****
	*** Omitted categories: Age 53, public school
	sum not_ret own_health early_eligible_s5 normal_eligible_s5 own_health_poor own_health_good yosatbegin yos2 married female aclass1 aclass2 aclass3 aclass5 aclass6 total_salary totalsalary2 

	** try to match existing results
	
	*gen early_eligible_only = early_eligible_s5 * (1-normal_eligible_s5)
	*gen early_eligible_only=early_eligible_s5==1 & normal_eligible_s5==0

	
	*************************************************
	***** REDEFINE AGENCY CLASSES ***
	*aclass 1-6 :City, county, public school, general govt, DOT, other
	tab agency_classification, nolab
	gen atype_school = (agency_classification==3) 
	gen atype_stategovt = (tsers == 1 & atype_school==0)
	tab atype_stategovt tsers if atype_school == 0
	tab atype_school tsers if atype_stategovt == 0
	
		
	
	***************************************************************aclass 1-6 :City, county, public school, general govt, DOT, other



	**** HEALTH INTERACTIONS ***
	gen elig_earlyxpoor = elig_early*own_health_poor
	gen elig_earlyxgood = elig_early*(1-own_health_poor)
	gen elig_normxpoor = elig_norm*own_health_poor
	gen elig_normxgood = elig_norm*(1-own_health_poor)
	gen elig_norm_yrsxpoor = elig_norm_yrs*own_health_poor
	gen elig_norm_yrsxgood = elig_norm_yrs*(1-own_health_poor)
	gen elig_early_yrsxpoor = elig_early_yrs*own_health_poor
	gen elig_early_yrsxgood = elig_early_yrs*(1-own_health_poor)
	
	rename elig_earlyxpoor interact_early_poor
	rename elig_normxpoor interact_normal_poor
	rename elig_earlyxgood interact_early_good
	rename elig_normxgood interact_normal_good




	***MARRIED SHOULD BE MARRIED_PARTNER***
	gen singlexfemale = (1-married)*female
	gen marriedxmale = married*(1-female)
	gen marriedxfemale = married*female
	gen singlexmale = (1-married)*(1-female)

	tab married female, row col cell
	sum *male
	
	
	****************************************************************************
	*** HEALTH INSURANCE
	
	gen health_ins_important= (v27=="Need for health insurance provided to active workers") ///
	  | (v34=="Access to retiree health insurance")
	 gen marriedxsphlthpoor=married*spouse_health_poor
     label var marriedxsphlthpoor "Married*Poor spouse health"

	tab health_ins_important own_health_poor,m cell
	bysort married: tab health_ins_important own_health_poor,m cell
	bysort female: tab health_ins_important own_health_poor,m cell
	tab own_health_poor marriedxsphlthpoor, row col cell

	* own_health prevent working after retirement
	gen why_health = strpos(v47, "My") > 0
	gen why_sphealth = strpos(v51, "I") > 0 
	gen why_access = strpos(v57, "I") > 0 
	tab why_*health, missing
	tab why_access

	*** reasons could move in opposite directions***

	gen workafter = work_p == 3 | work_p == 4
	tab workafter

	* spouse's age
	gen sp_age = 2016 - spouse_birthdate_yr
	replace sp_age = 0 if married == 0 
	gen sp_age_gt64 = sp_age >= 64
	replace sp_age_gt64 = 0 if married == 0 

	* number of children already defined: nkids, nkids12 nkids34, nkidsmis (omitted none)

	gen worried_healthexpenses = strpos(v70, "Disagree") == 1 


	/* qualify for RHI: 3.7 Do	you	expect	to	qualify	for	any	retiree	health	benefits	not	including	Medicare?
	o Yes,	I	expect	to	qualify	for	retiree	health	benefits	through	my	current	employer.	
	o Yes,	I	expect	to	qualify	for	retiree	health	benefits	through	my	spouse/partner’s	employer.
	o Yes,	I	expect	to	qualify	for	retiree	health	benefits	through	a	previous	employer.
	o Yes,	I	expect	to	qualify	for	retiree	health	benefits	through	other	means.
	o No,	I	do	not	expect	to	qualify	for	retiree	health	benefits.
	o I	don’t	know whether	I	will	qualify	for	retiree	health	benefits
	*/
	tab v136
	gen rhi_curr = strpos(v136, "current") > 0
	gen rhi_prv = strpos(v136, "previous") > 0
	gen rhi_sp = strpos(v136, "spouse") > 0
	gen rhi_miss = v136 == "-99" 
	gen rhi_dk = strpos(v136, "I don't know") > 0 
	gen rhi_none = strpos(v136, "No,") > 0
	gen test = rhi_curr + rhi_prv + rhi_sp + rhi_dk + rhi_none + rhi_miss
	tab test
	drop test
	tab rhi_none lgers, row col cell
	tab rhi_none own_health_poor, row cell mis

	/*** spouse source of health insurance **/
	/* starts with v126
	Please	indicate	whether	your	spouse/partner	is	currently	
	covered	by	any	of	these	types	of	insurance	:
	v126 - life insurance
	LTI 
	Medicare
	v129 - own employer
	v130 - my employer
	v131 RHI previous
	v132 - RHI from my employer
	v133 RHI from my prev
	v134 Medicaid
	v135 other
	***/
	gen rhi_spcurr = (v130 == "Yes"  | v132 == "Yes" )
	tab rhi_spcurr lgers, row col cell

	*** SPOUSE EMPLOYER HEALTH INSURNACE

	gen sp_resp_ehi = v130 == "Yes"

	gen sp_hashi = (v129 == "Yes" | v130 == "Yes" | v131 == "Yes" | v132 == "Yes" | v133 == "Yes" | v134 == "Yes" | v135 == "Yes")
	tab sp_hashi lgers, row col cell
	 
	gen interact_early_ehi = elig_early*sp_resp_ehi
	gen interact_norm_ehi = elig_norm*sp_resp_ehi
	gen interact_early_notehi = elig_early*(1-sp_resp_ehi)
	gen interact_norm_notehi = elig_norm*(1-sp_resp_ehi)



	**** LIFE EXPECTANCY ***
	gen low_life_expect = (own_life_expectancy == 1 | own_life_expectancy == 2 | own_life_expectancy == 6 | own_life_expectancy == 7)
	tab low_life own_life_e

	gen interact_early_low_le = low_life_expect*elig_early
	gen interact_norm_low_le = low_life_expect*elig_norm

	gen interact_early_high_le = (1-low_life_expect)*elig_early
	gen interact_norm_high_le = (1-low_life_expect)*elig_norm



	**** health insurance important****
	gen interact_early_import = health_ins_import*elig_early
	gen interact_norm_import = health_ins_import*elig_norm

	gen interact_early_notimport = (1-health_ins_import)*elig_early
	gen interact_norm_notimport = (1-health_ins_import)*elig_norm

	** WORRIED
	tab v70, missing
	gen worried = (1-(strpos(v70,"Agree")== 1))
	
	** hh_main_earner
	gen primary_earner = (hh_main_earner== 3 | hh_main_earner == 4)
	tab hh_main_earner primary_earner

	/** Importance of Health Insurance
	gen elig_earlyxhealth_ins_import=elig_early*(health_ins_important==1)
	gen elig_earlyxhealth_ins_notimport=elig_early*(health_ins_important==0)
	gen elig_normxhealth_ins_import=elig_norm*(health_ins_important==1)
	gen elig_normxhealth_ins_notimport=elig_norm*(health_ins_important==0)
	gen elig_norm_yrsxhealth_ins_import=elig_norm_yrs*(health_ins_important==1)
	gen elig_norm_yrsxhealth_ins_not=elig_norm_yrs*(health_ins_important==0)
	*/
	drop eligible_normal worried_healthexpenses

	save "${working}MakeData_Survey.dta", replace
	
	log close _all
