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
	
	s = MockStream()
	t = Cocaine.CocaineStream(Cocaine.RWStream, s)

	# Writing to stream
	@test write(t, 1) == 1
	@test write(t, "aa") == 2
	@test write(t, [2, 3, 4]) == 3

	# Read from stream
	@test bytestring(read(t)) == TEST_STR
	reset(s)
	@test bytestring(read(t)) == TEST_STR
	reset(s)
	
	# Cannot write into closed stream
	close(t)
	@test_throws ErrorException write(t,"aa")
	@test_throws ErrorException read(t)

	# Close underling stream
	t = Cocaine.CocaineStream(Cocaine.RWStream, s)
	close(s)
	# Cannot write into closed underling stream
	@test_throws ErrorException write(t,"aa")
	@test_throws ErrorException read(t)

end