#UjulipdateValues.jl
using DataFrames,Dates, Formatting, XLSX, MarketData, JSON3, Logging

firstDate=DateTime(2021,1,1)
"Calculate the previous business day (M-F"
function lastBusinessDay(d)
  dow=Dates.dayofweek(d)
  if dow in [2,3,4,5,6] #T-Sa
    offset=1
  elseif dow == 1 #M
    offset=3
  else
    offset=2 #Su
  end
  d-Dates.Day(offset)
end

"Get the High Low Open Close from Yahoo"
function getHLOC(ticker, first, last=nothing)
  lastDate(last)=isnothing(last) ?  lastBusinessDay(now()) : lastBusinessDay(last) 
  try 
    df=DataFrame(yahoo(ticker, YahooOpt(period1=first, period2=lastDate(last))))
  catch
    @info("Unable to find ticker $ticker for $(string(first))")
    return missing
  end
  rows=size(df, 1)
  tdf=DataFrame(fill(ticker, (rows,1)), :auto)
  df=hcat(df, tdf)
  DataFrames.rename!(df, 8 => "Ticker")
end

"Read the history file and update or create if it does not exist"
function updateHistory(ticker, path, first=firstDate, lastDate=nothing)
  tickerFileName=joinpath(path, ticker*".xlsx")
  @info("Writing $ticker to $tickerFileName")
  if isfile(tickerFileName)
    tickerSheet=DataFrame(XLSX.readtable(tickerFileName, ticker)...)
    lastEntry=last(sort(tickerSheet, :timestamp), 1)
    lastDateinSet=lastEntry[1,:timestamp]
    @info "Found last date $lastDate"
    hloc=getHLOC(ticker, lastDateinSet+Dates.Day(1), lastDate)
    if ismissing(hloc) 
      return missing
    end
    updated=vcat(tickerSheet, hloc)
    #TODO Overwrite all cells.  updated to only append new values
    XLSX.writetable(tickerFileName, updated, overwrite=true, sheetname=ticker, anchor_cell="A1")
    return hloc
  else
    @info "Getting HLOC for $ticker from $first to $lastDate"
    hloc=getHLOC(ticker, first, lastDate)
    println("HLOC: $hloc")
    XLSX.writetable(tickerFileName, hloc, overwrite=true, sheetname=ticker, anchor_cell="A1")
    return hloc
  end
end

function saveTickers(path, tickers)
  open(path, "w") do io
    j = JSON.json(tickers)
    print(io, j)
  end
  j
end

function getTickers(path)
  open(path, "r") do io
    tickers = JSON.parse(io)
  end
  tickers
end

function main(ARGS)
  l=length(ARGS)
  (tickersPath, outputPath) =if l == 2
    ARGS[1], ARGS[2]
  else
    throw(ArgumentError("Illegal number of arguments. Expected 2, found $l : julia UpdateValues.jl tickerPath outputPath"))
  end
  tickers=getTickers(tickersPath)
  map(t -> updateHistory(t, outputPath), tickers)
end

#main(ARGS)
#date=DateTime(2021,8,20)
#df=DataFrame(yahoo("MRNA", YahooOpt(period1=date)))
#getHLOC("MRNA", date)
updateHistory("MRNA", "test")
tickers=["MRNA", "JPM", "AMD", "TM", "INTC"]
map(x-> updateHistory(x, "data"), tickers)