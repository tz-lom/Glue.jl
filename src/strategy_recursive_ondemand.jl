"""
    RecursiveOnDemand(plan::ExecutionPlan, context::Context)

RecursiveOnDemand strategy object.

# Arguments
- `plan::ExecutionPlan` the [`@execution_plan`](@ref) of the [`RecursiveOnDemand`](@ref).
- `context::Context` the [`Context`](@ref) of the [`RecursiveOnDemand`](@ref).

# Example
```
strategy = RecursiveOnDemand(plan::ExecutionPlan, context::Context)
```
"""
struct RecursiveOnDemand
    plan::ExecutionPlan
    context::Context

    function RecursiveOnDemand(plan::ExecutionPlan, context::Context)
        return new(plan, context)
    end
end

# Define setindex! for RecursiveOnDemand to set artifacts in the context
function Base.setindex!(strategy::RecursiveOnDemand, value::Some{T}, idx::Type{<:Artifact{T}}) where {T}
    strategy.context[idx] = value
end
function Base.setindex!(strategy::RecursiveOnDemand, value::Nothing, idx::Type{<:Artifact{T}}) where {T}
    strategy.context[idx] = value
end

# Define getindex for RecursiveOnDemand to fetch artifacts
function Base.getindex(strategy::RecursiveOnDemand, artifact::Type{<:Artifact})
    current = strategy.context[artifact]
    if !isnothing(current)
        return something(current)
    end

    provider = strategy.plan.provider_for_artifact[artifact]
    if !isnothing(provider)
        strategy.context[provider.output] = Some(provider((x) -> strategy[x]))
        return something(strategy.context[artifact])
    else
        artifact_name_1 = nameof(artifact)
        error("Provider for artifact $artifact_name_1 not found")
    end
end

"""
    get_available_artifacts(strategy::RecursiveOnDemand)

Function to get the artifacts of which the values were computed.

# Arguments
- `strategy::RecursiveOnDemand` the [`RecursiveOnDemand`](@ref) of which the available artifacts should be returned.

# Returns
- `Type{<:Artifact}[]` set of the available artifacts.

# Example
```
desired_output = strategy[example_artifact]
available_artifacts = get_available_artifacts
```
"""
function get_available_artifacts(strategy::RecursiveOnDemand)
    # Pre-allocate memory for the set of artifacts
    available_artifacts_set = Vector{Type{<:Artifact}}(undef, count(!isnothing, values(strategy.context)))

    # Efficiently populate the array
    index = 1
    for (artifact, value) in strategy.context
        if !isnothing(value)
            available_artifacts_set[index] = artifact
            index += 1
        end
    end

    return available_artifacts_set
end