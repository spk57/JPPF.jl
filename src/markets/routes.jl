using Genie, Genie.Router, Genie.Renderer.Json, Genie.Requests

route("/") do
  serve_static_file("welcome.html")
end

route("/track", method = POST) do 
  parseTracking(postpayload())   
end

function parseTracking(payload)
#  println("Payload: $payload")
#  println("Labels: $(payload[:JSON_PAYLOAD])")
  labels=payload[:JSON_PAYLOAD]["labels"]
  println("Labels: $(labels) ")
end