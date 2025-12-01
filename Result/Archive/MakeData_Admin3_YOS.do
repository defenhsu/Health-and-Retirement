/************************************************************************************************************************ 
This file creates Years of Service using Administrative Data release at 04.06.2016 ==> pre-survey 
************************************************************************************************************************/

clear
capture log close _all
set more off
pause on

cd "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs"

global date "$S_DATE"
log using "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs\Logs\MakeData_Admin3_YOS_$date", replace text name("Ariel")
global raw "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\RawData\"
global working "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\WorkingData\"


*********************************************
*** Merging files of Admin Data from Survey 3 (pre-period)
*********************************************

use "${raw}ACTIVES_ALL_MEMBERSHIP_INFO.dta",clear //04.06.2016 version// go back to original dataset so we can ... 


*********************************************
*** Generating YOS for state administration retirement system
*********************************************

*** Keep state administration retirement system

	keep if mem_retirement_system_code=="LGERS" | mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="ORP" | mem_retirement_system_code=="RDSPF" | mem_retirement_system_code=="CJRS" | mem_retirement_system_code=="LRS"
	
// add indicator for ...
	
*** Drop if from both TSERS and LGERS system
		
	bysort individual_id: egen admin3_tsers=max(mem_retirement_system_code=="TSERS"|mem_retirement_system_code=="ORP")
	
	bysort individual_id: egen admin3_lgers=max(mem_retirement_system_code=="LGERS"|mem_retirement_system_code=="RDSPF")
	
	drop if admin3_tsers==1 & admin3_lgers==1
	
	duplicates report indi membership_begin_date last_contrib_date	
	
		
*** Drop individuals retired in TSERS/LGERS as of April 2016 

	/*Retired
	--Has claimed benefits as of April.06.2016 
	--Active Benefit status code
	--Early/Normal Benefit account type code */

	gen admin3_benefitdate=date(ba_effective_date, "MDY")  // benefit claim date
	format admin3_benefitdate %td
	
	gen _retired=(admin3_benefitdate<mdy(04,06,2016)) & (mem_retirement_system_code=="LGERS" | mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="ORP" | mem_retirement_system_code=="RDSPF" )

	replace _retired = 1 if (benefit_account_type_code=="EARLY"|benefit_account_type_code=="SVC") & ba_status_code=="ACTV" & (mem_retirement_system_code=="LGERS" | mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="ORP" | mem_retirement_system_code=="RDSPF" )
	
	egen admin3_status_retired=max(_retired), by(individual_id) //retired as of April 2016 
	
	replace admin3_status_retired=1 if individual_id=="P3013713" // drop No benefit account, membership status retired with no termination type code =
	
	
	drop if admin3_status_retired == 1 
	
	
*** Keep active workers with Active Membership and Not Claiming A Benefit

	/*Actives: 
	--Active membership status code
	--Null benefit status code
	--Null termination code */

	gen _active= (membership_status_code=="ACTV" & ba_status_code=="" & termination_type_code=="") 

	egen admin3_status_active=max(_active), by(individual_id)

	label var admin3_status_active "Active"
	
	tab admin3_status_active admin3_status_retired
	
	keep if admin3_status_active ==1	
	
	
*** Drop memberships with missing contribution dates ==> people with missing contribution dates has missing membership service years as well, so drop membership who doesn't have valid membership service years for YOS
    
	gen admin3_lastcontribdate=date(last_contrib_date, "MDY")
	format admin3_lastcontribdate %td
	
	drop if admin3_lastcontribdate ==.
	
	duplicates  report indi membership_begin_date last_contrib_date	
	

*** Keep active and retired non-termated Memberships

	duplicates  report indi

	keep if membership_status_code=="ACTV" |
	
	duplicates  report indi
	

*** YOS, all active emberships
	
	destring membership_total_service membership_contributory_service membership_other_servic, replace ignore("NULL")

	bysort individual_id: egen admin3_yos_sum=total(membership_total_service)
	
	bysort individual_id: egen admin3_yos_max=max(membership_total_service)
	
	bysort individual_id: egen admin3_contryos_sum=total(membership_contributory_service)
	
	bysort individual_id: egen admin3_contryos_max=max(membership_contributory_service)

		
*** Adjusting total service for individuals who had overlapping dates between membership begin date and last contribustion date

	duplicates tag indi, gen(admin3_multi_mem)	// Identifies multiple memberships

	gen admin3_membegindate=date(membership_begin_date, "MDY")
	format admin3_membegindate %td		
	
	bysort individual_id: egen admin3_last_membegindate=max(admin3_membegindate)
	
	bysort individual_id: egen admin3_first_memenddate=min(admin3_lastcontribdate)	

	gen _overlap = (admin3_first_memenddate>admin3_last_membegindate) if admin3_multi_mem>0 & admin3_lastcontribdate <.
	
	tab _overlap admin3_multi_mem,m
	
	gen admin3_date_overlap= (admin3_multi_mem==1 & _overlap==1)

	
	gen admin3_yos_sum_adj=admin3_yos_sum
	replace admin3_yos_sum_adj=admin3_yos_max if admin3_date_overlap==1
	
	gen admin3_contryos_sum_adj=admin3_contryos_sum
	replace admin3_contryos_sum_adj=admin3_contryos_max if admin3_date_overlap==1 


	duplicates list indi membership_begin_date	
	list membership_status_code membership_begin_date admin3_yos_sum_adj admin3_contryos_sum admin3_date_overlap membership_total_service if indi=="P3226728"
	
	

