type CocaineRequest	
	cond::Condition
	queue::Array{Any,1}
	quit::Bool

	CocaineRequest() = new(Condition(), Any[], false)
end

# On sandbox side
function Base.read(req::CocaineRequest)
	if req.quit
		error("Request is closed")
	end	
	req.cond = Condition()
	wait(req.cond)
	if length(req.queue) > 0 && !req.quit
		mtype, msg = shift!(req.queue)
		if mtype == :Read
			return msg
		else mtype == :Error
			req.quit = true
			error(msg)
		end
	else
		error("Request is closed")
	end
end

# On worker side
function Base.close(req::CocaineRequest)
	if req.quit
		error("Request is closed")
	end
	req.quit = true
	notify(req.cond)
end

function Base.push!(req::CocaineRequest, data)
	if req.quit
		error("Request is closed")
	end
	push!(req.queue, (:Read, data))	
	notify(req.cond)
end

function Base.error(req::CocaineRequest, msg)
	if req.quit
		error("Request is closed")
	end
	push!(req.queue, (:Error, msg))
	notify(req.cond)
end