/************************************************************************************************************************ 
This file creates Years of Service using Administrative Data release at 04.06.2016 ==> pre-survey 
************************************************************************************************************************/

include "Step0_SetDirectory"
log using "${log}MakeData_Admin3_YOS_$date", replace text name("Ariel")

*********************************************

use "${raw}ACTIVES_ALL_MEMBERSHIP_INFO.dta",clear //04.06.2016 version//  

/*Instead of using Admin3_Actives that I defined in MakeData_Admin3_Actives, I go back and use raw data to create YOS. Since Admin3_Actives keep only current membership, however, to define YOS, I need to sum over all the membership service from one individual.  */

*********************************************
*** Generating YOS for state administration retirement system
*********************************************

*** Keep state administration retirement system

	keep if mem_retirement_system_code=="LGERS" | mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="ORP" | mem_retirement_system_code=="RDSPF" | mem_retirement_system_code=="CJRS" | mem_retirement_system_code=="LRS"
	
	duplicates report indi membership_begin_date last_contrib_date	
	
		
*** Keep active and retired memberships

	keep if membership_status_code=="ACTV" | membership_status_code=="CLOSRET"
	
	duplicates report indi membership_begin_date last_contrib_date	
	
	duplicates  report indi
	
	
*** Identify people who has YOS containing membership service from other retirement systerm
	
	bysort individual_id: egen admin3_has_nonTSERSLGERS_mem = max(mem_retirement_system_code=="CJRS"|mem_retirement_system_code=="LRS") 
	
		
*** Generate YOS, all active memberships
	
	destring membership_total_service membership_contributory_service membership_other_servic, replace ignore("NULL")

	bysort individual_id: egen admin3_yos_sum=total(membership_total_service)
	
	bysort individual_id: egen admin3_yos_max=max(membership_total_service)
	
	bysort individual_id: egen admin3_contryos_sum=total(membership_contributory_service) // contributory service
	
	bysort individual_id: egen admin3_contryos_max=max(membership_contributory_service)

		
*** Adjusting total service for individuals who had overlapping dates between membership begin date and last contribustion date
*** ==> identify those who has first membership end date later than last membership begin date

	duplicates tag indi, gen(admin3_multi_mem)	// Identifies multiple memberships
	replace admin3_multi_mem=1 if admin3_multi_mem>0
	
	gen admin3_membegindate=date(membership_begin_date, "MDY")
	format admin3_membegindate %td	
	
	gen admin3_lastcontribdate=date(last_contrib_date, "MDY")
	format admin3_lastcontribdate %td
	
	*drop if admin3_lastcontribdate==. //count if admin3_lastcontribdate==. & membership_total_service<.
	
	bysort individual_id: egen admin3_last_membegindate=max(admin3_membegindate) // last membership begin date
	
	bysort individual_id: egen admin3_first_memenddate=min(admin3_lastcontribdate)	//first membership end date

	gen _overlap = (admin3_first_memenddate>admin3_last_membegindate) & (admin3_first_memenddate<. & admin3_last_membegindate<.) 
	replace _overlap = 0 if admin3_multi_mem==0
	
	tab _overlap admin3_multi_mem,m

	gen admin3_date_overlap= (admin3_multi_mem>0 & _overlap==1) // capture the suspicious duplicates who last membership begin date
	
	gen admin3_yos_sum_adj=admin3_yos_sum
	replace admin3_yos_sum_adj=admin3_yos_max if admin3_date_overlap==1 // use admin3_yos_max as YOS instead of admin3_yos_sum for duplicates 
	
	gen admin3_contryos_sum_adj=admin3_contryos_sum
	replace admin3_contryos_sum_adj=admin3_contryos_max if admin3_date_overlap==1 

	*duplicates re indi admin3_lastcontribdate	
	*duplicates re indi admin3_lastcontribdate admin3_yos_sum_adj // use admin3_yos_max as YOS instead of admin3_yos_sum for duplicates 
	
	
*** Define order of membership, and keep current membership
 
	gsort indi -admin3_lastcontribdate -admin3_membegindate
	by indi: gen admin3_mem_order = _n
	
	keep if admin3_mem_order ==1
	
	keep individual_id membership_total_service membership_contributory_service admin3*yos*   
			
	
*** Years of Service, Current Membership 

	gen admin3_yos_curr = membership_total_service
	label var admin3_yos_curr "Curr. YOS(Admin 3)"
	
	gen admin3_contryos_curr = membership_contributory_service
	label var admin3_contryos_curr "Curr. Contrib YOS (Admin3)"

*** keep YOS

	keep indi admin3*yos*
		
	label var admin3_yos_sum "YOS (Admin 3)" //as of 03.23.2016
	label var admin3_contryos_sum "Contri. YOS (Admin 3)" //as of 03.23.2016
	label var admin3_yos_sum_adj  "Adj. YOS (Admin 3)"	//as of 03.23.2016
	label var admin3_contryos_sum_adj  "Adj. Contri. YOS (Admin 3)" //as of 03.23.2016
	
	
*** Attaching notes to the data

note: This file generate YOS using administrative data release at 04.06.2016 ==> pre-survey 
note: Raw data used to creates this file: ACTIVES_ALL_MEMBERSHIP_INFO.dta(04.06.2016) 
note: Do file used to creates this file: MakeData_Admin3_YOS.do
note: I create YOS variable by summing over all the membership service from state administration retirement system for each individual
	
	save "${working}Admin3_YOS", replace

	count 
	
	duplicates re indi
	