*** Reshape dataset into wide form using time of membership begin date as subobservation
 
	gsort indi -admin3_lastcontribdate
	bysort indi: gen admin3_mem_order = _n
	
	keep individual_id pr_membership_id admin3_lastcontribdate membership_total_service membership_contributory_service admin3_yos* admin3_contryos* admin3_mem_order admin3_multi_mem
		
	reshape wide pr_membership_id admin3_lastcontribdate membership_total_service membership_contributory_service admin3_yos* admin3_contryos* admin3_multi_mem, i(individual_id) j(admin3_mem_order)
	
	
*** check reshape results and keep only one duplicated variables among duplicates

	local YOS "admin3_multi_mem admin3_yos_sum admin3_yos_max admin3_contryos_sum admin3_contryos_max admin3_yos_sum_adj admin3_contryos_sum_adj"

	foreach x in `YOS' {
	di"`x'"

	compare `x'1 `x'2

	gen `x' = `x'1

	drop `x'1 `x'2
	}


*** Years of Service, Current Membership 

	gen admin3_yos_curr = membership_total_service1
	label var admin3_yos_curr "Curr. YOS(Admin 3)"
	
	gen admin3_contryos_curr = membership_contributory_service1
	label var admin3_contryos_curr "Curr. Contrib YOS (Admin3)"


*** keep YOS

	keep indi admin3_yos* admin3_contryos*
		
	label var admin3_yos_sum "YOS (Admin 3)"
	label var admin3_contryos_sum "Contri. YOS (Admin 3)"	
	label var admin3_yos_sum_adj  "Adj. YOS (Admin 3)"	
	label var admin3_contryos_sum_adj  "Adj. Contri. YOS (Admin 3)"
	
	
	save "${working}Admin3_YOS", replace

	count
	
	duplicates re indi
	

log close _all

exit



