module TestCase0002

using ..Utils
using Glue

@artifact A1 = Int
@artifact A2 = Int
@artifact A3 = Int

@artifact A4 = Int

@artifact B1 = Bool


@provider function P1(a::A1)::A2
    return a + 1
end

@provider function P2(a::A1)::A3
    return a * 10
end


@conditional C1::A4 = B1 ? A2 : A3


@algorithm generated[P1, P2, C1](A1, B1)::A4


function expected(a::Int, b::Bool)
    if b
        return a + 1
    else
        return a * 10
    end
end


verifyEquals(generated, expected, 1, false)
verifyEquals(generated, expected, 1, true)

verifySvg(generated, "0002")


end
