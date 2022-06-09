using JPPF
using Test, HTTP, JSON
#Assumes the server is started first

url="http://localhost:8000/track"
trackJSON="""{"labels":["INT", "JPM", "IBM"]}"""

@testset "JPPF.jl" begin
  resp=HTTP.request("POST", url, [("Content-Type", "application/json")], trackJSON)
  @test resp.status == 200
end
