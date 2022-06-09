using Markets, Test, JSON3
# implement your tests here
@test 1 == 1
using HTTP

trackFile="sampletrack.json"
url="http://localhost:8000/track"

open(trackFile, "r") do io
    trackList=JSON3.read(io)
end

HTTP.request("POST", url, [("Content-Type", "application/json")], trackFile)
