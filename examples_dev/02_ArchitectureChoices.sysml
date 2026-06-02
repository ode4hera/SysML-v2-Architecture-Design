package SA_ArchitectureChoicesExample {
    doc /*
    Extension of the previous example with additional architectural choices:
    - Propeller has a discrete design variable: nr of blades = 3, 4, 6 or 8
    - Turbine has a continuous design variable: pressure ratio = 10 to 50
    - The subsystem containing the thrust generators and
      mechanical power generators can be instantiated 1 or 2 times
    - Battery pack can be instantiated 1, 2 or 4 times
    */
    private import ArchitectureDesign::*;

    // Abstract port definitions to define the top-level output flows required

    item def ThrustForce;
    abstract port def ThrustOutput {
        out thrustForce: ThrustForce;
    }

    // Abstract action definitions that define the outputs of the actions,
    // and associated abstract part definitions that perform the actions.

    abstract action def GenerateThrust {
        doc /* Abstract action: generate thrust */
        out thrustForce: ThrustForce;
    }
    abstract part def ThrustGenerator {
        doc /* Abstract part: thrust generator */
        perform action generateThrust: GenerateThrust;
    }

    item def BladePitchControlSignal;
    abstract action def ControlBladePitch {
        doc /* Abstract action: control blade pitch */
        out bladePitchControlSignal: BladePitchControlSignal;
    }
    abstract part def BladePitchController {
        doc /* Abstract part: blade pitch controller */
        perform action controlBladePitch: ControlBladePitch;
    }

    item def FuelFlowControlSignal;
    abstract action def ControlFuelFlow {
        doc /* Abstract action: control fuel flow */
        out fuelFlowControlSignal: FuelFlowControlSignal;
    }
    abstract part def FuelFlowController {
        doc /* Abstract part: fuel flow controller */
        perform action controlFuelFlow: ControlFuelFlow;
    }

    item def MechPower;
    abstract action def GenerateMechPower {
        doc /* Abstract function: generate mechanical power */
        out mechanicalPower: MechPower;
    }
    abstract part def MechPowerGenerator {
        doc /* Abstract part: mechanical power generator */
        perform action generateMechPower: GenerateMechPower;
    }

    item def ChemicalEnergy;
    abstract action def ProvideFuel {
        doc /* Abstract function: provide fuel */
        out chemicalEnergy: ChemicalEnergy;
    }
    abstract part def FuelProvider {
        doc /* Abstract part: fuel provider */
        perform action provideFuel: ProvideFuel;
    }

    item def ElectricEnergy;
    abstract action def ProvideElectricEnergy {
        doc /* Abstract function: provide electric energy */
        out electricEnergy: ElectricEnergy;
    }
    abstract part def ElectricEnergyProvider {
        doc /* Abstract part: electric energy provider */
        perform action provideElectricEnergy: ProvideElectricEnergy;
    }

    // Part definitions which define which action they perform
    // along with which inputs these actions need

    action def PropellerGenerateThrustInputs {
        in mechanicalPower: MechPower;
        in bladePitchControlSignal: BladePitchControlSignal;
    }
    part def Propeller specializes ThrustGenerator {
        doc /* Propeller part definition, which generates thrust
        by converting mechanical power into thrust. */

        perform action generateThrust redefines generateThrust: GenerateThrust, PropellerGenerateThrustInputs;

        #needsAction : GenerateMechPower;
        #needsAction : ControlBladePitch;

        // Declare the nr of blades as a discrete design variable
        #ordX attribute nrBlades : ScalarValues::Integer {
            redefines values = (3, 4, 6, 8);
        }
    }

    action def NozzleGenerateThrustInputs {
        in chemicalEnergy: ChemicalEnergy;
        in fuelFlowControlSignal: FuelFlowControlSignal;
    }
    part def Nozzle specializes ThrustGenerator {
        doc /* Nozzle part definition, which generates thrust
        by converting chemical energy (i.e. combustion) into thrust. */

        perform action generateThrust redefines generateThrust: GenerateThrust, NozzleGenerateThrustInputs;

        #needsAction : ProvideFuel;
        #needsAction : ControlFuelFlow;
    }

    action def TurbineGenerateMechPowerInputs {
        in chemicalEnergy: ChemicalEnergy;
        in fuelFlowControlSignal: FuelFlowControlSignal;
    }
    part def Turbine specializes MechPowerGenerator {
        doc /* Turbine part definition, which generates mechanical power
        by converting chemical energy (i.e. combustion) into rotational shaft power. */

        perform action generateMechPower redefines generateMechPower: GenerateMechPower, TurbineGenerateMechPowerInputs;

        #needsAction : ProvideFuel;
        #needsAction : ControlFuelFlow;

        // Declare the pressure ratio as continuous design variable (between 10 and 50)
        #continuousDesignVariable attribute pressureRatio {
            redefines lowerBound = 10.0;
            redefines upperBound = 50.0;
        }
    }

    action def ElectricMotorGenerateMechPowerInputs {
        in electricEnergy: ElectricEnergy;
    }
    part def ElectricMotor specializes MechPowerGenerator {
        doc /* Electric motor part definition, which generates mechanical power
        by converting electric energy into rotational shaft power. */

        perform action generateMechPower redefines generateMechPower: GenerateMechPower, ElectricMotorGenerateMechPowerInputs;

        #needsAction : ProvideElectricEnergy;
    }

    part def FuelSystem specializes FuelProvider {
        doc /* Fuel system part definition, which provides (conventional) fuel. */

        perform action provideFuel redefines provideFuel: ProvideFuel;
    }
    part def BatteryPack specializes ElectricEnergyProvider {
        doc /* battery pack part definition, which provides electric energy. */

        perform action provideElectricEnergy redefines provideElectricEnergy: ProvideElectricEnergy;
    }

    part def ControlSystem specializes BladePitchController, FuelFlowController {
        doc /* Control system part definition, which provides control signals. */

        perform action controlBladePitch redefines controlBladePitch: ControlBladePitch {
            out bladePitchControlSignal: BladePitchControlSignal; // Not automatically defined?
        }

        perform action controlFuelFlow redefines controlFuelFlow: ControlFuelFlow {
            out fuelFlowControlSignal: FuelFlowControlSignal; // Not automatically defined?
        }
    }

    // Variability model to represent different ways to generate thrust

    action generateThrust: GenerateThrust;

    abstract #architectureDesignSpace part def PropulsionSystem {
        doc /* Abstract propulsion system,
        which generate thrust by either a propeller or a nozzle.
        If a propeller is chosen, it can take mechanical power
        from a turbine (which needs fuel) or from an electric
        motor (which needs electric energy).
        If a nozzle is chosen, it needs fuel. */

        // Define the top-level system output: thrust force

        port thrustOutput: ThrustOutput;
        bind thrustOutput.thrustForce 
            = generateThrust.thrustForce;

        perform generateThrust;

        // Define a subsystem containing the thrust and mechanical power generators
        part thrustMechPowerSubsystem[1..2] ordered {

            // Define the first variation: propeller or nozzle to generate thrust

            variation part thrustGenerator: ThrustGenerator {
                variant part propeller: Propeller;
                variant part nozzle: Nozzle;
            }

            // Define flows into the variants; this declares which subsequent parts
            // are required depending on the choice of the thrust generator

            flow of MechPower
                from mechanicalPowerProvider.generateMechPower.mechanicalPower
                    to thrustGenerator::propeller.generateThrust.mechanicalPower;

            // Define the second variation: turbine or electric motor to
            // generate mechanical power (if a propeller is chosen to generate thrust)

            variation part mechanicalPowerProvider: MechPowerGenerator {
                variant part turbine: Turbine;
                variant part electricMotor: ElectricMotor;
            }

        }

        flow of BladePitchControlSignal
            from controlSystem.controlBladePitch.bladePitchControlSignal
                to thrustMechPowerSubsystem.thrustGenerator::propeller.generateThrust.bladePitchControlSignal;
        flow of ChemicalEnergy
            from fuelSystem.provideFuel.chemicalEnergy
                to thrustMechPowerSubsystem.thrustGenerator::nozzle.generateThrust.chemicalEnergy;
        flow of ChemicalEnergy
            from controlSystem.controlFuelFlow.fuelFlowControlSignal
                to thrustMechPowerSubsystem.thrustGenerator::nozzle.generateThrust.fuelFlowControlSignal;
        
        flow of ChemicalEnergy
            from fuelSystem.provideFuel.chemicalEnergy
                to thrustMechPowerSubsystem.mechanicalPowerProvider::turbine.generateMechPower.chemicalEnergy;
        flow of ChemicalEnergy
            from controlSystem.controlFuelFlow.fuelFlowControlSignal
                to thrustMechPowerSubsystem.mechanicalPowerProvider::turbine.generateMechPower.fuelFlowControlSignal;
        flow of ElectricEnergy
            from batteryPack.provideElectricEnergy.electricEnergy
                to thrustMechPowerSubsystem.mechanicalPowerProvider::electricMotor.generateMechPower.electricEnergy;

        // Define other parts that might be required by prior part selections

        part fuelSystem: FuelSystem;

        part batteryPack: BatteryPack ordered {
            // Define that the battery pack can be instantiated 1, 2 or 4 times
            attribute nPacks : ScalarValues::Positive = (1, 2, 4);
            multiplicity [nPacks];
        }

        part controlSystem: ControlSystem;

    }

    // System architectures that use different combinations of components to generate thrust
    
    #architecture part def ConventionalPropulsionSystem specializes PropulsionSystem {
        doc /* Conventional propulsion system,
        which generates thrust by a propeller,
        which takes mechanical power from a turbine,
        which uses fuel. */

        part thrustMechPowerSubsystem[1] redefines thrustMechPowerSubsystem {

            // Select the propeller as thrust generator, use 3 blades
            part propeller redefines thrustGenerator = PropulsionSystem::thrustMechPowerSubsystem.thrustGenerator::propeller {
                attribute redefines PropulsionSystem::thrustMechPowerSubsystem.thrustGenerator::propeller.nrBlades = 3;
            }
            // part propeller = thrustGenerator;

            // Select the turbine as mechanical power provider, use a pressure ratio of 30
            part turbine redefines mechanicalPowerProvider = PropulsionSystem::thrustMechPowerSubsystem.mechanicalPowerProvider::turbine {
                attribute redefines PropulsionSystem::thrustMechPowerSubsystem.mechanicalPowerProvider::turbine.pressureRatio: ScalarValues::Real = 30.0;
            }
            // part turbine = mechanicalPowerProvider;

        }
        
        // Select the fuel system and control system; remove the battery pack
        part redefines fuelSystem;
        part redefines batteryPack[0];
        part redefines controlSystem;
    }

    #architecture part def ReactionPropulsionSystem :> PropulsionSystem {
        doc /* Reaction propulsion system,
        which generates thrust by a nozzle,
        which uses fuel. */

        part thrustMechPowerSubsystem[1] redefines thrustMechPowerSubsystem {

            // Select the nozzle as thrust generator
            part nozzle redefines thrustGenerator = PropulsionSystem::thrustMechPowerSubsystem.thrustGenerator::nozzle;
            // part nozzle = thrustGenerator;

            // Remove the mechanical power provider
            part redefines mechanicalPowerProvider[0];

        }
        
        // Select the fuel system and control system; remove the battery pack
        part redefines fuelSystem;
        part redefines batteryPack[0];
        part redefines controlSystem;
    }

    #architecture part def ElectricPropulsionSystem :> PropulsionSystem {
        doc /* Electric propulsion system,
        which generates thrust by a propeller,
        which takes mechanical power from an electric motor,
        which uses electricity from a battery pack. */

        // Use two thrust and mechanical power subsystems
        part redefines thrustMechPowerSubsystem[2] = (thrustMechPowerSubsystem1, thrustMechPowerSubsystem2);
        
        // Use the propeller with 6 and 8 blades in the different subsystem instances
        part thrustMechPowerSubsystem1 subsets PropulsionSystem::thrustMechPowerSubsystem {

            // Select the propeller as thrust generator
            part propeller redefines thrustGenerator = PropulsionSystem::thrustMechPowerSubsystem.thrustGenerator::propeller {
                attribute :>> PropulsionSystem::thrustMechPowerSubsystem.thrustGenerator::propeller.nrBlades = 6;
            }

            // Select the electric motor as mechanical power provider
            part electricMotor redefines mechanicalPowerProvider = PropulsionSystem::thrustMechPowerSubsystem.mechanicalPowerProvider::electricMotor;
        }

        part thrustMechPowerSubsystem2 subsets PropulsionSystem::thrustMechPowerSubsystem {

            // Select the propeller as thrust generator
            part propeller redefines thrustGenerator = PropulsionSystem::thrustMechPowerSubsystem.thrustGenerator::propeller {
                attribute :>> PropulsionSystem::thrustMechPowerSubsystem.thrustGenerator::propeller.nrBlades = 8;
            }

            // Select the electric motor as mechanical power provider
            part electricMotor redefines mechanicalPowerProvider = PropulsionSystem::thrustMechPowerSubsystem.mechanicalPowerProvider::electricMotor;
        }
        
        // Remove the fuel system; select the battery pack (2x) and control system
        part redefines fuelSystem[0];
        part redefines controlSystem;

        part redefines batteryPack[2] = (batteryPack1, batteryPack2);
        part batteryPack1 subsets PropulsionSystem::batteryPack;
        part batteryPack2 subsets PropulsionSystem::batteryPack;
    }

}
