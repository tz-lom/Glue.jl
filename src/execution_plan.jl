
struct ExecutionPlan
    providers::Set{AbstractProvider}
    provider_for_artifact::Dict{Type{<:Artifact},AbstractProvider}
    artifacts::Set{Type{<:Artifact}}
    inputs::Set{Type{<:Artifact}}
    outputs::Set{Type{<:Artifact}}

    function ExecutionPlan(providers)
        provider_for_artifact = Dict{Type{<:Artifact},AbstractProvider}()


        input_set = Set{Type{<:Artifact}}()
        output_set = Set{Type{<:Artifact}}()

        for provider in providers
            for input in Glue.inputs(provider)
                push!(input_set, input)
            end

            for output in Glue.outputs(provider)
                provider_for_artifact[output] = provider
                push!(output_set, output)
            end
        end

        artifacts = union(input_set, output_set)
        inputs = setdiff(input_set, output_set)
        outputs = setdiff(output_set, input_set)


        return new(Set(providers), provider_for_artifact, artifacts, inputs, outputs)
    end
end
