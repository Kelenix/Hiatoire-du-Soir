# Tâches manuelles — Histoires du Soir

> Ce que seul toi peux faire (comptes, paiements, identité, juridique). Classé par jalon où la tâche
> devient bloquante. Les secrets ne se collent jamais dans le chat ni dans le dépôt : je te dirai
> dans quel fichier local ignoré par Git les placer.

## Poste de développement (vérifié le 20/11/2026)

- [x] Flutter 3.41.7 (stable), SDK Android 35
- [x] Docker Desktop 29.9.2 démarré
- [x] Node.js, Git, GitHub CLI
- [x] Émulateur Android `histoires_pixel` (Pixel 8, Android 15) installé le 20/11/2026
- [x] Supabase local du projet sur les ports 593xx (les autres projets locaux gardent les leurs)
- [ ] Pas de Mac : les builds iOS passeront par GitHub Actions (macOS), voir J4

## Dès que possible — fichiers sources du brand kit

- [x] Mascotte, 5 icônes, 4 univers et fiches couleur déposés dans `docs/design/` (20/11/2026).
- [ ] Générer avec le même outil et déposer dans `docs/design/` les éléments encore manquants
      (`docs/design/charte-graphique.md` §8) : étoile, lune, nuage, scintillements ; logo « lune +
      étoile » et monogramme « H » ; illustration enfant + renard ; univers Animaux, Océan, Espace,
      Dinosaures, Pirates, Halloween.
- [ ] Facultatif, même outil : 10 animaux (renard, lapin, ours, chat, chien, chouette, dragon,
      licorne, dauphin, tortue) et 4 héros prêts à l'emploi (Pipo le renard, Plume la chouette,
      Bulle le dauphin, Étincelle le dragon). En attendant, l'app affiche des émojis (ADR-030).

## Avant J1 — première histoire générée

- [ ] **Compte Anthropic** (console.anthropic.com) : moyen de paiement, clé API, **plafond de
      dépense mensuel**. Coller la clé après `ANTHROPIC_API_KEY=` dans `supabase/functions/.env`
      (fichier déjà créé, ignoré par Git), puis me prévenir : je lance l'essai de bout en bout.
- [ ] Conseil poste : Docker Desktop est limité à 8 Go et plusieurs projets Supabase tournaient en
      même temps ; le 20/11, Docker a coupé des conteneurs faute de mémoire. Arrêter les projets
      inutilisés (`npx supabase stop` dans chacun).

## À lancer dès maintenant (délais de validation) — bloquant pour J3

- [ ] **Google Play Console** : 25 $ une fois ; la vérification d'identité peut prendre plusieurs jours.
- [ ] **Apple Developer Program** : 99 $/an ; puis dans App Store Connect, accord « Paid
      Applications », coordonnées bancaires et fiscales.
- [ ] Demander la **commission réduite à 15 %** : programme Small Business d'Apple, et 15 % sur le
      premier million de Google Play (inscription au groupe de comptes).

## Avant J3 — monétisation

- [ ] Compte **RevenueCat** relié aux deux stores, puis :
      - droit (entitlement) nommé **`premium`** ;
      - produits : abonnement mensuel 5,99 € et annuel 34,99 €, avec **essai gratuit de 7 jours** ;
      - offre « current » contenant les paquets **Annual** et **Monthly** ;
      - webhook vers `https://tsndbpfdctuwxjpyvfwl.supabase.co/functions/v1/purchases-webhook`,
        en-tête d'autorisation `Bearer <secret>`, avec le secret déjà installé en production :
        ligne `REVENUECAT_WEBHOOK_SECRET` de `supabase/functions/.env.production` (fichier local
        ignoré par Git) ;
      - clés publiques Android et iOS dans `REVENUECAT_ANDROID_KEY` et `REVENUECAT_IOS_KEY`
        (`env/*.json`). Sans elles, l'écran d'offre affiche « offres indisponibles ».
