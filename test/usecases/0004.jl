module TestCase0004

using ..Utils

# using Test

using Glue

@artifact A1 = Int
@artifact A2 = Int

@promote P1 A1 A2


@algorithm generated[P1](A1)::A2

function expected(a::Int)::Int
    return a
end

verifyEquals(generated, expected, 42)
verifySvg(generated, "0004")

end


