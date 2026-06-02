package ADSG_AdvandedFunctionFullfillment {
    doc /* Demonstrate:
    - Non-fulfillment (1 function -> none)
      --> abstract #nonFulfillment part with perform action
    - Multi-fulfillment (1 function -> 1 or more components)
      --> abstract #multiFulfillment part with perform action and ref subparts
    - Decomposition (1 function -> 1 or more functions)
      --> abstract #decomposition connection
    - Concept (1 function -> 1 function)
      --> abstract #concept allocation
    */
    private import ArchitectureDesign::*;

    package NonFulfillment {
        #architectureDesignSpace part def NFDesignSpace {
            action boundaryFunction[1] :> boundaryFunctions;

            part part1[0..1] {
                perform action boundaryFunctionPerformance[1] references boundaryFunction;
            }
            abstract #nonFulfillment occurrence nonFulfillmentOfBoundary[0..1] {
                :>> nonFulfilledActions[1] default boundaryFunction;
            }

            :>> architecturalChoices {
                :>> choices[1] = fulfillmentChoice;
                occurrence fulfillmentChoice :> choices : FunctionFulfillmentChoice {
                    ref :>> actionToPerform[1] = boundaryFunction;
                    ref :>> performingAlternatives[2] = (part1, nonFulfillmentOfBoundary);
                }
            }
            :>> formalDesignProblem {
                :>> designVariables[1] = desVar;
                #catX attribute desVar {
                    :>> values[2] = (0, 1);
                }
                allocate architecturalChoices.fulfillmentChoice to desVar;
            }
        }
        #architecture part def NonFulfillArch :> NFDesignSpace {
            action :>> boundaryFunction[1];
            part :>> part1[0];
            #nonFulfillment occurrence :>> nonFulfillmentOfBoundary[1] {
                :>> nonFulfilledActions = boundaryFunction;
            }

            :>> architecturalChoices {
                :>> fulfillmentChoice ::> nonFulfillmentOfBoundary;
            }
            :>> formalDesignProblem {
                :>> desVar = 1;
            }
        }
    }

    package MultiFulfillment {
        #architectureDesignSpace part def MFDesignSpace {
            action boundaryFunction[1] :> boundaryFunctions;

            part part1[0..1] {
                perform action boundaryFunctionPerformance ::> boundaryFunction[1];
            }
            part part2[0..1] {
                perform action boundaryFunctionPerformance ::> boundaryFunction[1];
            }
            abstract #multiFulfillment occurrence multiFulfillmentPart[0..1] {
                :>> fulfilledActions[1] default boundaryFunction;
                :>> fulfillingParts[2] default (part1, part2);
            }

            :>> architecturalChoices {
                :>> choices[1] = fulfillmentChoice;
                occurrence fulfillmentChoice :> choices : FunctionFulfillmentChoice {
                    ref :>> actionToPerform[1] = boundaryFunction;
                    ref :>> performingAlternatives[3] = (part1, part2, multiFulfillmentPart);
                }
            }
            :>> formalDesignProblem {
                :>> designVariables[1] = desVar;
                #catX attribute desVar {
                    :>> values[3] = (0, 1, 2);
                }
                allocate architecturalChoices.fulfillmentChoice to desVar;
            }
        }
        #architecture part def MultiFulfill :> MFDesignSpace {
            action :>> boundaryFunction[1];
            part :>> part1[1] {
                perform action :>> boundaryFunctionPerformance[1] ::> boundaryFunction;
            }
            part :>> part2[1] {
                perform action :>> boundaryFunctionPerformance[1] ::> boundaryFunction;
            }
            #multiFulfillment occurrence :>> multiFulfillmentPart[1] {
                :>> fulfilledActions[1] = (boundaryFunction);
                :>> fulfillingParts[2] = (part1, part2);
            }

            :>> architecturalChoices {
                :>> fulfillmentChoice ::> multiFulfillmentPart;
            }
            :>> formalDesignProblem {
                :>> desVar = 2;
            }
        }
    }

    package Decomposition {
        #architectureDesignSpace part def DecompDesignSpace {
            action boundaryFunction[1] :> boundaryFunctions;

            abstract #decomposition connection functionDecomposition[0..1] connect (
                boundaryFunction,
                function1, function2
            );
            part part0[0..1] {
                perform action boundaryFunctionPerformance ::> boundaryFunction;
            }

            action function1[0..1];
            action function2[0..1];

            part part1[0..1] {
                perform action function1Performance ::> function1[1];
            }
            part part2[0..1] {
                perform action function2Performance ::> function2[1];
            }

            :>> architecturalChoices {
                :>> choices[1] = fulfillmentChoice;
                occurrence fulfillmentChoice :> choices : FunctionFulfillmentChoice {
                    ref :>> actionToPerform[1] = boundaryFunction;
                    ref :>> performingAlternatives[2] = (functionDecomposition, part0);
                }
            }
            :>> formalDesignProblem {
                :>> designVariables[1] = desVar;
                attribute desVar :> CategoricalDesignVariable {
                    :>> values[2] = (0, 1);
                }
                allocate architecturalChoices.fulfillmentChoice to desVar;
            }
        }
        #architecture part def DecompArch :> DecompDesignSpace {
            action :>> boundaryFunction[1];
            #decomposition connection :>> functionDecomposition[1];
            part :>> part0[0];
            action :>> function1[1];
            action :>> function2[1];
            part :>> part1[1] {
                perform action :>> function1Performance[1] ::> function1;
            }
            part :>> part2[1] {
                perform action :>> function2Performance[1] ::> function2;
            }

            :>> architecturalChoices {
                :>> fulfillmentChoice ::> functionDecomposition;
            }
            :>> formalDesignProblem {
                :>> desVar = 0;
            }
        }
    }

    package Concept {
        #architectureDesignSpace part def ConceptDesignSpace {
            action boundaryFunction[1] :> boundaryFunctions;

            abstract #concept allocation conceptName[0..1] allocate boundaryFunction to specificFunction;
            part part1[0..1] {
                perform action boundaryFunctionPerformance references boundaryFunction[1];
            }

            action specificFunction[0..1];

            part part2[0..1] {
                perform action specificFunctionPerformance[1] references specificFunction;
            }

            :>> architecturalChoices {
                :>> choices[1] = fulfillmentChoice;
                occurrence fulfillmentChoice :> choices : FunctionFulfillmentChoice {
                    ref :>> actionToPerform[1] = boundaryFunction;
                    ref :>> performingAlternatives[2] = (conceptName, part1);
                }
            }
            :>> formalDesignProblem {
                :>> designVariables[1] = desVar;
                attribute desVar :> CategoricalDesignVariable {
                    :>> values[2] = (0, 1);
                }
                allocate architecturalChoices.fulfillmentChoice to desVar;
            }
        }
        #architecture part def ConceptArch :> ConceptDesignSpace {
            action :>> boundaryFunction[1];
            #concept allocation :>> conceptName[1];
            part :>> part1[0];

            action :>> specificFunction[1];
            part :>> part2[1] {
                perform action :>> specificFunctionPerformance ::> specificFunction;
            }

            :>> architecturalChoices {
                :>> fulfillmentChoice ::> conceptName;
            }
            :>> formalDesignProblem {
                :>> desVar = 0;
            }
        }
    }
}
