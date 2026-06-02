package SA_FunctionAllocationExample {
    doc /*
    Example of definition of function allocation and induction relationships:
    - The top-level system output is a thrust force
    - This is provided by the "generate thrust" action
    - Generate thrust can be performed by either a propeller or a nozzle
    - The propeller needs mechanical power, which can be provided by a turbine or an electric motor
    - The nozzle and turbine need chemical energy (fuel); the electric motor needs electric energy

    Actions are defined abstractly first, with only their outputs defined
    (namely, what these actions "produce").
    Associated abstract parts are defined that perform the actions.

    Then, parts are defined which define what actions they perform,
    along with the inputs needed for these actions.
    They also declare which additional functions they might require in
    order to provide the inputs to their performed actions.

    This way it is possible to define alternate parts that perform the same
    actions (i.e. produce the same outputs) but need different inputs to
    do so (for example because of different technologies or principles used).
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

        perform action redefines provideFuel: ProvideFuel;
    }
    part def BatteryPack specializes ElectricEnergyProvider {
        doc /* battery pack part definition, which provides electric energy. */

        perform action redefines provideElectricEnergy: ProvideElectricEnergy;
    }

    part def ControlSystem specializes BladePitchController, FuelFlowController {
        doc /* Control system part definition, which provides control signals. */

        perform action redefines controlBladePitch: ControlBladePitch {
            out bladePitchControlSignal: BladePitchControlSignal; // Not automatically defined?
        }

        perform action redefines controlFuelFlow: ControlFuelFlow {
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

        // Define internal functions

        action generateMechPower: GenerateMechPower;
        action controlBladePitch: ControlBladePitch;
        action provideFuel: ProvideFuel;
        action controlFuelFlow: ControlFuelFlow;
        action provideElectricEnergy: ProvideElectricEnergy;

        // Define the first variation: propeller or nozzle to generate thrust

        part thrustGeneratorRef: ThrustGenerator {
            perform action :>> generateThrust;
        }
        variation part thrustGenerator subsets thrustGeneratorRef {
            variant part propeller: Propeller;
            variant part nozzle: Nozzle;
        }

        // Define flows into the variants; this declares which subsequent parts
        // are required depending on the choice of the thrust generator

        flow of MechPower
            from generateMechPower.mechanicalPower
                to thrustGenerator::propeller.generateThrust.mechanicalPower;
        flow of BladePitchControlSignal
            from controlBladePitch.bladePitchControlSignal
                to thrustGenerator::propeller.generateThrust.bladePitchControlSignal;
        flow of ChemicalEnergy
            from provideFuel.chemicalEnergy
                to thrustGenerator::nozzle.generateThrust.chemicalEnergy;
        flow of ChemicalEnergy
            from controlFuelFlow.fuelFlowControlSignal
                to thrustGenerator::nozzle.generateThrust.fuelFlowControlSignal;

        // Define the second variation: turbine or electric motor to
        // generate mechanical power (if a propeller is chosen to generate thrust)

        part mechanicalPowerProviderRef: MechPowerGenerator {
            perform action :>> generateMechPower;
        }
        variation part mechanicalPowerProvider subsets mechanicalPowerProviderRef {
            variant part turbine: Turbine;
            variant part electricMotor: ElectricMotor;
        }

        flow of ChemicalEnergy
            from provideFuel.chemicalEnergy
                to mechanicalPowerProvider::turbine.generateMechPower.chemicalEnergy;
        flow of ChemicalEnergy
            from controlFuelFlow.fuelFlowControlSignal
                to mechanicalPowerProvider::turbine.generateMechPower.fuelFlowControlSignal;
        flow of ElectricEnergy
            from provideElectricEnergy.electricEnergy
                to mechanicalPowerProvider::electricMotor.generateMechPower.electricEnergy;

        // Define other parts that might be required by prior part selections

        part fuelSystem: FuelSystem {
            perform action :>> provideFuel;
        }

        part batteryPack: BatteryPack {
            perform action :>> provideElectricEnergy;
        }

        part controlSystem: ControlSystem {
            perform action :>> controlBladePitch;
            perform action :>> controlFuelFlow;
        }

    }

    // System architectures that use different combinations of components to generate thrust
    
    #architecture part def ConventionalPropulsionSystem specializes PropulsionSystem {
        doc /* Conventional propulsion system,
        which generates thrust by a propeller,
        which takes mechanical power from a turbine,
        which uses fuel. */

        // Select the propeller as thrust generator
        part propeller[1] redefines thrustGenerator subsets PropulsionSystem::thrustGenerator::propeller;
        // part propeller = thrustGenerator;

        // Select the turbine as mechanical power provider
        part turbine[1] redefines mechanicalPowerProvider subsets PropulsionSystem::mechanicalPowerProvider::turbine;
        // part turbine = mechanicalPowerProvider;
        // alias turbine for mechanicalPowerProvider;
        
        // Select the fuel system and control system; remove the battery pack
        part redefines fuelSystem[1];
        part redefines batteryPack[0];
        part redefines controlSystem;

        perform action redefines generateThrust[1];
        action redefines generateMechPower[1];
        action redefines controlBladePitch[1];
        action redefines provideFuel[1];
        action redefines controlFuelFlow[1];
        action redefines provideElectricEnergy[0];

    }

    #architecture part def ReactionPropulsionSystem :> PropulsionSystem {
        doc /* Reaction propulsion system,
        which generates thrust by a nozzle,
        which uses fuel. */

        // Select the nozzle as thrust generator
        part nozzle[1] redefines thrustGenerator subsets PropulsionSystem::thrustGenerator::nozzle;
        // part nozzle = thrustGenerator;
        // alias nozzle for thrustGenerator;

        // Remove the mechanical power provider
        part redefines mechanicalPowerProvider[0];
        
        // Select the fuel system and control system; remove the battery pack
        part redefines fuelSystem[1];
        part redefines batteryPack[0];
        part redefines controlSystem[1];

        perform action redefines generateThrust[1];
        action redefines generateMechPower[0];
        action redefines controlBladePitch[0];
        action redefines provideFuel[1];
        action redefines controlFuelFlow[1];
        action redefines provideElectricEnergy[0];
    }

    #architecture part def electricPropulsionSystem :> PropulsionSystem {
        doc /* Electric propulsion system,
        which generates thrust by a propeller,
        which takes mechanical power from an electric motor,
        which uses electricity from a battery pack. */

        // Select the propeller as thrust generator
        part propeller[1] redefines thrustGenerator subsets PropulsionSystem::thrustGenerator::propeller;
        // part propeller = thrustGenerator;

        // Select the electric motor as mechanical power provider
        part electricMotor[1] redefines mechanicalPowerProvider subsets PropulsionSystem::mechanicalPowerProvider::electricMotor;
        // part electricMotor = mechanicalPowerProvider;
        
        // Remove the fuel system; select the battery pack and control system
        part redefines fuelSystem[0];
        part redefines batteryPack[1];
        part redefines controlSystem[1];

        perform action redefines generateThrust[1];
        action redefines generateMechPower[1];
        action redefines controlBladePitch[1];
        action redefines provideFuel[0];
        action redefines controlFuelFlow[0];
        action redefines provideElectricEnergy[1];
    }

}
