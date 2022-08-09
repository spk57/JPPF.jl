using WGLMakie, AlgebraOfGraphics,  XLSX, DataFrames, Dates
pwd()
include("../src/Common.jl")
include("../src/updateHoldings.jl")
cd("src")

dataDir="../data"
marketDir=joinpath(dataDir, "market")
(markets, marketNames)=readMarkets(marketDir);

holdingsFile=joinpath(dataDir, "Accounts_HistoryFidelity1.xlsx")

rh=readHoldings(holdingsFile, 3);
holdings=loadHoldings(rh);