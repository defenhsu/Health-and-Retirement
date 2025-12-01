/*This file ...*/

*************************************************
* Setup
*************************************************

global Y_num_seed = 	6574358

* Define the seeds for the variables other than the outcomes
foreach v of local statsvars {
	global `v'_seed = 6574360
}


* Number of bootstrap replications
local reps = 1000

/* In Kowaski(2021), she draw boostrap sample of same sampe size. And the first replication of the bootstrap process has no re-sampling; in other 
 words the first replication always runs on the full original non-bootstrapped 
 sample. */

set matsize 2000
	
	
*************************************************
* RUN CODE			  		*
*************************************************
	
* Start loop for variables here
foreach v of local statsvars {

	* Set the seed for each variable separately
	set seed $`v'_seed

	* Define a separate matrix for each covariate/predicted outcome/outcome 
	* as an output matrix
	matrix define boot_`v' = J(`reps', 27, .)	

	* Initialize the local macro for renaming variables in the matrix
	local renamevars ""
	
*************************************************
* RUN TESTS			  		*
*************************************************
	
	* Start bootstrap replications here
	forval rep = 1/`reps' {
		
		preserve	
			
		* Initialize the iterator for matrix output
		local matrixiter = 1
		
		* Drop observations where the variable is missing
		* We do this before bootstrapping in order to ensure that each 
		* bootstrapping sample has the same sample size. In addition, 
		* this ensures that we do not oversample individuals with 
		* missing values when bootstrapping.
		qui drop if `v'==.				
		local obs = _N
		
		* Observations by D
		qui count if `D'==1
		local N_T = `r(N)'
		
		qui count if `D'==0
		local N_U = `r(N)'
		
		* Re-sample for bootstrap
		qui if `rep' > 1 {
			bsample
		}
		
		* Mean for all
		qui su `v'
		local mean_all = `r(mean)'
	
		* Mean for always takers
		qui su `v' if `D'==1 & Z==0 
		local mean_AT = `r(mean)'
		
		* Mean for always takers and treated early compliers
		qui su `v' if `D'==1 & Z ==1 
		local mean_ATETC = `r(mean)'	
		
		* Mean for always takers and treated early compliers and treated normal compliers
		qui su `v' if `D'==1 & Z == 2
		local mean_ATNTC = `r(mean)'
		
		* Mean for never takers and untreated normal compliers	***	
		qui su `v' if `D'==0 & Z == 1 
		local mean_NTNUC = `r(mean)'
		
		* Mean for never takers and untreated early compliers and untreated normal compliers		
		qui su `v' if `D'==0 & Z ==0
		local mean_NTEUC = `r(mean)'
		
		* Mean for untreated individuals	
		qui su `v' if `D'==0
		local mean_UT = `r(mean)'
		
		* Mean for treated individuals	
		qui su `v' if `D'==1
		local mean_T = `r(mean)'
		
		* Mean for Never takers
		qui su `v' if `D'==0 & Z == 2 
		local mean_NT = `r(mean)'
		
		* Compute P(D = 1 | Z^{Early} =0, X) ==> Prob of Treatment in the Control Group
		quietly su `D' if Z == 0 
		local p_always  = `r(mean)'
			
		* Compute P(D = 1 | Z^{Early} =1, X) ==> Prob of Treatment in the Intervention Group 1 (Early Retirement)
		quietly su `D' if Z ==1 
		local p_complier_early = `r(mean)'

		* Compute P(D = 1 | Z^{Normal} =1, X) ==> Prob of Treatment in the Intervention Group 2 (Normal Retirement)
		quietly su `D' if Z ==2 
		local p_complier_normal = `r(mean)'
		

		* Define fraction of compliers for early retirement
		local N_EC = (`p_complier_early'-`p_always')*_N
		
		* Define fraction of compliers for normal retirement
		local N_NC = (`p_complier_normal'-`p_complier_early')*_N
		
		* Number of always takers and never takers
		local N_AT = _N*`p_always'
		local N_NT = _N*(1-`p_complier_normal')
		
		
		* Calculate the treated early compliers average 
		local mean_ETC = (1/(`p_complier_early' - `p_always'))*(`p_complier_early'*`mean_ATETC' - `p_always'*`mean_AT')
		
		* Calculate the treated normal compliers average 
		local mean_NTC = (1/(`p_complier_normal' - `p_complier_early'))*(`p_complier_normal'*`mean_ATNTC' - `p_complier_early'*`mean_ATETC')

		* Calculate the untreated early compliers average 
		local mean_EUC = (1/(`p_complier_early' - `p_always'))*((1-`p_always')*`mean_NTEUC' - (1-`p_complier_early')*`mean_NTNUC')
		
		* Calculate the untreated normal compliers average 
		local mean_NUC = (1/(`p_complier_normal' - `p_complier_early'))*((1-`p_complier_early')*`mean_NTNUC' - (1-`p_complier_normal')*`mean_NT')
		
		* Calculate the early compliers average
		qui su `v'
		local mean_EC = (1/(`p_complier_early' - `p_always'))*(`r(mean)' - `p_always'*`mean_AT' - (1-`p_complier_early')*`mean_NTNUC')
		
		* Calculate the normal compliers average
		qui su `v'
		local mean_NC = (1/(`p_complier_normal' - `p_complier_early'))*(`r(mean)' - `p_complier_early'*`mean_ATETC' - (1-`p_complier_normal')*`mean_NT')
		
		* Output
		matrix boot_`v'[`rep', `matrixiter'] = `p_always'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' p_always"
		
		matrix boot_`v'[`rep', `matrixiter'] = `p_complier_early'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' p_complier_early"
		
		matrix boot_`v'[`rep', `matrixiter'] = `p_complier_normal'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' p_complier_normal"
		
		matrix boot_`v'[`rep', `matrixiter'] = `mean_all'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' mean_all"
		
		matrix boot_`v'[`rep', `matrixiter'] = `obs'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' N"
		
		matrix boot_`v'[`rep', `matrixiter'] = `N_AT'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' N_AT"
		
		matrix boot_`v'[`rep', `matrixiter'] = `N_NT'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' N_NT"
		
		matrix boot_`v'[`rep', `matrixiter'] = `N_NC'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' N_NC"
		
		
		matrix boot_`v'[`rep', `matrixiter'] = `N_EC'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' N_EC"
		
		
		matrix boot_`v'[`rep', `matrixiter'] = `mean_AT'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' mean_AT"
		
		matrix boot_`v'[`rep', `matrixiter'] = `mean_EC'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' mean_EC"
		
		matrix boot_`v'[`rep', `matrixiter'] = `mean_NC'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' mean_NC" 
		
		matrix boot_`v'[`rep', `matrixiter'] = `mean_NT'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' mean_NT"
		
		
		matrix boot_`v'[`rep', `matrixiter'] = `mean_AT'-`mean_EC'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' AT_EC_Diff"
		
		matrix boot_`v'[`rep', `matrixiter'] = `mean_EC'-`mean_NC'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' EC_NC_Diff"
		
		matrix boot_`v'[`rep', `matrixiter'] = `mean_NC'-`mean_NT'
		local ++matrixiter
		if `rep'==1 local renamevars "`renamevars' NC_NT_Diff"
		
	restore	

	} // bootstrap loop ends here

	* Save the output matrix	
	svmat double boot_`v'
		
	* Rename variables
	local i=1		
	foreach var of local renamevars {			
		rename boot_`v'`i' `v'_`var'
		local ++i
	}
	
	qui missings dropvars boot*, force
	
	local x : variable label `v'
	
	qui mean  `v'_mean_all `v'_mean_AT `v'_mean_EC `v'_mean_NC `v'_mean_NT `v'_AT_EC_Diff `v'_EC_NC_Diff `v'_NC_NT_Diff 
	file write tbl "`x' & " %4.3f (_b[`v'_mean_all])  "&" %4.3f (_b[`v'_mean_AT])  "&" %4.3f (_b[`v'_mean_EC]) "&" %4.3f (_b[`v'_mean_NC]) "&" %4.3f (_b[`v'_mean_NT]) "&" %4.3f (_b[`v'_AT_EC_Diff]) "&" %4.3f (_b[`v'_EC_NC_Diff]) "&" %4.3f (_b[`v'_NC_NT_Diff]) "\\"  _n 
	
	file write tbl "  "
	foreach var of varlist `v'_mean_all `v'_mean_AT `v'_mean_EC `v'_mean_NC `v'_mean_NT {	
		qui su `var'
		sca se = r(sd)
		file write tbl " & (" %4.3f (se) ")" 
		}
		
	foreach var of varlist `v'_AT_EC_Diff `v'_EC_NC_Diff `v'_NC_NT_Diff {	
		qui su `var'
		sca se = r(sd)
		
			*** Calculate and output the 95% confidence intervals				
			_pctile `var', p(2.5)
			local ci_95_lower = `r(r1)'
			
			_pctile `var', p(97.5)
			local ci_95_upper = `r(r1)'
		
			* Calculate and output the 99% confidence intervals			
			_pctile `var', p(0.5)
			local ci_99_lower = `r(r1)'
			
			_pctile `var', p(99.5)
			local ci_99_upper = `r(r1)'
			
				
			* Calculate and output the 90% confidence intervals			
			_pctile `var', p(5)
			local ci_90_lower = `r(r1)'

			_pctile `var', p(95)
			local ci_90_upper = `r(r1)'
			

				
			* Calculate and output the significance stars for H0 = 0
			* We check each bootstrapped confidence interval (99%, 
			* 95%, and 90%, as computed above) to see if it contains 
			* zero. If a given confidence interval contains zero,
			* then the estimate is not significant at that level
			
			local pval_0 "***"
			
			if `ci_99_lower'<=0 & `ci_99_upper'>=0 {
				local pval_0 "**"
			} 
			if `ci_95_lower'<=0 & `ci_95_upper'>=0 {
				local pval_0 "*"
			}
			if `ci_90_lower'<=0 & `ci_90_upper'>=0 {
				local pval_0 ""
			}
				
			* Calculate and output the significance stars for H0 = 1
			* We check each bootstrapped confidence interval (99%,
			* 95%, and 90%, as computed above) to see if it 	
			* contains 1. If a given confidence interval contains 1, 
			* then the estimate is not significant at that level
			
			local pval "***"
			
			if `ci_99_lower'<=1 & `ci_99_upper'>=1 {
				local pval_1 "**"
			} 
			if `ci_95_lower'<=1 & `ci_95_upper'>=1 {
				local pval_1 "*"
			}
			if `ci_90_lower'<=1 & `ci_90_upper'>=1 {
				local pval_1 ""
			}
			
			file write tbl " & (" %4.3f (se) ") "  //(`pval_0') (`pval_1')
			
		}
				
	file write tbl " \\ " _n
	
	di "`v' done"
}

