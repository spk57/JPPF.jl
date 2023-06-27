#RetirementBudget.jl
#utility methods for RetirementBudget.ipynb

tabsNames=["Summary","Expense", "Income", "Assumptions", "Scenarios", "Personal", "Values"]

"read budget estimates from an excel file. 
Returns a Dict of names, dataframes from the loaded tabs"
function readRetirementBudget(xls)
  tabs=Dict{Symbol, DataFrame}()
  "Push a name and tab dataframe onto the dictionary"
  pushTab(tabName)=push!(tabs, Symbol(tabName)=>readTab(xls, tabName))
  tabDict=map(t -> pushTab(t), tabsNames )
  tabs
end

"get a scenario"
getScenario(tabs, s)=filter(row -> row.ID == s, tabs[:Scenarios])

"Get the income and expense elements for a scenario"
function getScenarioElements(scenarioTab)
  expSet=iRange(scenarioTab.Expenses[1])
  incSet=iRange(scenarioTab.Income[1])
  (expSet, incSet)
end

"Convert an index range to a set of indices"
function iRange(ir)
  parseInt(s)=parse(Int, s)
  if occursin(";", ir)  
    points=map(parseInt, split(ir, ";"))
  elseif occursin(">", ir) 
    r=parseInt.(split(ir, ">"))
    points=[x for x in r[1]:r[2]]
  else
    error("Illegal separator in $ir value must be either a set delimited by ; (set) or > (range).  ") 
  end
end

"Filter elements to match the scenario"
filterScenario(range, df)=filter( :ID => id -> id in range , df)
