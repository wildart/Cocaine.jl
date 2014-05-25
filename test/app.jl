#!/usr/bin/env julia
using Cocaine

function echo(req::CocaineRequest, resp::CocaineResponse)
    data = read(req)
    data = "Hello from Julia! $(data)"
    write(resp, data)
end

binds = Dict{String, Function}({
	"ping" => echo
})
worker(binds) # Assign binds and run event loop


