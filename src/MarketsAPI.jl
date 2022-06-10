using Genie, Genie.Router, Genie.Renderer.Json, Genie.Requests
using Logging, JSON3

const trackFile="trackfile.json"
route("/") do
  serve_static_file("welcome.html")
end

route("/track", method = POST) do 
  parseTracking(postpayload())   
end

"Save and merge with existing tracking information"
function saveTracking(payload, trackFile=trackFile)
  labels=payload[:JSON_PAYLOAD]["labels"]
  @info("Labels: $(labels) ")
  old=readTracking(trackFile)
  oldList
end

function readTracking(trackFile=trackFile)
  open(f->read(f, String), trackFile)
  trackFile
end