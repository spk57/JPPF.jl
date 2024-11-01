#Match.jl 
#Matching functions

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
