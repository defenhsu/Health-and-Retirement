/*******************************************************************
This file survey 3 variables using survey 3 response from May 2016 

Important Output: Marital status, Number of children, Race, Education level, Health condition, Spouse employer health insurance, Own RHI, Life expectacy, Financial Literacy, Self reported Salary, Survey engagement, Total Wealth 

/*** 3/22/2023
Define "blank/other" categories for less important demographics:
- White, Black, Hispanic, and "Other" -- with the "other" category including anyone with missing values
- Educ_ba and Educ_blank -- set educ_ba = 0 if educ_blank == 1
- Num kids should include numkids_blank = 1 if missing, zeros imputed for dummies
- Set svy3_sphlthpoor = 0 if not married. */ 
*******************************************************************/

include "Step0_SetDirectory"
log using "${log}MakeData_Survey3_$date", replace text name("Ariel")

*****************************************************

use "${raw}SurveyData\s3_pooled_actives",clear // import survey 3 response(raw data)

*******************
*** Marital status 
*******************
*** No item-non response in v24
tab v24,m

gen _svy3_marital_status=.
replace _svy3_marital_status=1 if v24=="Married"
replace _svy3_marital_status=2 if v24=="Living with a partner"
replace _svy3_marital_status=3 if v24=="Separated"
replace _svy3_marital_status=4 if v24=="Divorced"
replace _svy3_marital_status=5 if v24=="Widowed"
replace _svy3_marital_status=6 if v24=="Never Married"
replace _svy3_marital_status=7 if v24=="" | v24=="-99" //Missing//
label var _svy3_marital_status "Marital Status"
label define _svy3_marital_status 1 "Married" 2 "Living with a partner" 3 "Separated" 4 "Divorced" 5 "Widowed" 6 "Never Married"  7 "missing"
label values  _svy3_marital_status _svy3_marital_status

*encode v24, gen(_svy3_mstat)

*gen svy3_married=_svy3_marital_status==1
*replace svy3_married=. if _svy3_marital_status==7
*lab var svy3_married "Married"

gen svy3_married_partner=_svy3_marital_status==1 | _svy3_marital_status==2
replace svy3_married_partner=. if _svy3_marital_status==7
lab var svy3_married_partner "Married"

tab v24 svy3_married_partner,m

***********************
*** Number of children
***********************
tab v141,m

gen _svy3_num_kids=0 if v141=="None"
forvalues i=1/5{
replace _svy3_num_kids=`i' if strpos(v141, "`i'")
}
replace _svy3_num_kids=. if v141=="-99" | v141==""

gen svy3_num_kids_12= _svy3_num_kids>=1 & _svy3_num_kids<=2 & _svy3_num_kids!=.
*replace svy3_num_kids_12 =. if v141=="-99" | v141=="" //*** 3/22/2023: Num kids should include numkids_blank = 1 if missing, zeros imputed for dummies
label var svy3_num_kids_12 "1-2 Kids"

gen svy3_num_kids_34= _svy3_num_kids>=3 & _svy3_num_kids!=.
*replace svy3_num_kids_34 =. if v141=="-99" | v141=="" //*** 3/22/2023: Num kids should include numkids_blank = 1 if missing, zeros imputed for dummies
label var svy3_num_kids_3 "3+ Kids"

gen svy3_num_kids_miss= (_svy3_num_kids==.)
label var svy3_num_kids_miss "Missing Data on Kids"

tab svy3_num_kids_12 svy3_num_kids_miss,m 
tab svy3_num_kids_34 svy3_num_kids_miss,m

  
*********
*** Race 
*********
**revisit this: Currently using v139: Do you consider yourself Hispanic/Latino?
tab v140,m
tab v139,m

gen svy3_race_white=strpos(v140, "White")
*replace svy3_race_white=. if v140=="" | v140=="-99"
replace svy3_race_white=0 if strpos(v139, "Yes")

gen svy3_race_black=strpos(v140, "African")
*replace svy3_race_black=. if v140=="" | v140=="-99"
replace svy3_race_black=0 if strpos(v139, "Yes")

gen svy3_race_hisp=0
replace svy3_race_hisp= 1 if (strpos(v140, "Hispanic") | strpos(v139, "Yes"))
*replace svy3_race_hisp=. if (v140=="" | v140=="-99") & (v139=="" | v139=="-99")
replace svy3_race_hisp=0 if (v139=="No") & svy3_race_hisp==1

/*gen svy3_race_blank=v140=="-99" | v140==""
replace svy3_race_blank=0 if svy3_race_blank==1 & v139~="-99"
replace svy3_race_blank=0 if svy3_race_blank==1 & v139~=""*/

gen svy3_race_other=1
replace svy3_race_other =0 if svy3_race_white==1 | svy3_race_black==1 | svy3_race_hisp==1
*replace svy3_race_other =1 if svy3_race_white==0 & svy3_race_black==0 & svy3_race_hisp==0 //& svy3_race_blank==0

label var svy3_race_white "White"
label var svy3_race_black "Black"
label var svy3_race_hisp "Hispanic"
label var svy3_race_other "Other Race"
*******************
*** Education level
*******************
tab v137,m

gen svy3_educ=.

replace svy3_educ=1 if strpos(v137, "Grade school") 
replace svy3_educ=2 if strpos(v137, "High school, no diploma") 
replace svy3_educ=3 if strpos(v137, "High school diploma, GED, or alternative credential") 
replace svy3_educ=4 if strpos(v137, "Some college credit, no degree") 

