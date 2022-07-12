#Update Holdings.jl
using DataFrames, Dates
include("Common.jl")

const holdingsChanges=Vector{Holding}()
holdings=Vector{Holding}()

"Bring forward the value of a holding from the previous date"
replicateHolding(h, date)=Holding(date, h.stock, h.count)

"Filter out Zero value holdings"
filterZero(holdings, date)=filter(h -> !isapprox(h.count,  0.0) && h.date == date, holdings)

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
    #Find all holdings from yesterday 
    yesterdayHoldings = filter(x -> x.date == day-Day(1) && x.count > 0.0, holdings)
    #TODO Filter out zero value holdings from yesterday 
    #Replicate holdings from yesterday to today 
    todayHoldings=replicateHoldings(yesterdayHoldings, day)

    #Find changes from today
    todayChanges = filter(x -> x.date == day, holdingsChanges)

    #Get the changes to exising holdings
    #TODO figure out why intersect does not work here
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

#TODO if holding count == 0 delete
#Sample data for holdings
JPM=Stock("JPM", "JP Morgan and Chase")
INTC=Stock("INTC", "Intel Corporation")
AMD=Stock("AMD", "AMD Devices")
BNS=Stock("BNS", "Bank of Nova Scotia")
TM=Stock("TM", "Toyota Motors")
push!(holdingsChanges, Holding(today()-Day(4), JPM, 20))
push!(holdingsChanges, Holding(today()-Day(3), INTC, 30))
push!(holdingsChanges, Holding(today()-Day(2), AMD, 40))
push!(holdingsChanges, Holding(today()-Day(1), AMD,  50))
push!(holdingsChanges, Holding(today()-Day(1), JPM, -20))
fHoldings=fillOutHoldings!(holdings, holdingsChanges, today()-Day(5))
show(stdout, MIME("text/csv"), DataFrame(fHoldings))