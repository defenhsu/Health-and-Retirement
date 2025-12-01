*********************************************************
** compare s3_pooled_actives and s3_pooled_actives_new **
*********************************************************

clear
capture log close _all
set more off
pause on

cd "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs"

global date "$S_DATE"
log using "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\Programs\Logs\MakeData_Admin3_YOS_$date", replace text name("Ariel")
global raw "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\RawData\"
global working "G:\My Drive\NCRTS Retirement Timing\Retirement_Timing\WorkingData\"
cls
**********************************************************************
use "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\RawData\SurveyData\s3_pooled_actives_new.dta", clear

renvars _all ,subst(s3_ )

tempfile s3_pooled_actives_new
save `s3_pooled_actives_new'

use "G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\RawData\SurveyData\s3_pooled_actives.dta"

cf2 _all using `s3_pooled_actives_new', sortvars(individual_id) v all

/*Conclusion: 
The only different between s3_pooled_actives_new and s3_pooled_actives is just variable names
all variables with the form of v* has been change to s3_v* in new file.

*/

*replace v1 = "." in 1 // code to help checking if cf2 can identify mismatch in obervations not just in vars name
*replace v1 = "." in 2

log close _all
