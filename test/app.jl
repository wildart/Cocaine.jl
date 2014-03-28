#!/usr/bin/env julia
using Cocaine

function echo(request::CocaineRequest, response::CocaineResponse)
    data = read(request)
    write(response, data)
    close(response)
end

#logger = Logger()
binds = ["echo" => echo]
worker(binds) # Assign binds and event loop