replace svy3_educ=5 if strpos(v137, "Associate's degree (e.g., AA, AS)") 
replace svy3_educ=6 if strpos(v137, "Bachelor's degree (e.g., BA, BS)")
replace svy3_educ=7 if strpos(v137, "Master's degree (e.g., MA, MS, MEng, MEd, MSW, MBA")
replace svy3_educ=8 if strpos(v137, "Professional degree or doctorate (e.g., MD, PhD, JD, DDS, LLB")
replace svy3_educ=9 if svy3_educ==. //Missing//

label define educ 1 "Grade school" 2 "High school, no diploma" 3 "High school diploma" 4 "Some college credit, no degree" 5 "Associate's degree" 6 "Bachelor"  7 "Master" 8 "Professional" 9 "Missing"
label values  svy3_educ educ

replace svy3_educ = . if (v137=="-99" |v137=="")
gen svy3_educ_blank= (v137=="-99" |v137=="") //svy3_educ==9

gen svy3_educ_ba=strpos(v137, "Bachelor") | strpos(v137, "Master") | strpos(v137, "Profession") | strpos(v137, "Grade school")
replace svy3_educ_ba = . if (v137=="-99" |v137=="")
label var svy3_educ_ba "College Degree"

tab svy3_educ v137, m
tab svy3_educ_ba v137, m

*** 3/22/2023: Educ_ba and Educ_blank -- set educ_ba = 0 if educ_blank == 1
tab svy3_educ_ba,m
replace svy3_educ_ba = 0 if svy3_educ_ba ==. 

********************
****Health condition :  How would you rate your health, generally?
********************
*** Own health
tab v115,m

gen svy3_own_health = 1*(v115 == "Poor") + 2*(v115 == "Fair") + 3*(v115 == "Good") + 4*(v115 == "Very Good")+5*(v115 == "Excellent")
gen svy3_own_health_blank = (v115 == "" | v115 == "-99")
tab svy3_own_health v115, missing

gen svy3_own_health_poor = (svy3_own_health == 1 | svy3_own_health == 2)
lab var svy3_own_health_poor "Poor Health"

replace svy3_own_health_poor = . if svy3_own_health_blank ==1
replace svy3_own_health = . if svy3_own_health_blank ==1

tab svy3_own_health_poor v115,m
tab svy3_own_health v115,m


*** Spouse health :How would you rate the health of your spouse/partner, generally?
tab v116,m

gen svy3_spouse_health = 1*(v116 == "Poor") + 2*(v116 == "Fair") + 3*(v116 == "Good") + 4*(v116 == "Very Good")+5*(v116 == "Excellent")
gen svy3_spouse_health_blank = (v116 == "" | v116 == "-99")
tab svy3_spouse_health v116, missing

gen _svy3_spouse_health_poor = (svy3_spouse_health == 1 | svy3_spouse_health == 2)
gen svy3_sphlthpoor = svy3_married_partner*_svy3_spouse_health_poor //sphlthpoor: married*poor spouse health
replace svy3_spouse_health =. if svy3_spouse_health_blank ==1
replace svy3_sphlthpoor =. if svy3_spouse_health_blank ==1
label var svy3_sphlthpoor "Married*Poor spouse health"

tab svy3_sphlthpoor v116, missing
tab svy3_spouse_health v116, missing

*** 3/22/2023: Set svy3_sphlthpoor = 0 if not married.  
tab v116 svy3_married_partner,m
replace svy3_spouse_health = 0 if svy3_married ==0
replace svy3_sphlthpoor = 0 if svy3_married ==0

*************************************
*** Spouse employer health insurance
*************************************
tab v130,m

*gen svy3_sp_resp_ehi = v130 == "Yes" // spouse respond that having employer health insurance

gen svy3_sp_has_hi = .
replace svy3_sp_has_hi = 0 if (v126 == "No" |v127 == "No" |v128 == "No" | v129 == "No" | v130 == "No" | v131 == "No" | v132 == "No" | v133 == "No" | v134 == "No" | v135 == "No")
replace svy3_sp_has_hi = 1 if (v126 == "Yes" |v127 == "Yes" |v128 == "Yes" | v129 == "Yes" | v130 == "Yes" | v131 == "Yes" | v132 == "Yes" | v133 == "Yes" | v134 == "Yes" | v135 == "Yes")
replace svy3_sp_has_hi= 0 if svy3_married ==0

lab var svy3_sp_has_hi "Spouse Has Health Insurance"

tab svy3_sp_has_hi , m

*tab sp_hashi admin3_lgers, row col cell

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
		
	*gen rhi_spcurr = (v130 == "Yes"  | v132 == "Yes" )
	*tab rhi_spcurr lgers, row col cell

	*** SPOUSE EMPLOYER HEALTH INSURNACE

	*gen sp_resp_ehi = v130 == "Yes"

	*gen sp_hashi = (v129 == "Yes" | v130 == "Yes" | v131 == "Yes" | v132 == "Yes" | v133 == "Yes" | v134 == "Yes" | v135 == "Yes")
	*tab sp_hashi lgers, row col cell
	 
	*gen interact_early_ehi = elig_early*sp_resp_ehi
	*gen interact_norm_ehi = elig_norm*sp_resp_ehi
	*gen interact_early_notehi = elig_early*(1-sp_resp_ehi)
	*gen interact_norm_notehi = elig_norm*(1-sp_resp_ehi)

 
/*gen interact_early_ehi = svy5_eligible_early*sp_resp_ehi
gen interact_norm_ehi = svy5_eligible_normal*sp_resp_ehi
gen interact_early_notehi = svy5_eligible_early*(1-sp_resp_ehi)
gen interact_norm_notehi = svy5_eligible_normal*(1-sp_resp_ehi)*/ // I move this part to Result_Admin3_Survey3_Baseline


**************************************
**** Own RHI(Retiree Health Insurance) 
**************************************
tab v136,m

