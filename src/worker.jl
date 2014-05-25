const HEARTBEAT_TIMEOUT = 50.0
const DISOWN_TIMEOUT    = 5.0

type Worker
    uuid::String
    pipe::Base.AsyncStream
    stream::CocaineStream    
    session::Dict{Int, CocaineRequest} 
    heartbeat::Any
    disown::Any
    loop::Bool
end

type CocaineResponse
    session::Int
    worker::Worker
    quit::Bool
    CocaineResponse(sid, worker) = new(sid, worker, false)
end

function Base.write(resp::CocaineResponse, chunk)
    if !resp.quit
        _send_choke(resp.worker, resp.session, data)
    end
end

function Base.close(resp::CocaineResponse)
    if !resp.quit
        _send_choke(resp.worker, resp.session)
        resp.quit = true
    end
end

function Base.error(resp::CocaineResponse, code, msg)
    if !resp.quit
        _send_error(resp.worker, resp.session, code, msg)
        close(resp)
    end
end

function sandbox(eval::Function, req::CocaineRequest, resp::CocaineResponse)
    eval(req, resp) 
    consume(req, false) 
    close(resp)
end

function create_worker(args::Dict{String,Any})    
    workerID = args["uuid"]    
    sessions = Dict{Int, CocaineRequest}()
    
    addr, port = parse_endpoint(args["endpoint"])
    pipe = port == nothing ? connect(addr) : connect(addr, port)      
    stream = CocaineStream(RWStream, pipe)        

    w = Worker(workerID, pipe, stream, sessions, nothing, nothing, true)
    w.heartbeat = Timer((t,s)->_send_heartbeat(w))
    w.disown = Timer((t,s)->w.loop = false) 
        
    _send_handshake(w)
    _send_heartbeat(w)    
    return w
end

function _send_error(w::Worker, sid, code, msg)    
    debug("Error sent from session $(sid): $(msg)")     
    @async write(w.pipe, pack(Error(sid, code, msg)))
end

function _send_chunk(w::Worker, sid, chunk)       
    debug("Send chunk from session $(sid)")
    data = Msgpack.pack(chunk)
    @async write(w.pipe, pack(Chunk(sid, data)))
end

function _send_choke(w::Worker, sid::Int)
    debug("Choke session $(sid)") 
    @async write(w.pipe, pack(Choke(sid)))
end

function _send_handshake(w::Worker)
    debug("Send handshake")
    @async write(w.pipe, pack(Handshake(0, w.uuid)))
end

function _send_heartbeat(w::Worker)
    debug("Send heartbeat. Start disown timer")
    @async write(w.pipe, pack(Heartbeat(0)))
    start_timer(w.disown, DISOWN_TIMEOUT, 0)
    start_timer(w.heartbeat, HEARTBEAT_TIMEOUT, 0)    
end

function decode(data::Array{Uint8,1})
    msgs = Message[]
    msg_indx = findin(data, 0x93) # Dirty hack: no streaming decoding so separate manually           
    push!(msg_indx, length(data))
    for i = 1 : (length(msg_indx)-1)
        push!(msgs, unpack(data[msg_indx[i]:msg_indx[i+1]]))
    end
    msgs
end

function event_loop(w::Worker, binds::Dict{String,Function})    
    while w.loop                
        println("W: start read")
        data = read(w.stream) # Receive data from stream
        println("W: done reading: $(data)")
        msgs = decode(data) # Decode them into internal messages
        for msg in msgs # process messages
            
            if isa(msg, Heartbeat)
                debug("Receive heartbeat. Stop disown timer")
                stop_timer(w.disown)

            elseif isa(msg, Terminate)
                info("Receive terminate. $(msg.Reason), $(msg.Message)")
                @async write(w.pipe, pack(Terminate(0, msg.Reason, msg.Message)))   
                w.loop = false
                break

            elseif isa(msg, Internal)
                error(msg.Message)
            end

        end
    end
end

function worker(binds::Dict{String,Function})
    debug("Started worker")
    parsed_args = parse_commandline()    
    if isa(parsed_args["uuid"], Nothing) || isa(parsed_args["endpoint"], Nothing)
        error("Parameters are not specified: uuid, endpoint")
    else
        wrk = create_worker(parsed_args)
        event_loop(wrk, binds)
        # Cleanup        
        close(wrk.stream)
        close(wrk.pipe)
    end
    quit()
end