using ArgParse
using UUID

const HEARTBEAT_TIMEOUT = 20
const DISOWN_TIMEOUT    = 5

type CocaineRequest
    from_worker::Int
    to_worker::Int
    quit::Bool
end

type CocaineResponse
    from_worker::Int
    to_worker::Int
    session::Int
    quit::Bool
end

type CocaineWorker
    uuid::UUID.Uuid
    sessions::Dict{Int, CocaineRequest}
    heartbeat_timer::Timer
    disown_timer::Timer
    #logger          *Logger
    #unpacker        *streamUnpacker
    #from_handlers   chan rawMessage
    #socketIO
end

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

function create_worker(args::Dict{ASCIIString,Any})
    workerID = UUID.Uuid(args["uuid"])
    sessions = Dict{Int, CocaineRequest}()
    heartbeat_timer = Timer(HEARTBEAT_TIMEOUT)
    disown_timer = Timer(DISOWN_TIMEOUT)

    w = CocaineWorker(workerID, sessions, heartbeat_timer, disown_timer)
    worker_handshake(w)
    worker_heartbeat(w)
    return w
end

function worker_handshake(worker::CocaineWorker)
    handshake = Handshake(0, worker.uuid)
    worker.Write(pack(handshake))
end

function worker_heartbeat(worker::CocaineWorker)
    heartbeat = Heartbeat(0)
    worker.Write(pack(heartbeat))
    disown_timer.Reset(DISOWN_TIMEOUT)
    heartbeat_timer.Reset(HEARTBEAT_TIMEOUT)
end

function event_loop(worker::CocaineWorker, binds::Dict{ASCIIString,Function})

end

function worker(binds::Dict{ASCIIString,Function})
    parsed_args = parse_commandline()
    worker = create_worker(parsed_args)
    event_loop(worker, binds)
end
