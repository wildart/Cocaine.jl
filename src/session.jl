type CocaineRequest
	request::Task	
	CocaineRequest(stream_func::Function, init::Bool=true) = 
		CocaineStream(current_task(), stream_func, stream, init)
	function CocaineRequest(ct, stream_func::Function, init::Bool)
		t = @task stream_func(ct)
		if init
			yieldto(t)
		end
		new(t)
	end
end

function RequestProxy(ct)
	quit = false			
	while !quit					
		println("start consume")
		mdata, mtype = consume(ct)
		println("end consume")
		if mtype == :Push			
			println("start produce")
			r = produce(mdata)
			println("end produce: ", r)
		elseif mtype == :Quit
			quit = true
		end				
		if quit
			println("quit")			
			break
		end						
	end	
	println("end loop")	
	yieldto(ct)
end

create_request() = CocaineRequest(RequestProxy)

function sandbox(eval::Function, req::CocaineRequest)
    eval(req)   
    consume(req, false) 
end

function Base.read(req::CocaineRequest)
	consume(req, true)
end

function Base.push!(req::CocaineRequest, data)
	yieldto(req, (data, :Push))
end

function Base.close(req::CocaineRequest)
	yieldto(req, (true, :Quit))
end