- [ ] Compte **Google Cloud** pour les voix apaisantes (Inc-8), avec :
      - l'API **Cloud Text-to-Speech** activée et un moyen de paiement ;
      - un **budget avec alerte** (par exemple 10 €/mois) ;
      - une **clé d'API limitée à cette seule API** (Identifiants → Restreindre la clé). La coller
        après `GOOGLE_TTS_API_KEY=` dans `supabase/functions/.env`, puis dans
        `supabase/functions/.env.production` (fichiers ignorés par Git), puis me prévenir : je
        lance l'essai réel, puis le test d'écoute des voix (ADR-035).
- [ ] Création des produits dans les deux stores, identifiants à reprendre à l'identique :
      - abonnements : mensuel 5,99 € et annuel 34,99 €, essai de 7 jours, liés au droit `premium` ;
      - packs (produits consommables, sans droit RevenueCat) : `pack_aventures_10` (2,99 €),
        `pack_noel_10` (3,99 €), `histoire_sur_mesure_1` (1,99 €), `pack_famille_30` (9,99 €) ;
      - Pack Voix : `pack_voix` (1,99 €), produit **non consommable** (achat définitif, restaurable) ;
      - les ajouter aussi comme produits dans RevenueCat. Le contenu de chaque pack est en base
        (`credit_packs`), le prix vient du store.

## Avant J4 / J5 — publication

- [ ] Dépôt **GitHub** (privé) pour la CI et les builds iOS.
- [x] **Projet Supabase de production** créé (Irlande, UE) et configuré le 20/11/2026 : base,
      fonctions, secrets, authentification. Plan (gratuit / Pro) à décider en phase 6 : le plan
      gratuit met le projet en pause après 7 jours sans activité.
- [ ] **Envoi des e-mails (SMTP)** — bloquant avant la publication : l'expéditeur fourni par
      Supabase n'envoie qu'aux membres de ton équipe Supabase, quelques messages par heure. Les
      parents ne recevraient pas leur code. Créer un compte chez un service d'envoi (Brevo,
      Resend…) avec un nom de domaine, puis me donner l'hôte et l'expéditeur ; tu colleras le mot
      de passe SMTP toi-même dans Supabase (Authentication → Emails → SMTP).
- [ ] **Clé Anthropic de production** (conseillé) : une clé distincte avec son propre plafond de
      dépense. Aujourd'hui la production utilise la même clé que le développement ; pour la
      changer, la mettre dans `supabase/functions/.env.production`, puis me prévenir.
- [ ] **Sign in with Apple** (Service ID, clé) et **Google Sign-In** (identifiants Android et iOS) :
      les boutons Apple et Google du compte parent seront ajoutés dès réception (ADR-026).
- [ ] **Adresse e-mail de support** : à mettre dans `SUPPORT_EMAIL` (`env/*.json`) ; le bouton
      « Écrire au support » apparaît alors dans l'Espace Parents.
- [x] Projet Supabase de production : « Confirm email » actif (vérifié le 20/11/2026, ADR-025).
- [ ] **Informations de l'éditeur** (nom ou société, adresse) pour mentions légales, politique de
      confidentialité et conditions de vente ; relecture juridique recommandée (données d'enfants).
- [ ] **URL publique** pour la politique de confidentialité et le support (exigée par les stores) :
      à mettre dans `LEGAL_URL` (`env/*.json`) ; l'entrée « Informations légales » apparaît alors.
- [ ] **Anti-abus du quota gratuit (décision)** : activer l'attestation de l'appareil (Play
      Integrity sur Android, App Attest sur iPhone, gratuites) pour que les histoires gratuites ne
      puissent pas être obtenues en recréant des comptes par script (risque R15, ADR-036). Je
      recommande oui ; la configuration se fait dans la Play Console et l'App Store Connect.
- [ ] **Politique de confidentialité** : y nommer les sous-traitants (Supabase, Anthropic, Google
      Cloud Text-to-Speech, RevenueCat, stores) ; la liste et les données sont dans `docs/security.md` §3.
- [ ] **Un téléphone Android d'entrée de gamme** (le tien ou un prêt) pour mesurer démarrage et
      fluidité en conditions réelles pendant le test interne (`docs/performance.md`).
- [ ] **Captures d'écran des stores** : je les produis depuis l'app ; tu valides.
- [ ] **Clé de signature Android** : je la génère, tu la sauvegardes en lieu sûr (sa perte empêche
      toute mise à jour de l'app).
