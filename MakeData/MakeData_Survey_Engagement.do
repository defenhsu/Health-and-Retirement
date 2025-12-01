local i = 1

gen num_missing = 0

gen num_dk = 0

replace num_missing = num_missing + 1 if v163 == -99 | v163 ==. // not string

foreach x of varlist plan_stop_mo-v23 v39-v45 v82-v88 v111 v114-v118 v136-v141 v164-v168 v175-v182 enter_drawing {   // 

*di "`x'"
count if  `x' == "-99" | `x' == "" | `x' == "N/A"
*gen flag_`x' = 1 if (r(N) <1000)) 

replace num_missing = num_missing + 1 if `x' == "-99" | `x' == "" | `x' == "N/A" 

replace num_dk = num_dk + 1 if `x' == "Don't know"  

*drop num_miss_flag

local ++i
di `i'
}



*** 1.5 Which of the following are important factors in your decision about when to retire? Check all that apply.

gen num_uncheck = 0

foreach x of varlist v25-v38 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if `x' == "-99" | `x' == "" | `x' == "N/A" 
}

replace num_missing = num_missing + 1 if num_uncheck == 14 

drop num_uncheck


*** Why are you not planning to work after retiring from your government job? Check all that apply.

gen num_uncheck = 0

foreach x of varlist v46-v52 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if (`x' == "-99" | `x' == "" | `x' == "N/A") & strpos(v45, "Completely retire") 
}

replace num_missing = num_missing + 1 if num_uncheck == 7 

drop num_uncheck


*** How many hours do you plan to work a week after retiring from your government job?

gen num_uncheck = 0

foreach x of varlist v54 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if `x' == "-99" | `x' == "" | `x' == "N/A" & strpos(v45, "Work for pay") 
}

replace num_missing = num_missing + 1 if num_uncheck == 1 

drop num_uncheck


*** Why do you plan to work after retiring from your government job?

gen num_uncheck = 0

foreach x of varlist v55-v58 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if (`x' == "-99" | `x' == "" | `x' == "N/A") & strpos(v45, "Work for pay") 
}

replace num_missing = num_missing + 1 if num_uncheck == 4 

drop num_uncheck


*** Are you engaging in any activities to prepare for post-retirement employment?

gen num_uncheck = 0

foreach x of varlist v60-v66 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if `x' == "-99" | `x' == "" | `x' == "N/A" 
}

replace num_missing = num_missing + 1 if num_uncheck == 7

drop num_uncheck


*** Please indicate whether you agree or disagree with each of the following statements

gen num_uncheck = 0

foreach x of varlist v69-v72 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if (`x' == "-99" | `x' == "" | `x' == "N/A") & strpos(v45, "Completely retire")  
}

replace num_missing = num_missing + 1 if num_uncheck == 4

drop num_uncheck


*** Which of the following income sources does your household expect to have in retirement?

gen num_uncheck = 0

foreach x of varlist v73-v77 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if `x' == "-99" | `x' == "" | `x' == "N/A" 
}

replace num_missing = num_missing + 1 if num_uncheck == 5

drop num_uncheck


***  Which of the following sources of information, if any, have you used when making important financial and retirement decisions? Check all that apply

gen num_uncheck = 0

foreach x of varlist v89-v97 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if `x' == "-99" | `x' == "" | `x' == "N/A" 
}

replace num_missing = num_missing + 1 if num_uncheck == 9

drop num_uncheck


***  Are you currently receiving Social Security benefit payments? (Check all that apply)

gen num_uncheck = 0

foreach x of varlist v98-v101 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if `x' == "-99" | `x' == "" | `x' == "N/A" 
}

replace num_missing = num_missing + 1 if num_uncheck == 4

drop num_uncheck


/****  Is your spouse/partner currently receiving any Social Security benefit payments?

gen num_uncheck = 0

foreach x of varlist v104-v108 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if `x' == "-99" | `x' == "" | `x' == "N/A" 
}

replace num_missing = num_missing + 1 if num_uncheck == 5

drop num_uncheck*/


***  Please indicate whether you are currently covered by any of the following types of insurance:

gen num_uncheck = 0

foreach x of varlist v119-v125 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if `x' == "-99" | `x' == "" | `x' == "N/A" 
}

replace num_missing = num_missing + 1 if num_uncheck == 7

drop num_uncheck


***  Please indicate whether your spouse/partner is currently covered by any of these types of insurance :

gen num_uncheck = 0

foreach x of varlist v126-v135 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if (`x' == "-99" | `x' == "" | `x' == "N/A") & svy3_married_partner==1
}

replace num_missing = num_missing + 1 if num_uncheck == 10

drop num_uncheck


***  Last year, were any children, parents, or other relatives dependent on you for more than half of their financial support? Check all that apply.

gen num_uncheck = 0

foreach x of varlist v142-v149 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if `x' == "-99" | `x' == "" | `x' == "N/A" 
}

replace num_missing = num_missing + 1 if num_uncheck == 8

drop num_uncheck


***  In a typical week, do you spend time caring for any of the following family members? Check all that apply

gen num_uncheck = 0

foreach x of varlist v150-v156 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if `x' == "-99" | `x' == "" | `x' == "N/A" 
}

replace num_missing = num_missing + 1 if num_uncheck == 7

drop num_uncheck


***  Approximately how many hours per week do you typically spend caring for each of the following family members?

gen num_uncheck = 0

foreach x of varlist v157-v162 { 

*di "`x'"

replace num_uncheck = num_uncheck + 1 if `x' == "-99" | `x' == "" | `x' == "N/A" 
}

replace num_missing = num_missing + 1 if num_uncheck == 6

drop num_uncheck

exit

foreach x of varlist v170-v196  { 

di "`x'"
tab `x',m
}
