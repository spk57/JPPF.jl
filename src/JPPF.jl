"Julia Programmers Personal Finance"
module JPPF
using Dates, Pkg, JSON, DataFrames

include("PersonalFinance.jl")
include("setupFranklin.jl")
include("HTMLHelpers.jl")
include("Common.jl")
include("Match.jl")

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
## Analysis : 
"""
#TODO Fix Franklin Display 
const inputDataTemplate = """
@def title = "Julia Programmers Personal Finance Input Data"
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
function findOpenVersion(webPath, clearVersion)
  v=0
  if clearVersion #clear old versions for same date
    for outer v in 1:MAXVER
      p=joinpath(webPath, Dates.format(today, "yyyymm")* verFormat(v) * anaSuffix)
      if isdir(p) 
        rm(p, force=true, recursive=true) 
      else
        break
      end
    end
  end
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
function startup(dataDir="data", configFile="config.json", clearVersion=true)
  @info about()
  @info "dataDir: $dataDir"
  @info "configFile: $configFile" 

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
  anapath=findOpenVersion(webPath,clearVersion)
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

"HTML Display a formatted table or dictionary"
function dispTable(io, table, title, row_labels=nothing, show_header=false)
  s=pretty_table(String, table,  backend = Val(:html), show_header=show_header, row_labels=row_labels, show_subheader=false, title=title, alignment=:l)
  writeHTML(io, s)
end

"Log configuration information to the index web page"
function logConfig(io, config)
  println(io, "Analysis Date: $today")
  println(io, "* Start of Analysis Period: $(config["StartDate"])")
  println(io, "* Transaction Files: $(config["transactionFile"])")
  dispTable(io, sort(config["transactionMap"]), "Transaction Map")
  flush(io)
end

"Merge and cleanse transaction files"
function cleanseTransactions(dataDir, transFiles, config)
  transPaths=map(f -> joinpath(dataDir, f), transFiles) #Get paths for transaction files
  transactionMap=config["transactionMap"]
  trs=map(tp -> readTab(tp, 1), transPaths) #Rename columns to match expected
  transactions=reduce(vcat, trs,  cols=:union) #Merge transaction files
  cleanUp!(transactions, transactionMap)
  regularText=config["RegularExpressions"]
  regularDict=formatRE(regularText)
#  getType(s)=getType(s, regularDict)
  transactions=transform(transactions, :Action => ByRow(a -> getType(a, regularDict)) => :ActionCode)
  tNames=unique(transactions[!,:Symbol]) # Get unique named transactions
  syms=collect(skipmissing(map(stripMiss, tNames)))
  stocks=sort(filter(s -> !isnumeric(s[1]), syms))
  cds=sort(filter(s -> isnumeric(s[1]), syms))
  holdings=split(config["Holdings"], ",")
  (trans=transactions, syms=syms, stocks=stocks, cds=cds, holdings=holdings)
end

"Filter transactions"
isStock(t)=length(t) > 0 && !isdigit(strip(t)[1])
isCD(t::AbstractString)=length(t) > 0 && isdigit(strip(t)[1])
isANY(t)=true

"add or update holding history from the transaction"
function updateHolding!(holdingsHistory, transaction)
  sym=Symbol(transaction.Symbol)
  if !haskey(holdingsHistory, sym)
    h=Holding(sym)
    push!(holdingsHistory, sym =>  h)
  else
    h=holdingsHistory[sym]
  end
  set(h, transaction.Date, transaction.Value, transaction.Quantity)
end

"Use the transaction history to build a history of holdings"
function buildHoldingsHistory(transactions)
  #Transactions that change the amount of assets owned
  buySellcodes=[:Bought, :Sold, :Reinvestment] 
  fTransactions=filter(t -> t.ActionCode in buySellcodes,  transactions)
  holdingsHistory=Dict{Symbol, Holding}()
  map(ft -> updateHolding!(holdingsHistory, ft), eachrow(fTransactions))
  return holdingsHistory
end

"Log transaction information to the data web page"
function logData(io, tSum, config)
  println(io, "Analysis Date: $today")
  @info "Stocks: $(tSum.stocks)"
  writeHTML(io, collectionHTML(tSum.stocks, "Stocks"))
  writeHTML(io, collectionHTML(tSum.cds, "CDS"))
  writeHTML(io, collectionHTML(tSum.holdings, "Holdings"))
  
  #Summary information
  configTRE=config["RegularExpressions"]
  filt(s,is)=filter([:Action, :Symbol] => (a,sym) -> occursin(Regex(configTRE[s],"i"), a) && is(sym) , tSum.trans);
  tots=sort(map(k -> [k,  size(filt(k, isANY),1), size(filt(k, isStock),1), size(filt(k,isCD),1)], collect(keys(configTRE))))
  totM=reshape(collect(Iterators.flatten(tots)), (4,8))
  cols=totM[1,:]
  body=totM[2:end, :]
  totTab=DataFrame(body, cols)
  dispTable(io, totTab, "Transaction Totals", ["Total", "Stock", "CD"],  true)  
  flush(io)
end

function quarterSummary(io, tSum)
  #  sym=groupby(transactions, [:Symbol, :YQTR])
  transactions=tSum.trans
  qsym=groupby(transactions, [:Symbol, :YQTR])
  qsymAmt=combine(qsym, :Amount =>ByRow(+) => :Amount, :Symbol)
  @info "QSym Amt: $qsymAmt"
#  tsm=filter(:Symbol => s -> s=="TSM", transactions)
#  dispTable(io, tsm,"TSM")
end

"Calculate the profit and loss for a holding"
getProfitandLoss(holdings)=map(h-> (h, getProfit(holdings[h])), sort(collect(keys(holdings))))

function logAnalysis(io, tSum, config)
  startDate=Date(config["StartDate"], "dd-u-yyyy")
  println(io, "Analysis DateTime: $started")
  holdings=buildHoldingsHistory(tSum.trans)
  stockColl=[!isnothing(h.second.class) && isStock(h.second.class) ? h : nothing for h in holdings ]
  stockHoldings=filter(isnothing, [isStock(h.second.class) ? h : nothing for h in holdings ] )
  pl=getProfitandLossPerShare(stockHoldings)
  plt=getProfitTotal(stockHoldings)
  dispTable(io, pl, "Profit and Loss of holdings per Share")
  dispTable(io, plt, "Profit and Loss of holdings total")
#  quarters=collect(startDate:Quarter(1):lastdayofquarter(today()))
  quarterSummary(io, tSum)
  flush(io)
end

"Main program to run JPPF"
function run(dataDir="data", configFile="config.json", clearVersions=true)
  control=startup(dataDir, configFile, clearVersions)
  @info "Startup complete"
  logConfig(control.index, control.config)
  @info "logConfig complete"
  tSum=cleanseTransactions(dataDir, control.files, control.config)
  @info "CleanseTransactions complete"
  logData(control.input, tSum, control.config)
  @info "logData Complete"
  logAnalysis(control.analysis, tSum, control.config)
end#run

run("../jppfdata")
end #module
