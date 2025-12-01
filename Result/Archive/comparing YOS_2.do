*** Comparing YOS ***

clear

capture log close _all
set more off
pause on

cd "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs"

global date "$S_DATE"
log using "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs\Logs\ComparingYOS_$date", replace text name("Ariel")
global raw "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\RawData\"
global working "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\WorkingData\"
********************************************************
use "${working}HR_admin_$date.dta",clear

renvars  mem_retirement_system_code membership_begin_date membership_status_code membership_total_service \  retire_system mem_begein mem_status mem_tot_service

renvars _active-prev_ret retire_system mem_begein mem_status mem_tot_service, postfi(_new)

merge 1:1 individual_id using "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\WorkingData\HR_admin_NOIMP.dta"

keep if _merge==3
drop _merge

renvars  mem_retirement_system_code membership_begin_date membership_status_code membership_total_service \  retire_system mem_begein mem_status mem_tot_service

su yos_svy3_adj_new yos_svy3_curr_new yos_2016_adj yos_2016_curr

count if yos_svy3_curr_new~=yos_2016_curr
count if yos_svy3_adj_new ~= yos_2016_adj



export excel individual_id retire_system retire_system_new mem_begein mem_begein_new mem_status mem_status_new mem_tot_service mem_tot_service_new yos_2016_curr yos_svy3_curr_new using compare_YOS if mem_status_new~= mem_status, replace firstrow(varlabels)

exit
/*replace mem_retirement_system_code="LGERS" if mem_retirement_system_code=="RDSPF" // RDSPF are also in LGERS
replace mem_retirement_system_code="TSERS" if mem_retirement_system_code=="ORP" // ORP service credit may also be used to determine eligibility for TSERS benefits

//*** Years of Service, no restriction ***//
** Here I sum over years of service of every retirement system one individual have. In the orginal code it take mean instead of sum.**
destring membership_total_service membership_contributory_service membership_other_servic, replace ignore("NULL")

bysort individual_id : egen yos_2016_curr=total(membership_total_service) if membership_total_service<.
bysort individual_id : egen contrib_yos_2016_curr=total(membership_contributory_service)  if membership_total_service<.

local YOS "yos_2016_curr contrib_yos_2016_curr"

foreach x of varlist `YOS' {
bysort indi: egen mean_`x' =  mean(`x') 
drop `x'
rename mean_`x' `x'
}
lab var yos_2016_curr "YOS(Sum All Mem)"
lab var contrib_yos_2016_curr "Ctr. YOS(Sum All Mem)"

//*** YOS, all active and retired memberships ***//
gen restrict = (membership_status_code=="ACTV" | membership_status_code=="CLOSRET" ) &membership_total_service<.

bysort individual_id: egen yos_2016_sum=total(membership_total_service) if restrict ==1
bysort individual_id: egen contrib_yos_2016_sum=total(membership_contributory_service) if restrict ==1


local YOS "yos_2016_sum contrib_yos_2016_sum"

foreach x of varlist `YOS' {

bysort indi: egen mean_`x' =  mean(`x') 
drop `x'
rename mean_`x' `x'
}

drop restrict

label var yos_2016_sum "YOS(ACT/RT)"
label var contrib_yos_2016_sum  "Ctr. YOS(ACT/RT)"

//*** YOS, for TSERS/LGERS/CJRS/LRS ***//
gen restrict = (mem_retirement_system_code=="CJRS" | mem_retirement_system_code=="LGERS" | mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="LRS") &membership_total_service<.

bysort individual_id: egen yos_sum_tlcl=total(membership_total_service) if restrict ==1
bysort individual_id: egen contrib_yos_sum_tlcl=total(membership_contributory_service) if restrict ==1

local YOS "yos_sum_tlcl contrib_yos_sum_tlcl"

foreach x of varlist `YOS' {

bysort indi: egen mean_`x' =  mean(`x') 
drop `x'
rename mean_`x' `x'
}

drop restrict

label var yos_sum_tlcl "YOS(State-admin)"
label var contrib_yos_sum_tlcl  "Ctr. YOS(State-admin)"


//*** YOS, for TSERS/LGERS ***//
gen restrict = (mem_retirement_system_code=="LGERS" | mem_retirement_system_code=="TSERS") &membership_total_service<.

bysort individual_id: egen yos_sum_tl=total(membership_total_service) if restrict ==1
bysort individual_id: egen contrib_yos_sum_tl=total(membership_contributory_service) if restrict ==1

local YOS "yos_sum_tl contrib_yos_sum_tl"

foreach x of varlist `YOS' {
bysort indi: egen mean_`x' =  mean(`x') 

drop `x'
rename mean_`x' `x'
}


label var yos_sum_tl "YOS(LGERS/TSERS)"
label var contrib_yos_sum_tl  "Ctr. YOS(LGERS/TSER)"

drop restrict

//*** YOS, for TSERS/LGERS/CJRS/LRS, all active and retired memberships  ***//
gen restrict = (membership_status_code=="ACTV" | membership_status_code=="CLOSRET" )&(mem_retirement_system_code=="CJRS" | mem_retirement_system_code=="LGERS" | mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="LRS") &membership_total_service<.

bysort individual_id: egen yos_actre_tlcl=total(membership_total_service) if restrict ==1
bysort individual_id: egen contrib_yos_actre_tlcl=total(membership_contributory_service) if restrict ==1

local YOS "yos_actre_tlcl contrib_yos_actre_tlcl"

foreach x of varlist `YOS' {

bysort indi: egen mean_`x' =  mean(`x') 
drop `x'
rename mean_`x' `x'
}

drop restrict

label var yos_actre_tlcl "YOS(State-admin,ACT/RT)"
label var contrib_yos_actre_tlcl  "Ctr. YOS(State-admin,ACT/RT)"


