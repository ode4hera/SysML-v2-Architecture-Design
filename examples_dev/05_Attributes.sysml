package SA_AttributesExample {
    doc /*
    Example showing the different roles that attributes may play in an architecture optimization problem:
    - Input to the evaluation/simulation:
      - Static input
      - Discrete design variable
      - Continuous design variable
    - Output from the evaluation/simulation:
      - Metric
      - Objective
      - Constraint
    
    If no annotation is applied to an attribute, the following logic is applied to determine the role:
    - If the attribute has a value assigned, assume the role is "static input"
    - Else, assume it is an output
      - If the attribute has one or more constraints, assume the role is "constraint"
      - Else, assume the role is "metric"
    
    Additionally, it demonstrates a mixture between where the attributes are defined (defs or usages).

    Architecture instances have values assigned to the attributes using the following logic:
    - Input attributes (static inputs and design variables) always have values assigned
      - Note that in SysML, static inputs do not have a value re-assigned in the architecture instance,
        because the static input value was a "default" value, so it always applied
    - Output attributes optionally have values assigned:
      - If the architecture has not yet been evaluated, the output attributes
      - If the evaluation was not succesfull (for example, the simulation/calculations failed), it has a value of "CouldNotCompute" assigned
        - In other modeling languages this is normally represented using NaN (Not-a-Number), however KerML/SysML cannot represent NaN
      - If evaluation was succesfull, the resulting value is assigned
    */
    private import ArchitectureDesign::*;

    action def GenerateThrust {

        attribute seaLevelThrust :> ISQ::force = 150000[SI::N] {
            doc /* Static input: numerical value */
        }

    }

    part def Turboprop {

        attribute airfoil : ScalarValues::String;

        #ordinalDesignVariable attribute nrBlades : ScalarValues::Integer {
            doc /* Discrete design variable: nrBlades can be any of [3, 4, 6, 8] */
            redefines values = (3, 4, 6, 8);
        }

        #continuousDesignVariable attribute pressureRatio {
            doc /* Continuous design variable:
            pressure ratio can have any value between (including) 10 and 30. */
            redefines lowerBound = 10.0;
            redefines upperBound = 30.0;
        }

        #evaluationOutput attribute thrustSpecificFuelConsumption {
            doc /* Objective to be minimized */
            redefines role = OutputRole::MinimizationObjective;
        }

        #evaluationOutput attribute turbineInletTemperature :> ISQ::temperature {
            doc /* Inequality constraint */
            
            redefines role = OutputRole::Constraint;

            assert constraint { that <= 1500[SI::'°C_abs'] }
        }

        #evaluationOutput attribute propPressureRatio {
            doc /* Output metric (explicitly defined) */
            redefines role = OutputRole::Metric;
        }

    }

    abstract #architectureDesignSpace part def DesignSpace {
        doc /* The architecture design space definition with usages of
        part/action defs that can additionally define attributes. */

        action generateThrust : GenerateThrust;

        part turboProp : Turboprop {
            perform action generateThrust;

            attribute redefines airfoil = "NACA0016" {
                doc /* Static input: string value */
            }

            attribute mass :> ISQ::mass {
                doc /* Output metric (implicitly defined) */
            }

        }

    }

    #architecture part def Arch specializes DesignSpace {
        doc /* A specific architecture instance with values assigned to the attributes.
        For output values */

        action redefines generateThrust {
            // Static input value cannot be reassigned a value
            attribute redefines seaLevelThrust;
        }

        part redefines turboProp {
            perform action redefines generateThrust;

            // Input values (design variables)
            attribute redefines nrBlades = 4;
            attribute redefines pressureRatio = 25.0;

            // Output values
            attribute redefines mass; // Not evaluated
            attribute redefines thrustSpecificFuelConsumption = null; // Evaluated without result (e.g. because of failure)
            attribute redefines turbineInletTemperature = 1500[SI::K]; // Evaluation success (with unit)
            attribute redefines propPressureRatio = 1.5; // Evaluation success
        }

    }

}
