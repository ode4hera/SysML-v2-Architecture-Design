package ADSG_QuantitiesOfInterest {
    doc /* Demonstrates all forms of quantities of interests:
    - Input to the evaluation/simulation
      - Static input (numerical or string)
      - Discrete design variable: integer, numerical ordinal, categorical
      - Continuous design variable
    - Output from the evaluation/simulation
      - Metric
      - Objective
      - Constraint
    
    If no annotation is applied to an attribute, the following logic is applied to determine the role:
    - If the attribute has a value assigned, assume the role is "static input"
    - Else, assume it is an output
      - If the attribute has one or more constraints, assume the role is "constraint"
      - Else, assume the role is "metric"
    
    Additionally, it demonstrates a mixture between where the attributes are defined (defs or usages).

    Part attributes with multiplicity [1..*] are assumed to be instance-level QOIs: they can have a different value for each part instance.

    The type of discrete design variable is automatically detected:
    - If all values can be parsed to floats
      - Sort the values, then
      - If all values can be parsed to integers without gaps between the first and last value: integer design variable
      - Else: numerical ordinal design variable
    - Else: categorical design variable

    Architecture instances have values assigned to the attributes using the following logic:
    - Input attributes (static inputs and design variables) always have values assigned
      - Note that static inputs do not have a value re-assigned in the architecture instance,
        because the static input value was a "default" value, so it always applied
    - Output attributes optionally have values assigned:
      - If the architecture has not yet been evaluated, it has no value
      - If the evaluation was not succesfull (for example, the simulation/calculations failed), it has a value of null (representing NaN) assigned
      - If evaluation was succesfull, the resulting value is assigned
    */
    private import ArchitectureDesign::*;

    part def ImplicitQOIPartDef {
        doc /* Part def showing all the implicit-role QOIs */

        attribute implicitStaticInput : ScalarValues::Real default 10.0;

        attribute implicitStaticInputStr : ScalarValues::String = "string value";

        attribute implicitConstraint : ScalarValues::Real {
            assert constraint { that <= 1000.0 }
        }

        attribute implicitOutputMetric : ScalarValues::Real;

        attribute implicitConstraintFromReq references ADSG_QuantitiesOfInterest::implicitConstraintFromReq;

    }

    attribute implicitConstraintFromReq;

    requirement req {
        attribute attr = implicitConstraintFromReq;
        require constraint { attr >= 5.0 }
    }

    #architectureDesignSpace part def DesignSpace {

        #evalOut attribute systemLevelOutputMetric : ScalarValues::Real;

        action boundaryFunction[1] :> boundaryFunctions {
            #minObj attribute functionLevelMinObjective : ScalarValues::Real;

            #evalOut attribute functionLevelExplicitMetric : ScalarValues::Real {
                :>> role = OutputRole::Metric;
            }
        }

        part implicitPart[0..1] : ImplicitQOIPartDef {
            perform boundaryFunction;
        }

        part explicitPart[0..2] {
            perform boundaryFunction;

            #maxObj attribute partLevelMaxObjective : ScalarValues::Real;

            #con attribute partInstanceConstraint[1..*] : ScalarValues::Real {
                assert constraint { that >= -100 }
            }

            #contX attribute partInstanceContinuousDV[1..*] : ScalarValues::Real {
                :>> lowerBound = 0.0;
                :>> upperBound = 1.0;
            }

            #intX attribute partInstanceIntegerDV[1..*] : ScalarValues::Integer {
                :>> lowerBound = 0;
                :>> upperBound = 10;
            }

            #numOrdX attribute partInstanceNumOrdinalDV[1..*] : ScalarValues::Real {
                :>> values = (13, 42, 67, 666, 999);
            }

            #catX attribute partInstanceCategoricalDV[1..*] : ScalarValues::String {
                :>> values = ("A", "B", "C");
            }

        }

        #subsystem part theSubsystem[1..2] {

            attribute subsystemLevelMetric : ScalarValues::Real;

            part subsystemPart[0..1] {
                perform boundaryFunction;
            }
        }

        :>> architecturalChoices {
            :>> choices[11] = (
                fulfillmentChoice,
                explicitPartInstantiationChoice,
                subsystemInstantiationChoice,
                explicitPart#(1).partInstanceContinuousDV,
                explicitPart#(2).partInstanceContinuousDV,
                explicitPart#(1).partInstanceIntegerDV,
                explicitPart#(2).partInstanceIntegerDV,
                explicitPart#(1).partInstanceNumOrdinalDV,
                explicitPart#(2).partInstanceNumOrdinalDV,
                explicitPart#(1).partInstanceCategoricalDV,
                explicitPart#(2).partInstanceCategoricalDV,
            );

            occurrence fulfillmentChoice :> choices : FunctionFulfillmentChoice {
                ref :>> actionToPerform[1] = boundaryFunction;
                ref :>> performingAlternatives[3] = (implicitPart, explicitPart, theSubsystem.subsystemPart);
            }
            attribute explicitPartInstantiationChoice :> choices, InstantiationChoice {
                ref :>> instantiatingElement[1] = explicitPart;
                :>> values[2] = (1, 2);
            }
            attribute subsystemInstantiationChoice :> choices, InstantiationChoice {
                ref :>> instantiatingElement[1] = theSubsystem;
                :>> values[2] = (1, 2);
            }
        }
        :>> formalDesignProblem {
            :>> designVariables[11] = (
                fulfillmentDesVar,
                explicitInstDesVar,
                subsystemInstDesVar,
                explicitPart#(1).partInstanceContinuousDV,
                explicitPart#(2).partInstanceContinuousDV,
                explicitPart#(1).partInstanceIntegerDV,
                explicitPart#(2).partInstanceIntegerDV,
                explicitPart#(1).partInstanceNumOrdinalDV,
                explicitPart#(2).partInstanceNumOrdinalDV,
                explicitPart#(1).partInstanceCategoricalDV,
                explicitPart#(2).partInstanceCategoricalDV,
            );

            #catX attribute fulfillmentDesVar :> designVariables {
                :>> values = (0, 1, 2);
            }
            #intX attribute explicitInstDesVar :> designVariables {
                :>> lowerBound = 1;
                :>> upperBound = 2;
            }
            #intX attribute subsystemInstDesVar :> designVariables {
                :>> lowerBound = 1;
                :>> upperBound = 2;
            }

            allocate architecturalChoices.fulfillmentChoice to fulfillmentDesVar;
            allocate architecturalChoices.explicitPartInstantiationChoice to explicitInstDesVar;
            allocate architecturalChoices.subsystemInstantiationChoice to subsystemInstDesVar;

            :>> objectives[2] = (
                boundaryFunction.functionLevelMinObjective,
                explicitPart.partLevelMaxObjective,
            );
            :>> constraints[4] = (
                implicitPart.implicitConstraint,
                implicitPart.implicitConstraintFromReq,
                explicitPart#(1).partInstanceConstraint,
                explicitPart#(2).partInstanceConstraint,
            );
        }
    }

    #architecture part def Arch :> DesignSpace {

        action :>> boundaryFunction[1] {
            :>> functionLevelMinObjective; // Not evaluated yet
            :>> functionLevelExplicitMetric = null; // Evaluation failure (represents NaN)
        }

        part :>> implicitPart[0];

        part :>> explicitPart[2] = (explicitPart_1, explicitPart_2) {
            :>> partLevelMaxObjective = 100;
        }
        part explicitPart_1 :> explicitPart {
            :>> partInstanceConstraint = -150;
            :>> partInstanceContinuousDV[1] = 0.5;
            :>> partInstanceIntegerDV[1] = 3;
            :>> partInstanceNumOrdinalDV[1] = 42;
            :>> partInstanceCategoricalDV[1] = "A";
        }
        part explicitPart_2 :> explicitPart {
            :>> partInstanceConstraint = -80;
            :>> partInstanceContinuousDV[1] = 0.6;
            :>> partInstanceIntegerDV[1] = 7;
            :>> partInstanceNumOrdinalDV[1] = 13;
            :>> partInstanceCategoricalDV[1] = "C";
        }

        part :>> theSubsystem[0];

        :>> architecturalChoices {
            :>> fulfillmentChoice references explicitPart;
            :>> explicitPartInstantiationChoice = 2;
            :>> subsystemInstantiationChoice = null;
        }
        :>> formalDesignProblem {
            :>> fulfillmentDesVar = 1;
            :>> explicitInstDesVar = 2;
            :>> subsystemInstDesVar = null;
        }
    }

}