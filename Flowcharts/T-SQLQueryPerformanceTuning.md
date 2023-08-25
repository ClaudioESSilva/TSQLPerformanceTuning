# Flowchart - T-SQL Query Performance Tuning

This flowchart is meant to help find the reason why SQL Server query has performance issues and suggest ideas to fix (re-write) the code.

## DISCLAIMER: 
The suggestions here can be anywhere between a harmless code change or turn some "switch" on and that can have other impacts.  
Be sure you test these on a test environment before you put it on production!

This isn't a silver bullet neither an exhaustive list of the existing options.  
There are too many variables and combinations that will make the things go different.  
That said, this is a high level flowchart that will try to guide you and may or not lead you to the possible cause and/or solution.

Hopefully, it will give you more ideas where to look at.

```mermaid
flowchart TB
	Starting("Starting query performance tuning analysis") --> IsolateTsqlQuery{"Have you identified and isolated <br> the query that is slow?"}
	IsolateTsqlQuery -->|"No"| IsolateTsqlQuery_No["First find and isolate the query that is slow!"]
	IsolateTsqlQuery_No --> Starting
	Focus_CTE{"Does it use CTEs?"} -->|"Yes"| Focus_CTE_Structure{"Is it a recursive CTE?"}
	IsolateTsqlQuery --->|"Yes <br> "| Focus_CTE
	Focus_CTE_Structure -->|"Yes"| RecursiveCTERelation{"What is the relation? <br> 1-n or n-n?"}
	RecursiveCTERelation -->|"n-n"| RecursiveCTERelation_nTOn["Performance of n-n relations may not be great. <br> Check if you have good indexing in place. <br><br> Test doing the same with a <br> hand-made cycle (#tmp tables + cycle)"]
    Result_ImprovementYes["Do you see improvements? #128588;"]
	RecursiveCTERelation_nTOn --> Result_ImprovementYes
	RecursiveCTERelation -->|"1-n"| RecursiveCTERelation_1TOn["Nice! Recursive CTEs <br> are better on 1-n relations."]
	RecursiveCTERelation_1TOn --> RecursiveCTERelation_1TOn_MultipleCalls{"Do you see the CTE being <br> called more than once?"}
	Focus_CTE_Structure -->|"No"| RecursiveCTERelation_1TOn_MultipleCalls
	RecursiveCTERelation_1TOn_MultipleCalls -->|"Yes"| CTEsNotTempTables["CTEs aren't temp tables. <br> The result won't be cached anyway. <br> This means the content of the CTE will  <br> need to run as many times as it's mentioned <br>  Check <ins>Using Common Table Expression (CTE) - Did you know...</ins>  <br>  <br>  <br> Try to get the data you need into a #temp  <br> table so you just hit that table(s) once <br> Then use the #temp table instead of/with  <br> the CTE"]
	CTEsNotTempTables --> Result_ImprovementYes

    Focus_CTE{"Does it use CTEs?"} -->|"No"| PartitionedTable
    PartitionedTable{"Does the query uses<br> partitioned tables?"} -->|"Yes"| PartitionEliminationParttern{"Is it using the partitioned <br> column(s) to filter?"}
	PartitionEliminationParttern -->|"Yes"| ExpectedPartitionElimination{"Do you see partition<br> elimination happening?"}
	ExpectedPartitionElimination -->|"Yes"| ContinueOptimization["TODO: Continue with optimization"]
	ExpectedPartitionElimination -->|"No"| DataTypesAndPercision["Double check if the column(s)<br> data type and percision match the <br> variable/table column used as filter."]
	DataTypesAndPercision --> FixDataTypePrecision{"By fixing this <br> do you now see <br> partition elimination?"}
	FixDataTypePrecision -->|"No"| FixDataTypePrecision_No["Click here to read Paul's White - <br> 'Why doesn't partition elimination work?"]
	FixDataTypePrecision -->|"Yes"| Result_ImprovementYes
	PartitionEliminationParttern -->|"No"| AddPartitionColumns{"Can the query be <br> changed to use them?"}
	AddPartitionColumns -->|"Yes"| DataTypesAndPercision

	click CTEsNotTempTables "https://claudioessilva.eu/2017/11/30/Using-Common-Table-Expression-CTE-Did-you-know.../" "Using Common Table Expression (CTE) - Did you know..."
    click FixDataTypePrecision_No "https://www.sql.kiwi/2012/09/why-doesn-t-partition-elimination-work.html" "Paul's White - 'Why doesn't partition elimination work?'"