gen svy3_own_has_rhi = .
replace svy3_own_has_rhi = 1 if strpos(v136, "Yes,") == 1 //gen rhi = strpos(v136, "Yes,") == 1 
replace svy3_own_has_rhi = 0 if strpos(v136, "No") == 1 //gen rhi = strpos(v136, "Yes,") == 1 
*replace svy3_own_has_rhi = 2 if strpos(v136, "s employer") == 1 //gen rhi = strpos(v136, "Yes,") == 1 
*gen svy3_own_rhi_dk = strpos(v136, "I don") == 1 | v136 == "-99" //I don't know
*gen svy3_own_rhi_no = strpos(v136, "No") == 1
*gen svy3_own_no_rhi = 1- svy3_own_has_rhi
lab var svy3_own_has_rhi "Has RHI"

*label define rhi 0 "No RHI" 1 "Qualified" 2 "Qualified via Spouse" 
*label values  svy3_own_has_rhi rhi

gen svy3_own_has_hi = .
replace svy3_own_has_hi = 0 if (v119 == "No" | v120 == "No" | v121 == "No" | v122 == "No" | v123 == "No" | v124 == "No" | v125 == "No" | svy3_own_has_rhi == 0)
replace svy3_own_has_hi = 1 if (v119 == "Yes" | v120 == "Yes" | v121 == "Yes" | v122 == "Yes" | v123 == "Yes" | v124 == "Yes" | v125 == "Yes" | svy3_own_has_rhi == 1)
lab var svy3_own_has_hi "Has Health Insurance"

tab v136 svy3_own_has_rhi,m
tab svy3_own_has_hi,m

	/* qualify for RHI: 3.7 Do	you	expect	to	qualify	for	any	retiree	health	benefits	not	including	Medicare?
	o Yes,	I	expect	to	qualify	for	retiree	health	benefits	through	my	current	employer.	
	o Yes,	I	expect	to	qualify	for	retiree	health	benefits	through	my	spouse/partner’s	employer.
	o Yes,	I	expect	to	qualify	for	retiree	health	benefits	through	a	previous	employer.
	o Yes,	I	expect	to	qualify	for	retiree	health	benefits	through	other	means.
	o No,	I	do	not	expect	to	qualify	for	retiree	health	benefits.
	o I	don’t	know whether	I	will	qualify	for	retiree	health	benefits
	*/
	
	/*tab v136
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
	tab rhi_none own_health_poor, row cell mis*/

*********************
**** Life expectacy 
*********************
tab v117,m

gen svy3_own_life_expect=.

*replace svy3_own_life_expect=1 if strpos(v117, "-99")
replace svy3_own_life_expect=5 if strpos(v117, "90 or older")  
replace svy3_own_life_expect=4 if strpos(v117, "85 to 89") 
replace svy3_own_life_expect=3 if strpos(v117, "80 to 84") 
replace svy3_own_life_expect=2 if strpos(v117, "75 to 79") 
replace svy3_own_life_expect=1 if strpos(v117, "Less than 75") 
*replace svy3_own_life_expect=7 if strpos(v117, "Not sure") 
label define own_life 2 "75 to 79" 1 "Less than 75" 3 "80 to 84" 4  "85 to 89" 5 "90 or older"
label values  svy3_own_life_expect own_life
lab var svy3_own_life_expect "Expected Life Span"

tab svy3_own_life_expect v117,m


*gen svy3_low_own_life_expect = (svy3_own_life_expect == 1 | svy3_own_life_expect == 2 | svy3_own_life_expect == 6 | svy3_own_life_expect == 7)
*tab svy3_low_own_life_expect v117,m
*replace svy3_low_own_life_expect = . if v117==""

/*gen interact_early_low_le = low_life_expect*svy5_eligible_early
gen interact_norm_low_le = low_life_expect*svy5_eligible_normal

gen interact_early_high_le = (1-low_life_expect)*svy5_eligible_early
gen interact_norm_high_le = (1-low_life_expect)*svy5_eligible_normal*/ // I move this part to Result_Admin3_Survey3_Baseline

/*own_life_expectancy	Until what age do you expect to live?		
		-99				1
		75 to 79		2
		80 to 84		3
		85 to 89		4
		90 or older		5
		Less than 75	6
		Not sure		7 */
		
**********************************
*** Health insurance is important
**********************************


tab v27,m
tab v34,m

gen svy3_health_ins_important= (v27=="Need for health insurance provided to active workers") | (v34=="Access to retiree health insurance")
lab var svy3_health_ins_important "Health Insurance Important"

tab svy3_health_ins_important, m 
	
tab svy3_health_ins_important svy3_own_health_poor,m cell

	*bysort married: tab health_ins_important own_health_poor,m cell
	*bysort female: tab health_ins_important own_health_poor,m cell
	*tab own_health_poor marriedxsphlthpoor, row col cell

**********************************************
** Worried about health expenses in retirement
**********************************************
** Health Expenses a concern
/* I expect to have
enough money
to take care of
any medical
expenses
during my
retirement.
  Please indicate whether you agree or |
    disagree with each of the following |
                                stateme |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                                    -99 |         14        0.40        0.40
                                  Agree |      1,371       39.15       39.55
                               Disagree |        592       16.90       56.45
             Neither Agree nor Disagree |        969       27.67       84.12
             Not Applicable/ Don't Know |        556       15.88      100.00
*/
tab v70, missing

gen svy3_enough_money = .
replace svy3_enough_money = 1 if (strpos(v70,"Agree")== 1)
replace svy3_enough_money = 0 if (strpos(v70,"Agree")~= 1)
replace svy3_enough_money = . if (strpos(v70,"-99")== 1)

