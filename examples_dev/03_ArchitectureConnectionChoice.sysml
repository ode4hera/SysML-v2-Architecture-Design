package SA_ArchitectureConnectionChoiceExample {
    doc
    /*
     Package showing an example of architectural connection choice:
     - There are 3 sensors, 3 computers, and 3 actuators
     - Sensors need to be connected to computers, computers to actuators
     - Each sensor needs at least 1 connection to a computer, each computer needs at least 1 connection from a sensor
     - Each computer has 1 or 2 outgoing connections to an actuator
     - Each actuator can accept up to 2 connections from a computer

     Also shows an example of function decomposition.
     */
    private import ArchitectureDesign::*;

    // Abstract port definitions to define the top-level output flows
    
    item def OutputState;
    abstract port def ControlOutput {
        out outputState: OutputState;
    }

    // Abstract action definitions

    item def ReferenceState;
    item def ActuationSignal;
    item def SensorSignal;

    abstract action def SenseState {
        in referenceState: ReferenceState;
        out sensorSignal: SensorSignal;
    }

    abstract action def ComputeActuation {
        in sensorSignal: SensorSignal;
        out actuationSignal: ActuationSignal;
    }

    abstract action def ProvideActuation {
        in actuationSignal: ActuationSignal;
        out outputState: OutputState;
    }

    abstract action def ProvideControl {
        in referenceState: ReferenceState;
        out outputState: OutputState;

        action senseState: SenseState;
        action computeActuation: ComputeActuation;
        action provideActuation: ProvideActuation;

        bind senseState.referenceState = referenceState;
        flow from senseState.sensorSignal to computeActuation.sensorSignal;
        flow from computeActuation.actuationSignal to provideActuation.actuationSignal;
        bind outputState = provideActuation.outputState;
    }

    // Part, port, and flow definitions which implement the actions

    port def SensorSignalPort {
        out sensorSignal: SensorSignal;
    }

    interface def SensorSignalInterface {
        end sensorSignalOutPort: SensorSignalPort;
        end sensorSignalInPort: ~SensorSignalPort;

        flow of SensorSignal
            from sensorSignalOutPort.sensorSignal
                to sensorSignalInPort.sensorSignal;
    }

    port def ActuationSignalPort {
        out actuationSignal: ActuationSignal;
    }

    interface def ActuationSignalInterface {
        end actuationSignalOutPort: ActuationSignalPort;
        end actuationSignalInPort: ~ActuationSignalPort;

        flow of ActuationSignal
            from actuationSignalOutPort.actuationSignal
                to actuationSignalInPort.actuationSignal;
    }

    part def Sensor {
        doc /* Sensor part */
        perform action senseState: SenseState;

        port sensorSignalOutPort[1] ordered : SensorSignalPort {
            out :>> sensorSignal[1..*] ordered;
        }
        bind senseState.sensorSignal = sensorSignalOutPort.sensorSignal;
    }

    part def Computer {
        doc /* Computer part */
        perform action computeActuation: ComputeActuation;

        port sensorSignalInPort ordered : ~SensorSignalPort {
            in :>> sensorSignal[1..*] ordered;
        }
        bind computeActuation.sensorSignal = sensorSignalInPort.sensorSignal;

        port actuationSignalOutPort ordered : ActuationSignalPort {
            out :>> actuationSignal[(1, 2)] ordered;
        }
        bind computeActuation.actuationSignal = actuationSignalOutPort.actuationSignal;
    }

    part def Actuator {
        doc /* Actuator part */
        perform action provideActuation: ProvideActuation;

        port actuationSignalInPort ordered: ~ActuationSignalPort {
            in :>> actuationSignal[0..2] ordered;
        }
        bind provideActuation.actuationSignal = actuationSignalInPort.actuationSignal;
    }

    // Architecture design space model

    abstract #architectureDesignSpace part def ControlSystem {
        doc /* Control system architecture design space */

        // Define the top-level system output

        port controlOutput: ControlOutput;
        bind controlOutput.outputState = provideControl.outputState;


        // Define the top-level function decomposition

        perform action provideControl: ProvideControl;

        // Define the parts and attach flows

        part sensor[3]: Sensor {
            perform action redefines senseState = provideControl.senseState;
        }

        part computer[3]: Computer {
            perform action redefines computeActuation = provideControl.computeActuation;
        }

        part actuator[3]: Actuator {
            perform action redefines provideActuation = provideControl.provideActuation;
        }

        interface sensorSignalInterface: SensorSignalInterface
            connect sensorSignalOutPort references sensor.sensorSignalOutPort
                to sensorSignalInPort references computer.sensorSignalInPort;
        
        interface actuationSignalInterface: ActuationSignalInterface
            connect actuationSignalOutPort references computer.actuationSignalOutPort
                to actuationSignalInPort references actuator.actuationSignalInPort;

    }

    // Architecture instances
    #architecture part def ControlSystemInstance specializes ControlSystem {
        doc /* Control system architecture instance */

        part redefines sensor[3] = (sensor1, sensor2, sensor3);
        part sensor1 subsets sensor {
            port :>> sensorSignalOutPort {
                out :>> sensorSignal[3];
            }
        }
        part sensor2 subsets sensor {
            port :>> sensorSignalOutPort {
                out :>> sensorSignal[1];
            }
        }
        part sensor3 subsets sensor {
            port :>> sensorSignalOutPort {
                out :>> sensorSignal[1];
            }
        }

        part :>> computer[3] = (computer1, computer2, computer3);
        part computer1 subsets computer {
            port :>> sensorSignalInPort {
                in :>> sensorSignal[1];
            }
            port :>> actuationSignalOutPort {
                out :>> actuationSignal[1];
            }
        }
        part computer2 subsets computer {
            port :>> sensorSignalInPort {
                in :>> sensorSignal[2];
            }
            port :>> actuationSignalOutPort {
                out :>> actuationSignal[2];
            }
        }
        part computer3 subsets computer {
            port :>> sensorSignalInPort {
                in :>> sensorSignal[2];
            }
            port :>> actuationSignalOutPort {
                out :>> actuationSignal[1];
            }
        }

        part :>> actuator[3] = (actuator1, actuator2, actuator3);
        part actuator1 subsets actuator {
            port :>> actuationSignalInPort {
                in :>> actuationSignal[3];
            }
        }
        part actuator2 subsets actuator {
            port :>> actuationSignalInPort {
                in :>> actuationSignal[1];
            }
        }
        part actuator3 subsets actuator {
            port :>> actuationSignalInPort {
                in :>> actuationSignal[0];
            }
        }

        // Sensor signal connections: i connected to i, 1 connected to all
        interface redefines sensorSignalInterface[5]
            = (sscInt1, sscInt2, sscInt3, sscInt4, sscInt5);
        interface sscInt1 subsets sensorSignalInterface
            connect sensorSignalOutPort references sensor1.sensorSignalOutPort
                to sensorSignalInPort references computer1.sensorSignalInPort;
        interface sscInt2 subsets sensorSignalInterface
            connect sensorSignalOutPort references sensor1.sensorSignalOutPort
                to sensorSignalInPort references computer2.sensorSignalInPort;
        interface sscInt3 subsets sensorSignalInterface
            connect sensorSignalOutPort references sensor1.sensorSignalOutPort
                to sensorSignalInPort references computer3.sensorSignalInPort;
        interface sscInt4 subsets sensorSignalInterface
            connect sensorSignalOutPort references sensor2.sensorSignalOutPort
                to sensorSignalInPort references computer2.sensorSignalInPort;
        interface sscInt5 subsets sensorSignalInterface
            connect sensorSignalOutPort references sensor3.sensorSignalOutPort
                to sensorSignalInPort references computer3.sensorSignalInPort;

        // Actuation signal connections: i connected to 1, 2 connected to 2
        interface :>> actuationSignalInterface[4] = (ascInt1, ascInt2, ascInt3, ascInt4);
        interface ascInt1 subsets actuationSignalInterface
            connect actuationSignalOutPort references computer1.actuationSignalOutPort
                to actuationSignalInPort references actuator1.actuationSignalInPort;
        interface ascInt2 subsets actuationSignalInterface
            connect actuationSignalOutPort references computer2.actuationSignalOutPort
                to actuationSignalInPort references actuator1.actuationSignalInPort;
        interface ascInt3 subsets actuationSignalInterface
            connect actuationSignalOutPort references computer3.actuationSignalOutPort
                to actuationSignalInPort references actuator1.actuationSignalInPort;
        interface ascInt4 subsets actuationSignalInterface
            connect actuationSignalOutPort references computer2.actuationSignalOutPort
                to actuationSignalInPort references actuator2.actuationSignalInPort;

    }

}
