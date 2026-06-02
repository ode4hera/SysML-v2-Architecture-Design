package ADSG_PortConnections {
    doc /* Demonstrates everything related to port connection choice modeling.
    Port connection choices are choices related to the connection between
    one or more source nodes and one or more target nodes, subject to connection constraints:
    - Each connector may accept a number of connections
      - Specified as a lower and optional upper bound
      - Or a list of allowed number of connections
    - Duplicate connections between the same pairs of connectors might be allowed or not
    - Connections can be grouped per port or per owning part
      - Grouping means that the number of connections can still be chosen,
        but that different ordering of incoming/outgoing connections is not regarded as a separate architecture instance
    - The number of port instances might be subject to a choice (similar to part/subsystem instantiations)
    */
    private import ArchitectureDesign::*;

    package UsingConnection {

        item def Signal;
        port def SourcePort {
            // 0 to 3 connections, repeated connections allowed, grouped by port
            out item signal nonunique ordered : Signal;
        }
        port def TargetPort {
            // any nr of connections, repeated connections allowed
            in item signal nonunique : Signal;
        }

        part def TargetPart {
            // 1 or 2 ports, grouped by part instance
            port targetPort[1..2] ordered : TargetPort {
                in :>> signal[0..*];
            }
        }

        #architectureDesignSpace part def DesignSpace {
            action boundaryFunction1[1] :> boundaryFunctions;
            action boundaryFunction2[1] :> boundaryFunctions;
            action boundaryFunction3[1] :> boundaryFunctions;

            part source1[1] {
                perform boundaryFunction1;

                // 2 ports
                port sourcePort[2] : SourcePort {
                    out :>> signal[0..3];
                }
            }

            part source2[1] {
                perform boundaryFunction2;

                // 1 or 2 ports
                port sourcePort2[1..2] {
                    // 0 or 2 connections, repeated connections not allowed
                    out item signal[(0, 2)] : Signal;
                }
            }

            part target[1..2] : TargetPart {
                perform boundaryFunction3;
            }

            connection portConnection[0..*] {
                end ::> source1.sourcePort;
                end ::> source2.sourcePort2;
                end ::> target.targetPort;
            }

            :>> architecturalChoices {
                :>> choices[1] = connectionChoice;

                abstract connection connectionChoice :> choices : PortConnectionChoice {
                    ref :>> sourcePorts[2] = (source1.sourcePort, source2.sourcePort2);
                    ref :>> targetPorts = target.targetPort;
                    :>> associatedConnection = portConnection;
                }
            }
            :>> formalDesignProblem {
                :>> designVariables = connectionDesVar;

                #catX attribute connectionDesVars[1..*] : ScalarValues::Integer;
                attribute connectionDesVar :> connectionDesVars { :>> values = (0, 1); }
                // There might be more, depending on how the connection choice is encoded

                allocation allocate architecturalChoices.connectionChoice to connectionDesVars;
            }
        }

        #architecture part def Arch :> DesignSpace {
            
            part :>> source1[1] {
                :>> sourcePort[2] = (sourcePort_1, sourcePort_2);
                port sourcePort_1 :> sourcePort {
                    out :>> signal[0];
                }
                port sourcePort_2 :> sourcePort {
                    out :>> signal[3];
                }
            }

            part :>> source2[1] {
                port :>> sourcePort2[1] {
                    out :>> signal[2];
                }
            }

            part :>> target[2] = (target_1, target_2);
            part target_1 :> target {
                port :>> targetPort[1] {
                    in :>> signal[2];
                }
            }
            part target_2 :> target {
                port :>> targetPort[2] = (targetPort_1, targetPort_2);
                port targetPort_1 :> targetPort {
                    in :>> signal[1];
                }
                port targetPort_2 :> targetPort {
                    in :>> signal[2];
                }
            }

            connection :>> portConnection[5] = (portConnection_1, portConnection_2, portConnection_3, portConnection_4, portConnection_5);
            connection portConnection_1 :> portConnection connect source1.sourcePort_2 to target_1.targetPort;
            connection portConnection_2 :> portConnection connect source1.sourcePort_2 to target_1.targetPort;
            connection portConnection_3 :> portConnection connect source1.sourcePort_2 to target_2.targetPort_2;
            connection portConnection_4 :> portConnection connect source2.sourcePort2 to target_2.targetPort_1;
            connection portConnection_5 :> portConnection connect source2.sourcePort2 to target_2.targetPort_2;

            :>> architecturalChoices {
                :>> connectionChoice references portConnection;
            }
            :>> formalDesignProblem {
                :>> connectionDesVar = 1;
                // There will be more here
            }
        }
    }

    package UsingInterface {
        
        item def Signal;
        port def SignalPort {
            out item signal[0..2] ordered : Signal;
        }

        interface def SignalInterface {
            end signalOutPort : SignalPort;
            end signalInPort : ~SignalPort;
        }

        #architectureDesignSpace part def DesignSpace {
            action boundaryFunction1[1] :> boundaryFunctions;
            action boundaryFunction2[1] :> boundaryFunctions;

            part source[1] {
                perform boundaryFunction1;
                port signalPort[1] ordered : SignalPort {
                    out :>> signal[0..2];
                }
            }

            part target[1] {
                perform boundaryFunction2;
                port signalPort[1..2] ordered : ~SignalPort;
            }

            interface signalInterface[0..*] : SignalInterface
                connect source.signalPort to target.signalPort;

            :>> architecturalChoices {
                :>> choices[1] = connectionChoice;

                abstract connection connectionChoice :> choices : PortConnectionChoice {
                    ref :>> sourcePorts[2] = source.signalPort;
                    ref :>> targetPorts = target.signalPort;
                    :>> associatedConnection = signalInterface;
                }
            }
            :>> formalDesignProblem {
                :>> designVariables = connectionDesVar;

                #catX attribute connectionDesVar[1..*] : ScalarValues::Integer {
                    :>> values = (0, 1);
                }
                // There might be more, depending on how the connection choice is encoded

                allocation allocate architecturalChoices.connectionChoice to connectionDesVar;
            }
        }

        #architecture part def Arch :> DesignSpace {
            part :>> source[1] {
                port :>> signalPort[1] {
                    out :>> signal[2];
                }
            }
            part :>> target[1] {
                port :>> signalPort[2] = (signalPort_1, signalPort_2);
                port signalPort_1 :> signalPort {
                    in :>> signal[1];
                }
                port signalPort_2 :> signalPort {
                    in :>> signal[1];
                }
            }

            interface :>> signalInterface[2] = (signalInterface_1, signalInterface_2);
            interface signalInterface_1 :> signalInterface connect source.signalPort to target.signalPort_1;
            interface signalInterface_2 :> signalInterface connect source.signalPort to target.signalPort_2;

            :>> architecturalChoices {
                :>> connectionChoice references signalInterface;
            }
            :>> formalDesignProblem {
                :>> connectionDesVar = 1;
                // There will be more here
            }
        }

    }
}