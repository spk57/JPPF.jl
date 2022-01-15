module Retirement

using XLSX, DataFrames, ArgParse, Match, Pkg, Dates, Logging 

export run

"Global Constants"
const version=Pkg.project().version
const today=Dates.today()
const started=Dates.now()
const startDir=pwd()
const program=@__MODULE__

const monthPeriod=12
const weekPeriod=52
const period=monthPeriod
@enum accountStatus active inactive none

"Default Arguments"
const dataDir=pwd()*"/data"
const outDir=pwd()*"/output"
const dataFile="Retirement.xlsx"
const outFile="RetirementRun"*string(started)*".xlsx"

about() =  println("$program Version: $version $(string(started))")

"Command line arguments"
s=ArgParseSettings()
@add_arg_table! s begin 
"-D"
  help = "Set debugging"
  action = :store_true
"--save"
  help = "path to save output" 
  default = joinpath(outDir, outFile)
  required=false
"path" 
  help = "path for input files"
  default = joinpath(dataDir, dataFile)
  required=false
end

logmsg(msg)=string(now(), " ", msg)
rows(df::DataFrame)=size(df, 1)
readxl(file, sheet)=DataFrame(XLSX.readtable(file, sheet)...)

"Growth Type "
abstract type Growth end
abstract type ConstGrowth <: Growth end
abstract type ZeroGrowth <: Growth end
abstract type FixedLoan <: Growth end

"Generic growth rule.  Empty"
grow(g::Growth, base, factors::NamedTuple)=error("Illegal call to abstract type Growth $g")

"Const Growth Rule"
grow(g::Type{ConstGrowth}, base, factors::NamedTuple,  period=monthPeriod)=base*(factors.rate/period + 1.0)

"Zero Growth Rule"
grow(g::Type{ZeroGrowth}, base::Float64, factors::NamedTuple)=  base

"""
Loan factor[1] = rate, factor[2] = payment loan = interest - payment
Returns state of the loan (active, closed)
"""
function grow(g::Type{FixedLoan}, base, factors::NamedTuple, period=monthPeriod)
  if (base <= factors.payment)
    closeLoan(factors.name)
    return 0.0
  end  
  base*(1+factors.rate/period)-factors.payment
end

function calcInitial(sheet, calcType)
  @debug logmsg("$calcType rows: $(rows(sheet))")
  initialSum=sum(sheet.Initial)
  @debug logmsg("Initial $calcType: $initialSum")
  initialSum
end

"Save row with name / value from dataframe df into dictionary d"
pushRow!(d, df, row)=push!(d, df[row,1] => df[row,2])

"Create a dictionary from name value pairs in a dataframe"
function df2Dict!(df)
  d = Dict{String, Any}()
  map(r -> pushRow!(d, df, r), 1:nrow(df))
  d
end

"Set initial values from input config file"
function getInitialValues(dataFileName)
  income=readxl(dataFileName, "Income")
  @debug logmsg("Income rows: $(rows(income))")
  expenses=readxl(dataFileName, "Expenses")
  @debug logmsg("Expense rows: $(rows(expenses))")
  assets=readxl(dataFileName, "Assets")
  @debug logmsg("Asset rows: $(rows(assets))")
  liabilities=readxl(dataFileName, "Liabilities")
  @debug logmsg("Liability rows: $(rows(liabilities))")
  constantSheet=readxl(dataFileName, "Constants")
  @debug logmsg("Constant rows: $(rows(constantSheet))")
  @info logmsg("Completed reading input file")

  constants = df2Dict!(constantSheet)
  @debug logmsg("Constants: $constants")
  income, expenses, assets, liabilities, constants
end

"Convert Decimal Age to Year month"
function ageToYearMonth(age::Number)
  y=trunc(Int, age)
  m=trunc(Int, (age-y)*12)
  m,y
end

"Calculate the retirement date from birth date and age at retirement"
function getRetDate(retAgeYear, birthDate)
  (retMonth, retYear) = ageToYearMonth(retAgeYear)
  retDate=birthDate+Year(retYear)+Month(retMonth)
  retDate
end

"Calculate the number of periods in the model"
function calcPeriods(type, modelLength)
  periods  = if type == "Month"; 12 elseif type == "Week"; 52 end
  periods*modelLength      
end

"""
Create a DataFrame for saving outputs from the model run
The dataframe is structured with a row for each instance in the model. 
"""
function initializeDF(initialValues)
  output= DataFrame(Date=Date[], NetWorth=Float64[], Assets=Float64[], Liabilties=Float64[], NetIncome=Float64[], Income=Float64[], Expenses=Float64[] )
  push!(output, initialValues)
