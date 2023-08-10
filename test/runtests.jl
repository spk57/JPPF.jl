#using JPPF
using Test

jppfSrc="/home/steve/dev/projects/JPPF.jl/src"
common=joinpath(jppfSrc, "Common.jl")
include(common)


@testset "Common.jl" begin
#Sample data for holdings
  ibm=Holding(:IBM, "International Business Machines")
  firstIBM=HoldingValue(Date(2021,1,1), 100.0, 10.0)
  middleIBM =HoldingValue(Date(2022,1,1), 110.0, 10.0)
  lastIBM =HoldingValue(Date(2023,1,1), 120.0, 10.0)
  set(ibm, firstIBM)
  set(ibm, lastIBM)
   @test getFirst(ibm) == firstIBM
   @test getLast(ibm) == lastIBM
#  fHoldings=fillOutHoldings!(holdings, holdingsChanges, today()-Day(5))
#  @test length(holdingsChanges) == 5
#  todayChanges = filter(x -> x.date == today(), fHoldings)
#  @test length(todayChanges) == 2
end

