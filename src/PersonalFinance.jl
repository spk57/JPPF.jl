#PersonalFinance.jl

using DataFrames: Dict
using Dates, Markdown, DataFrames, Query, XLSX, Polynomials

assetHistoryTab="AssetHistory";
qtrTab="Qtrs"; 
currentTab="CurrentAssets"
invTab="Investments"

"Read an excel tab into a dataframe"
readTab(xls, tabName)=DataFrame(XLSX.readtable(xls, tabName, infer_eltypes=true))


df=DateFormat("mm/dd/yyyy")
stringToDate(s)=Date(strip(s),df)
"Get year of century and quarter of year from string mdy"
function yic(y)
  m=stringToDate(y)
  string(year(m)-2000, "Q", quarterofyear(m))
end

"Rename columns"
function remapColumns!(transactions, transactionMap)
  symToCol(sym)=Int(sym)-Int('A')+1
  for key in keys(transactionMap)  
	sym=transactionMap[key][1]
	col=symToCol(sym)
    transactions=rename!(transactions, [col => key])
  end
  transactions[!,:Symbol] = strip.(transactions[!,:Symbol])
  transform!(transactions, :Date => ByRow(stringToDate) => :DateD)
  transform!(transactions, :Date => ByRow(yic) => :YQTR)
  transactions.Amount=convert.(Float64, transactions.Amount);
end

"read asset lists from excel file"
function readAssetList(xls)
  assetHistory = DataFrame(XLSX.readtable(xls, assetHistoryTab, infer_eltypes=true));
  assetHistory.Value=convert.(Float64, assetHistory.Amount);
  assetHistory.Savings=convert.(Float64, assetHistory.Savings);
  assetHistory.Growth=convert.(Float64, assetHistory.Growth);
  currentAssets=DataFrame(XLSX.readtable(xls, currentTab, infer_eltypes=true));
  (assetHistory, currentAssets)
end

"join list of quarters to data points."
function qtrAssetTotals(assetHistory, quarters)
  assetsQtr = @from i in assetHistory begin
    @join j in quarters on i.YearQtr equals j.YearQtr
    @select {j.Qtr, j.YearQtr, i.Value, i.Savings, i.Growth }
    @collect DataFrame
  end
  assetsQtr
end

"Divide by 1000 and round"
roundThousands(f, digits=1)=round(f/1000.0, digits=digits)

"CurrentAssets"
function getCurrentAssets(assetHistory, currentAssets, yq)
  currentAssets= @from i in assetHistory begin
    @join j in currentAssets on i.AssetID equals j.AssetID
    @where i.YearQtr == yq
    @select {j.Name, i.Value, i.Savings, i.Growth }
    @collect DataFrame
  end
  currentAssets
end

"Sum net assets by quarter"
function sumNetAssets(assetsQtr)
  netAssets = assetsQtr |>
    @groupby(_.Qtr,  (YearQtr=_.YearQtr, Qtr=_.Qtr, Value=_.Value)) |>
    @map({Qtr=key(_), Value=roundThousands(sum(_.Value)) }) |>
  	@orderby(_)|> DataFrame
  netAssets
end

"Sum assets or liabilities by quarter.  set assets = false for liabilities"
function sumAssets(assetsQtr, assets=true)
  netAssets = assetsQtr |>
    @groupby(_.Qtr, (YearQtr=_.YearQtr, Qtr=_.Qtr, Value=_.Value, Savings=_.Savings, Growth=_.Growth)) |>
    @map({Qtr=key(_), Net        =roundThousands(sum(    _.Value)), 
                      Assets     =roundThousands(sum(gtz,_.Value)),
                      Liabilities=roundThousands(sum(ltz,_.Value)), 
                      Savings    =roundThousands(sum(    _.Savings)), 
                      Growth     =roundThousands(sum(    _.Growth))}) |>
  	@orderby(_)|> DataFrame
  netAssets
end

"First order fit for asset growth"
fitAssets(x, y)=fit(x, y, 1)

"Fit points to a curve"
fitPoints(curve, last)=[curve[1] + curve[2]*x for x=1:last] 

"fit line to assets"
function  monthlyGrowth(netAssets, poly)
  #fit(netAssets.Qtr, netAssets.Value, 1) |> p -> round.(coeffs(p), digits=1) |> Polynomial;
	monthlyGrowth=round(poly.coeffs[2]/3,digits=1);
  currNet=round(netAssets.Value[end],digits=1)
  netGrowth=round(netAssets.Value[end] - netAssets.Value[1], digits=1)
  nQuarters=netAssets.Qtr[end] - netAssets.Qtr[1]
  (currNet, monthlyGrowth, netGrowth, nQuarters)
end

"Display html"
ht(s)=display("text/html",s )
hr(s, color)=display("text/html", "<span style=\"color:$color\">$s</span>")

"Greater than zero"
gtz(x)= x > 0 ? x : 0

"Less Than Zero"
ltz(x)= x <= 0 ? x : 0

"""
Pareto filter of a data frame. 
returns the top elements of the list and the other elements as a tuple
"""
function pareto(df, col, rows=10,rounding=true)
  total=sum(df[:,col])
  sorted=sort(df, col, rev=true)
  cols=size(df,2)
  sortedP=select(sorted, :, col=> cumsum => :Cumsum, col=>(v-> cumsum(v) / total*100)=>:Pct)
  if rounding
    sortedP[:,:Pct] = round.(sortedP.Pct, digits=1)
  end
  sortedP.Rank=rownumber.(eachrow(sortedP))
  top=sortedP[1:rows,:]
  other= sortedP[rows+1:end, :]
  (top, other)
end