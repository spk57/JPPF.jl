#Update Holdings.jl
using DataFrames, Dates
include("Common.jl")

const holdingsChanges=Vector{Holding}()
holdings=Vector{Holding}()

"Bring forward the value of a holding from the previous date"
replicateHolding(h, date)=Holding(date, h.stock, h.count)

"Bring forward the value of all holdings from the previous date"
#replicateHoldings(holdings, date)=map(h-> replicateHolding(h, date), filterZero(holdings, date))
replicateHoldings(holdings, date)=map(h-> replicateHolding(h, date), holdings)

"Find a holding in a list of holdings"
findHolding(holdings, symbol)=findnext(h -> h.stock.symbol == symbol, holdings,1)

"Update a holding"
function updateHolding!(h, changes) 
  thisChange=findHolding(changes, h.stock.symbol)
  h.count+=changes[thisChange].count
  h
end

"""Updates holdings to totals by day
   Note:  Initial day holdings assumed to be complete as of that date
     For each day in the date range
       Find holdings for the previous day
       Replicate holdings from previous day for today
       Update holings with changes from today 
"""
function fillOutHoldings!(holdings, holdingsChanges, fromDate::Date, toDate::Date=today())
  startDate=fromDate+Day(1)
  dateRange=startDate:Day(1):toDate
  for day in dateRange
    #Find all holdings from yesterday that have not been sold
    yesterdayHoldings = filter(x -> x.date == day-Day(1) && x.count > 0.0, holdings)
    #TODO Filter out zero value holdings from yesterday 
    #Replicate holdings from yesterday to today 
    todayHoldings=replicateHoldings(yesterdayHoldings, day)

    #Find changes from today
    todayChanges = filter(x -> x.date == day, holdingsChanges)

    #Get the changes to exising holdings
    holdingsToUpdate=filter(h -> h in todayChanges, todayHoldings) #Set of existing holdings with changes today   
    #Update holdings for changes today
    changedHoldings=map(h -> updateHolding!(h, todayChanges), holdingsToUpdate)

    #Get the New Holdings
    newHoldings=filter(c -> !(c in todayHoldings), todayChanges) #Set of new holdings with changes today

    #Get todays holdings which did not change
    changedAndNew=vcat(changedHoldings, newHoldings)
    unchangedHoldings=filter(h -> !(h in changedAndNew), todayHoldings) 
   
    holdings=vcat(holdings, unchangedHoldings, changedAndNew)
  end
  holdings
end

