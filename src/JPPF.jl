"Julia Programmers Personal Finance"
module JPPF
using Dates, Pkg, JSON, Hyperscript

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

const indexText = """
@def title = "Julia Programmers Personal Finance"
# Julia Programmers Personal Finance
Personal Finance Tools intended to be flexible for people with Julia Language development skills. 
## Analysis Folders: 
"""
const folderIndex = """
@def title = "Julia Programmers Personal Finance Folder"
## Analysis Folder: 
"""

const sp=" "
"Parse Dir Name"
parseDirName(dir)=monthabbr(parse(Int, SubString(dir, 5:6))) * sp * SubString(dir, 1:4) * sp * SubString(dir, 7:9)

"Write the index.md file within a folder"
writeFolderIndex(path)=write(path, folderIndex)

hTable=m("table")
tr=m("tr")
th=m("th")
td=m("td")

"Build html representation of a header"
tableHeader(table)=map(th, columnnames(table))

"Build html representation of a row"
tableRow(table, row)=tr(map(td, values(table[row])))

"Build html representation of all rows"
tableBody(table)=map(r -> tableRow(table, r), 1:length(table))

"Build html representation of a table"
tableHTML(table)=hTable(tableHeader(table), tableBody(table))

"Build Markup representation directory list"
function dirMarkupList(dir) 
  label=parseDirName(dir)
  string("* [", label, "](", dir, ")")
end

"Main function to run JPPF"
function run(dataDir="data", configFile="config.json", rVersion="v01", port=8001)
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
  anapath=joinpath(webPath, Dates.format(today, "yyyymm")* rVersion * anaSuffix)
  isdir(anapath) ? println("[ Note: Analysis Path already exists $anapath") : mkpath(anapath)
  @info "Analysis Path: $anapath"
  open(indexWeb, "w") do indexIO
    write(indexIO, indexText)
    folders=getAnalysisFolders(webPath)
    folderList=map(dirMarkupList, folders)
    @info "Analysis Folders $folderList"
    map(f -> println(indexIO, f), folderList)
  end
  t=startWeb(webPath)
end #run
end #module
