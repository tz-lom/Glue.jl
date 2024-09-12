abstract type Artifact{T} end

real_type(::Type{Artifact{T}}) where {T} = T

"""
    @artifact name[,name...] = Type

Declares `Artifact` associated with `Type`

# Example
```
@artifact A = Int
@artifact B,C = Bool
```
"""
macro artifact(expr::Expr)

    function gen_expr(iname, itype)
        name = esc(iname)
        type = esc(itype)
        return quote
            Core.@__doc__ struct $name <: Artifact{$type}
                $name(args...) = $type(args...)
            end
        end
    end

    @match expr begin
        Expr(:(=), [Expr(:tuple, inames), itype]) => begin
            exprs = map(inames) do iname
                gen_expr(iname, itype)
            end

            return Expr(:block, exprs...)
        end
        Expr(:(=), [iname::Symbol, itype::Symbol]) => begin
            return gen_expr(iname, itype)
        end
        _ => error("Unsupported syntax: $(dump(expr))")
    end
end

"""
    artifact_type(Artifact)::Type

Get the `Type` associated with an `Artifact`

# Example
```julia
@artifact A = Int
artifact_type(A) == Int
```
"""
artifact_type(::Type{<:Artifact{T}}) where {T} = T



"""
    is_artifact(::Type)

Check if a given type is an `Artifact`.
"""
is_artifact(::Type{<:Artifact}) = true
is_artifact(_) = false

function Base.show(io::IO, ::MIME"text/plain", ::Type{T}) where {T<:Artifact}
    print(io, "Artifact $T=$(artifact_type(T))")
end
