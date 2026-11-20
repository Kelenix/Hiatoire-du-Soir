# Charte graphique — Histoires du Soir

> **Source de vérité visuelle : [`brand-kit.webp`](brand-kit.webp)**, fourni le 20/11/2026 (même image
> en PNG, de meilleure qualité, à la racine du projet : `Kit Identità Dreamy di Histoires du Soir.png`).
> L'application doit le reproduire **à l'identique**. Les couleurs officielles sont les valeurs
> écrites dans le kit ; les valeurs dérivées ont été mesurées au pixel sur l'image (1536 × 1024).
> Toute valeur visuelle passe par le thème Flutter : aucune couleur ni taille en dur dans les widgets.

## 1. Identité

- **Nom** : Histoires du Soir. **Slogan** : « Des histoires magiques pour de beaux rêves »
  (capitales, lettres très espacées).
- **Mascotte** : un renardeau orange endormi sur un nuage lavande, devant une lune dorée et des étoiles.
- **Ambiance** : la nuit. Violet profond, halos lumineux, or chaud, rendu doux et brillant.
- **Fond nuit sur tous les écrans** (confirmé le 20/11/2026) : fond bleu nuit, cartes foncées, textes
  clairs, comme dans le kit. Pas de version à fond clair. Les fiches couleur sur fond lavande servent
  seulement à présenter la palette.

## 2. Couleurs officielles (écrites dans le kit)

| Nom | Hex | Usage |
|-----|-----|-------|
| Nuit | `#0B0B2B` | fond de l'application |
| Violet | `#6C5CE7` | couleur principale, actions |
| Lavande | `#A78BFA` | couleur secondaire, contours, éléments actifs |
| Or | `#FFC857` | étoiles, lune, Premium, mises en avant |
| Crème | `#FFF8E6` | texte chaud (corps des histoires en lecture) |

## 3. Couleurs dérivées (mesurées sur le kit)

| Élément | Valeur |
|---------|--------|
| Surface des cartes | `#16143C` |
| Bordure des cartes | `#2A1C5E`, 1,5 dp |
| Halos du fond (coins, dégradés radiaux vers transparent) | `#6929C2` |
| Texte principal (interface) | `#F7F6FF` |
| Texte secondaire (sous-titres, légendes) | `#B4AED0` |
| Slogan | `#E8E4FF` |
| Titre du logo (dégradé vertical) | `#EDE9FF` → `#DED6FB` |
| **Dégradé « Magie »** (bouton principal, de gauche à droite) | `#8873FC` 0 % · `#7856FB` 20 % · `#814CFF` 40 % · `#9A4EEB` 55 % · `#C26BCB` 72 % · `#DD89A6` 82 % · `#F5A583` 92 % · `#FEBB77` 100 % |
| Bouton secondaire | fond transparent, contour `#AA90CB`, 2 dp |
| Bouton rond « favori » | fond `#442F86`, contour `#AF8CE3`, cœur `#F471C7` |
| Rose des cœurs (favoris) | `#F67BBE` |
| Tuiles d'icônes | dégradé vertical `#673EB5` → `#5434A3`, bord `#2B136B` |
| Icône de l'application | dégradé vertical `#9643D1` → `#4A37D0` |

## 4. Typographie

| Police | Usage | Graisses |
|--------|-------|----------|
| **Nunito** | titres, interface, boutons | Black/ExtraBold (logo, grands titres), Bold (titres de cartes, boutons) |
| **Inter** | textes, détails, légendes | Regular, Medium |

Les deux polices (licence libre OFL) sont **intégrées à l'application** : aucun chargement depuis les
serveurs de Google (conformité « Kids » et affichage sans connexion).

## 5. Formes et éléments

- **Boutons** : pilules (arrondi complet), hauteur 56 dp pour le bouton principal, icône à gauche.
- **Cartes** : arrondi 20 dp, fond `#16143C`, bordure fine, légère transparence.
- **Tuiles d'icônes** : carrés arrondis (arrondi ≈ 24 % du côté), aspect brillant.
- **Éléments graphiques** : étoile dorée, lune en croissant dorée, nuage lavande, scintillements.
- **Fond** : Nuit `#0B0B2B` avec halos violets dans les coins et étoiles scintillantes discrètes.

## 6. Composants du kit et règles d'usage

