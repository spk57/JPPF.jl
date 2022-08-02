# Common.jl
using Dates
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

Base.@kwdef mutable struct Holding
  date::Date
  name::Symbol
  count::Float16
  value::Union{Missing, Holding}
end
Holding(date::Date, name::Symbol, count::Float16)=Holding(date, name, count, missing)
  
Base.string(h::Holding)=string(h.date,sep, h.name, sep, h.count, sep, h.value)
Base.show(io::IO, h::Holding)=show(io,string(h))

<(h1::Holding, h2::Holding)=isless(h1,h2)
Base.isless(h1::Holding, h2::Holding)=h1.date < h2.date
==(h1::Holding, h2::Holding)=h1.name.symbol==h2.name.symbol
Base.isequal(h1::Holding, h2::Holding)=isequal(h1.name.symbol, h2.name.symbol)

dateTickerKey(date, ticker)=string(date, ticker)

function readMarket(marketFile)
  mdf=DataFrame(XLSX.readtable(marketFile, 1));
  mdf.Close=convert(Vector{Float64}, mdf.Close);    
  mdf
end

stripXLSX(s)=split(s, ".")[1]

function readMarkets(marketDir)
  marketFiles=readdir(marketDir)    
  marketPaths=map(x -> joinpath(marketDir, x), marketFiles)
  markets = map(readMarket, marketPaths) 
  marketArr = map(readMarket,  marketPaths)
  markets=reduce(vcat, marketArr)
  marketNames=map(stripXLSX, marketFiles)
  (markets, marketNames)
end

function readHoldings(holdingsFile, nameMap, first_row)
  hdf=DataFrame(XLSX.readtable(holdingsFile, 1, first_row=first_row));
  hdfs=select(hdf, nameMap...)
  filter(h -> !ismissing(h.Quantity), (hdfs)
end