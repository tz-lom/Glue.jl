using GraphvizDotLang: GraphvizDotLang, Graph, digraph, edge, node, attr, subgraph
import GraphViz

const Grph = Union{GraphvizDotLang.Graph,GraphvizDotLang.Subgraph}

# GraphViz.

as_id(f::Function) = String(Symbol(parentmodule(f), '.', f))
as_id(t::Type) = String(Symbol(t))
as_id(s::Symbol) = String(s)

function visualize!(g::Grph, a::Type{<:Artifact})
    id = as_id(a)
    g |> node(as_id(a), ; shape = "ellipse", label = "$id\n$(artifact_type(a))")
end

function visualize!(g::Grph, p::CallableProvider)
    id = as_id(p.call)
    g |> node(id; shape = "rectangle", label = "$id\n$(short_description(p))")

    for inp in p.inputs
        # visualize!(g, inp)
        g |> edge(as_id(inp), id)
    end

    # visualize!(g, p.output)
    g |> edge(id, as_id(p.output))
end

function visualize!(g::Grph, p::ConditionalProvider)
    id = as_id(p.name)
    g |> node(id; shape = "diamond", label = "$id")


    # visualize!(g, p.condition)
    g |> edge(as_id(p.condition), id; label = "?")

    # visualize!(g, p.if_true)
    g |> edge(as_id(p.if_true), id; label = "true")

    # visualize!(g, p.if_false)
    g |> edge(as_id(p.if_false), id; label = "false")

    visualize!(g, p.output)
    g |> edge(id, as_id(p.output))
end

function visualize!(g::Grph, p::AlgorithmProvider)
    id = as_id(p.call)

    sub = g #subgraph(g, "cluster_" * id; label = id)

    sub_inputs = subgraph(sub, "cluster_" * id * "inputs"; label = "Inputs")

    for inp in p.inputs
        visualize!(sub_inputs, inp)
    end

    visualize!(sub, p.output)

    for provider in p.providers
        visualize!(sub, provider)
    end
end

function visualize!(g::Grph, p::ComposedProvider)
    id = as_id(p.call)

    sub = subgraph(g, "cluster_$id#aside"; label = "$id implementation")
    for provider in p.plan.providers
        visualize!(sub, provider)
    end

    g |> node(id; label = id)

    for inp in inputs(p)
        visualize!(g, inp)
        g |> edge(as_id(inp), id)
    end
    for out in outputs(p)
        visualize!(g, out)
        g |> edge(id, as_id(out))
    end
end

function visualize!(g::Grph, p::PromoteProvider)
    id = as_id(p.call)

    visualize!(g, p.input)
    visualize!(g, p.output)

    g |> node(id; shape = "rpromoter", label = id)
    g |> edge(as_id(p.input), id)
    g |> edge(id, as_id(p.output))
end

function visualize(p::AbstractProvider)
    g = digraph()
    visualize!(g, p)
    return g
end

function visualize(p)
    visualize(describe_provider(p))
end

function render(g::Graph)
    io = IOBuffer()
    print(io, g)
    return GraphViz.Graph(String(take!(io)))
end