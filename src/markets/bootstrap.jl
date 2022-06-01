(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using Markets
push!(Base.modules_warned_for, Base.PkgId(Markets))
Markets.main()
