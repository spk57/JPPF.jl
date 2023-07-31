"Julia Programmers Personal Finance"
module JPPF
using Dates, Pkg, JSON

#include("PersonalFinance.jl")
include("setupFranklin.jl")
const version=Pkg.project().version
const today=Dates.today()
const started=Dates.now()
const startDir=pwd()
const program=@__MODULE__

about()="$program Version: $version $(string(started))"

"Main function to run JPPF"
function run(dataDir="data", configFile="config.json", port=8001)
  @info about()
  @info "dataDir: $dataDir"
  @info "configFile: $configFile" 
  @info "port: $port"
  configPath=joinpath(dataDir, configFile)
  configStr=read(configPath, String)
  config=JSON.parse(configStr)["Config"]
  startDate=Date(config["StartDate"], "dd-u-yyyy")
  @info "Start Date: $startDate"
  transFiles=map(strip, split(config["transactionFile"], ","))
  @info "Transaction Files: $transFiles"
  transPaths=map(f -> joinpath(dataDir, f), transFiles)
  transactionMap=config["transactionMap"]
  tKey=sort(collect(keys(transactionMap)))
  configTRE=config["RegularExpressions"]
  webPath=joinpath(dataDir, config["webFolder"])
  @info "Web Path: $webPath"
  t=startWeb(webPath)
end

end