end

"Reshape a ledger table so that the Description Column becomes the column headings and the Initial column becomes the first row in the table"
function reshapeLedger(ledgerDF::DataFrame, desc::Symbol, initial::Symbol)
  df = select(ledgerDF, [desc, initial])
  transform!(df, desc => ByRow(Symbol) => desc)
  convertFloat(v)=convert(Float64,v)
  transform!(df, initial => ByRow(convertFloat) => initial)
  newDF=permutedims(df, 1)
  select!(newDF, Not(1)) # Drop the description column
  newDF
end

"Add a row to the ledger for a df to model growth during the next period"
function growNextLedger!(ledgerDF, factorMap)
  lastRow=ledgerDF[end,:]
  newRow=copy(lastRow)
  cols=names(ledgerDF)
  g=map(name -> factorMap[name],  cols) 
  updated=map(n -> grow(g[n].rule, newRow[n], g[n]), 1:length(newRow))
  push!(ledgerDF, updated)
end

"If there are any closed loans, set the expense to zero "
function zeroClosedLoans(liability, expense)
  lastLia=liability[end,:]
  lastexp=expense[end,:]
  for n in names(expense)
    status = checkLoanStatus(n)
    if status==inactive 
      lastexp[Symbol(n)] = 0.0
    end
  end
end

"Grow each entry in each ledger by the growth rule"
function growLedgers!(income, incMap, expense, expMap, asset, asstMap, liabilty, liaMap, periods)
  for p in 1:periods-1
    growNextLedger!(income, incMap) 
    growNextLedger!(expense, expMap) 
    growNextLedger!(asset, asstMap) 
    growNextLedger!(liabilty, liaMap) 
    zeroClosedLoans(liabilty, expense)
  end
end

"Update the ruleMap from the row of initial conditions sheet"
function mapGrowth!(factorMap, row, descr=:Description, rule=:Rule, factor1=:Factor1, factor2=:Factor2)
  f=eval(Symbol(row[rule])) # Use the description to find the function 
  if row[rule] == "ConstGrowth"
    factors= (rule=f, rate=convert(Float64, row[factor1]))
  elseif row[rule] == "ZeroGrowth"
    factors=(rule=f, name=row[descr], rate=missing)
  elseif row[rule] == "FixedLoan"
    rate=convert(Float64, row[factor1])
    payment=convert(Float64, row[factor2])
    factors=(rule=f, rate=rate, payment=payment, name=row[descr])
  else
    error("Illegal growth rule: $(row[rule])")
  end
  push!(factorMap, row[descr] => factors)
end

"Manage loans. Loans are used to connect liabilties with payments"
const loanState=Dict{String, accountStatus}()
openLoan(name)=  push!(loanState, name => active)
closeLoan(name)= (loanState[name] = inactive)
function checkLoanStatus(name) 
  if name in keys(loanState)
    return loanState[name] 
  else
    return none
  end
end

"Open a loan for every liability"
openLoans(lMap)=map(l -> openLoan(l.name), values(lMap))

"Create a list of factors for each column in a ledger"
function mapGrowthFactors(df::DataFrame)
  factorMap=Dict{String, NamedTuple}()
  map(r -> mapGrowth!(factorMap, r), eachrow(df))
  factorMap
end

"Return a DF with the sums across all values for a ledger by period"
sumLedger(df, colName)=select(df, AsTable(:) =>  ByRow(sum) =>  colName)

"Return a DF with the net income by period"
function calcNet(incomeDF, expenseDF, net=:NetIncome)
  sumDF=hcat(incomeDF, expenseDF)
  transform!(sumDF, [1,2] => ByRow(-) => net)
  select!(sumDF, net)
  sumDF
end

function addNetToAssets(netIncome, assetsDF, cash, net)
  assetsPlusNet=hcat(netIncome, assetsDF)
  assetsNet=select(assetsPlusNet,  [cash, net] => ByRow(+) => :NetCash)
  temp=hcat(assetsDF, assetsNet)
  select(temp, Not(cash))
end

"Calculate loan payment amount"
payment(principal, rate, periods)=principal * (rate * (1+rate)^periods )/ ((1 + rate)^periods -1)
fv(pmt, rate, periods)=pmt*(1+rate)^periods
pv(pmt, rate, periods)=pmt/(1+rate)^periods

