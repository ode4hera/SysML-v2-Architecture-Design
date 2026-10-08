# Architecture Design Library

This library adds concepts for modeling architecture design problems to enable the automatic generation, evaluation and optimization of system architectures.

Following concepts are added:
- Architectural choices: function allocation, element instantiation, port connections
- Architectural constraints: incompatibility constraints, choice constraints
- Connection modeling: connection rules in native SysML v2, architectural patterns over labeled instances
- Design variables: continuous, discrete (integer, ordinal, categorical)
- Performance metrics: generic outputs, objectives (minimization/maximization), constraint functions
- Complexity management elements: concepts, decompositions, non/multi-fulfillments, subsystems
- Architecture design space: modular build-up of the design space containing all architecture instances
- Architecture instances: specific architectures as generated from the design space definition

This library has originally been developed as part of the [ODE4HERA project](https://www.ode4hera.eu/),
however we encourage contributions by anyone!
To contribute, go to:

**https://github.com/ode4hera/SysML-v2-Architecture-Design**

## Example

An architecture design space might look like this:

```sysml
private import ArchitectureDesign::*;

abstract #architectureDesignSpace part def PropulsionSystemDesignSpace {
    
    // System-level objective
    #minObj attribute mass :> ISQ::mass 
        = turboprop.mass + fuelSystem.fuelTank.mass;
    
    action generateThrust :> boundaryFunctions {
        // Static input
        attribute seaLevelthrust :> ISQ::force = 150e3[SI::N]; }

    // Part instantiation choice: between 2 and 4 times
    part turboprop[2..4] {
        // Function performance: this part can be used to fulfill the function
        perform generateThrust;

        // Function induction: if this part is selected,
        // the following functions also are selected and need to be fulfilled
        #needsAction ::> provideFuel;

        // Design variables
        #intX attribute nrStages { :>> lowerBound = 1; :>> upperBound = 3; }
        #catX attribute bladeManufacturer { :>> values = ("MT", "Sensenich"); }
        #contX attribute pressureRatio { :>> lowerBound = 10; :>> upperBound = 30; }

        // Objective, constraint and output metric
        #minObj attribute tsfc;
        #con attribute turbineTemp {
            assert constraint { that <= 1500[SI::'°C_abs'] }
        }
        attribute mass :> ISQ::mass;
    }

    // Alternative option for fulfilling generateThrust
    part alternativePropulsor[0..1] {
        perform generateThrust;
    }
    
    action provideFuel;
    
    // Subsystem instantiation choice: 1 or 2 times
    #subsystem part fuelSystem[1..2] {
        // Independent part instantiation choice
        part fuelTank[1..2] {
            perform provideFuel;
            attribute mass :> ISQ::mass; }
    }
}
```

An architecture instance generated from this design space might then look like this:

```sysml
#architecture part def SimpleArchitecture :> PropulsionSystemDesignSpace {

    // Output parameters have no value initially:
    // the values should be assigned by the architecture evaluation
    attribute :>> mass;

    action :>> generateThrust[1];

    part :>> turboprop[2] = (turboprop_1, turboprop_2);

    part turboprop_1 :> turboprop {
        perform generateThrust;
        #needsAction ::> provideFuel;

        attribute :>> nrStages = 2;
        attribute :>> bladeManufacturer = "MT";
        attribute :>> pressureRatio = 25;

        attribute :>> tsfc;
        attribute :>> turbineTemp;
        attribute :>> mass;
    }

    part turboprop_2 :> turboprop {
        perform generateThrust;
        #needsAction ::> provideFuel;

        attribute :>> nrStages = 3;
        attribute :>> bladeManufacturer = "MT";
        attribute :>> pressureRatio = 15;

        attribute :>> tsfc;
        attribute :>> turbineTemp;
        attribute :>> mass;
    }

    part :>> alternativePropulsor[0] = null; // Element not selected

    action :>> provideFuel[1];

    #subsystem part :>> fuelSystem[1] {
        part :>> fuelTank[1] {
            perform provideFuel;
            attribute :>> mass;
        }
    }
}
```

For more examples, have a look at the models in the `examples` folder.

## Connection Modeling

Connection rules for architecture generation are written in native SysML v2 wherever the language has a direct form for them.
The `ConnectionModeling` package adds architectural patterns as a concise quantified graph form for rules that would
otherwise require rule-specific port types and constraints.

| Connection rule | Native SysML v2 form |
|---|---|
| A port must be connected | Lower bound 1 on the port's item: `out item signal[1..*]` |
| A port may stay unconnected | Lower bound 0 on the port's item: `out item signal[0..2]` |
| Maximum number of connections of a port | Upper bound or allowed list on the item: `[0..3]`, `[(0, 2)]` |
| Repeated connections between the same two ports | `nonunique` on the item; absent means at most one per pair |
| Interchangeable ports of a part | One port usage with multiplicity: `port feed[0..3]` |
| Ports that can never be connected | Port types that do not mate; if they otherwise mate, a restrictive pattern containing the forbidden connection |
| At least one A-B connection in the architecture | Usage multiplicity on the connection: `connection ab[1..*] connect a to b` |
| Choose k out of heterogeneous candidates | `variation part choice[1..2] { variant part a; variant part b; ... }` |
| A port whose partner is outside the system | The partner is a part of the `#architectureDesignSpaceContext` part |
| Fixed connection that is not a choice | A plain connection usage in the design space |

An architectural pattern is a connection motif over labeled instances. A match of it must exist in every architecture
(`enforced`), must exist whenever every label has an instance (`prescriptive`), or must never exist (`restrictive`).
Labels are referential parts owned by the pattern; two labels are two distinct instances, also of the same part usage.
Rules about every instance of a part ("every computer is fed by a sensor") are not patterns; port multiplicities
state them.

```sysml
// When there are two sensors, at least one computer is fed by both
abstract #pattern occurrence sensorComparison : ArchitecturalPattern {
    :>> kind = PatternKind::prescriptive;

    ref part sensorA subsets sensor[1];
    ref part sensorB subsets sensor[1];
    ref part computerA subsets computer[1];

    connection connect sensorA.measurementOut to computerA.measurementIn;
    connection connect sensorB.measurementOut to computerA.measurementIn;
}
```

See `examples/05_ConnectionModeling.sysml` for the full model, and `examples/06_ConnectionRulesNative.sysml` for the
same rule written with standard SysML v2 elements only (named roles and an assert constraint), to compare the two
ways of stating it.

A more complete example, including optimization results, can be found here:
[https://github.com/jbussemaker/GNC-SysML-v2-Demo](https://github.com/jbussemaker/GNC-SysML-v2-Demo)

## More Information and Citation

If you use this library and/or if you want to know more about the background, please refer to and cite:

Bussemaker, J.H. et al., 2026, April.
System Architecture Optimization Using SysML v2: Language Extension and Implementation.
IEEE SysCon 2026, Halifax, Canada.
doi: [10.1109/SysCon66367.2026.11503593](https://dx.doi.org/10.1109/SysCon66367.2026.11503593)
