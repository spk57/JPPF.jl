#setupFranklin.jl
#Scipt to set up static web site for output using Franklin.jl 
using Franklin, Distributed

"Copy Franklin web files to the target path"
function setupFranklin(templatePath, targetPath, force=false)
  if !force && isdir(targetPath) return true end
  cp(templatePath, targetPath, force=force)
  @info "Created web site files in folder $targetPath"
end

"Count available worker threads"
function availableWorkers()
  w=workers()
  np=nprocs()
  length(np)-length(w)
end

"Get available worker thread or create one if none available"
function getWorker()
  aw=availableWorkers()
  if aw < 1
    addprocs(1)
    @info "Added worker thread available:  $aw" 
  else 
    @info "Available worker threads $aw" 
  end
  workers()[end]
end

#TODO This is not working start Franklin in a separate process
"Start the Franklin web server as a separate task."
function startWeb(serverPath, port=8000)
  return nothing
  t=@task web() 
  function web()
    @info "Starting Franklin server uid : $(myid()) path: $serverPath"
    @info "Web: Changing dir from $(pwd()) to $serverPath"
    cd(serve(port=port), serverPath)    
    @info "Exited Franklin server $s"
  end
  s=schedule(t)
  @info "Task Scheduled $s"
  t
end

"Stop the worker thread for the web server"
stopWeb(worker)=rmprocs(worker)