package ADSG_SystemContext {
    doc /* ADORE allows specifying that elements are part of the
    system context, that is not part of the system of interest.
    This is demonstrated here.

    The system context is defined in a special subsystem called context.
    This can be interpreted recursively to make subsystem definitions reusable.
    */
    private import ArchitectureDesign::*;

    package SystemContext {

        #architectureDesignSpaceContext part def DesignSpaceContext {
            ref part :>> systemOfInterest[1] : DesignSpace;

            action boundaryFunction[1] :> boundaryFunctions;
        }

        #architectureDesignSpace part def DesignSpace {
            ref part :>> systemContext[1] : DesignSpaceContext;

            part inSystem {
                perform action boundaryFunctionPerformance references systemContext.boundaryFunction;
            }
        }

        #architectureContext part def ArchContext :> DesignSpaceContext {
            ref part :>> systemOfInterest : Arch;

            action :>> boundaryFunction[1];
        }

        #architecture part def Arch :> DesignSpace {
            ref part :>> systemContext[1] : ArchContext;

            part :>> inSystem[1] {
                perform action :>> boundaryFunctionPerformance ::> systemContext.boundaryFunction;
            }
        }
    }
    
    package RefSystemContext {

        #architectureDesignSpaceContext part outsideSystemBoundary {
            ref part :>> systemOfInterest[1] references designSpace;

            action boundaryFunction[1] :> boundaryFunctions;
        }

        #architectureDesignSpace part designSpace {
            ref part :>> systemContext[1] references outsideSystemBoundary;

            part inSystem {
                perform action boundaryFunctionPerformance references systemContext.boundaryFunction;
            }
        }

        #architectureContext part archOutsideSystemBoundary :> outsideSystemBoundary {
            ref part :>> systemOfInterest references arch;

            action :>> boundaryFunction[1];
        }

        #architecture part arch :> designSpace {
            ref part :>> systemContext references archOutsideSystemBoundary;

            part :>> inSystem {
                perform action :>> boundaryFunctionPerformance[1] references systemContext.boundaryFunction;
            }
        }
    }

    package ReusableContext {

        part def ReusableSubsystem :> ArchitectureDesignSpacePart {
            ref part :>> systemContext[1] : ReusableSubsystemContext;

            action subsystemBoundaryFunction[1] :> boundaryFunctions;

            part subsystemPart[1] {
                perform action subsystemBoundaryFunctionPerformance references subsystemBoundaryFunction;
                #needsAction references systemContext.externalFunction;
                #needsAction references subsysInReusableSubsys.subsubAction;
            }

            #subsystem part subsysInReusableSubsys {
                action subsubAction;
                part subsubPart {
                    perform action subsubActionPerformance references subsubAction;
                }
            }
        }

        part def ReusableSubsystemContext :> ArchitectureDesignSpacePart {
            action externalFunction;
            part externalSystem {
                perform action externalFunctionPerformance ::> externalFunction;
            }
        }

        #architectureDesignSpace part def DesignSpace {
            action boundaryFunction[1] :> boundaryFunctions;

            part part1 {
                perform action boundaryFunctionPerformance references boundaryFunction;
                #needsAction references reusableSubsystem.subsystemBoundaryFunction;
            }

            #subsystem part reusableSubsystem[1..2] : ReusableSubsystem;

            :>> architecturalChoices {
                :>> choices[0];
            }
        }

        #architecture part def Arch :> DesignSpace, ReusableSubsystemContext {
            action :>> boundaryFunction[1];
            part :>> part1 {
                perform action :>> boundaryFunctionPerformance[1] ::> boundaryFunction;
            }

            // Elements from ReusableSubsystemContext
            action :>> externalFunction[1];
            part :>> externalSystem[1] {
                perform action :>> externalFunctionPerformance[1] ::> externalFunction;
            }

            #subsystem part :>> reusableSubsystem[1] {
                ref part :>> systemContext[0];

                action :>> subsystemBoundaryFunction[1];

                part :>> subsystemPart[1] {
                    perform action :>> subsystemBoundaryFunctionPerformance[1] ::> subsystemBoundaryFunction;
                }

                #subsystem part :>> subsysInReusableSubsys {
                    action :>> subsubAction[1];
                    part :>> subsubPart[1] {
                        perform action :>> subsubActionPerformance[1] ::> subsubAction;
                    }
                }
            }
        }
    }

    package ReusableDesignSpace {

        part def AdditionalFeatures {
            attribute metric1;
        }

        part def AdditionalExtraFeatures {
            attribute metric2;
        }

        part def ReusableDesignSpace :> ArchitectureDesignSpacePart, AdditionalFeatures {
            action boundaryFunction[1] :> boundaryFunctions;
            part part1 {
                perform action boundaryFunctionPerformance references boundaryFunction;
            }
        }

        #architectureDesignSpace part def DesignSpace :> ReusableDesignSpace, AdditionalExtraFeatures;

        #architecture part def Arch :> DesignSpace {
            action :>> boundaryFunction[1];
            part :>> part1 {
                perform action :>> boundaryFunctionPerformance[1] ::> boundaryFunction;
            }
            attribute :>> metric1 = 1000;
            attribute :>> metric2 = 2000;
        }

    }

    package ImplicitSubsystemCrossLinks {

        part def SubsystemContextDef :> ArchitectureDesignSpacePart {
            action topLevelFunction;
            action inducedFunction;
        }
        
        part def SubsystemDef :> ArchitectureDesignSpacePart {
            ref part :>> systemContext : SubsystemContextDef;

            part subsystemPart {
                perform systemContext.topLevelFunction;
                ref #needsAction references systemContext.inducedFunction;
            }
        }

        abstract #architectureDesignSpace part def DesignSpace :> SubsystemContextDef {

            part subsystem : SubsystemDef;

            part topLevelPart {
                perform inducedFunction;
            }

        }

    }
}