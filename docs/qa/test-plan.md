# Plan de test — Histoires du Soir

> Phase 5, 20/11/2026. Rôle : qa-engineer. Les tests suivent le risque : ce qui coûte (IA, voix,
> achats), ce qui touche l'enfant (contenu, prénom, espace protégé) et ce qui casserait la soirée
> (écoute, création) sont couverts à plusieurs niveaux.

## 1. Inventaire

| Type | Où | Nombre | Lancé par la CI |
|------|----|--------|-----------------|
| Unitaires et widgets (Flutter) | `test/` | 100 | oui |
| dont accessibilité (zones tactiles, libellés, contraste, texte ×1,6) | `test/accessibility_test.dart` | 23 | oui |
| Base de données et RLS (pgTAP) | `supabase/tests/database/` | 107 | oui |
| Fonctions serveur (Deno) | `supabase/functions/**/*.test.ts` | 9 | oui |
| Bout en bout + fluidité, sur émulateur | `integration_test/app_test.dart` | 1 parcours | non (voir §4) |
| Charge du backend (k6) | `tests/load/backend.js` | 3 profils | non (voir §4) |
| Recherche de secrets (gitleaks) | `.github/workflows/ci.yml` | — | oui |

## 2. Couverture par risque

| Risque | Ce qui le couvre |
|--------|------------------|
| Coût Claude (R5) | quota, crédits, tentatives bornées, demande rejouée sans nouvel appel (SQL) ; création refusée sous charge (k6) |
| Coût voix (R5) | droits vérifiés avant synthèse, écoute gratuite unique (SQL) ; audio gardé (essai émulateur) |
| Prénom de l'enfant (ADR-017) | jamais dans la demande à Claude, remplacé dans le texte du parent, élision (Deno, Flutter) ; signalements anonymes (SQL) |
| Contenu inadapté (R1) | contrôle par Claude (code relu) ; signalement et retrait (SQL, Flutter) |
| Accès aux données d'autrui | RLS de chaque table et du stockage, fonctions serveur seules (SQL) |
| Achats (H9, US-25 à US-37) | webhook idempotent, remboursements (SQL) ; achats simulés, attente robuste après paiement (Flutter) |
| Espace Parents (US-16, H22) | défi parental, verrou, retour en arrière-plan (Flutter, émulateur) ; code e-mail conservé (Flutter) |
| Écoute (US-10 à US-12, R7) | ordre préparation → décompte → lecture, sortie pendant la préparation, échec de chargement (Flutter) |
| Hors connexion (NF-06) | messages et réessai sans rien consommer (Flutter) |
| Accessibilité (NF-08) | 11 écrans : 48 dp, libellés, contraste WCAG AA, texte ×1,6 sur 360 dp sans débordement (Flutter) |

## 3. Essais manuels sur émulateur (20/11/2026)

- Parcours complet : création réelle par Claude, lecture, cœur (test de bout en bout).
- Compte parent par code e-mail (boîte mail locale), puis déconnexion : nouvelle session anonyme,
  aucune erreur (bug corrigé en phase 5).
- Espace Parents refermé au passage en arrière-plan, y compris rouvert sans défi (bug corrigé).
- Voix apaisantes, Pack Voix et effacement de l'audio (Inc-8).

## 4. Hors CI, et pourquoi

- **Bout en bout** : il faut un émulateur et le Supabase local, et chaque passage écrit une vraie
  histoire (≈ 1 ct chez Anthropic). À lancer avant chaque version :

```powershell
flutter drive --profile --no-dds --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart --dart-define-from-file=env/dev.json
```

- **Charge k6** : cible le Supabase local ; commande dans `docs/qa/load-report.md`.
- **Pas de tests d'images de référence (golden)** : le rendu diffère entre Windows (poste) et Linux
  (CI), ce qui les rendrait instables ; l'identité visuelle est vérifiée par les captures de chaque
  incrément (`docs/design/captures/`) et les tests de widgets (ADR-037).

## 5. Reste à couvrir (phase 6)

- Mesures de fluidité et de démarrage sur un vrai Android d'entrée de gamme, puis sur iPhone.
- Achats réels en bac à sable (comptes stores et RevenueCat).
- Synthèse réelle des voix (clé Google) et première écoute en moins de 10 s.
- Endurance du backend sur une préproduction.
