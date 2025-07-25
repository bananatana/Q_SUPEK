# Q_SUPEK 
Instructions (idiot proof, I hope!) for using Q6 and related tools on the [SUPEK cluster](https://www.srce.unizg.hr/napredno-racunanje). Here I will provide running scripts and examples. 

**General informations:**

There are two versions of Q installed on the SUPEK cluster, [Q6](https://github.com/qusers/Q6) and Q6_Esguerra (Q6 fork). Depending on the type of calculation, we will use one or the other version. All other versions (including these two) can also be used locally (and will since preparation of inputs is made locally).

we access them by loading the modules:

```
module load scientific/q6/23.11
```
```
module load scientific/q6-esguerra/21.09
```
Additionally, Q6 should be installed locally, along with the utilities required for the specific type of calculation we are performing.

## EVB reaction profiles

Here I provide an example workflow for studying the MAO A inhibition reaction with the inhibitor chlorgyline (CHG). While the focus here is on this specific system, the general approach can be adapted to other systems with appropriate modifications.

It is important to note that the reaction mechanism should be well-established—either experimentally or computationally—before proceeding. A clear understanding of the involved reactants and products is essential.

In the case of MAO A inhibition by CHG, the proposed mechanism involves a hydride transfer from the Cα atom of the inhibitor to the N5 position of the covalently bound flavin cofactor (FAD). This mechanism is described in detail in the following references:

[Eur. J. Org. Chem. (2011)](https://doi.org/10.1002/ejoc.201100873),
[ACS Chem. Neurosci. (2019)](https://doi.org/10.1021/acschemneuro.9b00147),
[Int. J. Mol. Sci. (2020)](https://doi.org/10.3390/ijms21176151)
... and others :) 

**Three distinct systems are modeled to study the reaction environment effects:**

1. Gas phase:
    Lumiflavin (LFN) + CHG
2. Aqueous phase:
    LFN + CHG + explicit water sphere
3. Enzymatic environment:
    MAO A enzyme (covalently bound FAD cofactor) + CHG + explicit water sphere

In the gas and water phase models, the full FAD cofactor is replaced with lumiflavin (LFN) to simplify the system while retaining the essential reactive moiety.

### System preparation - topology

The first step involves generating the system topology and preparing the initial simulation setup, including solvation and definition of the spherical region (if applicable).

Start with a `.pdb` file that contains the appropriate reactants:

- For **gas-phase** and **water-phase** systems: `CHG + LFN`
- For **enzyme systems**: `enzyme–FAD + CHG`

**Force Field Parameters**

This workflow uses the **OPLS-AA** force field.  
If you're unfamiliar with force fields, it's strongly recommended to review their fundamentals before proceeding.

**Required files:**

- `all.prm` – master parameter file
- `Qoplsaa_HUGO.lib` – standard OPLSAA library for amino acids
- `lfn.final.lib` – custom library for lumiflavin (LFN), consistent across MAO A and MAO B systems

> ⚠️ **Important:**
> - All parameters must be combined into a **single `.prm` file**.
> - If you add a new ligand or amino acid residue, include its parameters in this file.
> - Atom names must be **unique** within each molecule/residue.
> - You can include multiple `.lib` files. These act as interpreters, linking atom names in the `.pdb` file to the correct atom types defined in the parameter file.

**Ligand parameterization (OPLS-AA):**

For ligand parameterization under the **OPLS-AA** force field, the recommended tool is **LigParGen**. Parameters can be generated using either:

- The [LigParGen web server](https://zarbi.chem.yale.edu/ligpargen/)
- The terminal version available on [GitHub](https://github.com/Isra3l/ligpargen) (**recommended**)

**Usage on Supek**

On the *Supek* cluster, LigParGen is already installed and can be used as follows:

```
module load scientific/pymemdyn  # Load the module that includes LigParGen
```

Once the module is loaded, the ligpargen command becomes available in the path and can be used according to standard usage:

```
app ligpargen -h                      # Displays help
app ligpargen -i CHG.pdb -r CHG -c 0 # Generates parameters for neutral CHG
```
⚠️ Note: Be mindful of the charge assigned to the molecule, as it affects the geometry—even if you plan to recalculate the charges later using a different method.

>**Files and Integration**
> - LigParGen generates parameter files for several software packages. For use with Q, you’ll need the `.lib` and `.prm` files.
> - Make sure to merge the `.prm` file into the master parameter file used in your simulation.
> - Ensure atom names are unique and consistent with those in the `.pdb` file.

>**Charge Considerations**
> - You may keep the partial charges assigned by LigParGen.
> - For higher accuracy, charges can be recalculated using Gaussian16 (e.g., RESP method), and updated manually in the .prm file.
> - If the ligand is treated as fully reactive (i.e., all atoms are Q-atoms), charge groups are not necessary.
However, for passive ligands, charge groups must be defined in the .lib file. These are sets of adjacent atoms with an integer total charge.

>**RESP Charge Calculations**
>
> Input for Gaussian16 calculation looks like this: 
>```
>chk=chg
>#HF/6-31G* SCF=tight Test Pop=MK iop(6/33=2) iop(6/42=6) opt
># iop(6/50=1)
>
>CHG
>
>0 1
> C                   -0.95700000   -4.37800000    2.30700000
> 
>/lustre/home/ttandari/MAO_A_2025/CHG_RESP/chg.gesp
>
>```
> Resulting `.gesp` file goes through antechamber (which you install as a part of Ambertools package):
>
>```
>antechamber -fi gesp -i CHG.gesp -fo ac -o CHG.ac -nc 0
>```
>Resulting `.ac` contains RESP charges. You can use it in `.lib` file. 
>Be mindful about netto charge (-nc). 

**Final topology bulding**

Once all the necessary files are gathered, we proceed to build the topology. You can find input examples in the repository. In my case, the center of the sphere was defined as the N5 atom of FAD (or LFN). Both the sphere center and its radius can be adjusted in the `.inp` file.

To generate the topology, use the following command:

```
Qprep6 < qprep.inp > qprep.out
```

Always check the qprep.out file to ensure everything completed successfully, and examine the newly created `.pdb` file.

The most common issues arise from duplicate parameters—these can typically be removed, especially if they don’t belong to your custom residue (or any amino acid).

### FEP file

At this stage, we need a `.fep` file that specifies which atoms—and associated interactions such as bonds, angles, and dihedrals—undergo changes during the reaction (i.e., the FEP calculation). This information is provided to qtools via a `.qmap` file. You can find examples for both the enzyme and the water/gas phase in the repository.

Here, we use [qtools](https://github.com/mpurg/qtools/tree/master). You can install in locally. Some computer architectures may not work well with this installation and instead require a Python 2 environment. This can be easily addressed by using a virtual environment with pyenv. For example, I had to set this up on macOS, but there should be no issues on Linux.

In addition to the standard `.lib` and `.prm` files used for building the topology, corresponding `.lib` and `.prm` files are also required for the product molecules. In the repository, you can find an example illustrating the structure of a .qmap file and the resulting .fep file, though these will naturally vary depending on the specific case.

Locally, where **qtools** are installed, we run the following command:

```
q_makefep_old.py -s  your_start.pdb -m example.qmap -p *.prm -l *lib -o example.fep --index
```
The resulting .fep file will include data on the parameter changes, but certain elements will need to be edited manually (these are marked as <FIX> in the .fep file). This primarily concerns bonds that break during the reaction. For such bonds, the Morse potential is used instead of the standard harmonic potential to allow bond breaking. In my .fep file, you can see the adjustments I made for the FAD (LFN) + CHG system. For other cases, you should consult the relevant literature.

### Equilibration

Now that everything is prepared, we can proceed with running the simulation. Before starting the FEP calculations, the system must be equilibrated. The equilibration approach varies depending on whether the simulation is in the gas phase, water phase, or enzyme environment:

> - Gas phase: Typically, a single relaxation step is sufficient.
> - Water phase and enzyme: Equilibration is performed in multiple steps (I used 10), during which the restraints are gradually released, and the system is heated. The specific restraints applied will, of course, depend on the system.
> - Water and gas phase: Stronger restraints are often required because the system is not exactly at a minimum, whereas in the enzyme environment, the surroundings are already "adapted" to accommodate the ligand.
I have included my input files and initial .pdb structures in the repository for reference. You can also generate similar inputs automatically using the q_genrelax.py script (which I highly recommend!) in combination with the provided [templates](https://github.com/mpurg/qtools/tree/master/template_examples).

The logic behind applying restraints is as follows: we start by restraining the entire system and then gradually loosen these restraints, eventually applying them only to the heavy atoms, and so on. A useful trick to prevent the system from falling apart is to apply gentle restraints between the reactive atoms.

Once the equilibration is complete, it is important to visualize the resulting trajectories in PyMOL or VMD to verify that the simulation behaved as expected and that our parameters are appropriate (in particular, to check whether the system remained intact).

The script for running the job on Supek is available in the repository. Simply adapt it as needed and launch the run with:

```
qsub Q6_supek_eq.pbs
```

### FEP-s

We have now reached the stage of performing the FEP simulation. FEP is typically carried out in multiple replicates to ensure sufficient sampling of the conformational space.

The first step is to generate the necessary input files. This is done using the **q_genfeps.py** script (part of qtools) as follows:

```
q_genfeps.py genfeps_template.proc last_eq.inp inp
```

Here:
- `genfeps_template.proc` is a template that defines the FEP procedure.
- `last_eq.inp` is the input file from the final step of equilibration.

Running this command will create 10 replicas, each with 51 lambda steps. These parameters can, of course, be adjusted as needed. In fact, anything within the template—such as the number of steps, time step, or restraints—can be customized. How much is required depends on both the specific system and your goals.

I’ve included my template file in the repository so you can see how it works, including how the restraints are defined within it.

In short, the script will generate as many folders as the number of replicas you choose, each containing all the necessary inputs (including the two pre-FEP equilibration inputs and the FEP inputs).

To avoid running the simulations one folder at a time, I’ve provided two helper scripts`run_all.sh` and `q_run_feps.pbs` — which should be placed in the main folder containing all replicas.
You can then execute:

```
bash run_all.sh
```

This script will copy `q_run_feps.sh` into each replica folder and execute it automatically.

### Calibration - reference reaction

In these simulations, our focus is on examining how the environment affects the reference reaction. We already know the mechanism of this reference reaction, as well as its parameters—ΔG‡ and ΔGr. These reference values may come from experimental data or from other computational approaches (such as a QM model reaction or QM/MM calculations). I won’t go into detail here on how to determine these parameters, but you will need to have them in place for the subsequent steps.

In the first step, we will map the reference reaction using q_automapper.py (part of qtools, please run q_automapper.py -h to see options). In my case, this is mapped to the gas-phase reference reaction. This step allows us to obtain the parameters Hij and α, which will be used to determine ΔG‡ and ΔGr in different environments (such as water or an enzyme, in my case).

Navigate to the desired folder and run something like following command:

```
 q_automapper.py 38.81 34.99 0 0 --nt 1
```

Of course, this is just my example, where ΔG‡ = 38.81 and ΔGr = 34.99. The values 0 and 0 are the initial guesses for Hij and α, and nt denotes the number of threads. If the calculation does not converge, you can experiment with the options—be creative!
Here’s a refined version of your text:

q_mapper will generate the next command, which you will then apply to your non-reference reactions.

I would strongly recommend that, before proceeding with this step, you take the time to read the relevant literature to understand the meaning and significance of these parameters. A good starting point is this [article](https://doi.org/10.1039/B907354J.).

### Analysis & non-reference reactions 

** **

**Vizualization:**
When it comes to visualization, I always emphasize — and will continue to emphasize — the importance of checking trajectories visually. A quick inspection to ensure that everything is in place and all components of the system are present can save months of wasted effort.

The `.dcd` files can simply be loaded on top of the initial `.pdb` file in your preferred visualization tool (e.g., PyMOL or VMD). For equilibration runs, loading all trajectories is usually manageable, but for FEP phase analysis, this can become problematic.

To address this, I created a small VMD script, `concat_dcds.tcl`, which merges all FEP trajectories into a single file, `all.dcd`. The script can be executed with:

```
vmd -dispdev text -e concat_dcds.tcl
```

Before running it, make sure to set the correct paths within the script and ensure that VMD is included in your system’s PATH.
