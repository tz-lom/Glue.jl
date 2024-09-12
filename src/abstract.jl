using Markdown

abstract type AbstractProvider end


"""
    describe_provider(x)::AbstractProvider

Returns Provider object describing the provider
This function is only defined for providers, use `is_provider(x)` to check if `x` is a provider
"""
describe_provider(p::T) where {T<:AbstractProvider} = p


"""
    is_provider(x)::Boolean

Returns `true` if `x` is declared as a provider and `false` otherwise.
"""
is_provider(::AbstractProvider) = true
is_provider(f::Function) = hasmethod(describe_provider, (typeof(f),))

function collect_providers(lst)
    return map(describe_provider, lst)
end

function extract_short_description(doc::Markdown.MD)
    descr = string(Markdown.MD(doc.content[1]))
    if descr == "No documentation found.\n"
        return nothing
    else
        return descr
    end
end

function short_description(p::AbstractProvider)
    return nothing
    # docstring = @doc p

    # descr = string(Markdown.MD(docstring.content[1]))
    # if descr == "No documentation found.\n"
    #     return nothing
    # else
    #     return descr
    # end
end
