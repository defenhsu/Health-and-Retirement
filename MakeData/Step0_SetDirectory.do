clear
capture log close _all
set more off

global drive_letter G  // only need to change drive letter to revise directory
global date "$S_DATE"

cd "$drive_letter:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\RA"
global log "$drive_letter:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\RA\log\"
global raw "$drive_letter:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\RA\RawData\"
global working "$drive_letter:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\RA\WorkingData\"
global output "$drive_letter:\Shared drives\NCRTS Retirement Timing\Retirement_Timing\Programs\RA\output\"
