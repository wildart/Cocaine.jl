module TestSession
	using Base.Test
	using Cocaine

	const TEST1 =  "(#.#)"
	const TEST2 =  "(~.~)"

	# Correct scenario: 2 reads and finish
	function test1(req::CocaineRequest)
	    msg = read(req)
	    @test msg == TEST1
	    msg = read(req)
	    @test msg == TEST2
	end
	req = CocaineRequest()
	sandbox = @schedule test1(req)
	push!(req, TEST1)	
	push!(req, TEST2)

	# Correct scenario: 1 read => close => read fails
	function test2(req::CocaineRequest)
		msg = read(req)
	    @test msg == TEST1
	    @test_throws ErrorException read(req)
	end
	req = CocaineRequest()
	sandbox = @schedule test2(req)	
	push!(req, TEST1)	
	close(req)

	# Correct scenario: 1 read => error => read fails
	function test3(req::CocaineRequest)
		msg = read(req)
	    @test msg == TEST1
	    try
	    	read(req)
	    catch err	    	
	    	@test err.msg == TEST2
	    end	    	    
	end
	req = CocaineRequest()
	sandbox = @schedule test3(req)
	push!(req, TEST1)
	error(req, TEST2)
end

#[req; sandbox]