# Design system — Histoires du Soir

> Phase 3, 20/11/2026. Rôle : ui-ux-designer. Traduit `charte-graphique.md` (source de vérité) en
> thème Flutter et composants. Aucune valeur visuelle en dur dans un écran : tout vient d'ici.

## 1. Thème Flutter

Fond nuit uniquement (ADR-012) : un seul `ThemeData` sombre, Material 3.

| Rôle `ColorScheme` | Valeur |
|--------------------|--------|
| `primary` / `onPrimary` | `#6C5CE7` / `#FFFFFF` |
| `secondary` | `#A78BFA` |
| `tertiary` (or) | `#FFC857` |
| `surface` / `onSurface` | `#16143C` / `#F7F6FF` |
| `onSurfaceVariant` (texte secondaire) | `#B4AED0` |
| `outline` | `#2A1C5E` |
| `error` (dérivé, absent du kit, réservé aux formulaires parents) | `#FF8FA3` |
| `scaffoldBackgroundColor` | `#0B0B2B` |

Jetons hors `ColorScheme` dans `lib/core/theme/app_colors.dart` (`AppColors`, `AppGradients`,
ADR-022) : crème, slogan, cœur, halo, dégradés Magie, tuile et titre (valeurs : charte §3).

## 2. Typographie

| Style | Police | Taille / interligne | Usage |
|-------|--------|---------------------|-------|
| `displayLarge` | Nunito Black | 34 / 40 | logo, titre d'accueil |
| `headlineMedium` | Nunito ExtraBold | 26 / 32 | titres d'écran |
| `titleMedium` | Nunito Bold | 18 / 24 | titres de cartes, boutons |
| `labelLarge` | Nunito SemiBold | 15 / 20 | libellés, onglets |
| `bodyLarge` | Inter Regular | 16 / 24 | textes |
| `bodySmall` | Inter Regular | 13 / 18, `#B4AED0` | légendes |
| Histoire | Inter Regular | 18, 20 ou 24 (réglage) / × 1,6, crème | lecture |
| Slogan | Inter Medium | 12, espacement 4, capitales, `#E8E4FF` | accueil |

Les tailles suivent le réglage de texte du téléphone (plafonné à × 1,6 pour ne pas casser les écrans).

## 3. Espacements, formes, ombres, mouvement

- **Espacements** : 4 · 8 · 12 · 16 · 24 · 32 · 48 ; marge d'écran 20.
- **Arrondis** : cartes et illustrations 20 · champs 16 · tuiles d'icônes 24 % du côté · boutons en pilule.
- **Bordures** : cartes 1,5 `#2A1C5E` ; bouton secondaire 2 `#AA90CB`.
- **Lueurs** (pas d'ombres grises) : seulement autour des étoiles, de la lune et du cadenas (halo or
  à 50 %). Tuiles et boutons n'en ont pas, comme dans le kit : un halo violet flouté formait un
  reflet sombre sur le fond nuit (retiré le 20/11/2026).
- **Mouvement** : retour tactile 150 ms (légère réduction d'échelle à 0,97) ; transitions 300 ms en
  fondu ; étoiles qui scintillent lentement (2 à 4 s). Tout est coupé si « réduire les animations »
  est actif.
- **Zones tactiles** ≥ 48 dp partout ; ≥ 64 dp dans l'Espace Enfant.

## 4. Composants (`lib/shared/widgets/`)

| Composant | Rendu (kit) | États |
|-----------|-------------|-------|
| `NightBackground` | fond `#0B0B2B`, halos violets dans les coins, étoiles scintillantes | animé / statique |
| `MagicButton` | pilule 56 dp, dégradé Magie, texte blanc Nunito Bold avec ombre douce, icône à gauche, lueur | normal · appuyé · désactivé (40 %) · chargement (étoile qui tourne) |
| `OutlineButton` | pilule 56 dp, contour `#AA90CB`, fond transparent, icône or à gauche | normal · appuyé · désactivé |
| `RoundIconButton` | rond 56 dp, fond `#442F86`, contour `#AF8CE3` | normal · actif (cœur plein `#F67BBE`) · désactivé |
| `NightCard` | fond `#16143C`, bordure fine, arrondi 20 | normal · appuyé |
| `IconTile` | carré arrondi en dégradé violet, icône 3D du kit au centre | 64 dp (Parents) · 88 dp (Enfant) |
| `ThemeCard` | illustration 4:3 arrondie, nom du thème dessous ; cadenas doré si verrouillé | accessible · verrouillé · chargement (squelette) |
| `StarsLeft` | 3 étoiles, allumées (or) ou éteintes (contour lavande) | 0 à 3 |
| `ParentalKeypad` | consigne en toutes lettres, clavier 0-9 en tuiles rondes | saisie · erreur (secousse douce) · réussite |
| `AudioPlayerBar` | bouton lecture du kit, barre de progression en dégradé Magie, durées | prêt · chargement · lecture · pause · verrouillé |
| `StoryText` | texte crème, marges larges, titre Nunito ExtraBold | — |
| `MascotState` | mascotte + titre + texte + action | vide · erreur (avec « Réessayer ») · hors connexion |
| `CreatingAnimation` | mascotte qui respire, étoiles qui montent, phrase rassurante tournante | en cours |
| `TextFieldNight` | fond `#16143C`, contour lavande à la saisie, erreur en `#FF8FA3` | normal · focus · erreur · désactivé |
| `SkeletonList` | cartes nuit avec reflet lavande léger | chargement |

## 5. États obligatoires par écran

Chaque écran gère : **chargement** (squelette ou animation), **vide** (`MascotState`), **erreur**
(`MascotState` + Réessayer), **hors connexion** (bandeau ou `MascotState`) et **données**.
Côté enfant, les messages sont courts, doux et portés par la mascotte ; côté parent, ils sont précis.

## 6. Accessibilité

- Chaque icône et illustration porte un libellé (`Semantics`) lisible par TalkBack et VoiceOver.
- Contrastes : texte principal et crème > 7:1 sur fond et cartes ; texte secondaire > 4,5:1.
- Ordre de lecture logique ; le défi parental est utilisable au lecteur d'écran.
- Pas d'information portée par la couleur seule (cadenas + libellé « Demande à un parent »).
