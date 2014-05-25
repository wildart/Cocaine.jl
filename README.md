# Cocaine Julia Framework
This package helps you to write Julia application for PaaS Cocaine.

## Installation
```
Pkg.clone("https://github.com/wildart/Msgpack.jl.git")
Pkg.clone("https://github.com/wildart/Cocaine.jl.git")
```

## Example
This's aexample of echo application:
```go
using Cocaine

function echo(req::Cocaine.Request, resp::Cocaine.Response)
    data = read(req)    
    write(resp, data)
end

binds = Dict{String, Function}({
	"ping" => echo
})
worker(binds)
```

## Links
[Cocaine PaaS project](https://github.com/cocaine/)

[Cocaine PaaS server](https://github.com/cocaine/cocaine-core)

[Cocaine PaaS wiki](https://github.com/cocaine/cocaine-core/wiki)

## Copyright
Licensed under the [GPLv3](LICENSE.md).