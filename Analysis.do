
* This file executes the main achievement analysis for Island Park 2012-2013
* To do: correlate growth results with unique logins

***** Load Data
cd "/Users/maya/Documents/NWEA/Island Park 2012-2013/"
use CleanNWEA.dta, clear
merge m:1 nwea_id using DemogFull.dta, keep(match) nogen
* Manually correct some obvious matches
replace lastname = "Riviere-Santiago" if lastname=="Riviere" & firstname=="Antonio"
replace firstname = "Franklin" if lastname=="Suna" & firstname=="Franklyn"

* Merge in eSpark data
reshape long growthFallToSpring growthWinToSpring, i(nwea_id) j(domain, string)
cd "/Users/maya/Documents/PD/TestAnalyses/Island Park"
merge 1:m firstname lastname domain using CleaneSpark.dta
order nwea_id student_id firstname lastname, first

* Identify set of students who start any mission in eSpark and drop all others
bys nwea_id: egen temp = max(student_id)
bys nwea_id: gen eSparkStudent = (temp!=.)
drop if eSparkStudent==0

* Growth by completion bucket
gen b_growth25 = growthFallToSpring if complete >0 & complete <=.25 & abs(growthFallToSpring) < 5
gen b_growth50 = growthFallToSpring if complete >.25 & complete <=.5 & abs(growthFallToSpring) < 5
gen b_growth75 = growthFallToSpring if complete >.5 & complete <=.75 & abs(growthFallToSpring) < 5
gen b_growth100 = growthFallToSpring if complete >.75 & complete!=. & abs(growthFallToSpring) < 5

* Goal and nongoal growth, censored and uncensored versions
gen uc_goalgrowth = growthFall if complete>=.33 & complete!=.
gen uc_nongoalgrowth = growthFall if complete==.
gen c_goalgrowth = growthFall if complete>=.33 & complete!=. & abs(growthFallToSpring) < 5
gen c_nongoalgrowth = growthFall if complete==. & abs(growthFallToSpring) < 5

foreach t in c uc {
	bys nwea_id: egen m_`t'_goalgrowth = mean(`t'_goalgrowth)
	bys nwea_id: egen m_`t'_nongoalgrowth = mean(`t'_nongoalgrowth)
}

drop fall winter _merge temp eSparkStudent uc_* c_* 
save AnalysisSample.dta, replace


****** Output Results

* 1  Summarize baseline scores in fall and winter, overall and by subgroup. Each student is weighted as 1. 
preserve
duplicates drop nwea_id, force
tabstat OverallRITFall OverallPtileFall OverallRITSpring OverallPtileSpring OverallGrowth, s(mean count)
bys grade_group: tabstat OverallRITFall OverallPtileFall OverallRITSpring OverallPtileSpring OverallGrowth, s(mean count)
bys ethnic: tabstat OverallRITFall OverallPtileFall OverallRITSpring OverallPtileSpring OverallGrowth, s(mean count)
bys gender: tabstat OverallRITFall OverallPtileFall OverallRITSpring OverallPtileSpring OverallGrowth, s(mean count)
restore 

* 2 Summarize overall growth regardless of eSpark usage, overall and by subgroup. Each domain is weighted as 1
tabstat growthFall if domain!="SRR" & domain!="SRM" & domain!="CC", s(mean count)
bys grade_group: tabstat growthFall if domain!="SRR" & domain!="SRM" & domain!="CC", s(mean count)
bys ethnic: tabstat growthFall if domain!="SRR" & domain!="SRM" & domain!="CC", s(mean count)
bys gender: tabstat growthFall if domain!="SRR" & domain!="SRM" & domain!="CC", s(mean count)

* 3 Summarize growth by completion. These are censored at 500% expectation.
sum b_*

* 4a Count number of students with goals in each domain by season
tab domain if complete!=.

* 4b Summarize eSpark goal and nongoal growth, overall and by subgroup
* Collapse to get summary estimates counting one student as one
* Limit to set of students that have estimates for both goal and nongoal growth
gen sample = (m_c_goalgrowth!=. & m_c_nongoalgrowth!=.)
keep if sample==1
duplicates drop nwea_id, force
tabstat m_c_goal m_c_nongoal, s(mean count)
bys grade_group: tabstat m_c_goal m_c_nongoal, s(mean count)
bys ethnic: tabstat m_c_goal m_c_nongoal, s(mean count)
bys gender: tabstat m_c_goal m_c_nongoal, s(mean count)

* Also run uncensored goal/nongoal estimates
use AnalysisSample.dta, clear
preserve
gen sample = (m_uc_goalgrowth!=. & m_uc_nongoalgrowth!=.)
keep if sample==1
duplicates drop nwea_id, force
tabstat m_uc_goal m_uc_nongoal, s(mean count)
restore

