# T-SQL Performance Tuning

Try to find why a query is slow and get suggestions to fix it.

## Flowcharts

In the [Flowcharts](./Flowcharts) directory you will find some "decision tree" build with mermaid. 
These flowcharts are meant to help you find a reason why your SQL Server query may have performance issues and suggest some ideas to fix it.

Mainly the suggestions will be around code re-write. 

## DISCLAIMER - Please read it: 
The suggestions made can be anywhere between, a harmless code change to turn some "switch" on (for example: database scoped configurations). 
Keep in mind these can have other impacts.

Be sure you test these on a proper environment with proper workload (when applicable) before you put it on production!

This isn't a silver bullet neither an exhaustive list of the existing options.  
There are too many variables and combinations that will make the things go different.  

That said, this are high level flowcharts that will try to guide you and may or not lead you to the possible cause and/or solution.

Hopefully, it will give you more ideas where to look at.

## Contributing
Do you found something missing? I'm sure you will find it!
Please open an "Issue" and let me know what you found, maybe a typo, maybe a missing example that you see every day and you would like to see unfold here.

NOTE: As of now, I'm not accepting PR (pull requests), as I'm not yet fixed to this way of visualizing the things but, "Issues" are open.

## Future plans
- Adding some demos
- Work on an "automatic" query analyzer to check if it's feasible for some scenarios