//*** YOS, for TSERS/LGERS, all active and retired memberships***//
gen restrict = (membership_status_code=="ACTV" | membership_status_code=="CLOSRET" )&(mem_retirement_system_code=="LGERS" | mem_retirement_system_code=="TSERS") &membership_total_service<.

bysort individual_id: egen yos_actre_tl=total(membership_total_service) if restrict ==1
bysort individual_id: egen contrib_yos_actre_tl=total(membership_contributory_service) if restrict ==1


local YOS "yos_actre_tl contrib_yos_actre_tl"

foreach x of varlist `YOS' {
bysort indi: egen mean_`x' =  mean(`x') 

drop `x'
rename mean_`x' `x'
}
drop restrict 

label var yos_actre_tl "YOS(LGERS/TSERS,ACT/RT)"
label var contrib_yos_actre_tl  "Ctr. YOS(LGERS/TSERS,ACT/RT)"

*keep individual_id yos_2016_curr-contrib_yos_actre_tl

merge m:1 individual_id using "${raw}ACTIVES_PERSON_INFO.dta",keepusing(age)
drop _merge

foreach x of varlist yos_2016_curr-contrib_yos_actre_tl {

local y : variable label `x'	
di "`y'"
count if age < `x' & `x'<.
}


***
//*** YOS, all active memberships ***//
gen restrict = (membership_status_code=="ACTV" ) &membership_total_service<.

bysort individual_id: egen yos_active=total(membership_total_service) if restrict ==1
bysort individual_id: egen contrib_yos_active=total(membership_contributory_service) if restrict ==1

local YOS "yos_active contrib_yos_active"

foreach x of varlist `YOS' {

bysort indi: egen mean_`x' =  mean(`x') 
drop `x'
rename mean_`x' `x'
}

drop restrict

label var yos_active "YOS(ACT)"
label var contrib_yos_active  "Ctr. YOS(ACT)"

//*** YOS, for TSERS/LGERS/CJRS/LRS, all active memberships  ***//
gen restrict = (membership_status_code=="ACTV" )&(mem_retirement_system_code=="CJRS" | mem_retirement_system_code=="LGERS" | mem_retirement_system_code=="TSERS" | mem_retirement_system_code=="LRS") &membership_total_service<.

bysort individual_id: egen yos_act_tlcl=total(membership_total_service) if restrict ==1
bysort individual_id: egen contrib_yos_act_tlcl=total(membership_contributory_service) if restrict ==1

local YOS "yos_act_tlcl contrib_yos_act_tlcl"

foreach x of varlist `YOS' {

bysort indi: egen mean_`x' =  mean(`x') 
drop `x'
rename mean_`x' `x'
}

drop restrict

label var yos_act_tlcl "YOS(State-admin,ACT)"
label var contrib_yos_act_tlcl  "Ctr. YOS(State-admin,ACT)"


//*** YOS, for TSERS/LGERS, all active memberships***//
gen restrict = (membership_status_code=="ACTV"  )&(mem_retirement_system_code=="LGERS" | mem_retirement_system_code=="TSERS") &membership_total_service<.

bysort individual_id: egen yos_act_tl=total(membership_total_service) if restrict ==1
bysort individual_id: egen contrib_yos_act_tl=total(membership_contributory_service) if restrict ==1


local YOS "yos_act_tl contrib_yos_act_tl"

foreach x of varlist `YOS' {
bysort indi: egen mean_`x' =  mean(`x') 

drop `x'
rename mean_`x' `x'
}
drop restrict 

label var yos_act_tl "YOS(LGERS/TSERS,ACT)"
label var contrib_yos_act_tl  "Ctr. YOS(LGERS/TSERS,ACT)"



foreach x of varlist yos_active-contrib_yos_act_tl {

local y : variable label `x'	
di "`y'"
count if age < `x' & `x'<.
}

*duplicates drop indi,force
renvars yos_2016_curr-contrib_yos_act_tl,postfix(_new)

********************
** comparing **
	merge m:1 individual_id using "${working}YOS_actual_2016_$S_DATE"
	keep if _merge==3
	drop _merge
exit
local YOS "yos_2016_curr yos_2016_sum"
	
foreach x of varlist `YOS' {

sort indi
local y : variable label `x'	
di "`y'"
count if age_new < `x' & `x'<.
list individual_id age_new mem_retirement_system_code membership_status_code membership_total_service yos_2016_curr yos_2016_sum if age_new < `x' & `x'<.

}

local YOS " yos_2016_sum yos_actre_tlcl_new"

cd C:\Users\ariel\Desktop

lab var yos_2016_sum "YOS(State-admin,ACT/RT)-Original"
lab var yos_2016_curr "YOS(Mean All Mem)"
lab var indi "ID"
lab var age_new "Age"
lab var mem_retirement_system_code "System"
lab var membership_status_code "Status"
lab var membership_total_service "Mem. Total Sevice"
	
foreach x of varlist `YOS' {

sort indi
local y : variable label `x'	
di "`y'"
count if age_new < `x' & `x'<.
list individual_id age_new mem_retirement_system_code membership_status_code membership_total_service yos_2016_sum yos_actre_tlcl_new  if age_new < `x' & `x'<.

asdoc list individual_id age_new mem_retirement_system_code membership_status_code membership_total_service yos_2016_sum yos_actre_tlcl_new  if age_new < `x' & `x'<. , label replace save(list.doc) title(New Variables)

}
order age_new contri*
duplicates drop indi,force
asdoc sum yos_*new, label replace save(Summary stats.doc) title(New Variables)

asdoc sum yos_2016_curr yos_2016_sum, label append save(Summary stats.doc) title(Original Variables)
