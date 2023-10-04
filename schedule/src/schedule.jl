using JobSchedulers
using Dates
include("UpdateValues.jl")
#scheduler_start()

cron=Cron(0,0,0,0,0,"2-6")
c=Channel(2)

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

tickersPath="../data/tickers.json"
outputPath="../output"
put!(c,tickersPath)
@info "Using Ticker File: $tickersPath"
put!(c,outputPath)
@info "Saving to folder: $outputPath"
#task=Task(updateJob)
#j=Job(task, cron=cron, until(Day(10)))
#submit!(j)
updateJob()