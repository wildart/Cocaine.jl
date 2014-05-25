type CocaineStream
	stream::Task	
	CocaineStream(stream_func::Function, stream, init::Bool=true) = 
		CocaineStream(current_task(), stream_func, stream, init)
	function CocaineStream(ct, stream_func::Function, stream, init::Bool)
		t = @task stream_func(stream, ct)
		if init
			yieldto(t)
		end
		new(t)
	end
end

function RWStream(stream, ret)
	resp = (true, :Init)	
	while true
		#println("RWS: $(ret), $(current_task().last)")
		if isopen(stream)
			println("RWS-Resp: $(resp)")
			msg, mtype = yieldto(ret, resp)
			println("RWS-Msg: $(msg), $(mtype)")
			if mtype == :Quit
				break
			elseif mtype == :Read
				buf = stream.buffer
				Base.wait_readnb(stream, 1)
				msg = takebuf_array(buf)				
				resp = (msg, :Received)
    			#println("WRS-Read: $(msg)")
			elseif mtype == :Write				
				sent = write(stream, msg)
				resp = (sent, :Wrote)
				#println("WRS-Write: $(msg)")
			end
		else
			yieldto(ret, ("WriteStream: Stream is closed", :Error))
			break
		end
	end
end

function Base.write(s::CocaineStream, data)
	#println("write: $(s.stream)")
	if istaskdone(s.stream)
		error("Stream is stoped")
	end
	resp, rtype = yieldto(s.stream, (data, :Write))
	if rtype == :Error
		yieldto(s.stream)
		error(resp)
	else
		return resp
	end
end

function Base.close(s::CocaineStream)
	yieldto(s.stream, (true, :Quit))
	wait(s.stream)
end

function Base.read(s::CocaineStream)
	#println("read: $(s.stream)")
	if istaskdone(s.stream)
		error("Stream is stoped")
	end
	msg, mtype = yieldto(s.stream, (false, :Read))
	#println("read: $(msg), $(mtype)")
	if mtype == :Error
		yieldto(s.stream)
		error(msg)
	else
		return msg
	end
end

# function WritebleStream(stream, ret)	
# 	sent = 0
# 	while true				
# 		println("WS: $(ret), $(current_task().last)")
# 		if isopen(stream)			
# 			resp = (sent, :Wrote)			
# 			msg, mtype = yieldto(ret, resp)	
# 			println("WS: $(msg), $(mtype)")
# 			if mtype == :Quit
# 				break
# 			end			
# 			sent = write(stream, msg)			
# 		else 			
# 			yieldto(ret, ("WriteStream: Stream is closed", :Error))						
# 			break			
# 		end
# 	end		
# end

# function ReadableStream(stream, ret)		
# 	while true	
# 		println("RS: $(ret), $(current_task().last)")
# 		if isopen(stream)			
# 			# buf = stream.buffer
# 			# @assert buf.seekable == false
# 			# Base.wait_readnb(stream, 1)
# 			# msg = takebuf_array(buf)
# 			buf = stream.buffer
# 			Base.wait_readnb(stream, 1)
# 			msg = takebuf_array(buf)
#     		println("RS: $(msg)")
#     		resp, rtype = yieldto(ret, (msg, :Read))
#     		println("RS: $(resp), $(rtype)")
# 			if rtype == :Quit
# 				break
# 			end	
# 		else 
# 			yieldto(ret, ("ReadStream: Stream is closed", :Error))
# 			break
# 		end
# 	end	
# end


