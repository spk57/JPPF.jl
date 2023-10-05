#UpdateValues.jl
#Script to create a schedule job to get asset values 
#Note: Currently only gets from Yahoo

using DataFrames,Dates, Formatting, XLSX, MarketData, JSON, ArgParse

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

const c=Channel(2)

"Get daily updates from cloud for asssets"
function updateJob()
  first=DateTime(today()-Dates.Day(1))
  tickersPath=take!(c)    
  outputPath=take!(c)
  @info "Processing Tickers File:  $tickersPath"
  tickers=getTickers(tickersPath)
  @info "Read Tickers File:  $tickers"
  @info "Updating history files"
  map(t -> updateHistory(t, outputPath, first), tickers)
  @info "Processing Complete"
end

function parseCommandLine()
  s = ArgParseSettings()
  @add_arg_table! s begin
     "--config", "-c"
     help = "Path to the configuration file"
     default="data/tickers.json"
     "--output", "-o"
     help = "Path to the output directory"
     default="output"
  end
  return parse_args(s)
end

"Parse command line and schedule repeated downloads for schedule"
function main()
  parsed=parseCommandLine()

  tickersPath=parsed["config"]
  put!(c,tickersPath)
  @info "Using Ticker File: $tickersPath"

  outputPath=parsed["output"]
  put!(c,outputPath)
  @info "Saving to folder: $outputPath"

  updateJob()
end

main()
