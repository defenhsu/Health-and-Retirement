*------inserting some notes------*

note: Survey 3 Date: May 10,2016

note: {break} ///
To identify "retired (benefit claimants )" {break} ///
 {space 2} {break} ///
-Active Benefit status code  {break} ///
-Early/Normal Benefit account type code  {break} ///
==> Define retired as actively claiming a regular benefit. (benefit_account_type_code=="EARLY"| benefit_account_type_code=="SVC") & ba_status_code=="ACTV"

note:  {break} ///
To identify "active"  {break} ///
 {space 2} {break} ///
- Null Termination Code  {break} ///
- Active membership status code  {break} ///
- Null benefit status code  {break} ///

note:  {break} ///
To identify "terminated (retired and active)":  {break} ///
 {space 2} {break} ///
Terminated Retired: {break} ///
-Active membership account ==> Active membership status code {break} ///
-Non-null termination code {break} ///
-No benefit account ==> Null benefit status code {break} ///
-Termination date 2014-2016 {break} ///
-Termination and last contribution date were within +/-30 days {break} ///
 {space 2} {break} ///
Terminated Active: {break} ///
-Active membership account ==> Active membership status code {break} ///
-Non-null termination code {break} ///
-No benefit account ==> Null benefit status code {break} ///
-Termination date before 2014 or after 2016 {break} ///
OR termination and last contribution dates are more than 30 days apart. {break} ///
OR Last contribution later than 1st December, 2015	{break} ///		
Note: compare most recent termination date and corresponding last contribution date
 {space 2} {break} ///
Withdrawn Benefits: {break} ///
- Non-null refund amount for all benefit accounts

note:  {break} ///
To identify "deferred vested"  {break} ///
-Null refund amount and date


note termretired: Active membership account
note termretired: Non-null termination code
note termretired: No benefit account
note termretired: Termination date 2014-2016
note termretired: Termination and last contribution date were within +/-30 days
note termretired: Notes: compare most recent termination date and corresponding last contribution date
note termretired: Note: 1 individual with a non-null termination code but no active membership is unclassified. {break} ///
Since their most recent termination date is before 2014, classify these as terminated retired

note termactive: Active membership account
note termactive: Non-null termination code
note termactive: No benefit account
note termactive: Termination date before 2014 or after 2016 OR termination and last contribution dates are more than 30 days apart. OR Last contribution later than 1st December, 2015			
note termactive: Notes: compare most recent termination date and corresponding last contribution date

note mem_retirement_system_code: {break} ///
- CJRS: Consolidated Judicial Retirement System {break} ///
- FRSWPF: Firefighters' and Rescue Squad Workers' Pension Fund {break} ///
- LEO: Legacy LEO Retirement System {break} ///
- LF: Legislative Fund {break} ///
- LGERS: Local Governmental Employees' Retirement System {break} ///
- LRS: Legislative Retirement System {break} ///
- NG: National Guard {break} ///
- RDSPF: Register of Deeds' Supplemental Pension Fund (all members are also in LGERS) {break} ///
- TSERS: Teachers' and State Employees' Retirement System 

note membership_status_code: {break} ///
- ACTV: Active {break} ///
- CLOSDEAD: Closed - Dead {break} ///
- CLOSPENTRN: Closed - Pension Transferred {break} ///
- CLOSRET: Closed - Retired {break} ///
- CLOSTRANS: Closed - Transferred {break} ///
- CLOSWITH: Closed - Withdrawn {break} ///
- ESCHEAT: Escheat {break} ///
- FORCEWITH: Forced Withdrawn {break} ///
- INAC: Inactive {break} ///
- MERGED: Merged {break} ///
- PEND: Pending

note benefit_account_type_code:  {break} ///
- SVC: unreduced  {break} ///
- EARLY: reduced  {break} ///
- SRIP401K: 401k Transfer Benefit   {break} ///
- SRIP457: 457 Transfer Benefit   {break} ///
- ATR: refund   {break} ///
- PSR: partial refund   {break} ///
- PSRSP: partial refund with service purchase   {break} ///
- ORP: ORP eligible for health insurance only ($0 benefit)    {break} /// 
- OTHER: all other benefit account types including disability types  {break} ///

note ba_retirement_system_code: {break} ///
- CJRS: Consolidated Judicial Retirement System {break} ///
- FRSWPF: Firefighters' and Rescue Squad Workers' Pension Fund {break} ///
- LEO: Legacy LEO Retirement System {break} ///
- LF: Legislative Fund {break} ///
- LGERS: Local Governmental Employees' Retirement System {break} ///
- LRS: Legislative Retirement System {break} ///
- NG: National Guard {break} ///
- RDSPF: Register of Deeds' Supplemental Pension Fund (all members are also in LGERS) {break} ///
- TSERS: Teachers' and State Employees' Retirement System  {break} ///
note ba_retirement_system_code: {break} ///
- RDSPF are also in LGERS
- ORP service credit may also be used to determine eligibility for TSERS benefits


note ba_status_code:  {break} ///
- susp: suspended  {break} ///
- actv: active  {break} /// 
- clos: closed


note pr_membership_id: identifier for a membership, includes a leading "M" character  (matches PUBLIC RECORDS database PERSON_ID, does not match ORBIT PERSON_ID: indi. id)
