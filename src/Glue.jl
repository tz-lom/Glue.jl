module Glue

export @artifact, @provider, @conditional, @promote, @algorithm, @compose

import Base
using Match

include("abstract.jl")
include("artifact.jl")
include("provider.jl")

include("execution_plan.jl")

include("context.jl")
include("conditional.jl")
include("composed.jl")
include("promote.jl")

include("algorithm.jl")

# @todo: extract into submodule
include("visualization.jl")




end # module Glue
