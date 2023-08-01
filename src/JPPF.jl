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

const htmlStr="~~~"
"write and flush a string to the io"
writefl(io, str)=begin write(io, str);flush(io)end

"write an HTML string to the output"
writeHTML(io, str)=write(io, string(htmlStr, str, htmlStr))

const anaSuffix="_ANA"
"get a list of analysis folders"
getAnalysisFolders(dir)= filter(f-> occursin(anaSuffix, f),  readdir(dir))

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
  indexWeb=joinpath(webPath, "index.md")
  @info "Index.md $indexWeb"
  anapath=joinpath(webPath, Dates.format(today, "yyyymm")* anaSuffix)
  isdir(anapath) ? println("[ Note: Analysis Path already exists $anapath") : mkpath(anapath)
  @info "Analysis Path: $anapath"
  anaFolders=getAnalysisFolders(webPath)
  @info "Analysis Folders: $anaFolders"
#  indexIO=open(indexWeb, "a")
#  t=startWeb(webPath)

end

end
