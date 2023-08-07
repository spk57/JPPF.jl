"Julia Programmers Personal Finance"
module JPPF
using Dates, Pkg, JSON

include("PersonalFinance.jl")
include("setupFranklin.jl")
include("HTMLHelpers.jl")

const version=Pkg.project().version
const today=Dates.today()
const started=Dates.now()
const startDir=pwd()
const program=@__MODULE__

about()="$program Version: $version $(string(started))"

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
@def title = "Julia Programmers Personal Finance Configuration Summary"
## Analysis Details: 
* [Analysis](analysis)
* [Input Data](inputData)
## Analysis Configuration Summary: 
"""
const analysisTemplate = """
@def title = "Julia Programmers Personal Finance Analysis"
[Configuration](index)
## Analysis : 
"""
#TODO Fix Franklin Display 
const inputDataTemplate = """
@def title = "Julia Programmers Personal Finance Input Data"
[Configuration](index)
## Input Data : 
"""

const sp=" "
"Parse Dir Name"
parseDirName(dir)=monthabbr(parse(Int, SubString(dir, 5:6))) * sp * SubString(dir, 1:4) * sp * SubString(dir, 7:9)

"Write the index.md file within a folder"
writeFolderIndex(path)=write(path, folderIndex)

"Build Markup representation directory list"
function dirMarkupList(dir) 
  label=parseDirName(dir)
  string("* [", label, "](", dir, ")")
end

"Open a Markdown file with the given template"
function openMD(path, file, template)
  p=joinpath(path, file)
  io=open(p, "w") 
  write(io, template)
  flush(io)
  return io 
end

"Format the version number for file versions"
verFormat(v)="v"*string(v, pad=2)
verParse(sv)=parse(Int, SubString(sv, 2:3))
const MAXVER=99

"Find the next unused version number"
function findOpenVersion(webPath)
  #Create a folder for the analysis if it doesn't already exist
  local p
  v=0
  for outer v in 1:MAXVER
    p=joinpath(webPath, Dates.format(today, "yyyymm")* verFormat(v) * anaSuffix)
    if !isdir(p) break end
  end
  if v >= MAXVER throw(OverflowError("Max version exceeded $v")) end
  return p
end

"Strip whitespace, return missing if nothing there"
stripMiss(s)=length(strip(s)) > 0 ? s : missing

"start up JPPF"
function startup(dataDir="data", configFile="config.json", port=8001)
  @info about()
  @info "dataDir: $dataDir"
  @info "configFile: $configFile" 
  @info "port: $port"

  #Read the configuration file"
  configPath=joinpath(dataDir, configFile)
  configStr=read(configPath, String)
  config=JSON.parse(configStr)["Config"]
  startDate=Date(config["StartDate"], "dd-u-yyyy")
  @info "Start Date: $startDate"
  transFiles=map(strip, split(config["transactionFile"], ","))
  @info "Transaction Files: $transFiles"
  webPath=joinpath(dataDir, config["webFolder"])
  @info "Web Path: $webPath"
  indexWeb=joinpath(webPath, "index.md")
  @info "Index.md $indexWeb"
  anapath=findOpenVersion(webPath)
  mkpath(anapath)
  @info "Created analysis folder $anapath"

  #Set up markup files in the folder
  indexMarkdown="index.md"
  indIO=openMD(anapath, indexMarkdown, folderIndex)
  @info "Created markdown file index $indexMarkdown"

  analysisMarkdown="analysis.md"
  anaIO=openMD(anapath, analysisMarkdown, analysisTemplate)
  @info "Created markdown file Analysis markup $analysisMarkdown "
  
  inputDataMarkdown="inputData.md"
  idIO=openMD(anapath, inputDataMarkdown, inputDataTemplate)
  @info "Created markdown file Input Data markup $inputDataMarkdown "

  #Copy config file to the analysis folder
  folderConfig=joinpath(anapath, configFile)
  cp(configPath, folderConfig)

  #List all of the Analysis folders on the web site
  @info "Analysis Path: $anapath"
  open(indexWeb, "w") do indexIO
    write(indexIO, indexText)
    folders=getAnalysisFolders(webPath)
    folderList=map(dirMarkupList, folders)
    @info "Analysis Folders $folderList"
    map(f -> println(indexIO, f), folderList)
  end

  t=startWeb(webPath)
  (index=indIO, input=idIO, analysis=anaIO, config=config, files=transFiles)
end #startup

"Log configuration information to the index web page"
function logConfig(io, config)
  println(io, "Analysis Date: $today")
  println(io, "* Start of Analysis Period: $(config["StartDate"])")
  pretty_table(io, config["transactionFile"], backend = Val(:html), show_header=false, title="Transaction Files", alignment=:l)
  println(io, "* Transaction Map: $(config["transactionMap"])")
  flush(io)
end

"Merge and cleanse transaction files"
function cleanseTransactions(dataDir, transFiles, config)
  transPaths=map(f -> joinpath(dataDir, f), transFiles) #Get paths for transaction files
  transactionMap=config["transactionMap"]
  trs=map(tp -> readTab(tp, 1), transPaths) #Rename columns to match expected
  transactions=reduce(vcat, trs,  cols=:union) #Merge transaction files
  cleanUp!(transactions, transactionMap)
  tNames=unique(transactions[!,:Symbol]) # Get unique named transactions
  syms=collect(skipmissing(map(stripMiss, tNames)))
  @info "Symbols from Transaction files: $syms"
  stocks=sort(filter(s -> !isnumeric(s[1]), syms))
  @info "Stocks from Transaction files: $stocks"
  cds=sort(filter(s -> isnumeric(s[1]), syms))
  holdings=split(config["Holdings"], ",")
  (trans=transactions, syms=syms, stocks=stocks, cds=cds, holdings=holdings)
end

"Log transaction information to the data web page"
function logData(io, tSum)
  println(io, "Analysis Date: $today")
  @info "Stocks: $(tSum.stocks)"
  writeHTML(io, collectionHTML(tSum.stocks, "Stocks"))
  writeHTML(io, collectionHTML(tSum.cds, "CDS"))
  flush(io)
end

"Main program to run JPPF"
function run(dataDir="data", configFile="config.json", port=8001)
  control=startup(dataDir, configFile, port)
  logConfig(control.index, control.config)
  tSum=cleanseTransactions(dataDir, control.files, control.config)
  logData(control.input, tSum)
end#run

end #module
