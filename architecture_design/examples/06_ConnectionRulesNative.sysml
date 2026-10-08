package ArchitectureDesign_ConnectionRulesNativeExample {
    doc
    /*
     Package showing the rule of 05_ConnectionModeling.sysml, "when there are two sensors,
     at least one computer is fed by both", with standard SysML v2 elements only, for comparison.

     Without a pattern, the rule is written with named roles: a primary sensor, an optional
     backup sensor and a comparing computer, connected by fixed connections, plus an assert
     constraint that the backup connection exists exactly when the backup sensor exists.

     What this costs compared with the pattern:
     - The roles (primary, backup, comparing) are names that the rule does not need; every
       architecture instance has to say which sensor and which computer play them.
     - The condition "when there are two sensors" needs an assert constraint over counts,
       which a generator has to evaluate as an expression.

    Copyright: (c) 2026, The Contributors to the ODE4HERA SysML v2 Libraries.
     */
    private import SequenceFunctions::*;
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
        doc /* Control system architecture design space, native rules only */

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

        // The rule, with named roles
        part primarySensor[1] :> sensor;
        part backupSensor[0..1] :> sensor;
        part comparingComputer[1] :> computer;

        connection primaryFeed :> measurementLink
            connect primarySensor.measurementOut to comparingComputer.measurementIn;
        connection backupFeed[0..1] :> measurementLink
            connect backupSensor.measurementOut to comparingComputer.measurementIn;

        assert constraint { backupFeed->size() == backupSensor->size() }
    }

    // Architecture instance: the same one as in 05, two sensors both feed one computer,
    // which commands the actuator

    #architecture part def ComparedSensors :> ControlSystem {
        doc /* Control system architecture instance */

        action :>> control[1];

        part :>> sensor[2] = (primarySensor, backupSensor);
        part :>> backupSensor[1];

        part :>> computer[1] = comparingComputer;

        part :>> actuator[1] = actuator1;
        part actuator1 :> actuator {
            perform action :>> control;
        }

        connection :>> measurementLink[2] = (primaryFeed, backupFeed);
        connection :>> backupFeed[1];

        connection :>> commandLink[1] = commandLink1;
        connection commandLink1 :> commandLink connect comparingComputer.commandOut to actuator1.commandIn;
    }

}