| Composant | Rendu | Où |
|-----------|-------|----|
| Bouton principal « ▶ Créer une histoire » | dégradé Magie, texte blanc Nunito Bold, ombre douce | Espace Enfant |
| Bouton secondaire « 👑 Passer Premium » | contour lavande, couronne dorée, texte blanc | **Espace Parents uniquement** (aucun achat dans l'Espace Enfant, INTAKE §5.1) |
| Bouton rond ♥ | favori | lecture d'une histoire, listes |
| Icône livre | histoires | navigation |
| Icône lecture | écouter | lecteur audio |
| Icône cœur | favoris | navigation, lecture |
| Icône couronne | Premium | Espace Parents |
| Icône famille | Espace Parents (entrée protégée par le contrôle parental) | navigation |

## 7. Univers visuels (illustrations des thèmes)

Le kit fournit quatre univers ; correspondance proposée avec le catalogue de thèmes (plan, H6) :

| Univers du kit | Utilisation |
|----------------|-------------|
| Forêt lumineuse | thème Forêt magique |
| Dragon | thème Chevaliers et dragons |
| Maison enneigée | thème Noël |
| Château sous la lune | illustration d'accueil de l'Espace Enfant |

À créer **dans le même style et au même format** (1448 × 1086) : Animaux, Océan, Espace, Dinosaures,
Pirates, Halloween.

## 8. Fichiers sources haute définition

Inventaire du 20/11/2026 (dossier `docs/design/`). Les fichiers seront copiés et renommés dans les
ressources de l'app en phase 4 ; les originaux restent ici.

### Reçus et vérifiés

| Fichier | Contenu | Taille | État |
|---------|---------|--------|------|
| `… 14_25_00-1.png` | mascotte : renard endormi, lune, nuage, étoile | 1254 × 1254, transparent | ✅ net sur le fond nuit |
| `… 14_25_01-2.png` | icône livre | 1254 × 1254, transparent | ✅ |
| `… 14_25_02-3.png` | icône lecture | 1254 × 1254, transparent | ✅ |
| `… 14_25_03-4.png` | icône cœur | 1254 × 1254, transparent | ✅ net sur le fond nuit |
| `… 14_25_03-5.png` | icône couronne | 1254 × 1254, transparent | ✅ |
| `… 14_25_04-6.png` | icône famille | 1254 × 1254, transparent | ✅ |
| `… 14_26_26-1.png` | univers château sous la lune | 1448 × 1086 | ✅ |
| `… 14_26_26-2.png` | univers dragon | 1448 × 1086 | ✅ |
| `… 14_26_27-3.png` | univers forêt magique | 1448 × 1086 | ✅ |
| `… 14_26_29-4.png` | univers maison enneigée | 1448 × 1086 | ✅ |
| `… 14_26_29-5.png` à `… 14_26_33-9.png` | fiches des 5 couleurs | 1254 × 1254 | ✅ confirment la palette (référence, pas utilisées dans l'app) |

### Fabriqués par moi à partir des fichiers reçus

| Élément | Comment |
|---------|---------|
| Icône de l'application (1024 × 1024) et icône adaptative Android | mascotte posée sur le carré arrondi en dégradé `#9643D1` → `#4A37D0`, comme dans le kit |
| Logo texte « Histoires du Soir » | Nunito Black, dégradé blanc-lavande, étoile dorée et trait lumineux, comme dans le kit |
| Tuiles d'icônes | icônes reçues posées sur le carré arrondi en dégradé du §3 |

### Encore manquants (même style, à générer avec le même outil)

| Élément | Format |
|---------|--------|
| Étoile, lune en croissant, nuage, scintillements (4 fichiers) | PNG transparent ≥ 1024 px |
| Logo « lune + étoile » et monogramme « H » (2 fichiers) | PNG transparent ≥ 1024 px |
| Illustration enfant + renard qui lisent au lit (vue dans la tablette du kit) | PNG ≥ 1448 px de large |
| Univers Animaux, Océan, Espace, Dinosaures, Pirates, Halloween (6 fichiers) | PNG 1448 × 1086 |

En attendant, les écrans concernés utilisent des **découpes provisoires du kit**, remplacées dès
réception, au plus tard avant la publication (J4).

## 9. Accessibilité dans la charte

- Texte principal sur cartes et fond : contraste supérieur à 7:1.
- Bouton principal : la fin du dégradé (or) est claire ; on garde l'ombre douce du kit sous le texte
  blanc pour préserver la lisibilité.
- Zones tactiles ≥ 48 dp ; tailles de police dynamiques respectées.
- Animations lentes et douces (scintillement des étoiles), désactivées si « réduire les animations »
  est actif sur le téléphone.
