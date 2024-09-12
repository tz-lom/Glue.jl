"""
    struct ProviderSet

A `ProviderSet` is used to store providers to be used in an [`@execution_plan`](@ref).

# Fields
- `set::Set{Provider}` A set of providers.

# Constructor
The constructor turns the Vector of providers passed into a set of Providers and gives an error if something goes wrong.

# Example
```
providers = ProviderSet([provider1, provider2, provider3])
```
"""
struct ProviderSet
    set::Set{Provider}

    function ProviderSet(providers...)
        new(Set(map(describe_provider, providers)))
    end

    function ProviderSet(providers::Vector)
        new(Set(map(describe_providers, providers)))
    end
end


# Define length and iterate for ProviderSet
Base.length(p::ProviderSet) = Base.length(p.set)
Base.iterate(p::ProviderSet, i...) = Base.iterate(p.set, i...)

