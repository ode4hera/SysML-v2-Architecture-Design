package SA_FunctionAllocationChoiceExample {
    doc /*
    Example of definition of function allocation choices (excluding component selection).
    - There are two functions: Provide Energy 1 and 2 (for "consumers" 1 and 2)
    - There are two components that can fulfill these functions: Power System 1 and 2
    */
    private import ArchitectureDesign::*;

    action def ProvideEnergy1;
    action def ProvideEnergy2;

    part def PowerSystem1;
    part def PowerSystem2;

    abstract #architectureDesignSpace part def System {

        action provideEnergy1 : ProvideEnergy1;
        action provideEnergy2 : ProvideEnergy2;

        part powerSystem1 : PowerSystem1 {
            perform provideEnergy1;
            perform provideEnergy2;
        }
        part powerSystem2 : PowerSystem2 {
            perform provideEnergy1;
            perform provideEnergy2;
        }

    }

    #architecture part def SystemBoth specializes System {

        part redefines powerSystem1 {
            perform action :>> provideEnergy1;
        }

        part redefines powerSystem2 {
            perform action :>> provideEnergy2;
        }

    }

    #architecture part def SystemSingle :> System {

        part redefines powerSystem1 {
            perform action :>> provideEnergy1;
            perform action :>> provideEnergy2;
        }
        
        part redefines powerSystem2 = null;

    }

}
