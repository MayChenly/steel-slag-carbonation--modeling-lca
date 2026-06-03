"""Complete LCA table — both pathways × 37 countries with OWID 2025 CI.

Indirect pathway: from Python port of MATLAB BOF/BF/EAF_country_lca.m (validated bit-for-bit)
Gas-solid pathway: from analytical line formula (chapter 5 §5.3.2.2.3)
"""
import math
import openpyxl
from pathlib import Path

OUT_ROOT = Path('/sessions/gallant-loving-edison/mnt/outputs/lca_python')

# OWID 2025 CI (kg CO2/kWh)
CI = {
    'Austria': 0.11691, 'Belgium': 0.14982, 'Bulgaria': 0.27555, 'Croatia': 0.15850,
    'Czechia': 0.40146, 'Finland': 0.05747, 'France': 0.04144, 'Germany': 0.32965,
    'Greece': 0.31509, 'Hungary': 0.16302, 'Italy': 0.28478, 'Luxembourg': 0.12338,
    'Netherlands': 0.25356, 'Poland': 0.58860, 'Portugal': 0.12791, 'Romania': 0.25075,
    'Slovakia': 0.09485, 'Slovenia': 0.18329, 'Spain': 0.15360, 'Sweden': 0.03526,
    'Türkiye': 0.47474, 'United Kingdom': 0.21741, 'Russia': 0.44973,
    'Canada': 0.19072, 'Mexico': 0.47402, 'United States': 0.38440,
    'Argentina': 0.34600, 'Brazil': 0.10995, 'Chile': 0.28949,
    'Egypt': 0.56323, 'South Africa': 0.69929, 'Iran': 0.65953,
    'China': 0.52534, 'India': 0.67013, 'Japan': 0.47726,
    'South Korea': 0.41706, 'Australia': 0.52518,
}

# Gas-solid pathway analytical lines (Net = a + b·CI, kg CO2/t BOF slag)
# From chapter 5 §5.3.2.2.3 / Fig 1
GS_OPT1 = {'a': -109.2084, 'b': 245.6313, 'name': 'Gas-solid + DAC Opt 1'}
GS_OPT2 = {'a': -142.4536, 'b': 512.5320, 'name': 'Gas-solid + DAC Opt 2'}
# Indirect — for cross-check we also have an analytical version
IND_ANA = {'a': -220.2266, 'b': 824.2100, 'name': 'Indirect aqueous (analytical)'}

# Indirect — from validated Python port of MATLAB
# Energies per 10 kg batch (kWh)
E_INDIRECT_PER_BATCH = {
    'BOF': {
        'E_DAC': 2.5321, 'E_BPMED': 4.8134, 'E_crushing': 0.3999,
        'E_stir_R1': 0.0333, 'E_stir_R2': 0.2078, 'E_fan': 0.2398,
        'E_total': 8.2262, 'CO2_stored': 2.0023,
    },
    'BF': {
        'E_DAC': 2.5485, 'E_BPMED': 4.8134, 'E_crushing': 0.3999,
        'E_stir_R1': 0.0333, 'E_stir_R2': 0.2089, 'E_fan': 0.2429,
        'E_total': 8.2468, 'CO2_stored': 2.0153,
    },
    'EAF': {
        'E_DAC': 2.5639, 'E_BPMED': 4.8134, 'E_crushing': 0.3999,
        'E_stir_R1': 0.0333, 'E_stir_R2': 0.2114, 'E_fan': 0.2476,
        'E_total': 8.2695, 'CO2_stored': 2.0274,
    },
}
SLAG_KG = 10  # batch size

def indirect_net_per_tonne(slag_type, ci):
    """Indirect net emission per tonne at a given CI (kg CO2/t slag)."""
    e = E_INDIRECT_PER_BATCH[slag_type]
    total_em = e['E_total'] * ci
    net_per_batch = total_em - e['CO2_stored']
    conv = 1000 / SLAG_KG
    return net_per_batch * conv

def gs_opt1_net(ci):
    return GS_OPT1['a'] + GS_OPT1['b'] * ci

def gs_opt2_net(ci):
    return GS_OPT2['a'] + GS_OPT2['b'] * ci

def best_pathway_net(slag_type, ci):
    """Return (best_path_name, best_net) at given CI."""
    ind_n = indirect_net_per_tonne(slag_type, ci)
    gs1_n = gs_opt1_net(ci)
    gs2_n = gs_opt2_net(ci)
    paths = [('Indirect', ind_n), ('Gas-solid Opt 1', gs1_n), ('Gas-solid Opt 2', gs2_n)]
    paths.sort(key=lambda x: x[1])  # most negative first
    return paths[0]

def classify_regime(ci):
    if ci > 0.445:
        return 'Deferred'
    elif ci < 0.192:
        return 'Indirect'
    else:
        return 'Gas-solid'

# Compute for all 3 slag types
print('═' * 100)
print('Complete LCA: BOF / BF / EAF × 37 countries × Indirect + Gas-solid Opt 1/2')
print('Per-tonne Net LCA CO2 emissions (kg CO2 / t slag) at OWID 2025 CIs')
print('═' * 100)

for slag in ['BOF', 'BF', 'EAF']:
    print(f'\n### {slag} slag ###')
    print(f'{"Country":<18s} {"CI":>7s} {"Ind":>9s} {"GS-Opt1":>9s} {"GS-Opt2":>9s} {"Best":<18s} {"Best Net":>10s} {"Regime":<10s}')
    print('-' * 100)

    rows = [['Country', 'CI', 'Net_Indirect_kg/t', 'Net_GS_Opt1_kg/t', 'Net_GS_Opt2_kg/t',
             'Best pathway', 'Best Net kg/t', 'Regime']]
    for country, ci in sorted(CI.items(), key=lambda x: x[1]):
        ind_n = indirect_net_per_tonne(slag, ci)
        gs1_n = gs_opt1_net(ci)
        gs2_n = gs_opt2_net(ci)
        best_path, best_n = best_pathway_net(slag, ci)
        regime = classify_regime(ci)
        rows.append([country, ci, ind_n, gs1_n, gs2_n, best_path, best_n, regime])
        print(f'{country:<18s} {ci:>7.4f} {ind_n:>+9.1f} {gs1_n:>+9.1f} {gs2_n:>+9.1f} {best_path:<18s} {best_n:>+10.1f} {regime:<10s}')

    out_path = OUT_ROOT / f'{slag}_full_LCA_OWID2025.xlsx'
    wb = openpyxl.Workbook()
    ws = wb.active
    for r in rows:
        ws.append(r)
    wb.save(out_path)
    print(f'\n→ saved {out_path.name}')

# Aggregate statistics
print('\n')
print('═' * 100)
print('Summary statistics — BOF slag (primary)')
print('═' * 100)
slag = 'BOF'
counts = {'Indirect net-neg': 0, 'GS Opt1 net-neg': 0, 'GS Opt2 net-neg': 0,
          'Indirect': 0, 'Gas-solid': 0, 'Deferred': 0}
for c, ci in CI.items():
    if indirect_net_per_tonne(slag, ci) < 0: counts['Indirect net-neg'] += 1
    if gs_opt1_net(ci) < 0: counts['GS Opt1 net-neg'] += 1
    if gs_opt2_net(ci) < 0: counts['GS Opt2 net-neg'] += 1
    r = classify_regime(ci)
    counts[r] += 1
total = len(CI)
for k, v in counts.items():
    print(f'  {k:<25s}: {v}/{total} = {v/total*100:.0f}%')