lab var svy3_enough_money "Saved Enough for Health Expenses"

label define _svy3_enough_money 1 "Yes"  0 "No"
label values  svy3_enough_money _svy3_enough_money

tab v70 svy3_enough_money,m



**************************
*** Financial Literacy 
**************************
*** Q#1 (compound)
gen answer1=0 
replace answer1=1 if v179=="More than $110"
replace answer1=. if v179 == "-99" | v179 == ""  //| v179=="Don't know"

tab answer1 v179,m
 
*gen answer1_flag_dk=v179=="Don't know"


***Q#2 (inflation)
*** Imagine that the interest rate on your savings account was 1% per year and inflation was 2% per year. After 1 year, how much would you be able to buy with the money in this account? 

gen answer2=0 
replace answer2=1 if v180=="Less than today"
replace answer2=. if  v180 == "-99" | v180 == "" //| v180=="Don't know"
tab answer2 v180,m

*** Q#3 (stock)
*** 6.3 Is this statement True or False? Buying a single company’s stock usually provides a safer return than a stock mutual fund.

*tab v181
gen answer3=0 
replace answer3=1 if v181=="False"
replace answer3=. if v181 == "-99" | v181 == "" //| v181=="Don't know"
tab answer3 v181,m

gen svy3_num_finq_correct=answer1+answer2+answer3
gen svy3_finq_all_correct = (answer1 == 1 & answer2 == 1 & answer3==1) // answer all three correctly 
replace svy3_finq_all_correct =. if (answer1 == . & answer2 == . & answer3==.)

tab svy3_num_finq_correct svy3_finq_all_correct

gen svy3_finlit_compound = (answer1 == 1) if answer1 <. 
gen svy3_finlit_inflation = (answer2 == 1) if answer2 <. 
gen svy3_finlit_stock = (answer3 == 1) if answer3 <. 

/*gen answers_correct_blank=(answer1_flag==1 & answer2_flag==1 & answer3_flag==1)

gen finlit_compound_only = (answer1 == 1 & answer2 == 0 & answer3 == 0)
gen finlit_inflation_only = (answer1 == 0 & answer2 == 1 & answer3 == 0)
gen finlit_stock_only = (answer1 == 0 & answer2 == 0 & answer3 == 1)*/


*** 4.9 how would you rate your financial knowledge?

destring v163, replace
gen svy3_fin_selfscore = v163 
replace svy3_fin_selfscore = . if (v163 == -99 | v163 ==.)
tab svy3_fin_selfscore v163, missing
gen svy3_fin_selfscore_high = (svy3_fin_selfscore >= 5)
replace svy3_fin_selfscore_high = . if (v163 == -99 | v163 ==.)

*gen svy3_fin_overconf = (finknowhigh == 1 & finlit_three == 1)


*****************************
*** Self reported Salary
*****************************
*v84(current_salary): What is your current annual salary, approximately? ($ per year)
list current_salary in 1/10

gen _svy3_salary = subinstr( current_salary ,",","",.)
replace _svy3_salary = subinstr( _svy3_salary ,"'","",.)
replace _svy3_salary = subinstr( _svy3_salary ," ","",.)
replace _svy3_salary = subinstr( _svy3_salary ,"$","",.)
replace _svy3_salary = subinstr( _svy3_salary ,"K","000",.)
replace _svy3_salary = subinstr( _svy3_salary ,"k","000",.)
replace _svy3_salary = subinstr( _svy3_salary ,"thousand","000",.)
replace _svy3_salary = "" if _svy3_salary=="-99"

replace _svy3_salary = substr(_svy3_salary,strpos(current_salary,"about")+5,5) if strpos(current_salary,"about")>0
replace _svy3_salary = substr(_svy3_salary,strpos(current_salary,"Approximately")+13,5) if strpos(current_salary,"Approximately")>0
replace _svy3_salary = substr(_svy3_salary,strpos(current_salary,"Approx.")+7,5) if strpos(current_salary,"Approx.")
replace _svy3_salary = substr(_svy3_salary,strpos(current_salary,"Around")+6,5) if strpos(current_salary,"Around")

replace _svy3_salary = subinstr( _svy3_salary ,"&","",.)
replace _svy3_salary = subinstr( _svy3_salary ,";","",.)
replace _svy3_salary = subinstr( _svy3_salary ,"+","",.)
replace _svy3_salary = subinstr( _svy3_salary ,"~","",.)

generate svy3_salary = real(_svy3_salary)

replace _svy3_salary = substr(_svy3_salary,1,5) if current_salary ~= "-99" & svy3_salary==.
replace svy3_salary = real(_svy3_salary) if current_salary ~= "-99" & svy3_salary==.

replace svy3_salary = . if svy3_salary > 300000 & svy3_salary<.

gen svy3_answer_salary = (svy3_salary <. | indi =="P3074787" | indi =="P3385238" | indi =="P136243" | indi =="P3034703" ) // some answer the question but either range too big or don't know the measurement

*list current_salary _svy3_salary svy3_salary if current_salary ~= "-99" & svy3_salary ==.

/*list admin3_total_salary_2015 svy3_salary if svy3_salary > 300000 & svy3_salary<.

      +---------------------+
      | a~y_2015   svy3_s~y |
      |---------------------|
 523. | 55543.29    5300000 |
 754. |   265000     446000 |
1089. |    88056     885000 |
2438. | 77124.96     750000 |
3080. | 40237.83     401000 |
      +---------------------+*/
	  

*********************
*** Procrastination
*********************
**  Defined as responding to the survey after many reminders

 /*   Survey 3 timeline:
        
      Sun 5/10 First day of fielding survey 
      Wed 5/18 Reminder sent to actives, with date of first drawing 
      Tue 5/31 Reminders sent to all groups
      Tue 6/8 Reminder sent to all groups */

