#Match.jl 
#Matching functions
using Match

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

function matchTransactionType(str)
@match str begin
    r"[A-Z]*"i => :Stock
    r"[A-Z,0-9]*"i => :CD
    _ => nothing
  end
end
  