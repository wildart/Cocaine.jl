using ArgParse
using Lumberjack
Lumberjack.remove_truck("console")
Lumberjack.add_truck(LumberjackTruck("/tmp/julia_worker.log"), "worker")

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--uuid"
            help = "UUID"
        "--endpoint"
            help = "Connection path"
        "--app"
            help = "Application name"
            default = "standalone"
        "--locator"
            help = "Locator service location"
            default = "localhost:10053"
    end

    return parse_args(s)
end

function parse_endpoint(ep::String)
    epp = split(ep, ":")
    if isdigit(epp[end])
        addr = join(epp[1:end-1], length(epp[1:end-1]) == 1 ? "" : ":")
        port = int(epp[end])        
    else        
        addr = ep
        port = nothing
    end
    return addr, port
end