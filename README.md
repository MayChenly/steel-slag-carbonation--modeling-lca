# steel-slag-carbonation--modeling-lca
Process modeling, life-cycle assessment, and figure-generation code for grid-dependent steel slag carbonation pathway analysis.
## Code structure

The code is organized into Python and MATLAB components.

The Python scripts are used for life-cycle assessment aggregation, country-level analysis, and construction of the final LCA workbook. The main scripts include:

- run_lca_pipeline.py: runs the indirect aqueous carbonation LCA loop across the 37 assessed countries.
- gas_solid_lca.py: calculates gas-solid carbonation LCA results across 37 countries and four logistics/DAC scenarios.
- compute_full_lca.py: combines pathway-level results into a per-tonne summary dataset.
- build_complete_LCA_dataset.py: builds the master workbook Complete_LCA_OWID2025.xlsx.

The MATLAB code contains the process models used for carbonation pathway simulation and sensitivity analysis. It is organized into three folders:

- direct_carbonation/: gas-solid carbonation model implementation.
- indirect_carbonation/: indirect aqueous carbonation model implementation, including dissolution and precipitation calculations.
- sensitivity/: single-factor sensitivity analyses for key process parameters.

Together, the Python and MATLAB files reproduce the process-model outputs, life-cycle assessment results, and figure source data used in the manuscript.
