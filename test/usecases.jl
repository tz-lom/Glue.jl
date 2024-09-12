module UsecaseTests

using Test

module Utils

export verifyEquals, verifySvg

using InteractiveUtils: code_native
using Test
using Glue
using GraphvizDotLang: save

function signature(f)
    m = methods(f)

    if length(m) != 1
        error("Function $f have multiple signatures")
    end
    return Tuple(m[1].sig.types[2:end])
end

function return_type(f, args...)
    type = Core.Compiler.return_type(f, Base.typesof(args...))
    if type == Union{}
        error("Function $f is not defined for $args")
    end
    return type
end


function verifyEquals(generated, expected, arguments...)

    # Verify signature
    @test signature(generated) == signature(expected)
    # Verify return type                   
    @test return_type(generated, arguments...) == return_type(expected, arguments...)


    @test generated(arguments...) == expected(arguments...)

    io = IOBuffer()

    code_native(
        io,
        expected,
        Base.typesof(arguments...),
        debuginfo = :none,
        dump_module = false,
    )
    expected_native = String(take!(io))

    code_native(
        io,
        generated,
        Base.typesof(arguments...),
        debuginfo = :none,
        dump_module = false,
    )
    generated_native = String(take!(io))

    @test expected_native == generated_native
end


function verifySvg(to_visualize, expected)
    g = Glue.visualize(to_visualize)

    mktemp() do fname, _
        save(g, fname)

        result = read(fname, String)

        expected_path = joinpath(@__DIR__, "svgs", expected * ".svg")

        cp(fname, expected_path; force = true)

        expected_str = read(expected_path, String)
        @test result == expected_str
    end
end

end

function test()

    usecases() = filter(endswith(".jl"), readdir(joinpath(@__DIR__, "usecases")))

    @testset verbose = true for file in usecases()
        include(joinpath(@__DIR__, "usecases", file))
    end

end

end

@testset "Usecases" verbose = true UsecaseTests.test()