struct PromoteProvider <: AbstractProvider
    call::Function
    input::Type{<:Artifact}
    output::Type{<:Artifact}

    function PromoteProvider(call, input, output)
        if input == output
            error("You shouldn't promote artifact $input to the same artifact")
        elseif artifact_type(input) !== artifact_type(output)
            error(
                "You shouldn't promote artifact $input to an artifact of a different type",
            )
        end
        return new(call, input, output)
    end
end

inputs(p::PromoteProvider) = (p.input,)
outputs(p::PromoteProvider) = (p.output,)
storage(p::PromoteProvider) = p.output

function provide(p::PromoteProvider, result::Type, storage, source)
    if (p.output != result)
        error("$p can't provide $result")
    end
    return quote
        if isnothing($storage)
            $storage = $(source(p.input))
        end
        something($storage)
    end
end

"""
    @promote name input output

Defines promote provider that assigns data from the `input` Artifact to the `output` Artifact.
Both Artifacts have to share same data type.
"""
macro promote(name::Symbol, input::Symbol, output::Symbol)
    name = esc(name)
    input = esc(input)
    output = esc(output)


    return quote

        $name(a::$artifact_type($input))::$artifact_type($output) = a

        const provider = Glue.PromoteProvider($name, $input, $output)


        function Glue.describe_provider(::typeof($name))
            return provider
        end
    end
end
