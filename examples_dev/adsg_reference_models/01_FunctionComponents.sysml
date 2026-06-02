package ADSG_FunctionComponentsMapping {
    doc /* Show how functions are allocated to components (function fulfillment)
    and how components can induce (need) additional functions. */
    private import ArchitectureDesign::*;

    action def ActionDef;
    
    part def PartDef {
        perform action actionDef : ActionDef;
        #needsAction inducedActionDef : InducedActionDef;
    }

    action def InducedActionDef;

    #architectureDesignSpace part def DesignSpace {
        action mainAction[1] : ActionDef subsets boundaryFunctions;
        action secondAction[1] subsets boundaryFunctions;

        part part1[1] : PartDef {
            perform mainAction[1] redefines actionDef;
            #needsAction references inducedAction redefines inducedActionDef;
        }

        action inducedAction[1] : InducedActionDef;

        part part2[0..1] {
            perform action inducedActionPerformance ::> inducedAction[0..1];
            perform action secondActionPerformance ::> secondAction[0..1];
        }
        part part3[0..1] {
            perform action inducedActionPerformance ::> inducedAction[0..1];
        }
        part part4[0..1] {
            perform action secondActionPerformance ::> secondAction[0..1];
        }

        :>> architecturalChoices {
            :>> choices[2] = (inducedActionFulfillmentChoice, secondActionFulfillmentChoice);

            occurrence inducedActionFulfillmentChoice :> choices : FunctionFulfillmentChoice {
                ref :>> actionToPerform[1] = inducedAction;
                ref :>> performingAlternatives[2] = (part2, part3);
            }

            occurrence secondActionFulfillmentChoice :> choices : FunctionFulfillmentChoice {
                ref :>> actionToPerform[1] = secondAction;
                ref :>> performingAlternatives[2] = (part2, part4);
            }
        }

        :>> formalDesignProblem {
            :>> designVariables[2] default (inducedActionDesVar, secondActionDesVar);

            #catX attribute inducedActionDesVar :> designVariables {
                :>> values[2] = (0, 1);
            }
            allocate architecturalChoices.inducedActionFulfillmentChoice to inducedActionDesVar;

            #catX attribute secondActionDesVar :> designVariables {
                :>> values[2] = (0, 1);
            }
            allocate architecturalChoices.secondActionFulfillmentChoice to secondActionDesVar;
        }
    }

    #architecture part def Arch specializes DesignSpace {
        action redefines mainAction[1];
        action redefines secondAction[1];

        part redefines part1[1];

        action :>> inducedAction;

        part redefines part2[1] {
            perform action redefines inducedActionPerformance[1] ::> inducedAction;
            perform action redefines secondActionPerformance[0] ::> secondAction;
        }
        part :>> part3[0];
        part :>> part4[1] {
            perform action :>> secondActionPerformance[1] ::> secondAction;
        }

        :>> architecturalChoices {
            :>> inducedActionFulfillmentChoice references part2;
            :>> secondActionFulfillmentChoice ::> part4;
        }
        :>> formalDesignProblem {
            :>> inducedActionDesVar = 0;
            :>> secondActionDesVar = 1;
        }
    }

}
