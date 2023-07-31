#updateFranklin.jl

const configBase="""
+++
title = "Configuration"
+++
# Configuration
"""
function updateConfig(path, str)
  outputstr=configBase*str
  write(path, outputstr)
end