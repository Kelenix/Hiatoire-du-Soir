# Rapport de charge (k6) — Histoires du Soir

> Phase 5, 20/11/2026. Script : `tests/load/backend.js`. Cible : le Supabase **local** (Docker, un
> seul poste). Les chiffres donnent un ordre de grandeur et repèrent les régressions ; la production
> (Supabase hébergé) n'a pas été chargée, pour ne pas consommer son quota.

## 1. Ce qui est simulé

Chaque utilisateur virtuel joue une famille qui ouvre l'app, une fois par seconde :

- **lectures** (tag `lecture`) : droits (`my_entitlements`), thèmes, dernière histoire, voix ;
- **création** (tag `creation`), une itération sur cinq : `generate-story` avec un quota gratuit déjà
  utilisé. La fonction passe toute sa chaîne (jeton, validation, réservation de la tentative, contrôle
  du quota) et répond « quota atteint » **sans appeler Claude** : aucun coût.

Huit familles d'essai sont créées au début et supprimées à la fin (vérifié : aucune ne reste).

## 2. Seuils et résultats

Seuils : échecs < 1 % ; p95 des lectures < 500 ms ; p95 des créations < 1,5 s ; contrôles > 99 %.

| Profil | Utilisateurs | Requêtes (par s) | Lectures p95 / max | Créations p95 / max | Échecs | Verdict |
|--------|--------------|------------------|--------------------|---------------------|--------|---------|
| smoke (30 s) | 1 | 152 (4,8/s) | 6 / 22 ms | 30 / 30 ms | 0 % | ✅ |
| load (2 min) | 20 | 7 382 (60/s) | 49 ms / 1,7 s | 209 ms / 1,6 s | 0 % | ✅ |
| stress (2 min) | jusqu'à 50 | 13 084 (108/s) | 10 / 167 ms | 46 ms / 2,6 s | 0 % | ✅ |

Les maximums autour de 1,6 à 2,6 s correspondent aux démarrages à froid de la fonction serveur
(nouvelle instance) ; le premier appel du script les absorbe désormais avant les mesures.

## 3. Ce qui n'est pas couvert

- La création réelle d'une histoire (appel à Claude, 10 à 40 s) : sa capacité dépend des limites du
  compte Anthropic, pas de nos serveurs. Elle est bornée par compte (ADR-036) et vérifiée une fois de
  bout en bout par le test d'intégration.
- La synthèse des voix apaisantes (clé Google requise).
- L'endurance (soak, plusieurs heures) : à faire sur un environnement de préproduction avant J4.

## 4. Relancer

```powershell
$env:ANON_KEY = (npx --yes supabase@3.2.0 status -o env | Select-String '^ANON_KEY=').ToString().Split('"')[1]
```

```powershell
$env:SERVICE_ROLE_KEY = (npx --yes supabase@3.2.0 status -o env | Select-String '^SERVICE_ROLE_KEY=').ToString().Split('"')[1]
```

```powershell
docker run --rm -e PROFILE=load -e ANON_KEY -e SERVICE_ROLE_KEY -v "${PWD}/tests/load:/scripts" grafana/k6:0.57.0 run /scripts/backend.js
```

Ces clés sont celles du Supabase local (identiques sur tous les postes) ; ne jamais lancer ce script
contre la production.
