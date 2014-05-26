const HEARTBEAT_TIMEOUT = 30.0
const DISOWN_TIMEOUT    = 5.0

type Worker
    uuid::String
    pipe::Base.AsyncStream
    stream::CocaineStream    
    sessions::Dict{Int, CocaineRequest} 
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
        _send_chunk(resp.worker, resp.session, data)
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
    pipe = port === nothing ? connect(addr) : connect(addr, port)      
    stream = CocaineStream(RWStream, pipe)        

    w = Worker(workerID, pipe, stream, sessions, nothing, nothing, true)
    w.heartbeat = Timer((t,s)->_send_heartbeat(w))
    w.disown = Timer((t,s)->w.loop = false) 
        
    _send_handshake(w)
    _send_heartbeat(w)    
    return w
end

function _send_error(w::Worker, sid, code, msg)    
    println("Error sent from session $(sid): $(msg)")     
    @async write(w.pipe, pack(Error(sid, code, msg)))
end

function _send_chunk(w::Worker, sid, chunk)       
    println("Send chunk from session $(sid)")
    #data = Msgpack.pack(chunk)
    @async write(w.pipe, pack(Chunk(sid, chunk)))
end

function _send_choke(w::Worker, sid::Int)
    println("Choke session $(sid)") 
    @async write(w.pipe, pack(Choke(sid)))
end

function _send_handshake(w::Worker)
    println("Send handshake")
    @async write(w.pipe, pack(Handshake(0, w.uuid)))
end

function _send_heartbeat(w::Worker)
    println("Send heartbeat. Start disown timer")
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
            println("W: Process message $(msg)")

            if isa(msg, Heartbeat)
                println("Receive heartbeat. Stop disown timer")
                stop_timer(w.disown)

            elseif isa(msg, Terminate)
                info("Receive terminate. $(msg.Reason), $(msg.Message)")
                @async write(w.pipe, pack(Terminate(0, msg.Reason, msg.Message)))   
                w.loop = false
                break

            elseif isa(msg, Invoke)
                sid = sessionid(msg)
                println("Receive invoke $(msg.Event) in session $(sid)")
                resp = CocaineResponse(sid, w)
                callback = get(binds, msg.Event, nothing)
                if callback !== nothing
                    req = create_request()
                    w.sessions[sid] = req
                    @schedule callback(req, resp)
                    sleep(0.1)
                else
                    errMsg ="There is no event handler for $(msg.Event)"
                    println(errMsg)
                    _send_error(resp, -100, errMsg)
                    close(resp)
                end

            elseif isa(msg, Chunk)
                sid = sessionid(msg)
                println("Receive chunk: $(sid)")
                session = get(w.sessions, sid, nothing)
                if session !== nothing
                    push!(session, msg.Data)
                else
                    error("Unable to push data for session $(sid)")
                end

            elseif isa(msg, Choke)       
                sid = sessionid(msg) 
                println("Receive choke: $(sid)")
                session = get(w.sessions, sid, nothing)
                if session !== nothing
                    close(session)
                    # delete!(w.sessions, sid) // dispose later
                end

            elseif isa(msg, Error)
                println("Error: $(msg)")
                session = get(w.sessions, sessionid(msg), nothing)
                if session !== nothing
                    error(session, msg.Message)                    
                end

            elseif isa(msg, Internal)
                error(msg.Message)
            end

        end

        # Cleanup sessions
        for sid in keys(w.sessions)
            session = get(w.sessions, sid, nothing)
            if session !== nothing && istaskdone(session.request)
                println("Removed session: $(sid)")           
                delete!(w.sessions, sid)
            end
        end
    end
end

function worker(binds::Dict{String,Function})
    println("Started worker")
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