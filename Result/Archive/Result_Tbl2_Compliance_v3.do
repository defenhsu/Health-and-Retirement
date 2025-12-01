/* This file generate the "Table of Probability for Compliance by Health Satus and Wealth" and show compliance probabilities across the own health status, spouse health status, and whether saved enough for retirement.
Additionally, this file also generate "Table of Weighted Means by LATE group".
To make sure the results are rebust to early retirement instrument, we also compare results using different controls and restriction. */

capture file close _all
program drop _all
sca drop _all
cd "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\RA"
include "MakeData\Step0_SetDirectory"
log using "${log}HR2_COMPLIANCE_ANALYSIS_$date", replace text name("Ariel") 
*******************************************
use "${working}Admin3_Survey3.dta", clear // using MakeData_Admin3_Survey3.do (Aug 2023). Data restriction: answered own_health, married and has job classification

*** Different contrals and restriction to test rebustness
*drop if admin3_eligible_early_at_svy5 == 1
gen Ze = admin3_eligible_early_at_svy5  
gen Z_control = admin3_eligible_early_at_svy5 + admin3_eligible_normal_at_svy5

*** Treatment = Retirement
tab admin5_status_not_ret
gen not_working = 1-admin5_status_not_ret
gen D = not_working

*** Instrument = Elig. for Normal Retirement Benefit
gen Z = admin3_eligible_normal_at_svy5
tab Z,m

*** LABELS
lab var admin3_eligible_normal_at_svy5 "Elig Normal" //"Eligible Normal (Full Benefits)" //"Normal Eligible as of December 2017"
lab var admin3_eligible_early_at_svy5 "Elig Early" //"Eligible Early (Reduced Benefits)" // "Early Eligible as of December 2017"
lab var admin3_eligible_none_at_svy5 "Not Yet Eligible for Benefits" //"Not Eligible as of December 2017"
label var not_working "Not Working"
label var svy3_own_health_poor "Poor Health"
label var svy3_married "Married"
/*label var female "Female"
label var atype_school "Public School Employee"
label var atype_stategovt "State Gov't Employee"
label var total_salary "Salary (10K)"
label var race_blk "Black"
label var race_hisp "Hispanic"
label var race_other "Other Race"
label var educ_ba "College Degree"
label var nkids12 "1-2 Kids"
label var nkids34 "3+ Kids"
label var nkidsmis "Missing Data on Kids"
*/
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


replace svy3_sphlthpoor = . if svy3_married==0

global demo svy3_own_health_poor svy3_sphlthpoor svy3_married admin3_female ///
	svy3_num_kids_12 svy3_num_kids_34 svy3_num_kids_miss ///
 svy3_race_black svy3_race_hisp svy3_race_other  ///
 svy3_educ_ba svy3_educ_blank admin3_atype_school admin3_atype_stategovt ///
 admin3_total_salary_10K_2015 /// Ze
 admin3_yos_at_svy3 age2-age13

 su $demo
 
 
 file open tb2 using "${output}Check_bootstrap.tex", write replace
**************
***Programs***
**************
// MELINDA'S COMPLIERS PROGRAM //

program compliers, rclass

reg D Z $demo
sca fs = _b[Z] // first stage: the effect of Z on D ==> the prob of retiring if elig for retirement = COMPLIERS
sca fs_se = _se[Z]

*P[D=1] ==> COMPLIERS + ALWAYS-TAKER
mean D
sca pd = _b[D]

*P[Z=1]
mean Z
sca pz = _b[Z]
sca N = _N

sca P_AT = round(pd-fs*pz,0.001) //pd*(1-(fs*pz)/pd)
sca P_Com = round(fs,0.001)
sca P_Tr_COM = round(fs*pz,0.001) //pd*(fs*pz)/pd
sca P_NoTr_COM = round((1-pz)*fs,0.001) //(1-pd)*(1-pz)*fs/(1-pd)
sca P_NT = round((1-pd) - (1-pz)*fs,0.001) //(1-pd)*(1- (1-pz)*fs/(1-pd))
sca pd = round(pd,0.001)
sca pz = round(pz,0.001)

