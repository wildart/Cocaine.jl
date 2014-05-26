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
		h = wait(cond)
		#println("RP: Woke up!, $(length(queue)), $(h)")
		if h == REQUEST_READ
			if length(queue) > 0
				msg = shift!(queue)
				#println("RP: Sending: $(msg)")
				produce1((msg, :Msg))
				#println("RP: MSG sent!")
			end
		elseif h == REQUEST_QUIT
			break
		else
			produce1((h, :Error))
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
	notify(req.cond, REQUEST_QUIT)
end

function Base.push!(req::CocaineRequest, data)
	if istaskdone(req.request)
		error("Request is closed")
	end
	push!(req.queue, data)
	notify(req.cond, REQUEST_READ)
end

function Base.error(req::CocaineRequest, msg)
	if istaskdone(req.request)
		error("Request is closed")
	end
	notify(req.cond, msg)
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