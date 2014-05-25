#
# Correctness Tests
#

using Cocaine

my_tests = [
			"message.jl",
			"stream.jl"
           ]

println("Running tests:")

for my_test in my_tests
    println(" * $(my_test)")
    include(my_test)
end
