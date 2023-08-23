using Match, JSON
s1=" REINVESTMENT as of 04/30/2023 JPMORGAN CHASE & CO (JPM) (Cash)"
s2=" DIVIDEND RECEIVED as of 04/30/2023 JPMORGAN CHASE & CO (JPM) (Cash)"

reString="""{"RegularExpressions" : {
  "Dividend" : ".*dividend.*",
  "Interest" : ".*interest.*",
  "Reinvestment" : ".*reinvest.*",
  "Bought" : ".*bought.*",
  "Sold" : ".*sold.*",
  "Transfer" : ".*transfer.*",
  "ForeignTax" : ".*foreign.*",
  "Merger" : ".*merger.*"
}}"""
parsed=JSON.parse(reString)
re=parsed["RegularExpressions"]

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
  collect(skipmissing(m))[1]
end

reDict=formatRE(re)
t1=getType(s1, reDict)
t2=getType(s2, reDict)

function m(s)
  m=@match s begin
    r"reinvest"i   => :Reinvest
    r"dividend"i   => :Dividend
    r"Nothing" => :Nothing
    _          => :LessThanNothing
  end
  println("Matched: $m")
  return m
  end
  
#  m(s1)
#  m(s2)
#  m("other")