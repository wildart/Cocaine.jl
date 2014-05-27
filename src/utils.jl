using ArgParse
#using Lumberjack
#Lumberjack.remove_truck("console")
#Lumberjack.add_truck(LumberjackTruck("/tmp/julia_worker.log"), "worker")

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

function decode(data::Array{Uint8,1})
    msgs = Any[]
    msg_indx = findin(data, 0x93) # Dirty hack: no streaming decoding so separate manually           
    push!(msg_indx, length(data))
    for i = 1 : (length(msg_indx)-1)
        push!(msgs, unpack(data[msg_indx[i]:msg_indx[i+1]]))
    end
    msgs
end