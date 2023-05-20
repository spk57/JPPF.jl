#UjulipdateValues.jl
#Get asset values 
#Note: Currently only gets from Yahoo
#TODO Update ticker file for daily 

using DataFrames,Dates, Formatting, XLSX, MarketData, JSON

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
    display("Unable to find ticker $ticker for $(string(startDate))")
    return missing
  end
  rows=size(df, 1)
  tdf=DataFrame(fill(ticker, (rows,1)), :auto)
  df=hcat(df, tdf)
  DataFrames.rename!(df, 8 => "Ticker")
end

"Read the history file and update or create if it does not exist"
function updateHistory(ticker, path, first=firstDate, last=nothing)
  println("Writing $ticker")
  tickerFileName=joinpath(path, ticker*".xlsx")
  tickerFile = if isfile(tickerFileName)
    throw(ErrorException("Unimplemented to update history file"))
  else
    hloc=getHLOC(ticker, first, last)
    XLSX.writetable(tickerFileName, hloc, overwrite=true, sheetname=ticker, anchor_cell="A1")
  end
end

function saveTickers(path, tickers)
  open(path, "w") do io
    j = JSON.read!(tickers)
    print(io, j)
  end
  j
end

function getTickers(path)
  open(path, "r") do io
    tracklist=JSON.parse(io)
    tracklist["trackList"]
  end
end

function main(ARGS)
  l=length(ARGS)
  (tickersPath, outputPath) =if l == 2
    ARGS[1], ARGS[2]
  else
    println("Args: $ARGS")
    throw(ArgumentError("Illegal number of arguments. Expected 2, found $l : julia UpdateValues.jl tickerPath outputPath"))
  end
  tickers=getTickers(tickersPath)
  @info "Processing Tickers $tickers"
  map(t -> updateHistory(t, outputPath), tickers)
end

main(ARGS)
#date=DateTime(2021,8,20)
#df=DataFrame(yahoo("MRNA", YahooOpt(period1=date)))
#getHLOC("MRNA", date)
#updateHistory("MRNA", "../test/MRNA.xlsx")