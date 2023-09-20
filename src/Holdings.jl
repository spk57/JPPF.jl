# Common.jl
using Dates, DataFrames,  InlineTest
import XLSX
import Base.<, Base.==, Base.show, Base.string

abstract type Asset end

abstract type Property <: Asset end
abstract type Investment <: Asset end
abstract type Cash <: Asset end

abstract type House <: Property end

abstract type Bond <: Investment end
abstract type CD <: Bond end
abstract type Equity <: Investment end

# simple functions on abstract types
describe(a::Asset) = "Something valuable"
describe(e::Investment) = "Financial investment"
describe(e::Property) = "Physical property"
describe(e::House) = "Owned Home"
describe(e::Bond) = "Fixed income investment loaned to an entity"
describe(e::CD) = "Fixed income investment from a Bank"
describe(e::Equity) = "Shares in a company"

const sep=":"
"Convert a Struct to a DataFrame.  xs is an array of struct s"
st2df(xs, s)=DataFrame(Dict(n=>[getfield(x, n) for x in xs] for n in fieldnames(s)))

"The value of one Asset at a particular time"
struct AssetValue
  date::Date
  value::Float64
  change::Float64
  total::Float64
end

"The price range for an equity today"
struct EquityDailyPrice 
  high::Float64
  low::Float64
  Open::Float64
  Close::Float64
  date::Date
end

struct EquitySpotPrice
  price::Float64
  date::DateTime
end

"Information about a Holding"
Base.@kwdef mutable struct Holding <: Asset
  name::Symbol
  class::Union{Symbol, Nothing}
  description::Union{String, Missing}
  values=Dict{Date, AssetValue}
  prices=Vector{EquityDailyPrice}
end

#Holding Constructors
Holding(name::Symbol, description)=
  Holding(name, matchAssetClass(name), description, 
    Dict{Date, AssetValue}(), Vector{EquityDailyPrice}())
Holding(name::String, description)=Holding(Symbol(name), description)

#print(holding)=print("$(holding.name) $(holding.class)")
get(holding, date)=holding.values[date]
"Set the value for a change in a holding"
function set(holding, date, value, quantity)
  total=if length(holding.values)> 0
      last=getLast(holding)
      quantity + last.total
    else
      quantity
  end
  push!(holding.values, (date => AssetValue(date, value, quantity, total)))
end
set(holding, AssetValue)=push!(holding.values, AssetValue.date => AssetValue)

getSorted(holding)=sort(collect(keys(holding.values)))
getLast(holding)=get(holding, last(getSorted(holding)))
getFirst(holding)=get(holding, first(getSorted(holding)))
getBasisValue(holding)=getFirst(holding).value
getCurrentValue(holding)=getLast(holding).value
getProfitPerShare(holding)=getCurrentValue(holding)-getBasisValue(holding)
getProfitTotal(holding)=(getCurrentValue(holding)-getBasisValue(holding))*getLast(holding).Total
isCD(cl::Symbol)=(cl == :CD)
isEquity(cl::Symbol)=(cl==:Equity)
#Holding(name::Symbol)=Holding(date, name, count, missing)
#Base.string(h::Holding)=string(h.date,sep, h.name, sep, h.count, sep, h.value)
#Base.show(io::IO, h::Holding)=show(io,string(h))

"Add this entry to the Holding data structure"
function updateHoldingHLOC(holding, high, low, open, close, date)
  hloc=EquityDailyPrice(high, low, open, close, date)
  push!(holding.prices, hloc)
end

"Read information for one holding price history"
function readHoldingPriceHistory!(holding, path)
  prices=DataFrame(XLSX.readtable(path, string(holding.name), infer_eltypes=true));
  map(e -> updateHoldingHLOC(holding, e.High, e.Low, e.Open, e.Close, e.timestamp), eachrow(prices))
end

"create a copy dictionary of the RE's with RegularExpressions replacing the re string"
function formatRE(re)
  d=Dict{Symbol, Regex}()
  for rs in collect(keys(re))
    s=Symbol(rs)
    r=Regex(re[rs], "i")
    push!(d, s => r)
  end
  return d
end

isMatch(b, k)=b ? k : missing
function getType(str, reDict)
  keyList=collect(keys(reDict))
  m=map(k -> isMatch(occursin(reDict[k], str), k) , keyList) 
  nonMissing=collect(skipmissing(m))
  length(nonMissing) > 0 ? nonMissing[1] : :Unmatched
end

function matchAssetClass(str)
  eq=:Equity => r"^[A-Z]+$"
  cd= :CD =>   r"^[A-Z,0-9]+$"i
  typeList=Dict(eq,cd)
  t=getType(String(str), typeList)
  return t
end
matchAssetClass(sym::Symbol)=matchAssetClass(String(sym))

@testset "Holdings1" begin
  #Sample data for holdings
    ibm=Holding(:IBM, "International Business Machines")
    firstIBM=AssetValue(Date(2021,1,1), 100.0, 10.0, 10.0)
    lastIBM =AssetValue(Date(2023,1,1), 120.0, 1.0, 11.0)
    set(ibm, firstIBM)
    set(ibm, lastIBM)
     @test getFirst(ibm) == firstIBM
     @test getLast(ibm) == lastIBM  
  end
  
  @testset "Holdings2" begin
    s1=" REINVESTMENT as of 04/30/2023 JPMORGAN CHASE & CO (JPM) (Cash)"
    s2=" DIVIDEND RECEIVED as of 04/30/2023 JPMORGAN CHASE & CO (JPM) (Cash)"
    reString="""{"RegularExpressions" : {
    "Dividend" : ".*dividend.*",
    "Reinvestment" : ".*reinvest.*"
    }}"""
    parsed=JSON.parse(reString)
    re=parsed["RegularExpressions"]
    reDict=formatRE(re)
    @test getType(s1, reDict)   == :Reinvestment
    @test getType(s2, reDict)   == :Dividend  
    @test matchAssetClass("IBM")       == :Equity  
    @test matchAssetClass("69355NBK0") == :CD  
  end

  @testset "Holdings3" begin
    AMD=Holding(:AMD, "Advanced Micro Devices")
    amdHistory=readHoldingPriceHistory!(AMD, "data/AMD.xlsx")
    @test size(amdHistory,2)== 1
  end