end



// K-Weight Program //
program Kweight, rclass

*P[D=1] ==> COMPLIERS + ALWAYS-TAKER
qui mean D
sca pd = _b[D]

*P[Z=1]
qui mean Z
sca pz = _b[Z]
sca N = _N

** Prob by LATE-Group
qui mean D, over(Z)
	sca pC = _b[0] //pC is defined as P(D=1|Z=0) ==> Always Taker Prob
	
	sca pI = _b[1] //pI is defined as P(D=1|Z=1) ==> ALways Taker + Complier
	sca P_COM =pI-pC
	sca P_TC = (pI-pC)*pz
	sca P_UC = (pI-pC)*(1-pz)	
	sca P_AT =pC
	sca P_NT =1-pI	//P(D=0|Z=1)


foreach v in svy3_own_health_poor svy3_sphlthpoor svy3_enough_money {

* Mean for all
qui su `v'  
sca `v'_mean_all = `r(mean)'

** Mean by LATE-Group
qui mean `v', over(D Z)	

	sca `v'_mean_AT = _b[_subpop_3] //Mean for always takers
	sca `v'_mean_ATTC = _b[_subpop_4] //Mean for always takers and treated compliers
	sca `v'_mean_NTUC = _b[_subpop_1] //Mean for never takers and untreated compliers		
	sca `v'_mean_NT = _b[_subpop_2] //Mean for never takers
			
* Mean by treatment
qui mean `v', over(D)  
	sca `v'_mean_UT = _b[0]
	sca `v'_mean_T = _b[1]

*** Calculate the compliers average
	sca `v'_mean_C = (1/(pI-pC))*(`v'_mean_all - pC*`v'_mean_AT - (1-pI)*`v'_mean_NT)	
		sca `v'_mean_TC = (1/(pI - pC))*(pI*`v'_mean_ATTC - pC*`v'_mean_AT) // Calculate the treated compliers average 
		sca `v'_mean_UC = (1/(pI - pC))*((1-pC)*`v'_mean_NTUC - (1-pI)*`v'_mean_NT) // Calculate the untreated compliers average 	
	
*** Returns
foreach n in mean_all mean_AT mean_C mean_TC mean_UC mean_NT {
return sca `v'_`n' = `v'_`n' //round(`n',0.001)
	}
return sca `v'_di_A_N = `v'_mean_AT - `v'_mean_NT
return sca `v'_di_A_C = `v'_mean_AT - `v'_mean_C
return sca `v'_di_N_C = `v'_mean_NT - `v'_mean_C
}
*file write tb2 (svy3_own_health_poor_mean_AT) _n
foreach n in pI pC P_COM P_TC P_UC P_AT P_NT  N pz pd {
return sca `n' = `n' //round(`n',0.001)
	}
end


*** Kweight Bootstrap ***
program Kweight_bootstrap

foreach v in svy3_own_health_poor svy3_sphlthpoor svy3_enough_money {
foreach n in mean_all mean_AT mean_C mean_TC mean_UC mean_NT di_A_N di_A_C di_N_C {
local rclass `rclass' r(`v'_`n')
}
}
foreach n in pI pC P_COM P_TC P_UC P_AT P_NT  N pz pd {
local rclass `rclass' r(`n')
	}

bootstrap `rclass', reps(1000): Kweight // BOOTSTRAP FOR 1000 TIMES

qui return list 
mat list r(table)

local i = 0
foreach v in svy3_own_health_poor svy3_sphlthpoor svy3_enough_money {
foreach n in mean_all mean_AT mean_C mean_TC mean_UC mean_NT di_A_N di_A_C di_N_C  {
local ++i
sca `v'_b_`n' = _b[_bs_`i']
sca `v'_se_`n' = _se[_bs_`i']
	}
}
foreach n in pI pC P_COM P_TC P_UC P_AT P_NT N pz pd {
local ++i
sca b_`n' = _b[_bs_`i']
sca se_`n' = _se[_bs_`i']
	}

