#using JPPF
using Test, HTTP, JSON3

include("../src/updateHoldings.jl")
#Assumes the server is started first

url="http://localhost:8000/track"
trackJSON="""{"labels":["INT", "JPM", "IBM"]}"""

#@testset "JPPF.jl" begin
#  resp=HTTP.request("POST", url, [("Content-Type", "application/json")], trackJSON)
#  @test resp.status == 200
#end

@testset "updateHoldings.jl" begin
#Sample data for holdings
  h1=Holding(today(), :JPM, 20)
  push!(holdingsChanges, Holding(today()-Day(4), :JPM, 20.0))
  push!(holdingsChanges, Holding(today()-Day(3), :INTC, 30))
  push!(holdingsChanges, Holding(today()-Day(2), :AMD, 40))
  push!(holdingsChanges, Holding(today()-Day(1), :AMD,  50))
  push!(holdingsChanges, Holding(today()-Day(1), :JPM, -20))
  fHoldings=fillOutHoldings!(holdings, holdingsChanges, today()-Day(5))
  @test length(holdingsChanges) == 5
  todayChanges = filter(x -> x.date == today(), fHoldings)
  @test length(todayChanges) == 2
end

