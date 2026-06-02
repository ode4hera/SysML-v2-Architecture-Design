package SA_VariabilityCardinalityExample {
    doc /*
    Example of function allocation, demonstrating how choices with more complicated
    cardinality constraints can be modeled using variability modeling elements:
    1. Selective performing: a part that can perform one or more of multiple actions.
    2. Multi-performing: an action that can be performed by one or more parts.
    3. Non-performing: an action that can also not be performed.

    As can be seen, it is possible to model all scenarios using variability.
    However, in the selecting performing scenario, it is not possible to use simple alternative variations.
    Rather, complicated single-part variations have to be defined, with complicated constraints, which makes it
    difficult to understand the model.
    Additionally, exposing the constraints might lead the user in thinking they could modify them to modify the
    selection behavior of the design space model, which is usually not the case.
    */
    private import ArchitectureDesign::*;

    package SelectivePerforming {
        doc /* Selective performing: a part that can perform one or more of multiple actions.
        The example shows a flight control system with the following independent possible action to part mappings:
        - Control roll: aileron, spoiler
        - Reduce airspeed: airbrake, spoiler
        
        Spoiler can thus perform either actions or both.
        */

        abstract #architectureDesignSpace part def SelectiveDesignSpace {

            action controlRoll :> boundaryFunctions;
            action reduceAirspeed :> boundaryFunctions;

            variation part aileronSelection {
                variant part aileron[1] {
                    perform controlRoll;
                }
                variant part noAileron[0];
            }

            variation part spoilerSelection {
                variant part spoiler[1] {

                    variation perform action controlRollPerforming {
                        variant perform controlRoll[1];
                        variant perform action noControlRoll[0];
                    }

                    // Not working in Cameo...
                    assert constraint { aileronSelection == aileronSelection::aileron xor controlRollPerforming == controlRollPerforming::controlRoll }

                    variation perform action reduceAirspeedPerforming {
                        variant perform reduceAirspeed[1];
                        variant perform action noReduceAirspeed[0];
                    }

                    // Not working in Cameo...
                    assert constraint { airbrakeSelection == airbrakeSelection::airbrake xor reduceAirspeedPerforming == reduceAirspeedPerforming::reduceAirspeed }

                }
                variant part noSpoiler[0];
            }

            variation part airbrakeSelection {
                variant part airbrake[1] {
                    perform reduceAirspeed;
                }
                variant part noAirbrake[0];
            }

            // If no aileron is selected, the spoiler should be selected
            assert constraint {
                aileronSelection == aileronSelection::noAileron implies spoilerSelection == spoilerSelection::spoiler
            }

            // If no airbrake is selected, the spoiler should be selected
            assert constraint {
                airbrakeSelection == airbrakeSelection::noAirbrake implies spoilerSelection == spoilerSelection::spoiler
            }

        }

        #architecture part def NoSpoiler :> SelectiveDesignSpace {

            part aileron :>> aileronSelection = SelectiveDesignSpace::aileronSelection::aileron;
            part spoiler :>> spoilerSelection = SelectiveDesignSpace::spoilerSelection::noSpoiler;
            part airbrake :>> airbrakeSelection = SelectiveDesignSpace::airbrakeSelection::airbrake;
        }

        #architecture part def AllSpoiler :> SelectiveDesignSpace {
            
            part aileron :>> aileronSelection = SelectiveDesignSpace::aileronSelection::noAileron;
            part spoiler :>> spoilerSelection = SelectiveDesignSpace::spoilerSelection::spoiler {
                perform controlRoll :>> SelectiveDesignSpace::spoilerSelection::spoiler.controlRollPerforming = SelectiveDesignSpace::spoilerSelection::spoiler.controlRollPerforming::controlRoll;
                perform reduceAirspeed :>> SelectiveDesignSpace::spoilerSelection::spoiler.reduceAirspeedPerforming = SelectiveDesignSpace::spoilerSelection::spoiler.reduceAirspeedPerforming::reduceAirspeed;
            }
            part airbrake :>> airbrakeSelection = SelectiveDesignSpace::airbrakeSelection::noAirbrake;
        }

        #architecture part def PartiallySpoiler :> SelectiveDesignSpace {
            
            part aileron :>> aileronSelection = SelectiveDesignSpace::aileronSelection::aileron;
            part spoiler :>> spoilerSelection = SelectiveDesignSpace::spoilerSelection::spoiler {
                perform action noControlRoll :>> SelectiveDesignSpace::spoilerSelection::spoiler.controlRollPerforming = SelectiveDesignSpace::spoilerSelection::spoiler.controlRollPerforming::noControlRoll;
                perform reduceAirspeed :>> SelectiveDesignSpace::spoilerSelection::spoiler.reduceAirspeedPerforming = SelectiveDesignSpace::spoilerSelection::spoiler.reduceAirspeedPerforming::reduceAirspeed;
            }
            part airbrake :>> airbrakeSelection = SelectiveDesignSpace::airbrakeSelection::noAirbrake;
        }

    }

    package MultiPerforming {
        doc /* Multi-performing: an action that can be performed by one or more parts.
        The example shows a propulsion system with the action provideThrust that can be performed by:
        - Combustion engine
        - Electric motor
        - Both (hybrid)
        */

        abstract #architectureDesignSpace part def MultiDesignSpace {

            action provideThrust :> boundaryFunctions;

            variation part provideThrustSelection[1..2] {
                variant part combustionEngine[1] {
                    perform provideThrust;
                    attribute pressureRatio : ScalarValues::Real;
                }
                variant part electricMotor[1] {
                    perform provideThrust;
                    attribute nrSpools : ScalarValues::Integer;
                }
                variant part hybridThrust[2] = (combustionEngine, electricMotor);
            }
        }

        #architecture part def Hybrid :> MultiDesignSpace {
            part hybridThrust :>> MultiDesignSpace::provideThrustSelection = MultiDesignSpace::provideThrustSelection::hybridThrust;
            part combustionEngine subsets MultiDesignSpace::provideThrustSelection::combustionEngine = hybridThrust#(1) {
                :>> pressureRatio = 5;
            }
            part electricMotor subsets MultiDesignSpace::provideThrustSelection::electricMotor = hybridThrust#(2) {
                :>> nrSpools = 10;
            }
        }
    }

    package NonPerforming {
        doc /* Non-performing: an action that can also not be performed.
        The example shows an aircraft with an optional winglet. */

        abstract #architectureDesignSpace part def NonDesignSpace {

            action improveAerodynamics :> boundaryFunctions;

            variation part improveAerodynamicsSelection {
                variant part winglet[1] {
                    perform improveAerodynamics;
                }
                variant part noWinglet[0];
            }
        }

        #architecture part def HasWinglet :> NonDesignSpace {
            part winglet[1] :>> NonDesignSpace::improveAerodynamicsSelection = NonDesignSpace::improveAerodynamicsSelection::winglet;
        }

        #architecture part def HasNoWinglet :> NonDesignSpace {
            part noWinglet[0] :>> NonDesignSpace::improveAerodynamicsSelection = NonDesignSpace::improveAerodynamicsSelection::noWinglet;
        }
    }

}
