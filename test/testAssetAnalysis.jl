using WGLMakie, AlgebraOfGraphics,  XLSX, DataFrames, Dates
pwd()
include("../src/Common.jl")

cd("src")

dataDir="../data"
marketDir=joinpath(dataDir, "market")
(markets, marketNames)=readMarkets(marketDir);
