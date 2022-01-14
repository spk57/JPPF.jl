"Julia Programmers Personal Finance"
module JPPF
using Pkg, Dates

const version=Pkg.project().version
const today=Dates.today()
const started=Dates.now()
const startDir=pwd()
const program=@__MODULE__

about() =  println("$program Version: $version $(string(started))")

about()
end
