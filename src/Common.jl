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

"The value of 1 holding at 1 time"
struct HoldingValue
  value::Float64
  quantity::Float64
end

"Information about a Holding"
Base.@kwdef mutable struct Holding
  name::Symbol
  description::Union{String, Missing}
  values=Dict{Date, HoldingValue}() 
end

Holding(name::Symbol, description)=Holding(name, description, Dict{Date, HoldingValue}())
Holding(name::Symbol)=Holding(name, missing)
get(holding, date)=holding.values[date]
set(holding, date, value, quantity)=push!(holding, (date => HoldingValue(value, quantity)))

getSorted(holding)=sort(collect(keys(holding.values)))
getLast(holding)=last(getSorted(holding))

#Holding(name::Symbol)=Holding(date, name, count, missing)
#Base.string(h::Holding)=string(h.date,sep, h.name, sep, h.count, sep, h.value)
3Base.show(io::IO, h::Holding)=show(io,string(h))