end




// Output //
** LATE Stats by variables

label values svy3_own_health_poor _svy3_own_health_poor
label define _svy3_own_health_poor 1 "Poor Health" 0 "Good Health", replace
label values svy3_sphlthpoor _svy3_sphlthpoor
label define _svy3_sphlthpoor 1 "Sp Poor" 0 "Sp Good", replace
label values svy3_enough_money _svy3_enough_money
label define _svy3_enough_money 0 "Not Enough" 1 "Saved Enough", replace

file open tbl using "${output}Compliance_Tbl2_NoControl.tex", write replace
file write tbl "%\begin{landscape}" _n "\begin{table}[h!]\centering" _n "\caption{Compliance Probability by Health Satus and Wealth}" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n "\resizebox{\columnwidth}{!}{%" _n

file write tbl "\begin{tabular}{l*{5}{c}}" _n
file write tbl "\hline \hline"  _n
file write tbl " & (1) & (2) & (3) & (4) & (5)  \\ " _n
file write tbl " &        &  Elig.   & Always     &             & Never \\ " _n
file write tbl " &Treated &  Normal  & Taker      &     Complier & Taker \\ " _n
file write tbl " & P(D=1) & P(Z=1)      & P(D_0=D_1=1) & P(D_0<D_1)  & P(D_0=D_1=0) \\ " _n
file write tbl "\hline " _n 
file write tbl "\multicolumn{6}{l}{\textbf{Subgroup}}\\" _n 
compliers
file write tbl " All & " (pd) " &" (pz) " &" (P_AT) " &" (P_Com) "&"  (P_NT) "\\ " _n

foreach v in svy3_own_health_poor svy3_sphlthpoor svy3_enough_money {
forvalues n = 0/1 {
preserve
keep if `v' == `n' & `v' <.
compliers 
file write tbl " `:label _`v' `n'' & " (pd) " &" (pz) " &" (P_AT) " &" (P_Com) "&"  (P_NT) "\\ " _n
restore
}
}
file write tbl "\hline \hline" _n 
*file write tbl "\multicolumn{6}{l}{\footnotesize The sample is derived from the NCRTS dataset and includes workers ages 52-65 who were actively employed as of May 2016.}\\" _n 
count
file write tbl "\multicolumn{6}{l}{\footnotesize Elig. for early retirement benefit is not included in the regression. }" _n 
file write tbl "\multicolumn{6}{l}{\footnotesize Sample size : " (_N) ".}" _n 
file write tbl "\end{tabular}" _n "}"_n "\end{table}"_n "%\end{landscape}" _n 
file close tbl


** K-Weighted Means by LATE Groups

file open tbl using "${output}Compliance_Tbl2_NoControl.tex", write append
file write tbl "%\begin{landscape}" _n "\begin{table}[h!]\centering" _n "\caption{Means by LATE Groups}" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n "\resizebox{\columnwidth}{!}{%" _n
file write tbl "\begin{tabular}{l*{6}{c}}" _n
file write tbl "\hline \hline"  _n
file write tbl " & (1) & (2) & (3) & (4) & (5) & (6) \\ " _n
file write tbl " &              & Always       &  Never       & Diff     & Diff      & Diff  \\ " _n
file write tbl " & Complier     & Taker        &  Taker       & AT \& NT & AT \& Com & NT \& Com \\ " _n
file write tbl " & P(D_0<D_1)   & P(D_0=D_1=1) & P(D_0=D_1=0) &          &           &          \\ " _n

file write tbl "\hline " _n 
file write tbl "\multicolumn{7}{l}{\textbf{Characteristics}} \\" _n 

Kweight_bootstrap

