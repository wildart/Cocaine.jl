#!/usr/bin/env julia
using Cocaine

function echo(req::CocaineRequest, resp::CocaineResponse)
	println("ECHO: Start")
    data = read(req)
    data = "Hello from Julia! $(data)"
    println(data)
    write(resp, data)
    println("ECHO: End")
end

function noecho(req::CocaineRequest, resp::CocaineResponse)
	println("ECHO: Start")
    data = read(req)
    data = "Hello from Julia! $(data)"
    println(data)
end

binds = Dict{String, Function}({
	#"ping" => echo,
	"echo" => echo,
	#"sink" => noecho
})
worker(binds) # Assign binds and run event loop