/*** Legacy code 


list individual_id mem_retirement_system_code last_contrib_date membership_begin_date membership_status_code membership_total_service termination_type_code ba_status_code benefit_account_type_code _overlap if _overlap<.

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





*** compare with original YOS_curr // just to check 

	merge m:1 individual_id using "${raw}ACTIVES_PERSON_INFO.dta", keepusing(pr_membership_id) // 04.06.2016 version

	compare pr_membership_id1 pr_membership_id

	keep if _merge ==3 //==> change it 
	drop _merge pr_membership_id


*** drop indivuduals with non NULL termination code
	
	drop if termination_type_code==1 & termination_type_code~=""
	
list indi pr_membership_id1 admin3_lastcontribdate1 membership_total_service1 pr_membership_id2 admin3_lastcontribdate2 membership_total_service2 pr_membership_id  if pr_membership_id1~=pr_membership_id & membership_total_service2~=membership_total_service1


use "${raw}ACTIVES_ALL_MEMBERSHIP_INFO.dta",clear //04.06.2016 version


list individual_id pr mem_retirement_system_code membership_begin_date last_contrib_date membership_status_code membership_contributory_service membership_total_service  ///termination_type_code benefit_account_type_code  ba_status_code
if indi == "P125317" | indi == "P3226728" | indi == "P3357230" | indi == "P3544983"| indi == "P3624355" , display



        +-----------------------------------------------------------------------------------------+
        | indivi~d   pr_mem~1   admin3_~1   member..   pr_mem~2   admin3_~2   member..   pr_mem~d |
        |-----------------------------------------------------------------------------------------|
  9391. |  P125317   M3151903   01feb1993    20.3333    M314199   08sep1986          9    M314199 |
 25855. | P3226728   M3221659   11may1998    16.5834   M6064251   11may1998     1.0833   M6064251 |
 32996. | P3357230   M3301331   03dec1990     8.0833   M3551371   19mar1987    14.3333   M3551371 |
 45139. | P3544983   M3005274   16apr2004       8.75     M15967   02jan2001     6.3333     M15967 |
 49632. | P3624355    M856434   30sep2002        .25    M947051   22feb1983      32.75    M947051 |
        +-----------------------------------------------------------------------------------------+

		

        +----------------------------------------------------------------------------------------------------------------+
 20053. | indivi~d | pr_mem~d | mem_re~e | mem~n_date | member~de | member.. | m~tota~e | termi~de | benefi~e | ba_st~de |	x
        |  P125317 |  M314199 |    TSERS | 09/08/1986 |      ACTV |        9 |        9 |          |          |          |
        +----------------------------------------------------------------------------------------------------------------+

        +----------------------------------------------------------------------------------------------------------------+
 20054. | indivi~d | pr_mem~d | mem_re~e | mem~n_date | member~de | member.. | m~tota~e | termi~de | benefi~e | ba_st~de |	v		
        |  P125317 | M3151903 |     CJRS | 02/01/1993 |      ACTV |  20.3333 |  20.3333 |          |          |          | 
        +----------------------------------------------------------------------------------------------------------------+

        +----------------------------------------------------------------------------------------------------------------+
 20055. | indivi~d | pr_mem~d | mem_re~e | mem~n_date | member~de | member.. | m~tota~e | termi~de | benefi~e | ba_st~de |
        |  P125317 | M3271255 |    TSERS | 09/08/1986 | CLOSTRANS |        . |        . |          |          |          |
        +----------------------------------------------------------------------------------------------------------------+

        +----------------------------------------------------------------------------------------------------------------+
 54706. | indivi~d | pr_mem~d | mem_re~e | mem~n_date | member~de | member.. | m~tota~e | termi~de | benefi~e | ba_st~de |	v
        | P3226728 | M3221659 |    TSERS | 05/11/1998 |      ACTV |  16.5834 |  16.5834 |          |          |          |
        +----------------------------------------------------------------------------------------------------------------+

        +----------------------------------------------------------------------------------------------------------------+
 54707. | indivi~d | pr_mem~d | mem_re~e | mem~n_date | member~de | member.. | m~tota~e | termi~de | benefi~e | ba_st~de |	x
        | P3226728 | M6064251 |     CJRS | 05/11/1998 |      ACTV |   1.0833 |   1.0833 |          |          |          |
        +----------------------------------------------------------------------------------------------------------------+

        +----------------------------------------------------------------------------------------------------------------+
 72589. | indivi~d | pr_mem~d | mem_re~e | mem~n_date | member~de | member.. | m~tota~e | termi~de | benefi~e | ba_st~de |	v
        | P3357230 | M3301331 |     CJRS | 12/03/1990 |      ACTV |   8.0833 |   8.0833 |          |          |          |
        +----------------------------------------------------------------------------------------------------------------+

        +----------------------------------------------------------------------------------------------------------------+
 72590. | indivi~d | pr_mem~d | mem_re~e | mem~n_date | member~de | member.. | m~tota~e | termi~de | benefi~e | ba_st~de |	x
        | P3357230 | M3551371 |    TSERS | 03/19/1987 |      ACTV |  10.5833 |  14.3333 |          |          |          |
        +----------------------------------------------------------------------------------------------------------------+

        +----------------------------------------------------------------------------------------------------------------+
 72591. | indivi~d | pr_mem~d | mem_re~e | mem~n_date | member~de | member.. | m~tota~e | termi~de | benefi~e | ba_st~de |
        | P3357230 |  M598007 |    TSERS | 03/19/1987 |  CLOSWITH |        . |        . |          |          |          |
        +----------------------------------------------------------------------------------------------------------------+

        +----------------------------------------------------------------------------------------------------------------+
 94841. | indivi~d | pr_mem~d | mem_re~e | mem~n_date | member~de | member.. | m~tota~e | termi~de | benefi~e | ba_st~de |	x
        | P3544983 |   M15967 |    TSERS | 01/02/2001 |      ACTV |   6.3333 |   6.3333 |          |          |          |
        +----------------------------------------------------------------------------------------------------------------+

        +----------------------------------------------------------------------------------------------------------------+
 94842. | indivi~d | pr_mem~d | mem_re~e | mem~n_date | member~de | member.. | m~tota~e | termi~de | benefi~e | ba_st~de |	v
        | P3544983 | M3005274 |     CJRS | 04/16/2004 |      ACTV |     8.75 |     8.75 |          |          |          |
        +----------------------------------------------------------------------------------------------------------------+

        +----------------------------------------------------------------------------------------------------------------+
105140. | indivi~d | pr_mem~d | mem_re~e | mem~n_date | member~de | member.. | m~tota~e | termi~de | benefi~e | ba_st~de |	v
        | P3624355 |  M856434 |     CJRS | 09/30/2002 |      ACTV |      .25 |      .25 |          |          |          |
        +----------------------------------------------------------------------------------------------------------------+

        +----------------------------------------------------------------------------------------------------------------+
105141. | indivi~d | pr_mem~d | mem_re~e | mem~n_date | member~de | member.. | m~tota~e | termi~de | benefi~e | ba_st~de |	x
        | P3624355 |  M947051 |    TSERS | 02/22/1983 |      ACTV |    32.75 |    32.75 |          |          |          |
        +----------------------------------------------------------------------------------------------------------------+
