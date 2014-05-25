using Cocaine

function echo(req::Cocaine.Request)
	println("Start echo")
    data = read(req)
    data = "Hello from Julia! $(data)"
    println(data)
end

req = Cocaine.create_request()
#@schedule Cocaine.sandbox(echo, req)
t = @task Cocaine.sandbox(echo, req)
yieldto(t)
push!(req, "(^.^)")
close(req)

function echo(req::Request)
	println("Start echo")
    data = read(req)
    data = "Hello from Julia! $(data)"
    println(data)
    data = read(req)
    data = "$(data) Hello from Julia!"
    println(data)
end

req = create_request()
sb = @task sandbox(echo, req)
yieldto( sb )
push!(req, "(^.^)")
push!(req, "(~.~)")
close(req)


function Test()	
	ct = current_task()	
	echo = "start"
	c = 1	
	while c < 3				
		echo = yieldto(ct.last, echo)		
		println(echo)				
		c += 1
	end	
	println("end loop")		
end

ct = current_task()
t = @schedule Test()

yieldto(t)
yieldto(t, -2)