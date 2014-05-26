const REQUEST_READ = 1
const REQUEST_QUIT = 2

type CocaineRequest
	request::Task
	cond::Condition
	queue::Array{Any,1}	

	function CocaineRequest(stream_func::Function)
		queue = Any[]
		c = Condition()
		t = @schedule stream_func(queue, c)		
		new(t, c, queue)
	end
end

function RequestProxy(queue, cond)
	println("RP: Start proxy")
	while true
		wait(cond)
		#println("RP: Woke up!, $(length(queue)), $(h)")
		if length(queue) > 0
			mtype, msg = shift!(queue)
			if mtype == :Read									
				#println("RP: Sending: $(msg)")
				produce1((msg, :Msg))
				#println("RP: MSG sent!")				
			elseif mtype == :Quit
				break
			elseif mtype == :Error
				produce1((msg, :Error))
			end	
		end	
	end
	println("RP: Finished!")
end

create_request() = CocaineRequest(RequestProxy)

function Base.read(req::CocaineRequest)
	if istaskdone(req.request)
		error("Request is closed")
	end	
	msg = consume(req.request)
	if msg === nothing
		error("Request is closed")
	elseif msg[2] == :Msg
		return msg[1]
	else msg[2] == :Error
		error(msg[1])
	end
end

function Base.close(req::CocaineRequest)
	if istaskdone(req.request)
		error("Request is closed")
	end
	push!(req.queue, (:Quit, true))
	notify(req.cond)
end

function Base.push!(req::CocaineRequest, data)
	if istaskdone(req.request)
		error("Request is closed")
	end
	push!(req.queue, (:Read, data))
	notify(req.cond)
end

function Base.error(req::CocaineRequest, msg)
	if istaskdone(req.request)
		error("Request is closed")
	end
	push!(req.queue, (:Error, msg))
	notify(req.cond)
end

function produce1(v)    
    ct = current_task()
    local empty, t, q    
    while true
        q = ct.consumers
        if isa(q,Task)
            t = q
            ct.consumers = nothing
            empty = true
            break
        end
        wait()
    end

    t.state = :runnable    
    println("PRODUCE: suspend")
    if empty        
		yieldto(t, v)
    else
        schedule(t, v)        
    end
    println("PRODUCE: recover")
end