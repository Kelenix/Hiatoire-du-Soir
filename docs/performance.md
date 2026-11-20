# Performance — Histoires du Soir

> Phase 5, 20/11/2026. Rôle : performance-engineer. Mesures sur l'émulateur Android `histoires_pixel`
> (Pixel 8, Android 15, x86_64, carte graphique émulée) et le Supabase local. Un émulateur ne remplace
> pas un vrai téléphone : les chiffres de dessin à l'écran sont à confirmer sur un Android d'entrée de
> gamme pendant le test interne (phase 6).

## 1. Budgets

| Mesure | Budget | Mesuré | Verdict |
|--------|--------|--------|---------|
| Démarrage à froid (première image) | < 2 s | 1,7 à 2,0 s, médiane 1,87 s (8 essais, version de production) | ✅ |
| Calcul d'une image (fil de l'interface) | < 16 ms | moyenne 0,8 à 1,6 ms, 99ᵉ centile 2,6 à 5,5 ms | ✅ |
| Dessin d'une image (fil graphique) | < 16 ms | moyenne 17 à 22 ms sur émulateur | ⚠️ à mesurer sur un vrai téléphone |
| Mémoire en usage | stable, < 150 Mo | 89 Mo (PSS) après accueil, thèmes et lecture | ✅ |
| Taille de l'APK (arm64) | < 30 Mo | 27,3 Mo installable ; téléchargement estimé ≈ 12 Mo via le Play Store (bundle compressé) | ✅ |
| Lectures du backend (p95) | < 500 ms | 6 à 67 ms (k6, jusqu'à 50 utilisateurs) | ✅ |
| Création refusée par le serveur (p95) | < 1,5 s | 30 à 209 ms | ✅ |
| Première écoute avec une voix apaisante | < 10 s | non mesurable sans clé Google | ⏳ |

## 2. Mesures et optimisations

**Démarrage.** Avant : quatre initialisations enchaînées (orientation, lecteur en arrière-plan,
session audio, Supabase), 1,5 à 3,3 s (médiane 2,1 s, 5 essais). Après : lancées ensemble
(`lib/main.dart`), 1,7 à 2,0 s (médiane 1,87 s, 8 essais), avec beaucoup moins d'écart.

**Fluidité.** Mesurée en mode « profile » par le test de bout en bout (`integration_test/app_test.dart`,
`watchPerformance`), sur trois glissés vers le bas puis trois vers le haut :

| Écran | Calcul moyen / 99ᵉ c. | Dessin moyen / 90ᵉ c. | Images hors budget |
|-------|-----------------------|-----------------------|--------------------|
| Thèmes (étoiles animées) | 1,6 / 5,5 ms | 21,7 / 31,1 ms | 328 sur 431 |
| Lecture d'une histoire | 0,8 / 2,6 ms | 17,0 / 25,6 ms | 280 sur 570 |

Le code de l'app est très léger. Le dessin, lui, dépasse le budget, mais aussi sur l'écran de
lecture qui n'a pas d'animation : la cause est la carte graphique émulée. Optimisation faite quand
même : les étoiles qui scintillent ont leur propre calque (`RepaintBoundary`) et ne font plus
redessiner l'écran à chaque image. Si un vrai téléphone confirme un dessin lent, la piste suivante
est de remplacer les trois halos en dégradé plein écran par une image de fond.

**Batterie.** Les étoiles scintillent en continu sur l'accueil et les listes, sauf si le téléphone
est réglé pour réduire les animations. L'écran de lecture, celui qui reste allumé le soir, n'a pas
d'étoiles : il ne redessine rien quand rien ne bouge.

**Données et réseau.** Pas de requêtes N+1 ; favoris paginés par 20 ; catalogue et droits gardés en
mémoire ; audio des voix apaisantes gardé sur le serveur ; fichiers audio de la voix du téléphone
nommés par histoire et effacés à l'écoute suivante (jusqu'à 25 Mo pour 10 minutes).

**Taille.** Moteur Flutter 11,3 Mo, code Dart 7,7 Mo, ressources 2,1 Mo (polices Inter et Nunito,
images), icônes et écran de démarrage 3,2 Mo. Publication en bundle Android (phase 6) : chaque
téléphone ne télécharge que son architecture.

## 3. Reproduire les mesures

```powershell
flutter build apk --release --target-platform android-x64 --dart-define-from-file=env/dev.json
```

Démarrage : `adb shell am start -W -n fr.histoiresdusoir.app/.MainActivity` (ligne `TotalTime`), après
`adb shell am force-stop fr.histoiresdusoir.app`. Fluidité : commande du test de bout en bout dans
`docs/qa/test-plan.md` ; résultats dans `build/integration_response_data.json`.
