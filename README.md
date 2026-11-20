# Histoires du Soir

Application mobile (Flutter, iOS + Android) d'histoires du soir personnalisées par IA, pour les
enfants de 3 à 8 ans. Cahier des charges : `INTAKE.md` · état du projet : `PROJECT_STATE.md` ·
documentation : `docs/`.

## Prérequis (poste Windows)

Flutter 3.41.7 · Docker Desktop démarré · Node.js (pour la CLI Supabase) · un émulateur Android
(`histoires_pixel`, Android 15).

## Démarrer en local

```powershell
npx --yes supabase@3.2.0 start
```

Copier `env/example.json` en `env/dev.json`, y reporter l'URL (`http://10.0.2.2:59321` depuis
l'émulateur Android) et la clé publique affichée par `npx --yes supabase@3.2.0 status`, puis :

```powershell
flutter run --dart-define-from-file=env/dev.json
```

Supabase Studio : http://127.0.0.1:59323 · e-mails de test : http://127.0.0.1:59324.
Les ports 593xx évitent les autres projets Supabase locaux du poste. Docker Desktop est limité à
8 Go : arrêter les projets Supabase inutilisés (`npx supabase stop` dans chacun) évite que Docker
coupe les conteneurs faute de mémoire.

Création d'histoires : copier `supabase/functions/.env.example` en `supabase/functions/.env`, y mettre
la clé API Anthropic, puis servir les fonctions :

```powershell
npx --yes supabase@3.2.0 functions serve --env-file supabase/functions/.env
```

## Vérifier

```powershell
dart format --output=none --set-exit-if-changed lib test
```

```powershell
flutter analyze
```

```powershell
flutter test
```

Tests de la base (quota, accès protégés), Supabase local démarré :

```powershell
Get-ChildItem supabase/tests/database/*.sql | ForEach-Object { Get-Content $_ -Raw | docker exec -i supabase_db_histoires-du-soir psql -U postgres -q -t -A }
```

Tests des fonctions serveur (dont « le prénom n'est jamais envoyé à l'IA »), avec Docker :

```powershell
docker run --rm -v "${PWD}/supabase/functions:/app" -w /app denoland/deno:alpine deno test --allow-env
```

Parcours de bout en bout sur l'émulateur, avec mesures de fluidité (écrit une vraie histoire) :

```powershell
flutter drive --profile --no-dds --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart --dart-define-from-file=env/dev.json
```

Charge du backend local (k6) : voir `docs/qa/load-report.md`. Plan de test complet :
`docs/qa/test-plan.md` ; sécurité : `docs/security.md` ; performance : `docs/performance.md`.

La CI GitHub Actions (`.github/workflows/ci.yml`) rejoue ces vérifications (format, analyse, tests
Flutter, tests de la base, types et tests des fonctions).

## Déployer en production (Supabase)

Projet `tsndbpfdctuwxjpyvfwl` (Irlande). Une fois connecté (`npx --yes supabase@3.2.0 login`) et le
dossier relié (`npx --yes supabase@3.2.0 link --project-ref tsndbpfdctuwxjpyvfwl`) :

```powershell
npx --yes supabase@3.2.0 db push --remote
```

```powershell
npx --yes supabase@3.2.0 functions deploy
```

```powershell
npx --yes supabase@3.2.0 secrets set --env-file supabase/functions/.env.production
```

```powershell
npx --yes supabase@3.2.0 config push
```

Secrets attendus par les fonctions : voir `supabase/functions/.env.example` (Anthropic, RevenueCat,
Google Text-to-Speech).

App branchée sur la production : `flutter run --dart-define-from-file=env/prod.json`.

## Ressources

Icône et écran de démarrage générés depuis `assets/launcher/` et `assets/images/mascot.png` :

```powershell
dart run flutter_launcher_icons
```

```powershell
dart run flutter_native_splash:create
```
