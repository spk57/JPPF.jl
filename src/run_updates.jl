#run_updates.jl

using JobSchedulers, Dates
scheduler_start()

#include("UpdateValues.jl")

cron=Cron(0,0,0,0,0,"1-5")
recurring_job = submit!(cron) do
    ARGS=[]
    println(now())
    main(ARGS)
end
