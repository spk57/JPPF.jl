#HTMLHelpers.jl

using Hyperscript, DataFrames, PrettyTables
const htmlStr="~~~"
"write and flush a string to the io"
writefl(io, str)=begin write(io, str);flush(io)end

"write an HTML string to the output"
writeHTML(io, str)=write(io, string(htmlStr, str, htmlStr))

hTable=m("table")
tr=m("tr")
th=m("th")
td=m("td")

"Build html representation of a header"
tableHeader(table)=map(th, columnnames(table))

"Build html representation of a row"
tableRow(table, row)=tr(map(td, values(table[row])))

"Build html representation of all rows"
tableBody(table)=map(r -> tableRow(table, r), 1:length(table))

"Break a list into printable chuncks"
function breakColl(collection)
  cols = 4
  l=length(collection)
  rows=l ÷ cols +1
  newLength=rows*cols
  f=fill(" ", 1,newLength-l)
  tCol=reshape(collection, 1, l)
  newColl=hcat(tCol, f)
  reshape(newColl, rows, cols)
end

"Build html representation of a collection"
collectionHTML(collection, title)=
  pretty_table(String, breakColl(collection), backend = Val(:html), show_header=false, title=title, alignment=:l)

"Build html representation of a table"
tableHTML(table)=hTable(tableHeader(table), tableBody(table))
