local Fuzzy _Fuzzy //  => _Fuzzy Elig.; no string => Exact Elig
local restrict_to_no_early_elg // restrict=> restrict sample to people who does not elig. for early retirement. No => no restriction 
local compliers_prob_method compliers // compliers => use method provided by Abadie (2003) to calculate compliance prob.  ;compliers_both => adjust calculation formula to accommodate 2 instruments 
local Z_control admin3_eligible_early_at_svy5 //  => include early elig. as controls; no string=> exclude early elig.
local bootstrap_time = 1000 //bootstrap times 

**************************************************
use "${working}Admin3_Survey3`Fuzzy'.dta", clear // using MakeData_Admin3_Survey3.do (Aug 2023). Data restriction: answered own_health, married and has job classification

if "`restrict_to_no_early_elg'" == "_restrict" {
drop if admin3_eligible_early_at_svy5 == 1 //restrict sample to people who does not elig. for early retirement
}

if "`Z_control'" == "admin3_eligible_early_at_svy5" {
local control_footnote , early pension eligibility
local file_name BinaryControl`Fuzzy'`restrict_to_no_early_elg' //_bootstrap_`bootstrap_time'  _NoSP
} 
else {
local control_footnote 
local file_name NoControl`Fuzzy'`restrict_to_no_early_elg' //_bootstrap_`bootstrap_time'  _NoSP
}
if "`compliers_prob_method'" == "compliers" {
local cal_footnote %
} 
else {
local cal_footnote \multicolumn{6}{l}{\footnotesize Calculation for compliance probabilities have been adjusted for two instrument. }\\
local file_name `file_name'_AdjCal
}

*** Treatment = Retirement
tab admin5_status_not_ret
gen not_working = 1-admin5_status_not_ret
gen D = not_working

*** Instrument = Elig. for Normal Retirement Benefit
gen Z = admin3_eligible_normal_at_svy5
tab Z,m
gen Ze = admin3_eligible_early_at_svy5

*** LABELS
lab var Z "Elig Normal" //"Eligible Normal (Full Benefits)" //"Normal Eligible as of December 2017"
lab var admin3_eligible_early_at_svy5 "Elig Early" //"Eligible Early (Reduced Benefits)" // "Early Eligible as of December 2017"
lab var admin3_eligible_none_at_svy5 "Not Yet Eligible for Benefits" //"Not Eligible as of December 2017"
label var not_working "Not Working"
label var svy3_own_health_poor "Poor Health"
label var svy3_married "Married"
/*label var atype_school "Public School Employee"
label var atype_stategovt "State Gov't Employee"
label var total_salary "Salary (10K)"
label var race_blk "Black"
label var race_hisp "Hispanic"
label var race_other "Other Race"
label var educ_ba "College Degree"
label var nkids12 "1-2 Kids"
label var nkids34 "3+ Kids"
label var nkidsmis "Missing Data on Kids"*/
gen admin3_int_age = int(admin3_age_at_svy3) //truncating age toward 0. Could not skip this step if we want to run peak value py code. Otherwise the merge won't work.
gen admin3_int_yos = int(admin3_yos_at_svy3) //truncating YOS toward 0  Could not skip this step if we want to run peak value py code. Otherwise the merge won't work.

tab admin3_int_age, gen(age)
lab var age1 "Age 52"
lab var age2 "Age 53"
lab var age3 "Age 54"
lab var age4 "Age 55"
lab var age5 "Age 56"
lab var age6 "Age 57"
lab var age7 "Age 58"
lab var age8 "Age 59"
lab var age9 "Age 60"
lab var age10 "Age 61"
lab var age11 "Age 62"
lab var age12 "Age 63"
lab var age13 "Age 64"

gen svy3_notenough_money = 1 - svy3_enough_money

global demo `Z_control' svy3_own_health_poor  admin3_female svy3_married_partner ///svy3_sphlthpoor
	svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss ///
 svy3_race_black svy3_race_hisp svy3_race_other  ///
 svy3_educ_ba svy3_educ_blank admin3_atype_school admin3_atype_stategovt ///
 admin3_total_salary_10K_2015  ///
 admin3_yos_at_svy3 age2-age13

 su $demo
file open tbl using "${output}Tbl_Sum_Subgroup_`file_name'_`time'.tex", write replace
file write tbl "\begin{table}[h!]\centering" _n "\caption{Summary statistics by Subgroup}" _n "\label{tbl-sumsubgroup}" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n "\resizebox{\linewidth}{!}{%" _n
file write tbl "\begin{tabular}{l*{5}{c}}" _n
file write tbl "\toprule"  _n
file write tbl " &Full   & Good   &  Poor    & Saved   &  Not    \\ " _n
file write tbl " &Sample & Health &  Health  & Enough  & Enough  \\ " _n
file write tbl " & (1)   & (2a) & (2b) & (3a) & (3b) \\ " _n
file close tbl

lab var D "Not Working"
eststo sum_full: estpost tabstat D Z `Z_Control' $demo, statistics(n mean semean) columns(statistics)


foreach v in svy3_own_health_poor  svy3_enough_money { //svy3_sphlthpoor => Spouse Health is excluded since September 2023
forvalues n = 0/1 {
preserve
keep if `v' == `n' & `v' <. 
eststo sum_`v'`n': estpost tabstat D Z `Z_Control' $demo, statistics(n mean semean) columns(statistics)
restore
}
}
local cov "Z `Z_control' svy3_own_health_poor svy3_sphlthpoor admin3_female svy3_married_partner svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss svy3_race_black svy3_race_hisp svy3_race_other svy3_educ_ba svy3_educ_blank admin3_atype_school admin3_atype_stategovt admin3_total_salary_10K_2015 admin3_yos_at_svy3 age2 age3 age4 age5 age6 age7 age8 age9 age10 age11 age12 age13"
esttab sum_full sum_svy3_own_health_poor0 sum_svy3_own_health_poor1 sum_svy3_enough_money1 sum_svy3_enough_money0  using "${output}Tbl_Sum_Subgroup_`file_name'_`time'.tex", append ///
	lab  keep(`cov') order(`cov') noomit  main(mean 3) aux(semean 3) nobase nogap nomtitles nonumbers fragment nostar //stat( N, labels( "N"))

file open tbl using "${output}Tbl_Sum_Subgroup_`file_name'_`time'.tex", write append	
file write tbl "\bottomrule" _n "\end{tabular}\\" _n "}" _n
*file write tbl  "\\{\footnotesize Notes: Regression estimates are from a linear probability model that includes indicators for own and spouse's health status (where appropriate), gender, marital status, age dummies, years of service`control_footnote', salary, race/ethnicity indicators, number of children, education, and agency type indicators.}" _n
file write tbl "\end{table}" _n
file close tbl	
