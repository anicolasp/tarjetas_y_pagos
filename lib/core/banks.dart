/// Banks in the Dominican Republic, for the card form autocomplete. Any
/// other name can still be typed.
const dominicanBanks = [
  'Banreservas',
  'Banco Popular',
  'BHD',
  'Scotiabank',
  'APAP',
  'Banco Santa Cruz',
  'Promerica',
  'Banesco',
  'Banco Caribe',
  'BDI',
  'Banco Vimenca',
  'Banco López de Haro',
  'Banco Ademi',
  'Asociación Cibao',
  'Qik',
];

/// How each bank in [dominicanBanks] may be printed on a card, normalized
/// (lowercase, no accents). The card scan picks the longest match, so
/// "asociacion popular" (APAP) wins over "popular" (Banco Popular). Words
/// common on other cards (an address, a co-brand) are not aliases alone.
const bankAliases = {
  'Banreservas': ['banreservas', 'banco de reservas'],
  'Banco Popular': ['banco popular', 'popular dominicano', 'popular'],
  'BHD': ['bhd', 'bhd leon'],
  'Scotiabank': ['scotiabank', 'scotia'],
  'APAP': ['apap', 'asociacion popular'],
  'Banco Santa Cruz': ['santa cruz'],
  'Promerica': ['promerica'],
  'Banesco': ['banesco'],
  'Banco Caribe': ['banco caribe'],
  'BDI': ['bdi'],
  'Banco Vimenca': ['vimenca'],
  'Banco López de Haro': ['lopez de haro'],
  'Banco Ademi': ['ademi'],
  'Asociación Cibao': ['asociacion cibao'],
  'Qik': ['qik'],
};

/// Card colors offered in the form (ARGB).
const cardColors = [
  0xFF0F766E, // teal (brand)
  0xFF1D4ED8, // blue
  0xFF6D28D9, // violet
  0xFFBE123C, // rose
  0xFFB45309, // amber
  0xFF15803D, // green
  0xFF334155, // slate
  0xFF111827, // black
];
