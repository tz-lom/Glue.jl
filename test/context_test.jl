
module Test_context
using Test, Glue
@testset "@context" begin
    @artifact A = Int
    @artifact B = String
    @artifact C = Float64

    Glue.@context Ctx A B C
    ctx = Ctx()
    @test all(values(ctx)) do (_, x)
        isnothing(x)
    end == true

    ctx[A] = 4
    ctx[B] = "foo"

    @test something(ctx[A]) == 4
    @test something(ctx[B]) == "foo"
    @test isnothing(ctx[C])

    @test_throws ErrorException ctx[A] = 5
end

module Foo
using Glue
@artifact A = Int
@artifact B = String
end

@testset "@context with types from other modules" begin


    Glue.@context Ctx2 Foo.A Foo.B
    ctx = Ctx2()

    @test isnothing(ctx[Foo.A])

    ctx[Foo.A] = 4
    @test something(ctx[Foo.A]) == 4
end

end