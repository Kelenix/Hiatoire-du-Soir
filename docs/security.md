# Sécurité — Histoires du Soir

> Phase 5, 20/11/2026. Rôle : security-engineer. Revue indépendante du code (sous-agent, sans
> lecture de nos conclusions) sur le catalogue des menaces (`.claude/skills/common/12-threat-catalog.md`),
> puis vérification de chaque point dans le code et la base locale, puis corrections (ADR-036).

## 1. Surfaces et mesures en place

| Surface | Mesure | Vérification |
|---------|--------|--------------|
| Données en base | RLS sur les 12 tables ; aucune politique sur les tables de gestion (générations, tentatives, droits, achats, crédits, signalements) | tests SQL `inc1` à `phase5` (107) |
| Fonctions SQL `security definer` | `search_path` vide ; exécution accordée fonction par fonction ; toute nouvelle fonction fermée par défaut | `pg_proc` relu ; test « nouvelle fonction fermée » |
| Fonctions serveur | jeton Supabase vérifié (`getUser`) ; entrées validées (zod) ; codes d'erreur sans détail interne | tests Deno (9) |
| Coût Claude | une création à la fois par compte, tentatives bornées (40 / 24 h en Premium, 10 sinon, échecs compris), demande rejouée servie sans nouvel appel | tests SQL `phase5_hardening` |
| Coût Google (voix) | droits vérifiés avant la synthèse ; audio gardé, jamais synthétisé deux fois en temps normal | tests SQL `inc8` |
| Webhook d'achats | secret partagé, comparé en temps constant ; événements idempotents | tests SQL `inc5`, `inc7`, `inc8` |
| Stockage audio | bucket privé ; chaque famille ne lit que son dossier et les extraits ; écriture par le serveur seul ; audio effacé avec l'histoire et avec le compte | test SQL `inc8`, essai sur émulateur |
| Prénom de l'enfant | jamais envoyé à Claude (marqueur `{{HEROS}}`) ; remplacé dans le texte du parent, accents et casse ignorés, sans toucher les mots qui le contiennent | tests Deno |
| App | session dans le Keychain / Keystore ; aucun secret dans le binaire (clés publiques seulement) ; pas de sauvegarde Android des données ; HTTP en clair seulement dans l'app de développement, vers le Supabase local | revue du manifeste, ADR-016 |
| Dépôt | fichiers de secrets ignorés par Git ; recherche de secrets dans la CI (gitleaks) | `.gitignore`, `ci.yml` |

## 2. Constats de la revue et suite donnée

| Gravité | Constat | Suite |
|---------|---------|-------|
| Élevée | Requêtes de création simultanées : chacune passait le contrôle du quota et appelait Claude ; les échecs (contenu refusé) n'étaient jamais comptés | **Corrigé** : `start_generation` / `finish_generation` |
| Élevée | Comptes anonymes illimités (désinstaller, se déconnecter, script) : 3 histoires gratuites par compte | **Atténué** : 10 tentatives par compte et par jour, 30 sessions anonymes par heure et par IP, plafond de dépense chez Anthropic. **Reste** : attestation de l'appareil (Play Integrity, App Attest) à décider avant publication (tâche manuelle) |
| Moyenne | Synthèses simultanées de la même voix pour la même histoire | **Accepté** : réservé aux familles payantes, coût de quelques centimes au pire, alerte de budget Google |
| Moyenne | Achats de test (sandbox) acceptés par le webhook de production | **Accepté** : nécessaire à la revue Apple ; pas de TestFlight public |
| Moyenne | Prénom envoyé à Google pour la voix ; texte libre du parent | **Corrigé** pour le prénom du héros (accents, mots entiers) ; Google déclaré comme sous-traitant dans la politique de confidentialité (tâche manuelle) ; le champ demande déjà « Sans nom ni adresse » |
| Faible | Course sur la limite de 3 favoris | **Corrigé** : verrou par famille |
| Faible | Droits d'exécution par défaut sur les nouvelles fonctions | **Corrigé** : fermés par défaut |
| Faible | Sauvegarde Android des données de l'app | **Corrigé** : `allowBackup=false` et règles d'extraction |
| Faible | Comparaison du secret du webhook | **Corrigé** : temps constant |
| Faible | Suppression du compte : plus de 1 000 fichiers audio non effacés | **Corrigé** : liste paginée |
| Faible | Release signée avec la clé de débogage | Phase 6 (clé d'envoi Play Store) |
| Faible | Le client RevenueCat n'est pas supprimé avec le compte | Phase 6 (clé secrète RevenueCat requise) |
| Faible | La création de compte révèle qu'une adresse a déjà un compte | **Accepté** : inhérent au choix « se connecter à la place » (ADR-010) ; limité par le débit des e-mails |
| Faible | Le titre de l'histoire (avec le prénom) apparaît dans la notification de lecture | **Accepté** : c'est la commande de lecture écran verrouillé voulue (US-10) |

La revue du code a aussi relevé des bugs sans enjeu de sécurité (déconnexion, attente après achat,
écoute consommée sans lecture…), corrigés et couverts par des tests (`docs/qa/test-plan.md`).

## 3. Déclarations pour les stores (à reprendre en phase 6)

- **Données collectées** : adresse e-mail du parent (compte, facultatif), prénom et caractère des
  personnages de la famille, histoires créées, achats (via le store). Aucune donnée de localisation,
  de contacts, ni identifiant publicitaire ; aucun suivi.
- **Sous-traitants** : Supabase (UE, Irlande), Anthropic (écriture, sans le prénom), Google Cloud
  Text-to-Speech (voix apaisantes, avec le prénom), RevenueCat et les stores (achats).
- **Permissions Android** : Internet, service de lecture au premier plan et verrou de veille
  (écoute écran verrouillé). Rien d'autre.
- **Catégorie** : app pour enfants avec un espace parents protégé ; aucune publicité.

## 4. Alertes Supabase en production (20/11/2026, après déploiement)

| Alerte | Suite |
|--------|-------|
| Fonctions `security definer` appelables par les utilisateurs connectés (`my_entitlements`, `set_favorite`, `start_listening`, `report_story`) | **Voulu** : ce sont les appels de l'app ; chacune ne touche que les données de l'appelant (`auth.uid()`), revu en phase 5 |
| `rls_auto_enable` appelable par `anon` | **Sans risque** : fonction de Supabase qui active la RLS sur chaque nouvelle table ; elle ne s'exécute que sur un changement de structure (l'appel direct est refusé, vérifié) |
| Sessions anonymes autorisées | **Voulu** : premier lancement sans formulaire (US-01, ADR-010) ; abus suivi par R15 |
| Protection contre les mots de passe divulgués, double authentification | **Sans objet** : connexion par code à usage unique envoyé par e-mail, aucun mot de passe |

## 5. Points résiduels suivis

R5 (coûts) et R15 (abus du quota gratuit) dans `docs/risks.md` ; attestation de l'appareil et plafonds de dépense dans
`docs/manual-tasks.md`.
