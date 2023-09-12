# T-SQL Performance Tuning

Try to find out why a query is slow and get suggestions to fix it.

## Flowcharts

In the [Flowcharts](./Flowcharts) directory you will find some "decision trees" built with mermaid. 
These flowcharts are meant to help you find a reason why your SQL Server query may have performance issues and suggest some ideas to fix it.

Mainly the suggestions will be around code re-write. 

## DISCLAIMER - Please read it: 
The suggestions made can be anywhere between, a harmless code change, to turning some "switch" on (for example: database scoped configurations). 
Keep in mind these can have other impacts.

Be sure you test these in a proper environment with a proper workload (when applicable) before you push these changes to production!

This isn't a silver bullet neither an exhaustive list of the existing options.  
There are many variables and combinations that will make cause different results.  

That said, these are high-level flowcharts that will try to guide you and may or not lead you to the possible cause and/or solution.

Hopefully, it will give you more ideas about where to look.

## Contributing
Have you found something missing? I'm sure you will find it!
Please open an "Issue" and let me know what you found, maybe a typo, maybe a missing example that you see every day and you would like to see unfold here.

NOTE: As of now, I'm not accepting PR (pull requests), as I'm not yet fixed to this way of visualizing the charts but, "Issues" are open and welcomed.

## Future plans
- Adding some demos
- Work on an "automatic" query analyzer to check if it's feasible for some scenarios
