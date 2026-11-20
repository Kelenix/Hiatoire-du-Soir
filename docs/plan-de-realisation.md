# Plan de réalisation — Histoires du Soir

> Phase 0 (cadrage), 20/11/2026. Mode **PLAN_PUIS_VALIDATION** : aucune ligne de code avant ton feu vert.
> Source : `INTAKE.md` · Décisions : `DECISION_LOG.md` · Avancement : `PROJECT_STATE.md` ·
> Tâches manuelles : `docs/manual-tasks.md`.

## 1. Compréhension du besoin

**Objectif.** Une application mobile familiale (iOS + Android, en français) : un parent ou son enfant
choisit un thème, l'IA écrit une histoire du soir, on la lit ou on l'écoute, puis on peut la garder en
favori. La monétisation vise **uniquement les parents** (freemium + abonnement familial + achats
intégrés), **sans aucune publicité**.

**Deux espaces.**
- **Espace Enfant** : thèmes, personnages, création, lecture, écoute. Aucun achat, aucun lien externe, aucune pub.
- **Espace Parents** (derrière un contrôle parental) : abonnements, packs, compte, paramètres, support.

### Périmètre V1 (INTAKE §11) et traçabilité

| # | Exigence | Incrément(s) |
|---|----------|--------------|
| E1 | Génération d'histoires par IA | Inc-1 |
| E2 | Sélection des thèmes | Inc-1 (gratuits), Inc-5 (Premium) |
| E3 | Personnalisation : personnages, prénom, animal, situation | Inc-6 |
| E4 | Lecture des histoires | Inc-1 |
| E5 | Lecture audio avec voix | Inc-2 (voix standard), Inc-8 (voix Premium) |
| E6 | Favoris | Inc-3 |
| E7 | Espace Enfant | Inc-0, puis enrichi à chaque incrément |
| E8 | Espace Parents | Inc-4 |
| E9 | Contrôle parental (achats, liens externes, réglages) | Inc-4 |
| E10 | Gratuit limité à 3 histoires/semaine | Inc-1 |
| E11 | Abonnements mensuel/annuel + essai 7 jours | Inc-5 |
| E12 | Achats intégrés de packs d'histoires et de voix | Inc-7, Inc-8 |
| E13 | Crédits pour générer sans abonnement | Inc-7 |