foreach v in svy3_own_health_poor svy3_sphlthpoor svy3_enough_money {
foreach g in D Z {
mean `v' if `g' == 1 & `v' <.
sca mean_`g'_1 = _b[`v']
sca se_`g'_1 = _se[`v']
}
foreach n in mean_all mean_AT mean_C mean_TC mean_UC mean_NT di_A_N di_A_C di_N_C  {

			local `v'_p_`n' "$^{\sym{***}}$"
			
			if (`v'_b_`n'+invnormal(.005)*`v'_se_`n')<=0 & (`v'_b_`n'+invnormal(.995)*`v'_se_`n')>=0 {
				local `v'_p_`n' "$^{\sym{**}}$"
			} 
			if (`v'_b_`n'+invnormal(.025)*`v'_se_`n')<=0 & (`v'_b_`n'+invnormal(.975)*`v'_se_`n')>=0 {
				local `v'_p_`n' "$^{\sym{*}}$"
			}
			if (`v'_b_`n'+invnormal(.05)*`v'_se_`n')<=0 & (`v'_b_`n'+invnormal(.95)*`v'_se_`n')>=0 {
				local `v'_p_`n' " "			
			}
file write tb2 "`v'_p_`n' (99):"(`v'_b_`n'+invnormal(.005)*`v'_se_`n') ":" (`v'_b_`n'+invnormal(.995)*`v'_se_`n') _n	
file write tb2 "`v'_p_`n' (95):"(`v'_b_`n'+invnormal(.025)*`v'_se_`n') ":" (`v'_b_`n'+invnormal(.975)*`v'_se_`n') _n		
file write tb2 "`v'_p_`n' (90):"(`v'_b_`n'+invnormal(.05)*`v'_se_`n') ":" (`v'_b_`n'+invnormal(.95)*`v'_se_`n') _n				
			}

file write tbl " `:label _`v' 1' & "  (round(`v'_b_mean_C,0.001)) "``v'_p_mean_C'  &" (round(`v'_b_mean_AT,0.001)) "``v'_p_mean_AT'  &"  (round(`v'_b_mean_NT,0.001)) "``v'_p_mean_NT'  &" (round(`v'_b_di_A_N,0.001)) "``v'_p_di_A_N'  &" (round(`v'_b_di_A_C,0.001)) "``v'_p_di_A_C' &" (round(`v'_b_di_N_C,0.001))  "``v'_p_di_N_C' \\ " _n
file write tbl "  & (" (round(`v'_se_mean_C,0.001)) ") &(" (round(`v'_se_mean_AT,0.001)) ") &("  (round(`v'_se_mean_NT,0.001)) ") &(" (round(`v'_se_di_A_N,0.001)) ") &(" (round(`v'_se_di_A_C,0.001)) ") &(" (round(`v'_se_di_N_C,0.001))  ") \\ " _n
}
count
file write tbl "\hline " _n 
file write tbl " Estimated Portion  & " (round(b_P_COM,0.001))  " &  " (round(b_P_AT,0.001)) " &  " (round(b_P_NT,0.001)) " & & &  \\ " _n
file write tbl " Estimated Sample Size  &  " (round(_N*b_P_COM,0.1)) " &  " (round(_N*b_P_AT,0.1)) " &  "  (round(_N*b_P_NT,0.1)) " & & &  \\ " _n
file write tbl "\hline \hline" _n 
file write tbl "\multicolumn{7}{l}{\footnotesize The sample is derived from the NCRTS dataset and includes workers ages 52-65 who were actively employed as of May 2016.}\\" _n 
file write tbl "\multicolumn{7}{l}{\footnotesize The sample size is " (_N) ".}" _n 
file write tbl "\end{tabular}" _n "}"_n "\end{table}"_n "%\end{landscape}" _n 
file close _all
 
 
log close _all 
exit







/*
file open tbl using "${output}Compliance_Tbl2.tex", write replace
file write tbl "%\begin{landscape}" _n "\begin{table}[h!]\centering" _n "\caption{Compliance Probability by Health Satus and Wealth}" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n "\resizebox{\columnwidth}{!}{%" _n

file write tbl "\begin{tabular}{l*{7}{c}}" _n
file write tbl "\hline \hline"  _n
file write tbl " & (1) & (2) & (3) & (4) & (5) & (6) & (7) \\ " _n
file write tbl " &        &  Elig.   & Always     &              & Treated & Untreated & Never \\ " _n
file write tbl " &Treated &  Normal  & Taker      &     Complier &Complier & Complier & Taker \\ " _n
file write tbl " & P(D=1) & P(Z=1)      & P(D_0=D_1=1) & P(D_0<D_1) &P(D_0<D_1=D) & P(D=D_0<D_1)  & P(D_0=D_1=0) \\ " _n
file write tbl "\hline \\" _n 

compliers
file write tbl " All & " (pd) " &" (pz) " &" (P_AT) " &" (P_Com) "&" (P_Tr_COM) "&" (P_NoTr_COM) " &" (P_NT) "\\ " _n

foreach v in svy3_own_health_poor svy3_sphlthpoor svy3_enough_money {
forvalues n = 0/1 {
preserve
keep if `v' == `n' & `v' <.
compliers 
file write tbl " `:label _`v' `n'' & " (pd) " &" (pz) " &" (P_AT) " &" (P_Com) "&" (P_Tr_COM) "&" (P_NoTr_COM) " &" (P_NT) "\\ " _n
restore
}
}
file write tbl "\hline \hline" _n 
file write tbl "\multicolumn{8}{l}{\footnotesize The sample is derived from the NCRTS dataset and includes workers ages 52-65 who were actively employed as of May 2016.}\\" _n 
count
file write tbl "\multicolumn{8}{l}{\footnotesize The sample size is " (_N) ".}" _n 
file write tbl "\end{tabular}" _n "}"_n "\end{table}"_n "%\end{landscape}" _n 
file close tbl



file open tbl using "${output}Compliance_Tbl2.tex", write append
file write tbl "%\begin{landscape}" _n "\begin{table}[h!]\centering" _n "\caption{Means by LATE Groups}" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n "\resizebox{\columnwidth}{!}{%" _n
file write tbl "\begin{tabular}{l*{9}{c}}" _n
file write tbl "\hline \hline"  _n
file write tbl " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) & (9) \\ " _n
file write tbl " &       &        &  Elig.   & Always     &              & Never & Diff & Diff & Diff  \\ " _n
file write tbl " & All  &Treated &  Normal  & Taker      &     Complier & Taker & AT \& NT & AT \& Com & NT \& Com \\ " _n
file write tbl " &      & P(D=1) & P(Z=1)      & P(D_0=D_1=1) & P(D_0<D_1) & P(D_0=D_1=0) & & & \\ " _n

file write tbl "\hline \\" _n 
file write tbl "\multicolumn{10}{l}{\textbf{Characteristics}} \\" _n 

Kweight_bootstrap

foreach v in svy3_own_health_poor svy3_sphlthpoor svy3_enough_money {
foreach g in D Z {
mean `v' if `g' == 1 & `v' <.
sca mean_`g'_1 = _b[`v']
sca se_`g'_1 = _se[`v']
}
foreach n in mean_all mean_AT mean_C mean_TC mean_UC mean_NT di_A_N di_A_C di_N_C  {

			local `v'_p_`n' "$^{\sym{***}}$"
			
			if (`v'_b_`n'+invnormal(.005)*`v'_se_`n')<=0 & (`v'_b_`n'+invnormal(.995)*`v'_se_`n')>=0 {
				local `v'_p_`n' "$^{\sym{**}}$"
			} 
			if (`v'_b_`n'+invnormal(.025)*`v'_se_`n')<=0 & (`v'_b_`n'+invnormal(.975)*`v'_se_`n')>=0 {
				local `v'_p_`n' "$^{\sym{*}}$"
			}
			if (`v'_b_`n'+invnormal(.05)*`v'_se_`n')<=0 & (`v'_b_`n'+invnormal(.95)*`v'_se_`n')>=0 {
				local `v'_p_`n' " "			
			}
			}
file write tb2 "`v'_p_`n' (99):"(`v'_b_`n'+invnormal(.005)*`v'_se_`n') ":" (`v'_b_`n'+invnormal(.995)*`v'_se_`n') _n	
file write tb2 "`v'_p_`n' (95):"(`v'_b_`n'+invnormal(.025)*`v'_se_`n') ":" (`v'_b_`n'+invnormal(.975)*`v'_se_`n') _n		
file write tb2 "`v'_p_`n' (90):"(`v'_b_`n'+invnormal(.05)*`v'_se_`n') ":" (`v'_b_`n'+invnormal(.95)*`v'_se_`n') _n	

file write tbl " `:label _`v' 1' & " (round(`v'_b_mean_all,0.001)) " &" (round(mean_D_1,0.001)) " &"(round(mean_Z_1,0.001)) " &"(round(`v'_b_mean_AT,0.001)) "``v'_p_mean_AT'  &" (round(`v'_b_mean_C,0.001)) "``v'_p_mean_C'  &" (round(`v'_b_mean_NT,0.001)) "``v'_p_mean_NT'  &" (round(`v'_b_di_A_N,0.001)) "``v'_p_di_A_N'  &" (round(`v'_b_di_A_C,0.001)) "``v'_p_di_A_C' &" (round(`v'_b_di_N_C,0.001))  "``v'_p_di_N_C' \\ " _n
file write tbl "  & (" (round(`v'_se_mean_all,0.001)) ") &("(round(se_D_1,0.001)) ") &("(round(se_Z_1,0.001)) ") &(" (round(`v'_se_mean_AT,0.001)) ") &(" (round(`v'_se_mean_C,0.001)) ") &(" (round(`v'_se_mean_NT,0.001)) ") &(" (round(`v'_se_di_A_N,0.001)) ") &(" (round(`v'_se_di_A_C,0.001)) ") &(" (round(`v'_se_di_N_C,0.001))  ") \\ " _n
*file write tbl "  &``v'_p_mean_all'  & & & ``v'_p_mean_AT' & ``v'_p_mean_C' & ``v'_p_mean_NT' & ``v'_p_di_A_N' & ``v'_p_di_A_C' & ``v'_p_di_N_C'   \\ " _n
}
file write tbl "\hline " _n 
file write tbl " Estimated Portion  & 1  &  "(round(b_pd,0.001)) " &  "(round(b_pz,0.001)) " &  " (round(b_P_AT,0.001)) " &  " (round(b_P_COM,0.001)) " &  "  (round(b_P_NT,0.001)) " & & &  \\ " _n
file write tbl " Estimated Sample Size  & 1  &  "(round(b_pd,0.001)) " &  "(round(b_pz,0.001)) " &  " (round(b_P_AT,0.001)) " &  " (round(b_P_COM,0.001)) " &  "  (round(b_P_NT,0.001)) " & & &  \\ " _n
file write tbl "\hline \hline" _n 
file write tbl "\multicolumn{10}{l}{\footnotesize The sample is derived from the NCRTS dataset and includes workers ages 52-65 who were actively employed as of May 2016.}\\" _n 
count
file write tbl "\multicolumn{10}{l}{\footnotesize The sample size is " (_N) ".}" _n 
file write tbl "\end{tabular}" _n "}"_n "\end{table}"_n "%\end{landscape}" _n 
file close _all





** K-Weighted Means by LATE Groups

file open tbl using "output/Compliance_Tbl2.tex", write append
file write tbl "%\begin{landscape}" _n "\begin{table}[h!]\centering" _n "\caption{Means by LATE Groups}" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n "\resizebox{\columnwidth}{!}{%" _n
file write tbl "\begin{tabular}{l*{8}{c}}" _n
file write tbl "\hline \hline"  _n
file write tbl " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\ " _n
file write tbl " &       &        &  Elig.   & Always     &              & Treated & Untreated & Never \\ " _n
file write tbl " & All  &Treated &  Normal  & Taker      &     Complier &Complier & Complier & Taker \\ " _n
file write tbl " &      & P(D=1) & P(Z=1)      & P(D_0=D_1=1) & P(D_0<D_1) &P(D_0<D_1=D) & P(D=D_0<D_1)  & P(D_0=D_1=0) \\ " _n

file write tbl "\hline \\" _n 

Kweight_bootstrap

foreach v in svy3_own_health_poor svy3_sphlthpoor svy3_enough_money {
foreach g in D Z {
mean `v' if `g' == 1 & `v' <.
sca mean_`g'_1 = _b[`v']
sca se_`g'_1 = _se[`v']
}
file write tbl " `:label _`v' 1' & " (round(mean_D_1,0.001)) " &"(round(mean_Z_1,0.001)) " &"(round(`v'_b_mean_all,0.001)) " &" (round(`v'_b_mean_AT,0.001)) " &" (round(`v'_b_mean_C,0.001)) " &" (round(`v'_b_mean_TC,0.001)) " &" (round(`v'_b_mean_UC,0.001)) " &" (round(`v'_b_mean_NT,0.001))  "\\ " _n
file write tbl "  & (" (round(se_D_1,0.001)) ") &("(round(se_Z_1,0.001)) ") &("(round(`v'_se_mean_all,0.001)) ") &(" (round(`v'_se_mean_AT,0.001)) ") &(" (round(`v'_se_mean_C,0.001)) ") &(" (round(`v'_se_mean_TC,0.001)) ") &(" (round(`v'_se_mean_UC,0.001)) ") &(" (round(`v'_se_mean_NT,0.001))  ") \\ " _n
}
file write tbl "\hline " _n 
file write tbl " Portion (Estimated) & 1  &  "(round(b_pd,0.001)) " &  "(round(b_pz,0.001)) " &  " (round(b_P_AT,0.001)) " &  " (round(b_P_COM,0.001)) " &  " (round(b_P_TC,0.001)) "  &  " (round(b_P_UC,0.001)) "  &  " (round(b_P_NT,0.001)) "   \\ " _n
file write tbl "\hline \hline" _n 
file write tbl "\multicolumn{9}{l}{\footnotesize The sample is derived from the NCRTS dataset and includes workers ages 52-65 who were actively employed as of May 2016.}" _n 
count
file write tbl "\multicolumn{9}{l}{\footnotesize The sample size is " (_N) ".}" _n 
file write tbl "\end{tabular}" _n "}"_n "\end{table}"_n "%\end{landscape}" _n 
file close tbl

// Output Program //

** Compliers Stats by variables
program output1

args v   AT Com NT AT_poor_0 Com_poor_0 NT_poor_0 AT_poor_1 Com_poor_1 NT_poor_1 N poor_0 poor_1

local x : variable label `v'

file open tbl using "output/Compliance_Tbl2.tex", write append
file write tbl "%\begin{landscape}" _n "\begin{table}[h!]\centering" _n "\caption{LATE Group Stats by `x'}" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n "\resizebox{\columnwidth}{!}{%" _n
file write tbl "\begin{tabular}{l*{3}{c}}" _n
file write tbl "\hline \hline"  _n
file write tbl " & (1) & (2) & (3) \\ " _n
file write tbl " &      & `x'  & `x' \\ " _n
file write tbl " &  All &  == 0 &  == 1 \\ " _n
file write tbl "\hline \\" _n 
file write tbl "Always Taker & " (`AT') " &" (`AT_poor_0') "&" (`AT_poor_1') "\\ " _n
file write tbl "Complier & " (`Com') " & "(`Com_poor_0') "&" (`Com_poor_1') "\\ " _n
file write tbl "Never Taker & " (`NT') " &" (`NT_poor_0') "&" (`NT_poor_1') "\\ " _n
file write tbl "\hline \\" _n 
file write tbl "Observations &" (`N') "&" (`poor_0') "&" (`poor_1') "\\ " _n
file write tbl "\hline \hline" _n 
file write tbl "\end{tabular}" _n "}"_n "\end{table}"_n "%\end{landscape}" _n 
file close tbl
end

** K-Weighted Means by LATE Groups
program output2

args v mean_all AT Com NT mean_AT mean_C mean_NT

local x : variable label `v'

file open tbl using "output/Compliance_Tbl2.tex", write append
file write tbl "%\begin{landscape}" _n "\begin{table}[h!]\centering" _n "\caption{Means by LATE Groups}" _n "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}" _n "\resizebox{\columnwidth}{!}{%" _n
file write tbl "\begin{tabular}{l*{4}{c}}" _n
file write tbl "\hline \hline"  _n
file write tbl " & (1) & (2) & (3) & (4) \\ " _n
file write tbl " &      & Always  &  & Never    \\ " _n
file write tbl " &  All &  Takers &  Compliers  & Takers    \\ " _n
file write tbl " Portion (Estimated) & 1  &  " (`AT') " &  " (`Com') "  &  " (`NT') "   \\ " _n
file write tbl " `x' & " (`poor_1') "  &  " (`mean_AT') " & " (`mean_C') "   &   " (`mean_NT') "  \\ " _n
file write tbl "\hline \hline" _n 
file write tbl "\end{tabular}" _n "}"_n "\end{table}"_n "%\end{landscape}" _n 
file close tbl
end 
 

file open tbl using "output/Compliance_Tbl2.tex", write replace
file write tbl ""
file close tbl
 
********************
*** Compliance Table
********************

/**** HEALTH STATUS ****/
*** Own Health ****
di "svy3_own_health_poor"

lab var svy3_own_health_poor "Own Health Poor"

forvalues n = 0/1 {
preserve
keep if svy3_own_health_poor == `n'
compliers 
sca poor_`n' = r(N)
sca AT_poor_`n' = round(r(P_AT),0.001)
sca Com_poor_`n' = round(r(P_Com),0.001)
sca NT_poor_`n' = round(r(P_NT),0.001)
restore
}

compliers

sca N = r(N)
sca AT = round(r(P_AT),0.001)
sca Com = round(r(P_Com),0.001)
sca NT = round(r(P_NT),0.001)

output1 svy3_own_health_poor AT Com NT AT_poor_0 Com_poor_0 NT_poor_0 AT_poor_1 Com_poor_1 NT_poor_1 N poor_0 poor_1

*** SPOUSE'S HEALTH STATUS ***
di "svy3_own_health_poor"

lab var svy3_sphlthpoor "Spouse Health Poor"

forvalues n = 0/1 {
preserve
keep if svy3_married == 1
keep if svy3_sphlthpoor == `n'
compliers 
sca poor_`n' = r(N)
sca AT_poor_`n' = round(r(P_AT),0.001)
sca Com_poor_`n' = round(r(P_Com),0.001)
sca NT_poor_`n' = round(r(P_NT),0.001)
restore
}

compliers

sca N = r(N)
sca AT = round(r(P_AT),0.001)
sca Com = round(r(P_Com),0.001)
sca NT = round(r(P_NT),0.001)

output1 svy3_sphlthpoor AT Com NT AT_poor_0 Com_poor_0 NT_poor_0 AT_poor_1 Com_poor_1 NT_poor_1 N poor_0 poor_1

*** Health Expenses a concern /Saved Enough for Health Expenses ***
di "svy3_enough_money"

lab var svy3_enough_money "Saved Enough"

forvalues n = 0/1 {
preserve
keep if svy3_enough_money == `n'
compliers 
sca poor_`n' = r(N)
sca AT_poor_`n' = round(r(P_AT),0.001)
sca Com_poor_`n' = round(r(P_Com),0.001)
sca NT_poor_`n' = round(r(P_NT),0.001)
restore
}

compliers

sca N = r(N)
sca AT = round(r(P_AT),0.001)
sca Com = round(r(P_Com),0.001)
sca NT = round(r(P_NT),0.001)

output1 svy3_enough_money AT Com NT AT_poor_0 Com_poor_0 NT_poor_0 AT_poor_1 Com_poor_1 NT_poor_1 N poor_0 poor_1

log close _all
