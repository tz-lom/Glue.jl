module TestCase0001

using ..Utils

# using Test

using Glue

@artifact A1 = Int
@artifact A2 = Int
@artifact A3 = Int

"P1 description"
@provider function P1(a::A1)::A2
    return a + 1
end

"P2 description"
@provider function P2(a::A2)::A3
    return a * 10
end



@algorithm generated[P1, P2](A1)::A3

function expected(a::Int)::Int
    return (a + 1) * 10
end

verifyEquals(generated, expected, 1)
verifySvg(generated, "0001")


end


