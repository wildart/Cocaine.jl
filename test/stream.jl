module TestStream
	using Cocaine
	using Base.Test

	const TEST_STR = "test"

	type MockStream
		closed
		buffer
		MockStream() = new(false, IOBuffer(TEST_STR.data, true, false, false, false, typemax(Int)))
	end

	Base.isopen(s::MockStream) = !s.closed
	Base.write(s::MockStream, data) = length(data)
	Base.close(s::MockStream) = s.closed = true	
	Base.wait_readnb(s::MockStream, i::Int) = ()
	reset(s::MockStream) = s.buffer.ptr = 1
	
	# WritebleStream 
	#################

	s = MockStream()
	t = Cocaine.CocaineStream(Cocaine.WritebleStream, s)

	# Writing to stream
	@test write(t, 1) == 1
	@test write(t, "aa") == 2
	@test write(t, [2, 3, 4]) == 3
	
	# Cannot write into closed stream
	close(t)
	@test_throws ErrorException write(t,"aa")

	# Close underling stream
	t = Cocaine.CocaineStream(Cocaine.WritebleStream, s)
	close(s)
	# Cannot write into closed underling stream
	@test_throws ErrorException write(t,"aa")

	
	# ReadableStream 
	#################

	s = MockStream()
	t = Cocaine.CocaineStream(Cocaine.ReadableStream, s, false)

	# Writing to stream
	@test bytestring(read(t)) == TEST_STR
	reset(s)
	@test bytestring(read(t)) == TEST_STR

	# Cannot read closed stream
	close(t)
	@test_throws ErrorException read(t)

	# Close underling stream	
	t = Cocaine.CocaineStream(Cocaine.ReadableStream, s, false)
	reset(s)
	close(s)
	# Cannot write into closed underling stream
	@test_throws ErrorException read(t)
end