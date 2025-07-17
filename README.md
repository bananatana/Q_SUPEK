# Q_SUPEK 
Instructions for using Q6 and related tools on the [SUPEK cluster](https://www.srce.unizg.hr/napredno-racunanje). Here I will provide running scripts and examples. 

**General informations:**

There are two versions of Q installed on the SUPEK cluster, [Q6](https://github.com/qusers/Q6) and Q6_Esguerra (Q6 fork). Depending on the type of calculation, we will use one or the other version. All other versions (including these two) can also be used locally (and will since preparation of inputs is made locally).

we access them by loading the modules:

```
module load scientific/q6/23.11
```
```
module load scientific/q6-esguerra/21.09
```

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
--
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
> Resulting `.gesp` file goes through antechamber:
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

### FEP-file

At this stage, we need a `.fep` file that specifies which atoms—and associated interactions such as bonds, angles, and dihedrals—undergo changes during the reaction (i.e., the FEP calculation). This information is provided to qtools via a `.qmap` file. You can find examples for both the enzyme and the water/gas phase in the repository.

In addition to the standard `.lib` and `.prm` files used for building the topology, corresponding `.lib` and `.prm` files are also required for the product molecules.

### Equilibration

### FEP-s

### Calibration - referent reaction

### Analysis