log close _all

exit





/*** Legacy code 

*** Reshape dataset into wide form using last contribution date as subobservation
 
	gsort indi -admin3_lastcontribdate -admin3_membegindate
	by indi: gen admin3_mem_order = _n
	
	keep individual_id pr_membership_id membership_total_service membership_contributory_service admin3_*yos_sum_adj admin3_multi_mem admin3_mem_order admin3_membegindate admin3_lastcontribdate
		
	reshape wide pr_membership_id membership_total_service membership_contributory_service admin3_*yos_sum_adj admin3_multi_mem admin3_membegindate admin3_lastcontribdate , i(individual_id) j(admin3_mem_order)
	
	
	
*** check reshape results and keep only one duplicated variables among duplicates

	local YOS "admin3_yos_sum_adj admin3_contryos_sum_adj admin3_multi_mem"

	foreach x in `YOS' {
	di"`x'"

	compare `x'1 `x'2

	gen `x' = `x'1

	drop `x'1 `x'2
	}





renvars pr_membership_id-lala,postfix(1)

merge m:1 individual_id using "${raw}ACTIVES_PERSON_INFO.dta", keepusing(pr_membership_id)
keep if _merge==3
drop _merge

merge m:1 pr_membership_id using "${raw}ACTIVES_ALL_MEMBERSHIP_INFO.dta"
keep if _merge==3
drop _merge


gsort indi -admin3_lastcontribdate -admin3_membegindate

by indi: gen pr1 = pr_membership_id1[1]
rename pr_membership_id pr0

compare pr1 pr0

merge m:1 individual_id using "${working}Admin3_Actives", keepusing(indi)
keep if _merge==3
drop _merge


"The PERSON FILE contains information about all individuals who made a contribution (or had a contribution made by their employer on their behalf) for a pay period ending on or after 12/1/2013 who also meet the following criteria: 
1. Age >=50 and <86
2. Were first hired before 3/4/2014. 
3.  Have not retired from TSERS or LGERS, or gone out on long-term disability at any point prior to 2/2/2014.  
"		



list individual_id mem_retirement_system_code last_contrib_date membership_begin_date membership_status_code membership_total_service termination_type_code ba_status_code benefit_account_type_code admin3_yos_sum_adj if hi==1

       +------------------------------------------------------------------------------------------------------------------+
       | indivi~d   mem_re~e   last_con~e   mem~n_date   membe~de   m~tota~e   termin~de   ba_st~de   benefi~e   _overlap |
       |------------------------------------------------------------------------------------------------------------------|
 9392. |  P125317      TSERS   12/31/2015   09/08/1986       ACTV          9                                            1 |
 9393. |  P125317       CJRS   12/31/2006   02/01/1993       ACTV    20.3333                                            1 |
23172. | P3207547        LRS   07/01/2013   05/01/1990       ACTV      23.25   VOLUNTARY                                0 |
23173. | P3207547      TSERS   12/31/2015   07/01/2013       ACTV        2.5                                            0 |
25858. | P3226728      TSERS   10/31/2001   05/11/1998       ACTV    16.5834                                            1 |
       |------------------------------------------------------------------------------------------------------------------|
25859. | P3226728       CJRS   12/31/2015   05/11/1998       ACTV     1.0833                                            1 |
32943. | P3356663        LRS   12/31/2010   01/01/2007       ACTV          4   VOLUNTARY                                0 |
32944. | P3356663      TSERS   12/31/2015   03/01/2011       ACTV     4.8333                                            0 |
33001. | P3357230       CJRS   12/31/1998   12/03/1990       ACTV     8.0833                                            1 |
33002. | P3357230      TSERS   12/31/2015   03/19/1987       ACTV    14.3333                                            1 |
       |------------------------------------------------------------------------------------------------------------------|
45146. | P3544983      TSERS   12/31/2015   01/02/2001       ACTV     6.3333                                            1 |
45147. | P3544983       CJRS   12/31/2012   04/16/2004       ACTV       8.75                                            1 |
49642. | P3624355       CJRS   02/28/2003   09/30/2002       ACTV        .25                                            1 |
49643. | P3624355      TSERS   12/31/2015   02/22/1983       ACTV      32.75                                            1 |
56787. | P3706709        LRS   12/31/2015   11/01/2012       ACTV     3.1667                                            1 |
       |------------------------------------------------------------------------------------------------------------------|
56788. | P3706709      TSERS   12/31/2015   07/01/2013       ACTV        2.4                                            1 |
69323. |  P455549        LRS   12/31/2008   01/01/2003       ACTV          6   VOLUNTARY                                0 |
69324. |  P455549      TSERS   12/31/2015   01/05/2013       ACTV          3                                            0 |
71044. |  P488262      TSERS   01/31/2014   10/05/1998       ACTV    15.0833   VOLUNTARY                                0 |
71045. |  P488262        LRS   12/31/1992   01/01/1991       ACTV          2                                            0 |
       |------------------------------------------------------------------------------------------------------------------|
84206. |  P802224      TSERS   12/31/2015   01/05/2013       ACTV          3                                            0 |
84207. |  P802224        LRS   12/31/2012   03/13/2004       ACTV     8.8333   VOLUNTARY                                0 |
       +------------------------------------------------------------------------------------------------------------------+