### Hors périmètre V1
Publicité et option « suppression des pubs » (prévues pour plus tard par l'INTAKE §11) · lecture
hors-ligne · plusieurs profils enfants · autres langues que le français · illustrations ·
notifications push · back-office dédié (Supabase Studio suffit) · version web/desktop.

### Hypothèses (elles comblent des trous de l'INTAKE ; tu les valides avec le plan)

| # | Hypothèse |
|---|-----------|
| H1 | iOS + Android, interface et histoires en français, prix en euros. |
| H2 | Âge cible 3-8 ans : vocabulaire simple, ton rassurant, fin apaisante propice au coucher. |
| H3 | Durées : 2 min en gratuit ; 2, 5 ou 10 min en Premium. Base ≈ 130 mots/min lus à voix haute (2 min ≈ 260 mots, 10 min ≈ 1 300 mots). |
| H4 | « 3 histoires par semaine » = semaine calendaire, remise à zéro le lundi à 00:00 (heure de Paris). |
| H5 | « 1 écoute par histoire » = une lecture audio complète (pause/reprise permises) ; la lecture du texte reste ensuite possible. |
| H6 | Thèmes stockés en base (modifiables sans mise à jour de l'app). Catalogue de départ proposé : gratuits Animaux, Forêt magique ; Premium Océan, Espace, Dinosaures, Chevaliers et dragons, Pirates ; saisonniers Noël, Halloween. |
| H7 | Personnages : quelques personnages prêts à l'emploi par thème, plus des personnages créés par le parent (prénom, animal, trait de caractère), réutilisables (Premium et packs). |
| H8 | Un crédit = 1 histoire hors quota avec tous les thèmes, durées et la personnalisation. Ordre de consommation : abonnement → quota gratuit (si l'histoire reste dans l'offre gratuite) → crédits du pack du thème → crédits génériques. *Remarque : « Histoire sur mesure » (1,99 € l'unité) revient alors 6× plus cher qu'un crédit du Pack Famille (0,33 €) ; c'est cohérent comme petit achat d'entrée, mais c'est ton choix de prix.* |
| H9 | Pack Voix = achat définitif (non consommable) ; packs d'histoires et crédits = consommables. |
| H10 | Si l'abonnement expire avec plus de 3 favoris, ils restent lisibles ; on ne peut plus en ajouter avant d'être repassé sous 3. |
| H11 | Bouton « Signaler cette histoire » dans l'Espace Parents : exigé par la politique Google Play sur les contenus générés par IA (INTAKE §9.3). |
| H12 | Connexion Internet requise pour générer une histoire ; pas de mode hors-ligne en V1. |

## 2. Architecture cible (résumé, détaillée en phase 3)

```
App Flutter (iOS / Android)          Supabase (région UE)                  Services externes
Riverpod · go_router · freezed       Auth : anonyme + e-mail / Apple / Google
 ├─ Espace Enfant                    Postgres + RLS : histoires, favoris,
 ├─ Contrôle parental                  quotas, crédits, droits
 └─ Espace Parents  ── HTTPS ──▶     Edge Functions (Deno / TypeScript)
                                      ├─ generate-story ───────────────▶ Claude (API Anthropic)
                                      ├─ synthesize-voice ─────────────▶ Synthèse vocale cloud
                                      ├─ purchases-webhook ◀────────────  Achats (App Store / Play)
                                      └─ delete-account
                                     Storage privé : audio mis en cache
```

- **Le serveur fait foi** pour tout ce qui coûte ou rapporte : quota hebdomadaire, crédits, droits
  Premium, limite de favoris, écoutes. Vérifiés dans Postgres (RLS + fonctions transactionnelles),
  jamais seulement dans l'app.
- **Aucun secret dans l'app** : les clés IA, voix et achats vivent dans les secrets des Edge
  Functions ; l'app ne connaît que l'URL et la clé publique Supabase (`--dart-define`).
- **Le prénom de l'enfant n'est jamais envoyé à l'IA** : le modèle écrit avec un marqueur remplacé
  côté serveur (avec fille/garçon/neutre pour les accords).
- **Sécurité du contenu** : consignes strictes, champs libres du parent bornés et traités comme des
  données (anti-injection), sortie structurée (titre + paragraphes), contrôle avant enregistrement.
- **Conformité « Kids / Familles » par défaut** : aucun SDK de publicité ni d'analytics tiers,
  contrôle parental, données minimales. Le choix de la catégorie store se fera en phase 6, sans
  impact sur le code.
- **Pas de VPS nécessaire** : toute la logique serveur tient dans Supabase. Seules les pages
  légales/support auront besoin d'une URL publique (décision en phase 6).

## 3. Incréments verticaux (ordonnés)

| ID | Incrément | Exigences | Démonstration |
|----|-----------|-----------|---------------|
| Inc-0 | Socle : projet Flutter, thème fidèle au brand kit (`docs/design/charte-graphique.md`), navigation Enfant/Parents, Supabase local sous Docker, session anonyme, CI (analyse + tests) | E7 | l'app démarre et navigue sur émulateur Android, à l'identique du kit |
| Inc-1 | Première histoire : thèmes gratuits, fonction `generate-story` (Claude), quota 3/semaine côté serveur, écran de lecture | E1 E2 E4 E10 | choisir « Animaux » → histoire affichée ; la 4ᵉ de la semaine est refusée |
| Inc-2 | Écoute : voix standard du téléphone, lecteur (lecture/pause), 1 écoute par histoire en gratuit | E5 | écouter une histoire ; la 2ᵉ écoute est bloquée |
| Inc-3 | Favoris et « Mes histoires » (3 favoris max en gratuit) | E6 | le 4ᵉ favori est refusé avec un message clair |
| Inc-4 | Contrôle parental + Espace Parents : paramètres, support, compte parent, suppression de compte, signalement | E8 E9 | le contrôle est exigé avant réglages et liens externes |
| Inc-5 | Abonnements : mensuel 5,99 €, annuel 34,99 €, essai 7 jours, écran d'offre côté parents, droits Premium (tous les thèmes, durées, favoris et écoutes illimités), parcours « limite atteinte » | E2 E11 | achat en bac à sable → Premium débloqué |
| Inc-6 | Personnalisation : prénom, animal, situation, personnages enregistrés | E3 | une histoire où l'enfant est le héros |
| Inc-7 | Packs et crédits : Famille (30 crédits), Aventures Premium, Noël, Histoire sur mesure ; registre des crédits | E12 E13 | achat d'un pack → crédits → histoire |
| Inc-8 | Voix Premium : voix neuronales cloud mises en cache, Pack Voix | E5 E12 | écouter une histoire avec une voix apaisante |

Ordre : le socle, puis toute la valeur gratuite (Inc-1 à 4), puis la monétisation (Inc-5 à 8).
Chaque incrément se termine par `flutter analyze`, les tests et une revue de code, avant de passer
au suivant.

## 4. Séquence des phases et rôles

Phase 0 Cadrage (ce document) → 1 Produit (user stories et critères d'acceptation,
`docs/product/user-stories.md`) → 2 Planification (risques, jalons) → 3 Architecture et design
(schéma de base + RLS, Edge Functions, maquettes, charte) → 4 Implémentation Inc-0 à Inc-8 (backend,
Flutter, état ; sécurité en continu) → 5 Qualité et performance → 6 Publication (Android d'abord,
iOS via une CI macOS) → 7 Documentation → 8 Maintenance.

| Jalon | Contenu | Démontrable |
|-------|---------|-------------|
| J1 | Inc-0 et Inc-1 | première histoire générée sur émulateur Android |
| J2 | Inc-2 à Inc-4 | expérience gratuite complète |
| J3 | Inc-5 à Inc-8 | monétisation testable en bac à sable (comptes stores requis) |
| J4 | Builds release Android (.aab) + iOS (TestFlight), CI verte | testeurs internes |
| J5 | Soumission aux stores | — |

## 5. Risques et parades

| Niv. | Risque | Parade |
|------|--------|--------|
| 🔴 | Contenu inadapté généré pour un enfant | consignes de sécurité, champs parent bornés, sortie structurée, contrôle avant enregistrement, signalement parent |
| 🔴 | Rejet par les stores (règles enfants/familles, achats, contrôle parental, contenus IA, suppression de compte, fiches confidentialité) | conformité dès la conception, checklist dédiée en phase 6, publication Android d'abord |
| 🔴 | Pas de Mac : impossible de compiler, signer et tester iOS en local | builds iOS via GitHub Actions (macOS) + Fastlane, tests sur iPhone via TestFlight |
| 🟡 | Coûts IA/voix supérieurs à la marge (voir §7) | quotas côté serveur, audio mis en cache, modèle paramétrable sans mise à jour de l'app, plafond de dépense chez les fournisseurs |
| 🟡 | Tester les achats exige des comptes stores et un build signé déjà publié en test interne | comptes à ouvrir dès maintenant (vérification d'identité Google : plusieurs jours) |
| 🟡 | Données personnelles d'enfants (RGPD) | minimisation, prénom jamais envoyé à l'IA, hébergement UE, politique de confidentialité, suppression de compte |
| 🟡 | Éléments du kit encore manquants en haute définition : éléments graphiques, 2 variantes de logo, illustration principale, 6 univers de thèmes | liste précise dans la charte §8 et `docs/manual-tasks.md` ; découpes provisoires du kit en attendant |
| 🟡 | Voix françaises absentes ou médiocres sur certains Android | détection au lancement, message guidant l'installation d'une voix |
| 🟡 | Temps de génération (10 à 30 s pour une histoire longue) | animation d'attente apaisante, affichage progressif du texte (à trancher en phase 3) |

## 6. Questions

**Tranchées le 20/11/2026** (détail dans `DECISION_LOG.md`) :
- Q1 — Profil « Équilibré » : Claude Sonnet 5.5 + voix du téléphone, voix Premium cloud Google mises en cache (ADR-008).
- Q2 — Achats intégrés via RevenueCat (ADR-009).
- Q3 — Démarrage sans compte ; compte parent exigé au premier achat (ADR-010).
- Q4 — Premium inclut tout ; les packs s'adressent aux non-abonnés (ADR-011).

**Reportées à la phase 6** (non bloquantes) : publication en catégorie « Kids » (Apple) ou non ;
hébergement des pages légales/support ; plan Supabase de production (gratuit ou Pro à 25 $/mois).

## 7. Économie unitaire (estimations à confirmer en conditions réelles)

- **Revenu net Premium** : 5,99 € TTC ≈ 4,99 € HT (TVA 20 %) ≈ **4,24 €/mois** après 15 % de
  commission (programme petites entreprises Apple/Google). Annuel 34,99 € ≈ **2,07 €/mois** net.
- **Écriture d'une histoire** (sortie ≈ 500 tokens pour 2 min, ≈ 1 200 pour 5 min) :
  Haiku 5.5 ≈ 0,1 ct · Sonnet 5.5 ≈ 1,5 ct · Opus 5.5 ≈ 3 ct (histoire de 5 min).
  **Mesuré le 20/11/2026** (Sonnet 5.5, contrôle du contenu compris) : ≈ 1,3 ct par histoire de 2 min.
- **Voix cloud** (≈ 3 800 caractères pour 5 min) : ≈ 1,5 ct (gamme WaveNet) à 6 ct (Neural2) ou
  11 ct (Chirp 3 HD) chez Google ; voix du téléphone : 0 €.
- **Utilisateur gratuit actif** (≈ 13 histoires de 2 min/mois, voix du téléphone) : ≈ 0,4 ct (Haiku)
  à 16 ct (Opus) par mois.
- **Point d'attention** : un abonné annuel qui écoute chaque soir une histoire de 5 min en voix cloud
  Neural2 coûte ≈ 2 €/mois, soit à peu près son revenu net. Le cache audio (relectures gratuites) et
  le choix de la gamme de voix (phase 3, test d'écoute) gardent la marge positive.
