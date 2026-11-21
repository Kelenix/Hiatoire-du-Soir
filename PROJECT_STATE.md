# État du projet — PROJECT_STATE

> Mis à jour par Claude à la fin de chaque phase / incrément. Permet de **reprendre** le
> travail à tout moment, même dans une nouvelle session. Toujours lire ce fichier avant d'agir.

## Snapshot

- **Phase courante** : 6 — Publication (Android), en cours
- **Dernière mise à jour** : 21/11/2026
- **Santé** : 🟢 OK
- **Prochaine action** : phase 6 (publication, Android d'abord) ; elle dépend de tes comptes
  (Play Console, Apple, RevenueCat, SMTP, Google Cloud), voir `docs/manual-tasks.md`
- **Reste de la phase 5** : mesures sur un vrai téléphone (dessin des images, démarrage) ;
  décision sur l'attestation de l'appareil (R15)
- **Reste de l'Inc-8** : synthèse réelle par Google et test d'écoute des voix (clé Google Cloud) ;
  vrai achat du Pack Voix (comptes stores et RevenueCat)
- **Reste de l'Inc-7** : un vrai achat de pack, en attente des comptes stores et RevenueCat
- **Production à jour le 20/11/2026** : 10 migrations, 4 fonctions serveur ; vérifiée par une
  vraie création d'histoire (11 s), une demande rejouée sans nouvel appel à Claude et la suppression
  d'un compte d'essai ; voix apaisantes en attente de la clé Google
- **Production Supabase** : en service depuis le 20/11/2026 (Irlande) ; reste à configurer
  l'envoi des e-mails (SMTP), bloquant pour les comptes parents avant publication
- **Reste de l'Inc-5, en attente de tes comptes** : un vrai achat en bac à sable (Google Play,
  App Store, RevenueCat) ; tout le reste est validé avec des achats simulés
- **Restes de l'Inc-4, en attente de tes informations** : connexion Apple et Google (identifiants),
  bouton « Écrire au support » (adresse), page des informations légales (URL)

## Avancement par phase

| Phase | État | Notes |
|-------|------|-------|
| 0 — Cadrage & intake        | ✅ fait | plan validé le 20/11/2026 : `docs/plan-de-realisation.md` |
| 1 — Définition produit      | ✅ fait | 37 stories, 8 exigences transverses : `docs/product/user-stories.md` |
| 2 — Planification           | ✅ fait | backlog ci-dessous, `docs/risks.md` (14 risques, chemin critique, jalons) |
| 3 — Architecture & design   | ✅ fait | `docs/architecture.md`, `docs/system-design.md`, `docs/data-model.md`, `docs/design/design-system.md`, `docs/design/flows.md` |
| 4 — Implémentation          | 🔄 en cours | Inc-0 ✅ · Inc-1 ✅ (J1) · Inc-2 ✅ · Inc-3 ✅ · Inc-4 ✅ (J2) · Inc-5 ✅ · Inc-6 ✅ · Inc-7 ✅ · Inc-8 ✅ |
| 5 — Qualité & performance   | ✅ fait | `docs/security.md`, `docs/performance.md`, `docs/qa/test-plan.md`, `docs/qa/load-report.md` ; reste la mesure sur un vrai téléphone |
| 6 — Publication (stores)    | 🔄 en cours | Android : fiche Play prête ; reste paquet, achats, test fermé 14 j |
| 7 — Documentation           | ⬜ à faire | |
| 8 — Maintenance             | ⬜ à faire | |

> États : ⬜ à faire · 🔄 en cours · ✅ fait · ⏸️ en attente (raison)

## Backlog incréments (incrément vertical = livrable)

