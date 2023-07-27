# Common.jl
using Dates, DataFrames
import Base.<, Base.==, Base.show, Base.string

abstract type Asset end

abstract type Property <: Asset end
abstract type Investment <: Asset end
abstract type Cash <: Asset end

abstract type House <: Property end

abstract type Bond <: Investment end
abstract type Equity <: Investment end

# simple functions on abstract types
describe(a::Asset) = "Something valuable"
describe(e::Investment) = "Financial investment"
describe(e::Property) = "Physical property"
describe(e::House) = "Owned Home"
describe(e::Bond) = "Fixed income investment loaned to an entity"
describe(e::Equity) = "Shares in a company"

const sep=":"
"Convert a Struct to a DataFrame.  xs is an array of struct s"
st2df(xs, s)=DataFrame(Dict(n=>[getfield(x, n) for x in xs] for n in fieldnames(s)))

Base.@kwdef mutable struct Holding
  date::Date
  name::Symbol
  count::Float16
  value::Union{Missing, Float16}
end
Holding(date::Date, name::Symbol, count)=Holding(date, name, count, missing)
#Holding(t)=Holding(t.date, t.name, t.count, t.value)  
Base.string(h::Holding)=string(h.date,sep, h.name, sep, h.count, sep, h.value)
Base.show(io::IO, h::Holding)=show(io,string(h))

<(h1::Holding, h2::Holding)=isless(h1,h2)
Base.isless(h1::Holding, h2::Holding)=h1.date < h2.date
==(h1::Holding, h2::Holding)=h1.name==h2.name
Base.isequal(h1::Holding, h2::Holding)=isequal(h1.name, h2.name)

dateTickerKey(date, ticker)=string(date, ticker)

function readMarket(marketFile)
  mdf=DataFrame(XLSX.readtable(marketFile, 1));
  mdf.close=convert(Vector{Float64}, mdf.Close);  
  mdf.date=convert(Vector{Date}, mdf.timestamp)
  mdf.name.=Symbol.(mdf.Ticker)
  mdf
end

stripXLSX(s)=split(s, ".")[1]

function readMarkets(marketDir)
  marketFiles=readdir(marketDir)    
  marketPaths=map(x -> joinpath(marketDir, x), marketFiles)
  markets = map(readMarket, marketPaths) 
  marketArr = map(readMarket,  marketPaths)
  markets=reduce(vcat, marketArr)
  markets=select(markets, Between(:close, :name))
  marketNames=map(stripXLSX, marketFiles)
  (markets, marketNames)
end

const mdy=DateFormat("mm/dd/yyyy")

const nameMap=(1=>:Date, 4=>:Symbol, 7=>:Quantity, 8=>:Price)
const nameMap2=(5=>:Date, 6=>:Symbol, 7=>:Quantity, 8=>:Price)
"Read the holdings file and return a df with no missing values"
function readHoldings(holdingsFile, first_row)
  hdf=DataFrame(XLSX.readtable(holdingsFile, 1, first_row=first_row));
  hdfs=select(hdf, nameMap...)
  nomiss=filter(h -> !ismissing(h.Quantity), hdfs)
  nomiss.d2.= Date.(lstrip.(nomiss.Date), mdy);  
  nomiss.s2.=Symbol.(strip.(nomiss.Symbol))  
  nomiss.q2.=convert.(Float16, nomiss.Quantity)
  nomiss.v2.=convert.(Float16, nomiss.Price)
  select(nomiss, nameMap2...)
end

"Load a holdings df into an array of Holdings"
function loadHoldings(rh)
  map(h -> Holding(h.Date, h.Symbol, h.Quantity, h.Price), copy.(eachrow(rh)))
end

 "Calculate the minumum closing value for each equity"
function getMinClose(gmarkets)
  closeHL=combine(gmarkets, :Close => minimum)
  minClose=Dict{String, Float64}()
  [minClose[closeHL[r, :Ticker]] = closeHL[r, :Close_minimum]  for r in eachrow(closeHL)]
  minClose
end

"Get the first and last date for the charts"
function getDateRange(market)
  #TODO get actual first and last, don't assume positions
  first=market[1,:timestamp]
  last=market[end,:timestamp]
  dateRange=first : Day(1) : last
end

function plotTicker(markets, marketNames, pos)
  dateRange=getDateRange(markets[pos])
  lines!(days, markets[pos].Close, label=marketNames[pos])
end