"""
    generate_diagram_from_plan(plan::ExecutionPlan)

Function to generate a diagram from an [`@execution_plan`](@ref), returns the diagram code as a string.

# Arguments
- `plan::ExecutionPlan` the [`@execution_plan`](@ref) that should be visualized.

# Returns
- `diagram_code::String` the NomnomlJS code of the diagram.

# Example
```
diagram_code_string = generate_diagram_from_plan(plan)
```
"""
function generate_diagram_from_plan(plan::ExecutionPlan)
  # Create a diagram header
  diagram_code = "#.provider: fill=#8f8 stroke=black\n#.conditional: fill=#F28C28 stroke=black\n#.promote: fill=#87CEEB stroke=black\n" *
                 "#.artifact: fill=#FFFF00 stroke=black\n#.inputartifact: fill=#BF40BF stroke=black\n#.outputartifact: fill=red stroke=black\n" *
                 "#stroke: black\n#.container: fill=#F0FFFF\n[<container> Legend|\n[<inputartifact> Input Artifact] -/- [<artifact> Artifact]\n" *
                 "[<artifact> Artifact] -/- [<outputartifact> Output Artifact]\n[<outputartifact> Output Artifact] -/- [<provider> Provider]\n" *
                 "[<provider> Provider] -/- [<conditional> Conditional]\n[<conditional> Conditional] -/- [<promote> Promote]\n]\n" *
                 "[<container> Algorithm Diagram|\n"

  diagram_code = private_generate_diagram_from_plan(diagram_code, plan)

  diagram_code *= "]"

  # Draw the diagram
  diagram = Diagram(diagram_code)
  write("diagram.png", diagram)
  return diagram_code
end

"""
    generate_diagram_from_plans(execution_plans::Vector; plan_links="")

Function to generate a diagram from multiple [`@execution_plan`](@ref)s, returns the diagram code as a string.

# Arguments
- `execution_plans::Vector` is a Vector of execution plans.
- `plan_links::String` is a String for connecting the execution plans in the diagram, connecting the execution plans is optional.

# Returns
- `diagram_code::String` the NomnomlJS code of the diagram.

# Example
```
execution_plans = [plan1, plan2, plan3]
plan_links = "plan1 to plan3\\n" *
             "plan2 to plan3"
example_name = generate_diagram_from_plans(execution_plans; plan_links)
```
"""
function generate_diagram_from_plans(execution_plans::Vector; plan_links="")
  # Create a diagram header
  diagram_code = "#.provider: fill=#8f8 stroke=black\n#.conditional: fill=#F28C28 stroke=black\n#.promote: fill=#87CEEB stroke=black\n" *
                 "#.artifact: fill=#FFFF00 stroke=black\n#.inputartifact: fill=#BF40BF stroke=black\n#.outputartifact: fill=red stroke=black\n" *
                 "#stroke: black\n#.container: fill=#F0FFFF\n[<container> Legend|\n[<inputartifact> Input Artifact] -/- [<artifact> Artifact]\n" *
                 "[<artifact> Artifact] -/- [<outputartifact> Output Artifact]\n[<outputartifact> Output Artifact] -/- [<provider> Provider]\n" *
                 "[<provider> Provider] -/- [<conditional> Conditional]\n[<conditional> Conditional] -/- [<promote> Promote]\n]\n"

  for plan in execution_plans
    plan_name = plan.name

    diagram_code *= "[<container> $plan_name|\n"
    diagram_code = private_generate_diagram_from_plan(diagram_code, plan)
    diagram_code *= "]\n"
  end

  if plan_links != ""
    lines = split(plan_links, '\n')  # Split the string into lines

    for line in lines
      match_result = match(r"(\w+)\s+to\s+(\w+)", line)
      if match_result !== nothing
        var_from, var_to = match_result.captures
        diagram_code *= "[<container> $var_from] -> [<container> $var_to]\n"
      end
    end
  end

  # Draw the diagram
  diagram = Diagram(diagram_code)
  write("diagram.png", diagram)

  return diagram_code
end

# Private function to get the diagram_code of an ExecutionPlan
function private_generate_diagram_from_plan(diagram_code_string::String, plan::ExecutionPlan)
  provider_type_string = ""

  inputs, outputs = sort_plan_artifacts(plan)

  # Add all the Provider and Artifact lines to the diagram_code string
  for provider in plan.provider_set
    provider_name = string(provider.name)

    # handle_provider will handle the provider based on it's type and add it to the diagram_code string
    provider_type_string, diagram_code_string = handle_provider_diagram(provider, diagram_code_string, provider_name, inputs)

    # Get the output Artifact of the specific provider
    output_artifact_name = nameof(provider.output)

    artifact_type_string = "artifact"

    if provider.output in outputs
      artifact_type_string = "outputartifact"
    end

    # Add arrows for dependencies
    diagram_code_string *= "[<$provider_type_string> $provider_name] -> [<$artifact_type_string> $output_artifact_name]\n"
  end

  return diagram_code_string
end

# Return provider_type_string, and Artifact to Provider diagram_code_string lines for either ConditionalProvider, PromoteProvider, or CallableProvider
function handle_provider_diagram(provider::ConditionalProvider, diagram_code_string::String, provider_name::String, inputs::Vector{Type{<:Artifact}})
  provider_type_string = "conditional"
  conditional_name = nameof(provider.condition)
  if_true_name = nameof(provider.if_true)
  if_false_name = nameof(provider.if_false)

  conditional_artifact_type_string = "artifact"
  if_true_artifact_type_string = "artifact"
  if_false_artifact_type_string = "artifact"

  if provider.condition in inputs
    conditional_artifact_type_string = "inputartifact"
  end
  if provider.if_true in inputs
    if_true_artifact_type_string = "inputartifact"
  end
  if provider.if_false in inputs
    if_false_artifact_type_string = "inputartifact"
  end

  # Add arrows for dependencies
  diagram_code_string *= "[<$conditional_artifact_type_string> $conditional_name] Condition -> [<$provider_type_string> $provider_name]\n"
  diagram_code_string *= "[<$if_true_artifact_type_string> $if_true_name] IfTrue -> [<$provider_type_string> $provider_name]\n"
  diagram_code_string *= "[<$if_false_artifact_type_string> $if_false_name] IfFalse -> [<$provider_type_string> $provider_name]\n"

  return provider_type_string, diagram_code_string
end
function handle_provider_diagram(provider::PromoteProvider, diagram_code_string::String, provider_name::String, inputs::Vector{Type{<:Artifact}})
  provider_type_string = "promote"
  input_artifact_name = nameof(provider.input)
  artifact_type_string = "artifact"

  if in(provider.input, inputs)
    artifact_type_string = "inputartifact"
  end

  # Add arrows for dependencies
  diagram_code_string *= "[<$artifact_type_string> $input_artifact_name] -> [<$provider_type_string> $provider_name]\n"

  return provider_type_string, diagram_code_string
end
function handle_provider_diagram(provider::CallableProvider, diagram_code_string::String, provider_name::String, inputs::Vector{Type{<:Artifact}})
  provider_type_string = "provider"
  for input_artifact in provider.inputs
    artifact_type_string = "artifact"

    if in(input_artifact, inputs)
      artifact_type_string = "inputartifact"
    end
    input_artifact_name = nameof(input_artifact)

    # Add arrows for dependencies
    diagram_code_string *= "[<$artifact_type_string> $input_artifact_name] -> [<$provider_type_string> $provider_name]\n"
  end

  return provider_type_string, diagram_code_string
end