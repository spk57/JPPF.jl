#Update Holdings.jl
using DataFrames, Dates
include("Common.jl")

const holdingsChanges=Vector{Holding}()
holdings=Vector{Holding}()

"Bring forward the value of a holding from the previous date"
replicateHolding(h, date)=Holding(date, h.stock, h.count)

"Bring forward the value of all holdings from the previous date"
replicateHoldings(holdings, date)=map(h-> replicateHolding(h, date), holdings)

"Find a holding in a list of holdings"
findHolding(holdings, symbol)=findnext(h -> h.stock.symbol == symbol, holdings,1)

"Update a holding"
function updateHolding!(h, changes) 
  thisChange=findHolding(changes, h.stock.symbol)
  h.stock.count+=thisChange.stock.count
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
    previousHoldings = filter(x -> x.date == day-Day(1), holdings)
    todayHoldings=replicateHoldings(previousHoldings, day)
    todayChanges = filter(x -> x.date == day, holdingsChanges)#Changes today 
    existingChanges=∩(todayChanges, todayHoldings) #Set of existing holdings with changes today
    newChanges=setdiff(todayChanges, todayHoldings) #Set of new holdings with changes today
    todayNotChanged=setdiff(todayHoldings, todayChanges)
    todayPlusExisting=map(h -> updateHoldings(h, todayChanges), existingChanges)
    holdings=vcat(holdings, newChanges, todayPlusExisting, todayNotChanged)
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
fillOutHoldings!(holdings, holdingsChanges, today()-Day(5))