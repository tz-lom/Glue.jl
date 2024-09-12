abstract type AbstractContext end

Base.haskey(::AbstractContext, _) = false

for_context(x::Type{<:Artifact}) = Union{Nothing,Some{artifact_type(x)}}
for_context(x::Type{<:AbstractContext}) = x

default_constructed(::Type{<:Artifact}) = nothing
default_constructed(x::Type{<:AbstractContext}) = x()


"""
    @context(name, artifacts_or_contexts...)

Creates structure `name` which contains set of artifacts and contexts.
This structure implements single write, so it's elements can be stored only once.
Access to elements of the structure is done via index operator `[]` where key is the `Artifact` or `Context` types

Example:
```
@artifact A,B Int
@context Ctx A B

ctx = Ctx()
isnothing(ctx[A]) == true

ctx[A] = 1
isnothing(ctx[A]) == false
```

"""
macro context(name, artifacts...)
    field_name_unquoted(artifact) = Symbol("salt_", artifact)
    field_name(artifact) = QuoteNode(field_name_unquoted(artifact))

    fields = map(artifacts) do artifact
        return :($(field_name_unquoted(artifact))::Glue.for_context($artifact))
    end


    getindex = map(artifacts) do artifact
        err = "Artifact $artifact is not set"
        return esc(:(function Base.getindex(c::$name, ::Type{$artifact})
            x = getfield(c, $(field_name(artifact)))
            return x
        end))
    end

    setindex = map(artifacts) do artifact
        return esc(
            :(
                if $artifact <: $Artifact
                    function Base.setindex!(
                        c::$name,
                        v::Glue.artifact_type($artifact),
                        ::Type{$artifact},
                    )
                        if !isnothing(getfield(c, $(field_name(artifact))))
                            error($("Artifact $artifact is already set"))
                        end
                        setfield!(c, $(field_name(artifact)), Some(v))
                    end
                end
            ),
        )
    end

    iterate_body = foldr(enumerate(artifacts), init = :(nothing)) do (i, name), other
        :(
            if iter == $i
                ($(esc(name)) => getfield(ctx, $(field_name(name))), $(i + 1))
            else
                $other
            end
        )
    end

    esc_name = esc(name)


    return quote
        mutable struct $name <: AbstractContext
            $((esc(field) for field in fields)...)

            $name() = new(
                $((:(default_constructed($(esc(artifact)))) for artifact in artifacts)...),
            )
        end

        $(getindex...)

        $(setindex...)

        function Base.iterate(ctx::$esc_name, iter::Int)
            $iterate_body
        end

        function Base.iterate(ctx::$esc_name)
            return Base.iterate(ctx, 1)
        end

        $esc_name
    end
end

function Base.show(io::IO, type::MIME"text/plain", d::T) where {T<:AbstractContext}
    indent = get(io, :indent, 0)
    if indent == 0
        println(io, "Context $(typeof(d))")
        indent = 2
    end
    spaces = repeat(' ', indent)

    for i in d
        if isnothing(i.second)
            println(io, "$spaces[ ] $(i.first)")
        elseif typeof(i.second) <: AbstractContext
            println(io, "$spaces[+] $(i.first)")
            nio = IOContext(io, :indent => indent + 4)
            show(nio, type, i.second)
        else
            println(io, "$spaces[✔] $(i.first) => $(something(i.second))")
        end
    end
end

function Base.propertynames(::AbstractContext, ::Bool)
    return ()
end

function Base.getproperty(::AbstractContext, ::Symbol)
    error("no properties in AbstractContext, use array indexing instead")
end

function Base.setproperty!(::AbstractContext, ::Symbol, ::Any)
    error("no properties in AbstractContext, use array indexing instead")
end
