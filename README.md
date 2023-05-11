# JPPF
## Julia Programmers Personal Finance Tools
 
This is a collection of tools which can be used by a programmer to help manage personal finance.  I started this activity becuase commercial tools lack the flexibility I was looking for.   The approach is to leverage standard tools like Excel, Jupyter. This is not intended for conusmers.  It is intended for developers who want a flexible tool to manage their own personal finances. This was written in Julia,  because its my favorite language.  

* Budget Analysis
* Investment Analsis
* Retirement Planning
   > Allows any combination of Expenses, Income, Assets and Liabilities. Each may be inflated or grown using separate factors.  Includes rules for zeroGrowth (cash), fixedGrowth, fixedLoan.  Handles loan payoff

Technology usage: Julia, Excel, Jupyter

## Installation instructions: 
* Download JPPF
   * pkg> dev [JPPF](https://github.com/spk57/JPPF.jl.git)

## Usage: 

### RetirementPlanning 
#### Model Run
1. Enter the model configuration, planned expenses, income, assets and liabilties in the spreadsheet
2. change directory to JPPF
3. julia --project ./src/Retirement.jl [-D] [--save savePath]  [inputPath]
4. Note: savePath defaults to output/RetirementRun(now).xlsx and inputPath is data/Retirement.xlsx
#### View Model Results
1. change directory to JPPF
2. julia --project
3. using IJulia
4. notebook(dir="./src")
5. open Retirement.ipynb
6. Update the runFile variable to point to the analysis file
7. Run the cells 
### Update investment values
1.  TODO Add investments to lookup list
2.  TODO create a cron job to update list on a schedule