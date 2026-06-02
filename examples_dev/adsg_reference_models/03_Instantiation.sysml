package ADSG_InstantiationChoices {
    doc /* Demonstrates instantiation choices of components and sub-systems. */
    private import ArchitectureDesign::*;

    package PartInstantiation {
        #architectureDesignSpace part def DesignSpace {
            action boundaryFunction1[1] :> boundaryFunctions;

            part part1[1..3] {
                perform boundaryFunction1[1];
            }

            action boundaryFunction2[1] :> boundaryFunctions;

            part part2[0..2] {
                perform boundaryFunction2[1];
            }
            part part3[(0, 2, 4)] {
                perform boundaryFunction2[1];
            }

            :>> architecturalChoices {
                :>> choices[4] = (fulfillmentChoice,
                    part1InstantiationChoice, part2InstantiationChoice, part3InstantiationChoice);

                occurrence fulfillmentChoice :> choices : FunctionFulfillmentChoice {
                    ref :>> actionToPerform[1] = boundaryFunction2;
                    ref :>> performingAlternatives[2] = (part2, part3);
                }

                attribute part1InstantiationChoice :> choices, InstantiationChoice {
                    ref :>> instantiatingElement[1] = part1;
                    :>> values[3] = (1, 2, 3);
                }
                attribute part2InstantiationChoice :> choices, InstantiationChoice {
                    ref :>> instantiatingElement[1] = part2;
                    :>> values[3] = (1, 2);
                }
                attribute part3InstantiationChoice :> choices, InstantiationChoice {
                    ref :>> instantiatingElement[1] = part3;
                    :>> values[3] = (2, 4);
                }
            }
            :>> formalDesignProblem {
                :>> designVariables[4] = (fulfillmentDesVar, part1InstDesVar, part2InstDesVar, part3InstDesVar);

                attribute fulfillmentDesVar :> designVariables, CategoricalDesignVariable {
                    :>> values[2] = (0, 1);
                }
                attribute part1InstDesVar :> designVariables, IntegerDesignVariable {
                    :>> lowerBound = 1;
                    :>> upperBound = 3;
                }
                attribute part2InstDesVar :> designVariables, IntegerDesignVariable {
                    :>> lowerBound = 1;
                    :>> upperBound = 2;
                }
                attribute part3InstDesVar :> designVariables, NumericalOrdinalDesignVariable {
                    :>> values[3] = (2, 4);
                }

                allocate architecturalChoices.fulfillmentChoice to fulfillmentDesVar;
                allocate architecturalChoices.part1InstantiationChoice to part1InstDesVar;
                allocate architecturalChoices.part2InstantiationChoice to part2InstDesVar;
                allocate architecturalChoices.part3InstantiationChoice to part3InstDesVar;
            }
        }
        #architecture part def InstArch :> DesignSpace {

            part :>> part1[1];

            part :>> part2[0];
            
            part :>> part3[2] ordered = (part3_1, part3_2);
            part part3_1[1] :> part3;
            part part3_2[1] :> part3;

            :>> architecturalChoices {
                :>> fulfillmentChoice ::> part3;
                :>> part1InstantiationChoice = 1;
                :>> part2InstantiationChoice = null; // inactive
                :>> part3InstantiationChoice = 2;
            }
            :>> formalDesignProblem {
                :>> fulfillmentDesVar = 1;
                :>> part1InstDesVar = 1;
                :>> part2InstDesVar = null;
                :>> part3InstDesVar = 0;
            }
        }
    }

    package SubsystemInstantiation {
        #architectureDesignSpace part def DesignSpace {
            action boundaryFunction[1] :> boundaryFunctions;

            #subsystem part theSubsystem[1..2] {
                part part1[1..2] {
                    perform boundaryFunction;
                }
            }

            :>> architecturalChoices {
                :>> choices[3] = (theSubsystemInstantiationChoice, subsys1part1InstantiationChoice, subsys2part1InstantiationChoice);

                attribute theSubsystemInstantiationChoice :> choices, InstantiationChoice {
                    ref :>> instantiatingElement[1] = theSubsystem;
                    :>> values[2] = (1, 2);
                }

                attribute subsys1part1InstantiationChoice :> choices, InstantiationChoice {
                    ref :>> instantiatingElement[1] = theSubsystem#(1).part1;
                    :>> values[2] = (1, 2);
                }
                attribute subsys2part1InstantiationChoice :> choices, InstantiationChoice {
                    ref :>> instantiatingElement[1] = theSubsystem#(2).part1;
                    :>> values[2] = (1, 2);
                }
            }
            :>> formalDesignProblem {
                :>> designVariables[3] = (subsysInstDesVar, subsys1part1InstDesVar, subsys2part2InstDesVar);

                #intX attribute subsysInstDesVar :> designVariables {
                    :>> lowerBound = 1; :>> upperBound = 2;
                }
                #intX attribute subsys1part1InstDesVar :> designVariables {
                    :>> lowerBound = 1; :>> upperBound = 2;
                }
                #intX attribute subsys2part2InstDesVar :> designVariables {
                    :>> lowerBound = 1; :>> upperBound = 2;
                }

                allocate architecturalChoices.theSubsystemInstantiationChoice to subsysInstDesVar;
                allocate architecturalChoices.subsys1part1InstantiationChoice to subsys1part1InstDesVar;
                allocate architecturalChoices.subsys2part1InstantiationChoice to subsys2part2InstDesVar;
            }
        }
        #architecture part def DoubleArch :> DesignSpace {

            part :>> theSubsystem[2] ordered = (theSubsystem_1, theSubsystem_2);
            
            #subsystem part theSubsystem_1[1] :> theSubsystem {
                part :>> part1[1];
            }
            
            #subsystem part theSubsystem_2[1] :> theSubsystem {
                part :>> part1[2] = (part1_1, part1_2);
                part part1_1 :> part1;
                part part1_2 :> part1;
            }

            :>> architecturalChoices {
                :>> theSubsystemInstantiationChoice = 2;
                :>> subsys1part1InstantiationChoice = 1;
                :>> subsys2part1InstantiationChoice = 2;
            }
            :>> formalDesignProblem {
                :>> subsysInstDesVar = 2;
                :>> subsys1part1InstDesVar = 1;
                :>> subsys2part2InstDesVar = 2;
            }
        }
    }
}