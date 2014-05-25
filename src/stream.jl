typealias CocaineStream Task

const START_CHUNK_SIZE = 4096

function WriteStream(stream)
	msg = produce("WriteStream is active") # Init
	while true
		if isopen(stream)
			sent = write(stream, msg)
			msg = produce((sent, msg))
		else
			produce(pack(Internal(0, 1, "WriteStream: Stream is closed")))
			break
		end
	end
end

function ReadStream(stream)
	ct = current_task()
	produce("ReadStream is active") # Init
	while true
		if isopen(stream)
			buf = stream.buffer
			@assert buf.seekable == false
			Base.wait_readnb(stream,1)
			msg = takebuf_array(buf)
			produce(msg)
		else
			produce(pack(Internal(0, 2, "ReadStream: Stream is closed")))
			break
		end
	end
end

function init(streamTask::Task)
	r = consume(streamTask)
	#println("Init: $(r)")
end

function write_stream(streamTask::CocaineStream, msg)
	sent, sent_msg = consume(streamTask, msg)
	#println("WS: bytes sent = $(sent), msg = $(sent_msg)")
end
function read_stream(streamTask::CocaineStream)
	consume(streamTask)
end