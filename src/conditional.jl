struct ConditionalProvider <: AbstractProvider
    name::Symbol
    condition::Type{<:Artifact}
    if_true::Type{<:Artifact}
    if_false::Type{<:Artifact}
    output::Type{<:Artifact}

    function ConditionalProvider(name, condition, if_true, if_false, output)
        if artifact_type(condition) != Bool
            error("Conditional provider requires `condition` artifact of type Bool")
        end
        if artifact_type(if_true) != artifact_type(output)
            error(
                "Conditional provider requires that `if_true` and `output` shares same type",
            )
        end
        if artifact_type(if_false) != artifact_type(output)
            error(
                "Conditional provider requires that `if_false` and `output` shares same type",
            )
        end

        return new(name, condition, if_true, if_false, output)
    end
end

inputs(p::ConditionalProvider) = (p.condition, p.if_true, p.if_false)
outputs(p::ConditionalProvider) = (p.output,)
storage(p::ConditionalProvider) = p.output

function provide(p::ConditionalProvider, result::Type, storage, source)
    if p.output != result
        error("$p can't provide $result")
    end
    return quote
        if isnothing($storage)
            $storage = if $(source(p.condition))
                $(source(p.if_true))
            else
                $(source(p.if_false))
            end
        end
        something($storage)
    end
end

"""
    @conditional name::output_artifact = bool_artifact ? input_artifact1 : input_artifact2

Defines a `ConditionalProvider` that promotes one of the `input_artifact` to an `output_artifact` depending on a value of `bool_artifact`.
The `input_artifact`s and `output_artifact` should be of the same type and `bool_artifact` shall be of type `Bool`

# Example
```
@artifact A = Int
@artifact B = Int
@artifact C = Bool
@artifact D = Int

@conditional conditional::D = C ? A : B
```
"""
macro conditional(e::Expr)
    @match e begin
        Expr(
            :(=),
            [Expr(:(::), [name, output]), Expr(:if, [condition, if_true, if_false])],
        ) => begin
            sname = QuoteNode(name)

            name = esc(name)
            condition = esc(condition)
            if_true = esc(if_true)
            if_false = esc(if_false)
            output = esc(output)
            return quote
                $name = Glue.ConditionalProvider(
                    $sname,
                    $condition,
                    $if_true,
                    $if_false,
                    $output,
                )

                function Glue.describe_provider(::typeof($name))
                    return $name  
                end
                
                Glue.is_provider(::typeof($name)) = true
            end
        end
        _ => throw(DomainError(e, "Can't make conditional provider from given definition"))
    end
end