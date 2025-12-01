*** Data Construction ***
- The working data we are using now is "Admin3_Survey3". ("Admin3_Survey3_Fuzzy" if using Fuzzy Eligibility)
+ "Admin3_Survey3_Fuzzy": Constructed using code files Step 1 through Step 6 in the MakeData folder (Step1_MakeData_Admin3_Actives to Step6_MakeData_Admin3_Survey3_Fuzzy).
+ "Admin3_Survey3": Constructed using code files Step 1 through Step 6 in the MakeData folder  (Step1_MakeData_Admin3_Actives to Step6_MakeData_Admin3_Survey3).
+ README provides explanations of the data construction path, outlining each step from the code files to our final working dataset.

- Data restriction: 
     +  Not retired as of April 2016 (Active Benefit Account and Claim Benefit)
     +  Active Membership 
     +  TSERS or LGERS
     +  Drop law enforcement, firefighters
     +  Drop indi. claiming disability or other benefit types(non-regular) as of April 2016 
     +  Drop data with unidentified gender 
     +  Drop individuals deceased as of April 2016
     +  Drop individuals/memberships with missing contribution dates
     +  First hired before 3/4/2014
     +  Aged 52 to 64 as of April 2016 
     +  With five or more years of service as of April 2016.
     +  Drop if the last contribution date is missing or is earlier than April 2016 in Admin 5 data
     +  Must have a non-missing value for:
	> Marital status 
	> Health status
	> Agency type (for TSERS) or indicator for LGERS
	> Health status of spouse non-missing if married


*** Main Output ***
// Compliance Probability //
- Output Table (baseline, no control, no restriction, fuzzy eligibility): Tbl2_Compliance_NoControl_Fuzzy
- Corresponding Code: G:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\RA\Result\Result_Tbl2_Tbl3
- Method: Abadie 2003
+ First-stage estimates, i.e., the effect of Z on D, are equal to the probability of compliers P(D_1 > D_0). P(D_1 > D_0) is obtained through a regression, where we regress D (retirement status as of 2017) on Z (eligibility for normal retirement), while controlling for health status, marital status, gender, race, number of children, job classification, salaries, whether one has a bachelor's degree or not, years of service (yos), and age.
+ Among those who didn't retire, there are individuals categorized as never takers and compliers who are not eligible for normal retirement. Therefore, the probability of being a never taker can be calculated by P(D=0) - P(Z=0)*P(D_1>D_0).
+ Among those who retired, there are individuals categorized as always takers and compliers who are eligible for normal retirement. Therefore, the probability of being an always taker can be calculated by P(D=1) - P(Z=1)*P(D_1>D_0).
