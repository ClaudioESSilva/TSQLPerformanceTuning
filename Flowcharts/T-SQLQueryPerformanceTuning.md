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
