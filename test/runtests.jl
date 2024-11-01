using Dates, JSON
using ReTest

jppfSrc="/home/steve/dev/projects/JPPF.jl/src"
holdingsjl=joinpath(jppfSrc, "Holdings.jl")
include(holdingsjl)


@testset "Holdings1" begin
#Sample data for holdings
  ibm=Holding(:IBM, "International Business Machines")
  firstIBM=AssetValue(Date(2021,1,1), 100.0, 10.0, 10.0)
  lastIBM =AssetValue(Date(2023,1,1), 120.0, 1.0, 11.0)
  set(ibm, firstIBM)
  set(ibm, :IBM, Date(2022,1,1), 110.00, 1.0)
   @test getFirst(ibm) == firstIBM
   @test getLast(ibm) == lastIBM

   #  fHoldings=fillOutHoldings!(holdings, holdingsChanges, today()-Day(5))
#  @test length(holdingsChanges) == 5
#  todayChanges = filter(x -> x.date == today(), fHoldings)
#  @test length(todayChanges) == 2
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