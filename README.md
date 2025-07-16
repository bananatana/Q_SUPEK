# Q_SUPEK
Instructions for using Q6 and related tools on the [SUPEK cluster](https://www.srce.unizg.hr/napredno-racunanje). Here I will provide running scripts and examples. 

**General informations:**

There are two versions of Q installed on the SUPEK cluster, [Q6](https://github.com/qusers/Q6) and Q6_Esguerra (Q6 fork). Depending on the type of calculation, we will use one or the other version. All other versions (including these two) can also be used locally (and will since preparation of inputs is made locally).

we access them by loading the modules:

```module load scientific/q6/23.11```
```module load scientific/q6-esguerra/21.09```

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

---

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

---

**Usage on Supek**

On the *Supek* cluster, LigParGen is already installed and can be used as follows:

```module load scientific/pymemdyn  # Load the module that includes LigParGen```

Once the module is loaded, the ligpargen command becomes available in the path and can be used according to standard usage:



### FEP-file

### Equilibration

### FEP-s

### Calibration - referent reaction

### Analysis
