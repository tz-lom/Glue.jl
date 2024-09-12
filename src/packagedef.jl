

abstract type Artifact{T} end

struct ProviderDefinition{T}
    inputs::Vector{T}
    output::T
end

# Will return ProviderDefinition for a given Provider
function describe_provider end