gen _start_date = subinstr( v4 ,"-",".",.)
gen _end_date = subinstr( end_date ,"-",".",.)

gen start_time = clock(_start_date,"YMD hms")
gen end_time = clock(_end_date,"YMD hms")

format start_time %tc
format end_time %tc

gen svy3_num_reminder = . // number of reminder until response
replace svy3_num_reminder = 0 if (end_time < mdyhms(05,18,2016,0,0,0))
replace svy3_num_reminder = 1 if (end_time >= mdyhms(05,18,2016,0,0,0) & end_time < mdyhms(05,31,2016,0,0,0))
replace svy3_num_reminder = 2 if (end_time >= mdyhms(05,31,2016,0,0,0) & end_time < mdyhms(06,08,2016,0,0,0))
replace svy3_num_reminder = 3 if (end_time >= mdyhms(06,08,2016,0,0,0))

tab svy3_num_reminder

gen svy3_need_reminder = svy3_num_reminder~=0



/*gen time_to_complete = end_time-start_time

su time_to_complete 

gen svy3_long_lag = (time_to_complete > 86400000) //responding to the survey after a long lag of time(24 hours)

tab svy3_long_lag 

*gen svy3_procrast = (long_lag==1) | (num_reminder>0)*/



********************
*** Survey engagement 
*********************
*** Defined as the number of skipped/blank responses

include "MakeData_Survey_Engagement" //include Eligibility code

su num_missing num_dk

gen svy3_num_miss_dk = num_missing + num_dk 

su svy3_num_miss_dk

local threshold_num_miss_dk = r(mean)  //+ r(sd) 

