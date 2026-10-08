package ArchitectureDesign_ConnectionModelingExample {
    doc
    /*
     Package showing an architectural pattern on a small control system design space:
     - 1 or 2 sensors, 1 or 2 computers and one actuator
     - any sensor may feed any computer, and any computer may command the actuator
     - rule: when there are two sensors, at least one computer is fed by both,
       so that it can compare their readings

     Without the rule, architectures exist in which the two sensors each feed a different
     computer and no computer sees both readings. The rule is stated as a prescriptive
     #pattern with three labels and two edges, and it shows the two things a pattern adds:
     - sensorA and sensorB both subset sensor, and two labels are always two different
       instances: the motif needs two different sensors feeding the same computer
     - prescriptive: architectures with a single sensor have no match and are not affected

     Port multiplicities cannot state this rule. Requiring two connections on every computer
     input would force every computer to read both sensors, and would rule out the
     architectures with a single sensor.

     The kind of the pattern selects the rule:
     - prescriptive: at least one comparing computer whenever there are two sensors (used here)
     - enforced: at least one comparing computer in every architecture, so a single sensor
       is no longer allowed
     - restrictive: no computer is fed by both sensors, so the two sensor channels stay independent

     The same rule without a pattern is shown in 06_ConnectionRulesNative.sysml.

    Copyright: (c) 2026, The Contributors to the ODE4HERA SysML v2 Libraries.
     */
    private import ArchitectureDesign::*;

    // Items and ports

    item def Measurement;
    item def Command;

    port def MeasurementPort {
        out item measurement[1] : Measurement;
    }
    port def CommandPort {
        out item command[1] : Command;
    }

    // Part definitions: every port is optional, so the wiring is free

    part def Sensor {
        port measurementOut[0..2] : MeasurementPort;
    }
    part def Computer {
        port measurementIn[0..2] : ~MeasurementPort;
        port commandOut[0..1] : CommandPort;
    }
    part def Actuator {
        port commandIn[0..2] : ~CommandPort;
    }

    // Architecture design space model

    abstract #architectureDesignSpace part def ControlSystem {
        doc /* Control system architecture design space */

        action control :> boundaryFunctions;

        part sensor[1..2] : Sensor;
        part computer[1..2] : Computer;
        part actuator[1] : Actuator {
            perform control;
        }

        // Connection choices: which sensors feed which computers,
        // and which computers command the actuator
        connection measurementLink[0..*] connect sensor.measurementOut to computer.measurementIn;
        connection commandLink[0..*] connect computer.commandOut to actuator.commandIn;

        // The rule: when there are two sensors, at least one computer is fed by both
        abstract #pattern occurrence sensorComparison : ArchitecturalPattern {
            :>> kind = PatternKind::prescriptive;

            ref part sensorA subsets sensor[1];
            ref part sensorB subsets sensor[1];
            ref part computerA subsets computer[1];

            connection connect sensorA.measurementOut to computerA.measurementIn;
            connection connect sensorB.measurementOut to computerA.measurementIn;
        }
    }

    // Architecture instance: two sensors both feed one computer, which commands the actuator

    #architecture part def ComparedSensors :> ControlSystem {
        doc /* Control system architecture instance */

        action :>> control[1];

        part :>> sensor[2] = (sensor1, sensor2);
        part sensor1 :> sensor;
        part sensor2 :> sensor;

        part :>> computer[1] = computer1;
        part computer1 :> computer;

        part :>> actuator[1] = actuator1;
        part actuator1 :> actuator {
            perform action :>> control;
        }

        connection :>> measurementLink[2] = (measurementLink1, measurementLink2);
        connection measurementLink1 :> measurementLink connect sensor1.measurementOut to computer1.measurementIn;
        connection measurementLink2 :> measurementLink connect sensor2.measurementOut to computer1.measurementIn;

        connection :>> commandLink[1] = commandLink1;
        connection commandLink1 :> commandLink connect computer1.commandOut to actuator1.commandIn;
    }

}
