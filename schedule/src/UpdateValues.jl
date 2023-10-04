#UpdateValues.jl
#Get asset values 
#Note: Currently only gets from Yahoo

using DataFrames,Dates, Formatting, XLSX, MarketData, JSON

"Get the High Low Open Close from Yahoo"
function getHLOC(ticker, first::DateTime, last=DateTime(today()))
  try 
    df=DataFrame(yahoo(ticker, YahooOpt(period1=first, period2=last)))
  catch
    display("Unable to find ticker $ticker for $first")
    return missing
  end
  rows=size(df, 1)
  tdf=DataFrame(fill(ticker, (rows,1)), :auto)
  df=hcat(df, tdf)
  DataFrames.rename!(df, 8 => "Ticker")
end

"Read the history file and update or create if it does not exist"
function updateHistory(ticker, path, first::DateTime, saveOld=true)
  @info "Writing $ticker"
  tickerFileName=joinpath(path, ticker*".xlsx")
  hloc=getHLOC(ticker, first)
  if ismissing(hloc) return missing end
  tickerFile = if isfile(tickerFileName)
    df=DataFrame(XLSX.readtable(tickerFileName, 1))
    saveName=string(tickerFileName, "-", today(), ".save")
    if saveOld 
      @info "Saving old tickerFile $tickerFileName to $saveName"
      mv(tickerFileName, saveName, force=true) 
    end
    hloc=vcat(df, hloc)
  end
  XLSX.writetable(tickerFileName, hloc, overwrite=true, sheetname=ticker, anchor_cell="A1")
end

function saveTickers(path, tickers)
  open(path, "w") do io
    j = JSON.read(tickers)
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

function main(ARGS=ARGS)
  today=DateTime(Dates.today())
  @info "Started UpdateValues.jl @ $today"
  l=length(ARGS)
  (tickersPath, outputPath, days) =if l == 2
    ARGS[1], ARGS[2], :All
  else
    (tickersPath,outputPath, days ) = if l==3
      ARGS[1], ARGS[2], ARGS[3]
    else
      @error "Args: $ARGS"
      throw(ArgumentError("Illegal number of arguments. Expected 2 or 3, found $l : syntax: julia UpdateValues.jl tickerPath outputPath [days]"))
    end
  end
  if lowercase(days) == "all"
    first=firstDate
  else
    first=today-Dates.Day(parse(Int, days))
  end
  @info "First date = $first"
  tickers=getTickers(tickersPath)
  @info "Processing Tickers $tickers"
  map(t -> updateHistory(t, outputPath, first), tickers)
end

#main(ARGS)
#date=DateTime(2021,8,20)
#df=DataFrame(yahoo("MRNA", YahooOpt(period1=date)))
#getHLOC("MRNA", date)
#updateHistory("MRNA", "../test/MRNA.xlsx")