"Save the results to an excel file"
function saveRunExcel(incomeDF, expenseDF, assetsDF, liabilityDF, netIncomeDF, outputPath)
  XLSX.writetable(outputPath, 
    Income=( collect(DataFrames.eachcol(incomeDF)), DataFrames.names(incomeDF) ), 
    Expense=( collect(DataFrames.eachcol(expenseDF)), DataFrames.names(expenseDF)), 
    Assets=( collect(DataFrames.eachcol(assetsDF)), DataFrames.names(assetsDF)), 
    Liabilties=( collect(DataFrames.eachcol(liabilityDF)), DataFrames.names(liabilityDF)), 
    Net=( collect(DataFrames.eachcol(netIncomeDF)), DataFrames.names(netIncomeDF)),     
    )
end

"Main workflow method"
function run(ARGS)
  #Get the configuration 
  args=parse_args(ARGS, s)
  about()
  @info logmsg("Started")
  debug=args["D"]
  outputPath=args["save"]
  
  debug ? ENV["JULIA_DEBUG"] = Main  : nothing 
  @debug logmsg(args)
  @debug logmsg("Current directory: $startDir")
  dataFileName=args["path"]
  @info logmsg("Reading configuration from file $dataFileName")

  #Set initial values
  initialIncome, initialExpenses, initialAssets, initialLiabilities, constants =  getInitialValues(dataFileName)

  initIncomeSum=calcInitial(initialIncome, string(:Income))
  initExpensesSum=calcInitial(initialExpenses, string(:Expenses))
  initalNetIncome=initIncomeSum - initExpensesSum

  initAssetSum=calcInitial(initialAssets, string(:Assets))
  initLiabiltySum=calcInitial(initialLiabilities, string(:Liabilties))
  initialNetWoth=initAssetSum-initLiabiltySum
  
  retAgeYear=constants["Retirement Age"]
  birthDate=constants["Birth Date"]
  modelStart=constants["Model Start"]
  modelLength=constants["Model Length"]
  periodType=constants["Period Type"]
  retDate=getRetDate(retAgeYear, birthDate)
  @info logmsg("retAgeYear: $retAgeYear  birthDate $birthDate")
  @info logmsg("Planned retirement Date: $retDate")
  periods=calcPeriods(periodType, modelLength)
  @info logmsg("There are $periods periods in the model")
  initialValues= [modelStart initialNetWoth initAssetSum initLiabiltySum initalNetIncome initIncomeSum initExpensesSum]
  @debug "Initial Values $initialValues"
  output=initializeDF(initialValues)
  @debug "Output: $output"

  #Reshape tables with categories in columns and one row per period (Month)
  incomeDF=reshapeLedger(initialIncome, :Description, :Initial)
  expenseDF=reshapeLedger(initialExpenses, :Description, :Initial)
  assetsDF=reshapeLedger(initialAssets, :Description, :Initial)
  liabilityDF=reshapeLedger(initialLiabilities, :Description, :Initial)

  #Grow each category for the number of periods by the rule and factors associated with it
  incomeMap=mapGrowthFactors(initialIncome)
  @debug "incomemap: $incomeMap"
  expenseMap=mapGrowthFactors(initialExpenses)
  @debug "expenseMap: $expenseMap"
  assetsMap=mapGrowthFactors(initialAssets)
  @debug "assetMap: $assetMap"
  liabilityMap=mapGrowthFactors(initialLiabilities)
  @debug "liabilityMap: $liabilityMap"
  openLoans(liabilityMap)
  growLedgers!(incomeDF, incomeMap, expenseDF, expenseMap, assetsDF, assetsMap, liabilityDF, liabilityMap, periods)

  #Calculate totals 
  totalLiabilty=sumLedger(liabilityDF, :TotalLiability)
  totalIncome=sumLedger(incomeDF, :TotalIncome)
  totalExpense=sumLedger(expenseDF, :TotalExpense)

  #Calculate Nets after expenses and income
  netIncome=calcNet(totalIncome, totalExpense)
  assetsNet=addNetToAssets(netIncome, assetsDF, :Cash, :NetIncome)
  totalAssets=sumLedger(assetsNet, :TotalAssets)
  netWorth=calcNet(totalAssets, totalLiabilty, :NetWorth)
  net=hcat(netIncome, totalIncome, totalExpense, netWorth)
  @info logmsg("Completed model run")

  #Save model run
  saveRunExcel(incomeDF, expenseDF, assetsDF, liabilityDF, net, outputPath)
  @info logmsg("Saved output to $outputPath")
end

#ENV["JULIA_DEBUG"]=all
run(ARGS)
end
