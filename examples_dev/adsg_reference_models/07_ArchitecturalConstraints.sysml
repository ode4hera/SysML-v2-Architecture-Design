package ADSG_ArchitecturalConstraints {
    doc /* This model demonstrates two types of architectural constraints:
    - Incompatibility constraints: declares that two elements should not appear in an architecture together
    - Choice constraints: constrains two or more architectural choices
    */
    private import ArchitectureDesign::*;

    package Incompatibilities {
        #architectureDesignSpace part def DesignSpace {
            action boundaryFunction1[1] :> boundaryFunctions;
            action boundaryFunction2[1] :> boundaryFunctions;

            part part1[0..1] {
                perform action boundaryFunction1Performance references boundaryFunction1;
            }
            part part2[0..1] {
                perform action boundaryFunction1Performance[0..1] references boundaryFunction1;
                perform action boundaryFunction2Performance[0..1] ::> boundaryFunction2;
            }
            part part3[0..1] {
                perform action boundaryFunction2Performance ::> boundaryFunction2;
            }

            // The result is that either part1 and part3 exist OR part2
            #incompatibility connection connect part1 to part2;
            #incompatibility connection connect part2 to part3;

            :>> architecturalChoices {
                :>> choices[2] = (func1FulfillmentChoice, func2FulfillmentChoice);

                occurrence func1FulfillmentChoice :> choices : FunctionFulfillmentChoice {
                    ref :>> actionToPerform[1] = boundaryFunction1;
                    ref :>> performingAlternatives[2] = (part1, part2);
                }
                occurrence func2FulfillmentChoice :> choices : FunctionFulfillmentChoice {
                    ref :>> actionToPerform[1] = boundaryFunction2;
                    ref :>> performingAlternatives[2] = (part2, part3);
                }
            }
            :>> formalDesignProblem {
                :>> designVariables[1] = (func1DesVar);

                #catX attribute func1DesVar :> designVariables {
                    :>> values[2] = (0, 1);
                }
                allocate architecturalChoices.func1FulfillmentChoice to func1DesVar;

                // func2FulfillmentChoice is not encoded as a design variable,
                // because its value is fully determined by func1DesVar
            }
        }
        #architecture part def ArchPart13 :> DesignSpace {
            action :>> boundaryFunction1[1];
            action :>> boundaryFunction2[1];

            part :>> part1[1] {
                perform action :>> boundaryFunction1Performance[1] ::> boundaryFunction1;
            }
            part :>> part2[0];
            part :>> part3[1] {
                perform action :>> boundaryFunction2Performance[1] ::> boundaryFunction2;
            }

            :>> architecturalChoices {
                :>> func1FulfillmentChoice references part1;
                :>> func2FulfillmentChoice ::> part3;
            }
            :>> formalDesignProblem {
                :>> func1DesVar = 0;
            }
        }
        #architecture part def ArchPart2 :> DesignSpace {
            action :>> boundaryFunction1[1];
            action :>> boundaryFunction2[1];

            part :>> part1[0];
            part :>> part2[1] {
                perform action :>> boundaryFunction1Performance[1] ::> boundaryFunction1;
                perform action :>> boundaryFunction2Performance[1] ::> boundaryFunction2;
            }
            part :>> part3[0];

            :>> architecturalChoices {
                :>> func1FulfillmentChoice references part2;
                :>> func2FulfillmentChoice ::> part2;
            }
            :>> formalDesignProblem {
                :>> func1DesVar = 1;
            }
        }
    }

    package ChoiceConstraints {
        #architectureDesignSpace part def DesignSpace {
            action boundaryFunction1[1] :> boundaryFunctions;
            action boundaryFunction2[1] :> boundaryFunctions;

            part part1a[0..1] {
                perform boundaryFunction1;
            }
            part part1b[0..1] {
                perform boundaryFunction1;
            }
            part part2a[0..1] {
                perform boundaryFunction2;
            }
            part part2b[0..1] {
                perform boundaryFunction2;
            }

            :>> architecturalChoices {
                :>> choices[2] = (boundaryFunction1FulfillmentChoice, boundaryFunction2FulfillmentChoice);

                occurrence boundaryFunction1FulfillmentChoice :> choices : FunctionFulfillmentChoice {
                    ref :>> actionToPerform[1] = boundaryFunction1;
                    ref :>> performingAlternatives[2] = (part1a, part1b);
                }

                occurrence boundaryFunction2FulfillmentChoice :> choices : FunctionFulfillmentChoice {
                    ref :>> actionToPerform[1] = boundaryFunction2;
                    ref :>> performingAlternatives[2] = (part2a, part2b);
                }

                :>> choiceConstraints[1] = fulfillmentConstraint;
                
                #choiceConstraint occurrence fulfillmentConstraint :> choiceConstraints {
                    ref :>> choices[2] = (boundaryFunction1FulfillmentChoice, boundaryFunction2FulfillmentChoice);
                    :>> constraintType = ChoiceConstraintType::Linked;
                }
            }
            :>> formalDesignProblem {
                :>> designVariables[1] = (func1DesVar);

                #catX attribute func1DesVar :> designVariables {
                    :>> values[2] = (0, 1);
                }
                allocate architecturalChoices.boundaryFunction1FulfillmentChoice to func1DesVar;
                
                // boundaryFunction2FulfillmentChoice is not encoded as a design variable,
                // because its value is fully determined by func1DesVar from fulfillmentConstraint
            }
        }
        #architecture part def Arch :> DesignSpace {
            :>> part1a[1];
            :>> part1b[0];
            :>> part2a[1];
            :>> part2b[1];

            :>> architecturalChoices {
                :>> boundaryFunction1FulfillmentChoice references part1a;
                :>> boundaryFunction2FulfillmentChoice ::> part2a;
            }
            :>> formalDesignProblem {
                :>> func1DesVar = 0;
            }
        }
    }
}
