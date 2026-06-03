# steel-slag-carbonation--modeling-lca
Process modeling, life-cycle assessment, and figure-generation code for grid-dependent steel slag carbonation pathway analysis.
│   ├── python/                             ← Python implementation
│   │   ├── run_lca_pipeline.py             ← Indirect 37-country LCA loop
│   │   ├── gas_solid_lca.py                ← Gas-solid 37-country × 4 scenarios LCA
│   │   ├── compute_full_lca.py             ← Combined per-tonne summary
│   │   └── build_complete_LCA_dataset.py   ← Builds Complete_LCA_OWID2025.xlsx
│   └── matlab/                             ← MATLAB implementation
│       ├── direct_carbonation/             ← Gas-solid pathway
│       ├── indirect_carbonation/           ← Indirect aqueous pathway
│       └── sensitivity/                    ← Single-factor analyses