gen svy3_engage = (num_missing <= `threshold_num_miss_dk')

su svy3_num_miss_dk
gen svy3_sd_num_miss_dk = (svy3_num_miss_dk-r(mean))/r(sd)


*******************
*** Total Wealth
********************
*** "amount of all other wealth -- categories"

tab v88,m
gen svy3_wealth_lt25k = (strpos(v88, "Less than") > 0) if v88 ~="" | v88 ~="-99" | v88 ~="Don't know"  //Less than $25,000
gen svy3_wealth_gt25k = (strpos(v88, "$") > 0 & strpos(v88, "Less than")==0)  if v88 ~="" | v88 ~="-99" | v88 ~="Don't know"  //more than $25,000

replace svy3_wealth_lt25k = . if strpos(v88, "$") ==0  //Less than $25,000
replace svy3_wealth_gt25k = .  if strpos(v88, "$") ==0  //more than $25,000

tab svy3_wealth_lt25k v88,m
tab svy3_wealth_gt25k v88,m


*** account balances --- categoires
tab v87,m
gen svy3_acctbal_lt25k = (strpos(v87, "$") > 0 & strpos(v87, "Less than") > 0)
gen svy3_acctbal_gt25k = (strpos(v87, "$") > 0 & strpos(v87, "Less than") == 0)

replace svy3_acctbal_lt25k = . if strpos(v87, "$") ==0  //Less than $25,000
replace svy3_acctbal_gt25k = .  if strpos(v87, "$") ==0 

tab svy3_acctbal_lt25k v87,m
tab svy3_acctbal_gt25k v87,m

***hh total combined income past 12 months

tab v85
gen svy3_income_gt50K = strpos(v85,"$100") + strpos(v85,"$150") + strpos(v85, "$250") + strpos(v85, "$50") + strpos(v85,"$75")
gen svy3_income_lt50K = strpos(v85,"$25,000 to") + strpos(v85,"Less")

replace svy3_income_gt50K = . if strpos(v85, "$") ==0  //Less than $25,000
replace svy3_income_lt50K = .  if strpos(v85, "$") ==0 

tab svy3_income_gt50K v85,m
tab svy3_income_lt50K v85,m



*keep indi svy3*	
save "${working}Survey3_Demo_Health", replace
exit





 
********************************************************************************************************************************
 //================================ other variables not appear in the current table ============================================

******************************************
*** Important factors in retirement decision
******************************************

gen imp_factor_inc=(v25!="")
gen imp_factor_mortgage=(v26!="")
gen imp_factor_health_ins=(v27!="")
gen imp_factor_own_health=(v28!="")
gen imp_factor_job_satisfaction=(v29!="")
gen imp_factor_spouse_ret_plan=(v30!="")
gen imp_factor_spouse_otherfin_needs=(v31!="")
gen imp_factor_savings=(v32!="")
gen imp_factor_kids_college=(v33!="")
gen imp_factor_ret_health_ins=(v34!="")
gen imp_factor_able_todo_job=(v35!="")
gen imp_factor_desire_free_time=(v36!="")
gen imp_factor_spouse_health=(v37!="")
gen imp_factor_none_of_these=(v38!="")


*********************************************************
*** health insurance important X Eligibility
*********************************************************

gen interact_early_import = imp_factor_health_ins*svy5_eligible_early
gen interact_norm_import = imp_factor_health_ins*svy5_eligible_normal

gen interact_early_notimport = (1-imp_factor_health_ins)*svy5_eligible_early
gen interact_norm_notimport = (1-imp_factor_health_ins)*svy5_eligible_normal


**************************
*** Financial Literacy 
**************************

gen answer1=0 
replace answer1=1 if v179=="More than $110"
gen answer1_flag= (strpos(v179, "-99")==1 )
replace answer1_flag=1 if v179==""
 
gen answer1_flag_dk=v179=="Don't know"


*** Imagine that the interest rate on your savings account was 1% per year and inflation was 2% per year. After 1 year, how much would you be able to buy with the money in this account? 

gen answer2=0 
replace answer2=1 if v180=="Less than today"
gen answer2_flag= (strpos(v180, "-99") == 1)
replace answer2_flag=1 if  v180==""

gen answer2_flag_dk=(v180=="Don't know")

*** 6.3 Is this statement True or False? Buying a single company’s stock usually provides a safer return than a stock mutual fund.

tab v181
gen answer3=0 
replace answer3=1 if v181=="False"
gen answer3_flag= (strpos(v181, "-99") == 1)
replace answer3_flag=1 if  v181==""

gen answer3_flag_dk=(v181=="Don't know")

gen answers_correct=answer1+answer2+answer3
gen answers_correct_blank=(answer1_flag==1 & answer2_flag==1 & answer3_flag==1)

gen finlit_compound_only = (answer1 == 1 & answer2 == 0 & answer3 == 0)
gen finlit_inflation_only = (answer1 == 0 & answer2 == 1 & answer3 == 0)
gen finlit_stock_only = (answer1 == 0 & answer2 == 0 & answer3 == 1)

gen finlit_three = (answer1 == 1 & answer2 == 1 & answer3==1)

*** 4.9 how would you rate your financial knowledge?

destring v163, replace
gen fin_selfscore = v163 
replace fin_selfscore = 0 if (v163 == -99 | v163 ==.)
gen fin_selfscore_missing = (v163 == -99 | v163 == .)
tab fin_selfscore v163, missing
gen finknowhigh = (fin_selfscore >= 5 & fin_selfscore_missing == 0)

gen fin_overconf = (finknowhigh == 1 & finlit_three == 0)


**********************************
*** date expect to claim benefit
*********************************

gen expected_claim_ben_date=plan_claim_yr
replace expected_claim_ben_date="2030" if expected_claim_ben_date=="2030 or later"
replace expected_claim_ben_date=expected_claim_ben_date+plan_claim_mo

gen _expected_claim_ben_date = monthly(expected_claim_ben_date, "YM")
format _expected_claim_ben_date %tm

* year expect to claim benefit
destring plan_claim_yr, gen(expected_claim_ben_yr) i("or later" "Don't know")

***************************
*** date expect to stop work
****************************
gen expected_stop_work_date=plan_stop_yr
replace expected_stop_work_date="2030" if expected_stop_work_date=="2030 or later"
replace expected_stop_work_date=expected_stop_work_date+plan_stop_mo

gen _expected_stop_work_date = monthly(expected_stop_work_date, "YM")
format _expected_stop_work_date %tm

* year expect to stop work
destring plan_stop_yr, gen(expected_stop_work_yr) i("or later" "Don't know")


****************************
*** Have a retirement plan 
****************************
tab v23,m

encode v23, gen(ret_planning)
replace ret_planning=0 if ret_planning==1|ret_planning==3




*********
*** Risk
*********


*** We have 7 questions on risk aversion in survey 3
*** 6.4 Suppose that you are offered a choice between two prizes. If you choose Prize A, ///
*** you are guaranteed to receive $1,000. Alternatively, if you choose prize B, ///
*** you will have a 50-50 chance of receiving $2,500 and a 50-50 chance of receiving nothing. ///
*** Which prize would you choose -- Prize A or Prize B? 
tab v195
gen risk_aversion_prize1=0
replace risk_aversion_prize1=1 if v195=="Prize A"

gen risk_seeking_prize1=0
replace risk_seeking_prize1=1 if v195=="Prize B"

gen risk_dk_prize1=0
replace risk_dk_prize1=1 if v195=="Not sure"

gen risk_blank_prize1=0
replace risk_blank_prize1=1 if risk_aversion_prize1==0 & risk_seeking_prize1==0 & risk_dk_prize1==0

*** 6.5 Now suppose that with Prize A, you are guaranteed to receive $1,000. /// 
*** Alternatively, if you choose prize B, you will have a 50-50 chance of receiving /// 
*** $3,500 and a 50-50 chance of receiving nothing. Which prize would you choose -- Prize A or Prize B?
tab v196
gen risk_aversion_prize2=0
replace risk_aversion_prize2=1 if v196=="Prize A"

gen risk_seeking_prize2=0
replace risk_seeking_prize2=1 if v196=="Prize B"

gen risk_dk_prize2=0
replace risk_dk_prize2=1 if v196=="Not sure"

gen risk_blank_prize2=0
replace risk_blank_prize2=1 if risk_aversion_prize2==0 & risk_seeking_prize2==0 & risk_dk_prize2==0

*** 6.6 Now suppose that with Prize A, you are guaranteed to receive $1,000. /// 
*** Alternatively, if you choose prize B, you will have a 50-50 chance of receiving /// 
*** $4,000 and a 50-50 chance of receiving nothing. Which prize would you choose -- Prize A or Prize B?
tab v197
gen risk_aversion_prize3=0
replace risk_aversion_prize3=1 if v197=="Prize A"

gen risk_seeking_prize3=0
replace risk_seeking_prize3=1 if v197=="Prize B"

gen risk_dk_prize3=0
replace risk_dk_prize3=1 if v197=="Not sure"

gen risk_blank_prize3=0
replace risk_blank_prize3=1 if risk_aversion_prize3==0 & risk_seeking_prize3==0 & risk_dk_prize3==0

*** 6.7 Now suppose that with Prize A, you are guaranteed to receive $1,000. ///
*** Alternatively, if you choose prize B, you will have a 50-50 chance of receiving ///
*** $3,000 and a 50-50 chance of receiving nothing. Which prize would you choose -- Prize A or Prize B?
tab v198
gen risk_aversion_prize4=0
replace risk_aversion_prize4=1 if v198=="Prize A"

gen risk_seeking_prize4=0
replace risk_seeking_prize4=1 if v198=="Prize B"

gen risk_dk_prize4=0
replace risk_dk_prize4=1 if v198=="Not sure"

gen risk_blank_prize4=0
replace risk_blank_prize4=1 if risk_aversion_prize4==0 & risk_seeking_prize4==0 & risk_dk_prize4==0

*** 6.8 Now suppose that with Prize A, you are guaranteed to receive $1,000. /// 
*** Alternatively, if you choose prize B, you will have a 50-50 chance of receiving /// 
*** $2,300 and a 50-50 chance of receiving nothing. Which prize would you choose -- Prize A or Prize B?
tab v199
gen risk_aversion_prize5=0
replace risk_aversion_prize5=1 if v199=="Prize A"

gen risk_seeking_prize5=0
replace risk_seeking_prize5=1 if v199=="Prize B"

gen risk_dk_prize5=0
replace risk_dk_prize5=1 if v199=="Not sure"

gen risk_blank_prize5=0
replace risk_blank_prize5=1 if risk_aversion_prize5==0 & risk_seeking_prize5==0 & risk_dk_prize5==0

*** 6.9 Now suppose that with Prize A, you are guaranteed to receive $1,000. /// 
*** Alternatively, if you choose prize B, you will have a 50-50 chance of receiving ///
*** $2,200 and a 50-50 chance of receiving nothing. Which prize would you choose -- Prize A or Prize B?
tab v200
gen risk_aversion_prize6=0
replace risk_aversion_prize6=1 if v200=="Prize A"

gen risk_seeking_prize6=0
replace risk_seeking_prize6=1 if v200=="Prize B"

gen risk_dk_prize6=0
replace risk_dk_prize6=1 if v200=="Not sure"

gen risk_blank_prize6=0
replace risk_blank_prize6=1 if risk_aversion_prize6==0 & risk_seeking_prize6==0 & risk_dk_prize6==0

*** 6.10 Now suppose that with Prize A, you are guaranteed to receive $1,000. /// 
*** Alternatively, if you choose prize B, you will have a 50-50 chance of receiving /// 
*** $2,400 and a 50-50 chance of receiving nothing. Which prize would you choose -- Prize A or Prize B?
tab v201
gen risk_aversion_prize7=0
replace risk_aversion_prize7=1 if v201=="Prize A"

gen risk_seeking_prize7=0
replace risk_seeking_prize7=1 if v201=="Prize B"

gen risk_dk_prize7=0
replace risk_dk_prize7=1 if v201=="Not sure"

gen risk_blank_prize7=0
replace risk_blank_prize7=1 if risk_aversion_prize7==0 & risk_seeking_prize7==0 & risk_dk_prize7==0


********************************
*** Mortality 
********************************

*until what age do you expect to live / your spouse
tab v128
gen own_mort_blank =  (v128 == "-99" | v128=="")
gen own_mort_old = strpos(v128, "85 to") + strpos(v128, "90 or")
gen own_mort_dk = v128 == "Not sure" 
gen own_mort_yng = strpos(v128, "75 to") + strpos(v128, "80 to") + strpos(v128, "Less than")

*until what age do you expect to live / your spouse
tab v128
gen own_mort_old2 = strpos(v128, "85 to") + strpos(v128, "90 or")+ strpos(v128, "80 to")
gen own_mort_85 = strpos(v128, "85 to") 
gen own_mort_90 = strpos(v128, "90 or")
gen own_mort_75 = strpos(v128, "75 to") 
gen own_mort_80 = strpos(v128, "80 to") 
gen own_mort_LT = strpos(v128, "Less than")

gen own_lifee_low = strpos(v128, "Less than")

****Health*** 
gen own_health = 1*(v126 == "Poor") + 2*(v126 == "Fair") + 3*(v126 == "Good") + 4*(v126 == "Very Good")+5*(v126 == "Excellent")
gen own_health_blank = (v126 == "" | v126 == "-99")
tab own_health v126, missing

gen own_health_poor = (own_health == 1 | own_health == 2)


/********************************************************************************
***                        Spouse                                            ***
********************************************************************************

*** 5.3 What is your spouse/partner's employment status? 
tab v181
tab v182
gen employment_spouse = 7 if v181~=""
gen employment_spouse_clean = 7 if inlist(S3marital_status, 1, 2)
replace employment_spouse = 1 if v181 == "Currently employed and working full-time"
replace employment_spouse = 2 if v181 == "Currently employed and working part-time"
replace employment_spouse = 3 if v181 == "Not currently working but actively looking for work"
replace employment_spouse = 4 if v181 == "Disabled"
replace employment_spouse = 5 if v181 == "Retired and not working for pay"
replace employment_spouse = 6 if v181 == "Primary caretaker/not in labor force"
replace employment_spouse = 8 if v181 == "Other"
replace employment_spouse_clean = 1 if v181 == "Currently employed and working full-time"
replace employment_spouse_clean = 2 if v181 == "Currently employed and working part-time"
replace employment_spouse_clean = 3 if v181 == "Not currently working but actively looking for work"
replace employment_spouse_clean = 4 if v181 == "Disabled"
replace employment_spouse_clean = 5 if v181 == "Retired and not working for pay"
replace employment_spouse_clean = 6 if v181 == "Primary caretaker/not in labor force"
*work on obs. with "Others" in 5.3
*treat those without information on part-time/full-time as full-time workers
replace employment_spouse_clean = 1 if v181 == "Other" & v182 == "RETIRED WORKING"
replace employment_spouse_clean = 1 if v181 == "Other" & v182 == "Retired and working for pay"
replace employment_spouse_clean = 1 if v181 == "Other" & v182 == "Retired working for pay"
replace employment_spouse_clean = 1 if v181 == "Other" & v182 == "RETIRED WORKING"
*treat those "retired but working part-time" as part-time workers
replace employment_spouse_clean = 2 if v181 == "Other" & strpos(v182, "part-time")
replace employment_spouse_clean = 2 if v181 == "Other" & strpos(v182, "part time")
replace employment_spouse_clean = 2 if v181 == "Other" & strpos(v182, "pt")
replace employment_spouse_clean = 2 if v181 == "Other" & strpos(v182, "PT")
replace employment_spouse_clean = 2 if v181 == "Other" & strpos(v182, "occasional")
*some are self-employed, treat as full-time workers unless specified
replace employment_spouse_clean = 2 if v181 == "Other" & strpos(v182, "Self") & employment_spouse==7
replace employment_spouse_clean = 2 if v181 == "Other" & strpos(v182, "self") & employment_spouse==7
*others, categorize them into the correct groups
replace employment_spouse_clean = 6 if v181 == "Other" & strpos(v182, "homemaker")
replace employment_spouse_clean = 6 if v181 == "Other" & strpos(v182, "never worked")
replace employment_spouse_clean = 6 if v181 == "Other" & strpos(v182, "not working, not looking")
label define employment_spouse_clean 1 "Currently employed and working full-time" 2 "Currently employed and working part-time" ///
	3 "Not currently working but actively looking for work" 4 "Disabled" 5 "Retired and not working for pay" ///
	6 "Primary caretaker/not in labor force"  7 "missing/-99"
label values employment_spouse_clean employment_spouse_clean
label define employment_spouse 1 "Currently employed and working full-time" 2 "Currently employed and working part-time" ///
	3 "Not currently working but actively looking for work" 4 "Disabled" 5 "Retired and not working for pay" ///
	6 "Primary caretaker/not in labor force"  7 "missing/-99" 8 "Other"
label values employment_spouse employment_spouse

*** 5.4 At what month and year does your spouse/partner plan to stop working for pay or looking for work entirely?
gen v183_1 = v183
replace v183_1 = "Jan" if v184~="" & v184~="Don't know" & v184~="N/A"
gen v184_1 = v184
replace v184_1 = "2030" if v184=="2030 or later"
gen v183_184 = v183_1+v184_1  if v183~="Don't know" & v183~="N/A" & v184~="Don't know" & v184~="N/A"
gen retire_plan_date_spouse = monthly(v183_184, "MY")
format %tm retire_plan_date_spouse
drop v183_* v184_1

*** 5.5 What month and year did your spouse/partner stop working full-time?
gen v185_1 = v185
replace v185_1 = "Jan" if v186~="" & v186~="Don't know" 
gen v186_1 = v186
replace v186_1 = "2012" if v186=="Before 2013"
gen v185_186 = v185_1+v186_1  if v186~="Don't know" & v186~="Don't know" 
gen retire_date_spouse = monthly(v185_186, "MY")
format %tm retire_plan_date_spouse
drop v185_* v186_1

*** 5.6 Not including Social Security, is your spouse/partner covered by or currently receiving benefits ///
*** from a pension plan?
gen pension_spouse = 4 if inlist(S3marital_status, 1, 2)
replace pension_spouse = 1 if v187=="Yes"
replace pension_spouse = 2 if v187=="No"
replace pension_spouse = 3 if v187=="Don't know"
label define pension_spouse 1 "Yes" 2 "No" /*
*/	3 "Don't know" 4 "Missing" 
label values pension_spouse pension_spouse

*** 3.5 Own health insurance
la var v130 "Life insurance"
la var v131 "Long-term care insurance"
la var v132 "Medicare "
la var v133 "Employer-provided health insurance from my current employer "
la var v134 "Employer-provided health insurance from my spouse/partner's current employer "
la var v135 "Retiree health insurance from my previous employer "
la var v136 "Retiree health insurance from my spouse/partner’s current employer "
la var v137 "Retiree health insurance from my spouse/partner's previous employer" 
la var v138 "Medicaid "
la var v139 "Other"

//AP added 03/02/2017
local instype "life ltc Mcare empcurr empspousecurr rhiselfprev rhispousecurr Mcaid ohi rhilatespouse rhispouseprev"
forvalues i=0/9{
encode v13`i', gen(ins`i')
recode ins`i' ( 1=.) (2=0) (3=2) (4=1), gen (newins`i')     //Recode 0:No 1:Yes 2:Not sure
drop ins`i'
local j=`i'+1
local a: word `j' of `instype'
rename newins`i' ins_`a'
}

*** 3.6 Spouse health insurance
la var v140 "Life insurance"
la var v141 "Long-term care insurance "
la var v142 "Medicare "
la var v143 "Employer-provided health insurance from my spouse/partner's current employer "
la var v144 "Employer-provided health insurance from my current employer "
la var v145 "Retiree health insurance from my spouse/partner's previous employer "
la var v146 "Retiree health insurance from my current employer "
la var v147 "Retiree health insurance from my previous employer "
la var v148 "Medicaid "
la var v149 "Other"

//AP added 03/02/2017
local sp_instype "life ltc Mcare empcurr emprespcurr rhiownprev rhirespcurr rhirespprev Mcaid ohi"
forvalues i=0/9{
encode v14`i', gen(spins`i')
recode spins`i' ( 1=.) (2=0) (3=2) (4=1), gen (newspins`i') //Recode 0:No 1:Yes 2:Not sure
drop spins`i'
local j=`i'+1
local a: word `j' of `sp_instype'
rename newspins`i' spins_`a'
}
