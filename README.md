# Cocaine Julia Framework [![Build Status](https://travis-ci.org/wildart/Cocaine.jl.png?branch=master)](https://travis-ci.org/wildart/Cocaine.jl)
This package helps you to write Julia application for [PaaS Cocaine](https://github.com/cocaine/cocaine-core).

## Installation
```
Pkg.clone("https://github.com/wildart/Msgpack.jl.git")
Pkg.clone("https://github.com/wildart/Cocaine.jl.git")
```

## Example
This's an example of 'echo' application:
```julia
using Cocaine

function echo(req::CocaineRequest, resp::CocaineResponse)
    data = read(req)    
    write(resp, data)
end

binds = Dict{String, Function}({
	"ping" => echo
})
worker(binds)
```

## Note
All data received from service is packed in msgpack format.

## Links
[Cocaine PaaS project](https://github.com/cocaine/)

[Cocaine PaaS server](https://github.com/cocaine/cocaine-core)

[Cocaine PaaS wiki](https://github.com/cocaine/cocaine-core/wiki)

## Copyright
Licensed under the [GPLv3](LICENSE.md).