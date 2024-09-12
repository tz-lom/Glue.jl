using Test, Glue

@testset "" verbose = true begin
    include("artifact_and_provider_definitions_test.jl")

    include("context_test.jl")

    include("usecases.jl")

end
