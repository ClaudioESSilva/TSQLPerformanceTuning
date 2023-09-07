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

    Focus_WhereClause["Lets focus on the WHERE clause"]
    RecursiveCTERelation_1TOn_MultipleCalls -->|"No"| Focus_WhereClause
    PartitionedTable -->|"No"| Focus_WhereClause
    Focus_WhereClause --> Pattern_LongInClause{"Does the query have a <br> long IN clause? <br> Ex: 'ID IN (1,2,3...,19,21)'"}
	Pattern_LongInClause -->|"Yes"| Fix_LongInClause["If you see a CONSTANT SCAN or FILTER <br>operator on the  plan with big cost this <br> will most probably be the problem. <br><br> Replace the long in clause by either: <br> (1) using the BETWEEN clause or <br> (2) a temp table <br> (3) Table variable can also work but <br> be aware that can make query run <br> in serial if pre 2019 or if <br> DEFERED_COMPILATION_TV is OFF"]
	Fix_LongInClause --> Result_ImprovementYes
	
    Pattern_LongInClause -->|"No"| Pattern_LongListOfAndOr{"What about a mix of <br> of AND/OR filters?"}
	Pattern_LongListOfAndOr -->|"Yes"| Fix_MutilpleANDsORs["If possible combine them on a temp table. <br> Sometimes this is not possible and one other workaround <br> would be split the query into 2 or more joined by UNION (ALL). <br><br> The UNION (ALL) will act as the 'OR'. <br> Each SELECT should only have a part of the filter. <br><br> Be careful with the logic. Some times this queries <br>has so much parenthesis that makes it confuse to split."]
	Fix_MutilpleANDsORs --> Result_ImprovementYes

    Pattern_LongListOfAndOr -->|"No"| Pattern_NativeFunctions{"Do you see native functions such as <br> SUBSTRING, LEN, DATEPART,<br>  CAST, CONVERT etc, being used on the table's columns? <br><br>Examples: <br>(1) 'DATEPART(YEAR, ModifiedDate) = 2023' <br> or <br>(2) 'LEN(PostalCode) = 4'<br> or <br>(3) CAST(t.Date AS DATE) = CAST(GETDATE() AS DATE)"}
	Pattern_NativeFunctions -->|"Yes"| Fix_NativeFunctions["Most probably you are getting an 'Index Scan' operator <br> instead of a 'Index Seek' and/or a big number of records <br> being read whereas you were expecting just a few of them. <br> <br> Rewrite that clause in a way that you <br> don't touch the table column. <br> Instead apply the logic to the constant part. <br> Ex: <br> (1) ModifiedDate &gt;= '2023-01-01' AND ModifiedDate &lt; '2024-01-01' <br> (2) PostalCode &gt; 999 AND PostalCode &lt; 10000 <br> (3) t.Date &gt;= CAST(GETDATE() AS DATE) <br> AND t.Date &lt; CAST(DATEADD(dd, 1, GETDATE()) AS DATE)"]
	Fix_NativeFunctions --> Result_ImprovementYes

	Focus_SelectWhere["Lets keep in mind the whole query again"]
    Pattern_NativeFunctions -->|"No"| Focus_SelectWhere
	Focus_SelectWhere --> Pattern_ScalarUDF{"What about Scalar User <br> Defined Functions (UDF)?"}
	Pattern_ScalarUDF -->|"Yes"| CheckVersion_ScalarUDF{"Is database compatibility <br> level 150 (2019) or higher?"}
	CheckVersion_ScalarUDF -->|"No"| Attention_WontParallelise["Your query won't parallelize!"]
            %% Fix_LongInClause
	Attention_WontParallelise --> Version_ScalarUDFNot2019["Try to pull the code from the function into <br> a CROSS/OUTER APPLY and then do the check. <br><br> Make sure you test the scenario correctly. <br> Use the OUTER if you need to still need <br> to return 'NULL' values."]
	CheckVersion_ScalarUDF -->|"Yes"| Version_ScalarUDF2019Or+_Inlineable{"Is the scalar <br> UDF <ins>inlineable</ins>? <br> <br> Query the <br> sys.sql_modules <br> to find out"}
	Version_ScalarUDF2019Or+_Inlineable -->|"Yes"| UDFInlineableCheckSC{"Is the <br> 'TSQL_SCALAR_UDF_INLINING' <br> database scoped <br> configuration turned ON?"}
	UDFInlineableCheckSC -->|"No"| Attention_UDFInlineableCheckSC["This option is ON by default, be aware that if you found <br> it OFF may be theris a good reason. <br><br> You can use a query HINT to disable it but not to enable. <br> You can, out of curiosity, turn it on and check <br> if it will make a difference"]
	Attention_UDFInlineableCheckSC -->|"However..."| Version_ScalarUDFNot2019
	UDFInlineableCheckSC -->|"Yes"| Version_ScalarUDFNot2019
	Version_ScalarUDF2019Or+_Inlineable -->|"No"| Note_ReasonsNotInlineable["There are a lot of requirements that <br> need to be met for a scalar UDF to be inlineable. <br> Check <ins>'Inlineable scalar UDF requirements</ins>'"]
	Note_ReasonsNotInlineable -->|"Workaround"| Version_ScalarUDFNot2019
	Version_ScalarUDFNot2019 --> Result_ImprovementYes

	click CTEsNotTempTables "https://claudioessilva.eu/2017/11/30/Using-Common-Table-Expression-CTE-Did-you-know.../" "Using Common Table Expression (CTE) - Did you know..."
    click FixDataTypePrecision_No "https://www.sql.kiwi/2012/09/why-doesn-t-partition-elimination-work.html" "Paul's White - 'Why doesn't partition elimination work?'"
    click Note_ReasonsNotInlineable "https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/scalar-udf-inlining?view=sql-server-ver16#requirements" "Inlineable scalar UDF requirements"