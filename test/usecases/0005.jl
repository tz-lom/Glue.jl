module TestCase0005

using ..Utils
using Glue

@artifact A1 = Int
@artifact A2 = Int
@artifact A3 = Int

@provider function P1(a::A1)::A2
    return a + 1
end

@provider function P2(a::A2)::A3
    return a * 10
end

@artifact F1_in = Int
@artifact F1_out = Int

@compose C1[P1, P2] where {(F1_in => A1, A3 => F1_out)}


@algorithm generated[C1](F1_in)::F1_out

function expected(a::Int)::Int
    return (a + 1) * 10
end

verifyEquals(generated, expected, 1)
verifySvg(generated, "0005")


end