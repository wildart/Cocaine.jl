module TestSession
	using Base.Test
	using Cocaine

	const TEST1 =  "(#.#)"
	const TEST2 =  "(~.~)"

	# Correct scenario: 2 reads and finish
	function test1(req::CocaineRequest)		
	    msg = read(req)
	    @test msg == TEST1
	    data = "Hello from Julia! $(msg)"
	    println("TEST1: ", data)
	    msg = read(req)
	    @test msg == TEST2
	    data = "Hello from Julia! $(msg)"
	    println("TEST1: ", data)
	    println("TEST1 ended")
	end
	req = Cocaine.create_request()
	sandbox = @schedule test1(req)
	sleep(1.0)
	push!(req, TEST1)
	sleep(1.0)
	push!(req, TEST2)
	sleep(1.0)
	close(req)
	sleep(1.0)
	@test istaskdone(req.request)
	@test istaskdone(sandbox)
	@test sandbox.exception === nothing

	# Correct scenario: 1 read => close => read fails
	function test2(req::CocaineRequest)
		msg = read(req)
	    @test msg == TEST1
	    @test_throws ErrorException read(req)
	    println("TEST2 ended")
	end
	req = Cocaine.create_request()
	sandbox = @schedule test2(req)
	sleep(1.0)
	push!(req, TEST1)
	sleep(1.0)
	close(req)
	sleep(1.0)
	@test istaskdone(req.request)
	@test istaskdone(sandbox)
	@test sandbox.exception === nothing

	# Correct scenario: 1 read => error => read fails
	function test3(req::CocaineRequest)
		msg = read(req)
	    @test msg == TEST1
	    try
	    	read(req)
	    catch err
	    	println("TEST3: ", err.msg)
	    	@test err.msg == TEST2
	    end	    
	    println("TEST3 ended")
	end
	req = Cocaine.create_request()
	sandbox = @schedule test3(req)
	sleep(1.0)
	push!(req, TEST1)
	sleep(1.0)
	error(req, TEST2)
	sleep(1.0)
	close(req)
	sleep(1.0)
	@test istaskdone(req.request)
	@test istaskdone(sandbox)
	@test sandbox.exception === nothing
end

#[req; sandbox]