| ID | Incrément | Stories | Exigence liée | Bloqué par | État |
|----|-----------|---------|---------------|------------|------|
| Inc-0 | Socle (Flutter, thème du kit, accueil Enfant, Supabase local, session anonyme, CI) | US-01, US-02, NF-05, NF-06, NF-08 | E7 | — | ✅ 20/11 |
| Inc-1 | Première histoire (thèmes gratuits, `generate-story`, quota, lecture, dernière histoire) | US-03 à US-09, NF-02, NF-03 | E1 E2 E4 E10 | — | ✅ 20/11 |
| Inc-2 | Écoute voix standard + 1 écoute/histoire | US-10, US-11, US-12 | E5 | — | ✅ 20/11 |
| Inc-3 | Favoris + Mes histoires | US-13, US-14, US-15 | E6 | — | ✅ 20/11 |
| Inc-4 | Contrôle parental, Espace Parents, compte, suppression, signalement, légal | US-16 à US-23 | E8 E9 | identifiants Apple/Google | ✅ 20/11 (Apple/Google, support et légal en attente d'infos) |
| Inc-5 | Abonnements, essai, droits Premium, « Demande à un parent » | US-24 à US-29 | E2 E11 | comptes stores, RevenueCat | ✅ 20/11 (achats simulés ; vrai achat en attente des comptes) |
| Inc-6 | Personnages et histoires sur mesure | US-30, US-31, US-32 | E3 | — | ✅ 20/11 |
| Inc-7 | Packs et crédits | US-33, US-34, US-35 | E12 E13 | comptes stores | ✅ 20/11 (achats simulés ; vrai achat en attente des comptes) |
| Inc-8 | Voix Premium cloud + Pack Voix | US-36, US-37 | E5 E12 | compte Google Cloud | ✅ 20/11 (audio de test ; synthèse Google en attente de la clé) |

Risques et chemin critique : `docs/risks.md`.

## Décisions ouvertes / questions à l'utilisateur

- [x] Q1 — Profil « Équilibré » : Claude Sonnet 5.5 + voix du téléphone / voix cloud Premium (ADR-008)
- [x] Q2 — Achats intégrés via RevenueCat (ADR-009)
- [x] Q3 — Démarrage sans compte, compte parent au premier achat (ADR-010)
- [x] Q4 — Premium inclut tout ; packs pour les non-abonnés (ADR-011)
- [x] Feu vert sur le plan et les hypothèses H1 à H12 (20/11/2026)
- [x] Règles H13 à H22 validées (20/11/2026)

## Blocages

- (aucun)

## Tâches manuelles utilisateur en attente

- voir `docs/manual-tasks.md` — à lancer tôt : comptes Google Play et Apple Developer (délais de validation)

## Journal de session (résumé court, le plus récent en haut)

- 21/11/2026 — Phase 6 lancée (Android).
  - **Connexion Google** configurée (Cloud `histoires-du-soir` sur lionelkelenix@gmail.com, écran
    publié) et activée dans Supabase local et production.
  - **Pages légales** en ligne : https://kelenix.github.io/histoires-du-soir-site/ (ADR-041).
  - **Clé d'envoi Android** générée ; paquet `app-release.aab` 1.0.0 (1) signé.
  - **Play Console** (Kelenix Tech) : app créée, fiche complète (textes, icône, bannière, 6 captures),
    catégorie, contact, confidentialité, publicités, classification PEGI 3 ; sécurité des données en
    brouillon (attend le public cible, qui attend l'accès réviseur).
  - Code e-mail masqué en production (ADR-040). 108 tests verts, analyse sans remarque.
  - Paquet 1.0.0 (1) publié en **test interne** ; empreinte de signature Play ajoutée à la connexion
    Google ; **abonnement et 5 produits** créés et actifs ; compte de service RevenueCat prêt.
    Puis : RevenueCat configuré (clé JSON, notifications temps réel), codes promo réviseur, vidéo
    du service de lecture, public cible 0-8 ans (programme Famille), sécurité des données validée ;
    **test fermé 1.0.0 (2) et les 14 modifications envoyés à l'examen de Google**.
    Reste : réponse de Google (≈ 7 jours), secret du webhook RevenueCat, 12 testeurs pendant
    14 jours, statut de commerçant, puis demande d'accès à la production.
- 20/11/2026 — Retours de l'essai sur téléphone.
  - **Voix du téléphone** (ADR-039) : plus lente, ton plus doux, meilleure voix française
    installée, 0,9 s de pause entre les paragraphes. Sur émulateur, une histoire de 2 minutes dure
    2:19 au lieu de 2:03, et la lecture démarre en 6 s.
  - **Bande noire en bas** (barre de navigation, Android 14 et antérieurs) : le fond nuit passe
    désormais sous les barres du système.
  - **Halo derrière les tuiles et le bouton principal** retiré, comme dans le kit.
  - **Connexion Google des parents** codée (ADR-038), en attente des ID client Google (tâche
    manuelle détaillée).
  - Preuves : 108 tests Flutter verts, analyse sans remarque.
- 20/11/2026 — **Production mise à jour** : migrations Inc-7, Inc-8 et phase 5, et les 4 fonctions
  serveur (dont `synthesize-voice`).
  - **Contrôles** :
    - appels sans session refusés (401) ;
    - catalogue en place (3 voix, 4 packs) ;
    - création réelle en 11 s, puis demande rejouée en 0,7 s, avec la même histoire et sans
      nouvel appel à Claude ;
    - compte d'essai supprimé ;
    - extrait de voix refusé proprement sans clé Google.
  - **Alertes Supabase** relues : rien à corriger (`docs/security.md` §4).
- 20/11/2026 — Phase 5 terminée.
  - **Relectures indépendantes** (sécurité, code) : aucune faille critique. Corrigés :
    - dépense Claude sans limite en cas de requêtes simultanées ou d'échecs provoqués ;
    - déconnexion qui plantait et laissait les données de l'ancien compte ;
    - « Rien n'a été débité » affiché après un paiement réussi ;
    - écoute consommée sans lecture ;
    - Espace Parents parfois resté ouvert en arrière-plan ;
    - double appui sur le cœur ;
    - durée restée verrouillée ;
    - prénom mal masqué dans le texte du parent ;
    - boutons mal lus par le lecteur d'écran ;
    - quelques durcissements (ADR-036).
  - **Mesures** :
    - démarrage 1,87 s (au lieu de 2,1 s) ;
    - calcul des images < 2 ms ;
    - dessin à confirmer sur un vrai téléphone ;
    - charge jusqu'à 50 utilisateurs sans échec ;
    - 11 écrans conformes aux contrôles d'accessibilité.
  - **Preuves** : 107 tests SQL, 9 tests serveur, 100 tests Flutter, un parcours de bout en bout
    sur émulateur avec une vraie histoire, 3 profils k6 ; compte par code e-mail puis déconnexion
    validés sur émulateur.
- 20/11/2026 — Inc-8 livré sans clé Google : 3 voix apaisantes (Douce, Conteur, Lune ; Google
  WaveNet, modifiables en base), extraits écoutables avant achat dans les réglages, choix de la voix
  au lecteur pour les familles qui y ont droit (rien de plus pour les autres), Pack Voix (achat
  définitif) dans « Packs d'histoires et de voix », audio gardé dans un bucket privé et effacé avec
  l'histoire ou le compte (ADR-035). Preuves : 98 tests SQL, 8 tests des fonctions, 71 tests
  Flutter verts, analyse sans remarque ; sur émulateur, avec un audio de test déposé dans le
  stockage local : achat du Pack Voix envoyé deux fois au webhook (enregistré une fois), extrait de
  « Douce » lu, histoire écoutée avec « Douce » (écoute décomptée, puis verrou en fin d'écoute comme
  en gratuit), audio de l'ancienne histoire effacé à la création suivante, audio d'un compte de
  test effacé à sa suppression ; sans clé Google, message clair et écoute non décomptée. Bug trouvé
  et corrigé : le lecteur Android refusait l'audio du Supabase local en HTTP (réglage limité à
  l'app de développement). Captures `inc-8-*.png`.
- 20/11/2026 — Inc-7 livré avec achats simulés : 4 packs décrits en base (Aventures Premium, Noël,
  Histoire sur mesure, Famille ; prix fournis par le store), registre des crédits, ordre de
  consommation tranché par le serveur, crédit pris seulement si l'histoire est créée, remboursement
  géré, écran « Packs d'histoires » et solde dans l'Espace Parents, thèmes et options ouverts par
  les crédits sans rien montrer à l'enfant (ADR-033). Preuves : 85 tests SQL, 5 tests des
  fonctions et 66 tests Flutter verts ; sur émulateur, achat du Pack Noël envoyé deux fois au
  webhook (10 crédits, une seule fois), Noël ouvert pour l'enfant, histoire de Noël de 5 min créée
  (solde 10 → 9), solde et packs visibles côté parent. Bug trouvé et corrigé : le contrôle refusait
  le Père Noël et les histoires sans héros (régression de l'Inc-6), correctif redéployé en
  production (ADR-034). Captures `inc-7-*.png`.
- 20/11/2026 — Production Supabase configurée (projet « Histoires du Soir », Irlande, UE) : 7
  migrations appliquées sur une base vérifiée vide, 3 fonctions déployées avec leurs secrets
  (nouveau secret de webhook), authentification réglée (session anonyme, code à 6 chiffres, e-mail
  en français, confirmation de l'adresse, un code par minute), `env/prod.json` créé (ADR-032).
  Preuves : appels sans autorisation refusés (401) ; sur émulateur branché sur la production,
  session anonyme, histoire « Pipo et la lumière du soir » créée en 15 s, compteur passé à 2 ;
  contrôles de sécurité Supabase relus. Reste : SMTP pour envoyer les codes aux parents.
- 20/11/2026 — Inc-6 livré : personnages de la famille gérés par le parent (prénom, accords,
  animal, caractère ; 10 au plus), écran « Personnages » de l'enfant, 4 héros prêts à l'emploi,
  écran « Prépare ton histoire » (héros, animal, situation de la liste ou racontée par le parent,
  durée), prénom jamais envoyé à l'IA et remis à l'affichage avec l'élision (ADR-029 à ADR-031).
  Preuves : 68 tests SQL, 5 tests des fonctions serveur et 58 tests Flutter verts, CI complétée
  (types et tests des fonctions) ; sur émulateur, Emma créée côté parent puis histoire « La nuit
  douce d'Emma » (peur du noir) en 21 s (≈ 3 200 jetons), texte stocké avec `{{HEROS}}` seulement ;
  texte de parent détourné sans effet. Bugs trouvés et corrigés : policy de limite récursive
  (remplacée par un déclencheur) ; `ABUSE_LIMIT` renvoyé comme erreur technique par
  `generate-story` (désormais 429, message « Reviens demain »). Note : une session dont
  l'utilisateur a disparu côté serveur n'est pas réparée automatiquement (vu après une remise à zéro
  de la base locale ; sans effet en production, où la suppression passe par l'app). Captures
  `inc-6-*.png`.
- 20/11/2026 — Inc-5 livré avec achats simulés : droits Premium tranchés par le serveur (tous les
  thèmes, durées 2/5/10 min, écoutes et favoris illimités, plafond de 30 histoires par 24 h),
  webhook RevenueCat (`purchases-webhook`, secret partagé, idempotent), écran d'offre (prix du store,
  économie de l'annuel, essai 7 jours, restauration, compte exigé avant achat), « Je suis le parent »,
  état Premium et gestion de l'abonnement dans l'Espace Parents, lecture en morceaux des longues
  histoires (limite Android de 4 000 caractères). Preuves : 55 tests SQL et 50 tests Flutter verts ;
  webhook appelé en local (401 sans secret, achat appliqué une fois) ; sur émulateur, Premium actif,
  histoire Océan de 10 min créée en 31 s (1 118 mots, ≈ 4 ct) puis écoutée (7 min 42, 2 morceaux
  réassemblés). Bugs trouvés et corrigés : histoires de 10 min refusées (plus de 80 paragraphes,
  limite portée à 200) ; pendant « Réessayer », l'erreur restait affichée au lieu de l'animation.
  Capture `inc-5-premium.png`.
- 20/11/2026 — Inc-4 livré (jalon J2 : expérience gratuite complète) : contrôle parental (addition
  en toutes lettres, 3 essais), Espace Parents protégé 5 min et refermé dès que l'app passe en
  arrière-plan (H22), réglages de lecture (vitesse, taille du texte), aide, compte parent par code
  à 6 chiffres (session anonyme conservée, connexion sur un 2ᵉ appareil), suppression du compte
  (fonction `delete-account`), signalement d'une histoire (copie sans compte, purge à 90 jours).
  Preuves : 39 tests SQL et 40 tests Flutter verts, types TypeScript vérifiés ; sur émulateur :
  défi résolu, signalement enregistré et histoire retirée, compte créé avec le code reçu par e-mail
  (mauvais code refusé), compte supprimé en base avec ses histoires, retour automatique à l'Espace
  Enfant. Deux bugs trouvés sur l'émulateur et corrigés : e-mail rattaché sans vérification du code
  (confirmation désactivée dans la config locale → rendue obligatoire, ADR-025) ; retour automatique
  jamais déclenché (écouteur du cycle de vie non créé). Capture `inc-4-espace-parents.png`.
- 20/11/2026 — Inc-3 livré : cœur sur l'écran de lecture (bouton rond du kit), 3 favoris maximum
  en gratuit tranchés par le serveur (`set_favorite`), message « Ta bibliothèque est pleine »,
  écran « Mes histoires » par pages de 20 avec état vide, favoris gardés à chaque nouvelle histoire
  (H13). Preuves : 32 tests SQL et 30 tests Flutter verts, analyse sans remarque ; sur émulateur,
  favori enregistré en base, liste « Mes histoires », 4ᵉ favori refusé avec le message (captures
  `inc-3-*.png`, données de test retirées ensuite).
- 20/11/2026 — Inc-2 livré : écoute avec la voix du téléphone (synthèse en fichier puis lecteur
  unique, ADR-013), barre d'écoute (lecture, pause, progression), 1 écoute par histoire en gratuit
  décomptée par le serveur (`start_listening`), message si aucune voix française. Preuves sur
  émulateur : lecture d'une histoire de 2:07, écran éteint → lecteur toujours actif, audio coupé en
  quittant l'histoire, histoire rouverte → « déjà écoutée » ; compteur à 1 en base. Tests : 23 SQL,
  26 Flutter, analyse sans remarque. Bug trouvé sur l'émulateur et corrigé : quand la voix française
  n'est pas installée, le plugin de synthèse ne répond jamais → délai de 45 s, voix détectée comme
  « installée » et non seulement « disponible », test de non-régression. La synthèse d'une histoire
  de 2 min prend ≈ 8 s sur l'émulateur.
- 20/11/2026 — Inc-1 validé avec Claude : 3 vraies histoires de 2 min (288 à 308 mots) créées en
  10,5 à 12,4 s (objectif 15 s), 4ᵉ refusée (`QUOTA_REACHED`), une seule histoire gardée (H13).
  Coût mesuré ≈ 1,3 ct par histoire de 2 min, contrôle compris (≈ 1 850 jetons en entrée, 950 en
  sortie). Contenu relu : doux, adapté, fin apaisante. Parcours complet dans l'app sur l'émulateur
  (captures `inc-1-histoire.png`, `inc-1-accueil-ce-soir.png`). Étoiles retirées derrière le texte
  de lecture pour la lisibilité.
- 20/11/2026 — Inc-1 codé : migration (thèmes, histoires, journal des générations, quota, RLS),
  fonction `generate-story` (Claude Sonnet 5.5, sortie structurée, contrôle du contenu), écrans
  Thèmes, Création, Lecture, « Demande à un parent », étoiles et « Ce soir » sur l'accueil.
  Preuves : 18 tests SQL et 20 tests Flutter verts, analyse sans remarque, types TypeScript vérifiés,
  appels réels de la fonction (401, 400, 403 verrouillé, 502 sans clé), parcours sur émulateur
  avec captures `docs/design/captures/inc-1-*.png`, aucun quota consommé après échec. Bug trouvé
  sur l'émulateur et corrigé : thèmes affichés à l'envers (tri descendant par défaut). Reste :
  essai avec une vraie clé Anthropic (contenu, délai), puis NF-03 (200 histoires de test) avant
  publication. ADR-023, ADR-024.
- 20/11/2026 — Inc-0 livré : projet Flutter (`fr.histoiresdusoir.app`), thème et composants du kit,
  accueil Enfant, session anonyme dans le stockage sécurisé, écran hors connexion, icône et écran de
  démarrage, Supabase local (ports 593xx), CI GitHub Actions, émulateur Android. Preuves : 9 tests
  verts, `flutter analyze` sans remarque, session anonyme créée en base, capture
  `docs/design/captures/inc-0-accueil-enfant.png`. Les boutons de l'accueil seront branchés par
  leurs incréments (création Inc-1, favoris Inc-3, parents Inc-4, personnages Inc-6). Dépôt Git
  initialisé, aucun commit. ADR-020 à ADR-022.
- 20/11/2026 — Phases 2 et 3 : registre des risques, backlog par incrément, architecture, flux,
  modèle de données et RLS, design system, parcours et maquettes en texte. ADR-013 à ADR-019.
- 20/11/2026 — Phase 1 : personas, 37 user stories avec critères Étant donné / Quand / Alors,
  8 exigences transverses, MoSCoW, matrice de couverture (13/13 exigences couvertes, contrôle
  automatique). 10 nouvelles règles de gestion H13 à H22 à valider.
- 20/11/2026 — 15 images reçues dans `docs/design/` : inventaire et contrôle de transparence faits
  (charte §8). Fond nuit sur tous les écrans confirmé. Restent à fournir : éléments graphiques,
  2 variantes de logo, illustration enfant + renard, 6 univers.
- 20/11/2026 — Brand kit reçu : archivé (`docs/design/brand-kit.webp`), charte rédigée avec couleurs
  mesurées au pixel (`docs/design/charte-graphique.md`), ADR-012. Fichiers sources HD demandés.
- 20/11/2026 — Cadrage : INTAKE lu, reformulation, hypothèses, plan de réalisation, risques,
  tâches manuelles. Poste vérifié (Flutter 3.41.7, SDK Android 35, Docker Desktop 29.9.2 ; pas de Mac).
