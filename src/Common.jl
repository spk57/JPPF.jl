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
"Convert a Struct to a DataFrame.  xs is an array of struct s"
st2df(xs, s)=DataFrame(Dict(n=>[getfield(x, n) for x in xs] for n in fieldnames(s)))

"The value of 1 holding at 1 time"
struct HoldingValue
  date::Date
  value::Float64
  change::Float64
  total::Float64
end

"Information about a Holding"
Base.@kwdef mutable struct Holding
  name::Symbol
  class::Union{Symbol, Nothing}
  description::Union{String, Missing}
  values=Dict{Date, HoldingValue}() 
end

#Holding Constructors
Holding(name::Symbol, description)=
  Holding(name, matchTransactionType(name), description, Dict{Date, HoldingValue}())
Holding(name::String, description)=Holding(Symbol(name), description)
Holding(name::Symbol)=Holding(name, missing)

print(holding)=print("$(holding.name) $(holding.class)")
get(holding, date)=holding.values[date]
"Set the value for a change in a holding"
function set(holding, date, value, quantity)
  total=if length(holding.values)> 0
      last=getLast(holding)
      quantity + last.total
    else
      quantity
  end
  push!(holding.values, (date => HoldingValue(date, value, quantity, total)))
end
set(holding, holdingValue)=push!(holding.values, holdingValue.date => holdingValue)

getSorted(holding)=sort(collect(keys(holding.values)))
getLast(holding)=get(holding, last(getSorted(holding)))
getFirst(holding)=get(holding, first(getSorted(holding)))
getBasisValue(holding)=getFirst(holding).value
getCurrentValue(holding)=getLast(holding).value
getProfitPerShare(holding)=getCurrentValue(holding)-getBasisValue(holding)
getProfitTotal(holding)=(getCurrentValue(holding)-getBasisValue(holding))*getLast(holding).Total
isCD(cl::Symbol)=(cl == :CD)
isStock(cl::Symbol)=(cl==:Stock)
#Holding(name::Symbol)=Holding(date, name, count, missing)
#Base.string(h::Holding)=string(h.date,sep, h.name, sep, h.count, sep, h.value)
#Base.show(io::IO, h::Holding)=show(io,string(h))