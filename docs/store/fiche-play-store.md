# Fiche Play Store — Histoires du Soir (fr-FR)

> Textes saisis dans la Play Console (compte développeur Kelenix, app `fr.histoiresdusoir.app`).
> Toute modification se fait ici d'abord, puis dans la console.

## Textes

**Nom de l'app (30 max)** : Histoires du Soir

**Description courte (80 max)** :
Des histoires du coucher personnalisées pour votre enfant, à lire ou à écouter.

**Description complète (4 000 max)** :

Chaque soir, une nouvelle histoire rien que pour votre enfant.

Histoires du Soir crée des histoires du coucher personnalisées en quelques secondes. Choisissez un
univers, un héros et une durée : l'histoire s'écrit pour votre enfant, avec son prénom s'il le
souhaite. Lisez-la ensemble ou écoutez-la, lumière éteinte, avec une voix douce.

UNE HISTOIRE UNIQUE À CHAQUE FOIS
• Des univers qui font rêver : animaux, forêt magique, château, dragons, Noël…
• Votre enfant devient le héros, ou choisit un compagnon : renard, lapin, chouette, dauphin…
• Des histoires de 2, 5 ou 10 minutes, toujours douces et rassurantes, pensées pour l'endormissement.

À LIRE OU À ÉCOUTER
• Une lecture à voix haute posée, avec des pauses entre les paragraphes.
• Des voix apaisantes, plus naturelles, avec Premium ou le Pack Voix.
• L'écoute continue écran verrouillé.

UN ESPACE ENFANT SÛR
• Aucune publicité, jamais.
• Aucun lien extérieur ni achat dans l'espace Enfant.
• Les réglages, les achats et le compte sont protégés par un contrôle parental.
• Un bouton « Signaler » pour nous alerter sur une histoire.

VOS HISTOIRES PRÉFÉRÉES
• Gardez les histoires que votre enfant aime pour les relire.
• Créez les personnages de la famille et retrouvez-les dans chaque histoire.

GRATUIT, AVEC PREMIUM EN OPTION
La version gratuite permet de créer 3 histoires par semaine sur les thèmes gratuits. L'abonnement
Premium (mensuel ou annuel, avec essai gratuit de 7 jours) débloque les histoires illimitées, tous
les univers, toutes les durées, les favoris illimités et les voix apaisantes. Des packs d'histoires
sont aussi proposés sans abonnement.

VIE PRIVÉE
Le prénom de votre enfant n'est jamais envoyé au service d'intelligence artificielle qui écrit
l'histoire. Pas de publicité, pas de pistage, pas de revente de données.

Les histoires sont écrites par une intelligence artificielle encadrée par des consignes adaptées
aux enfants. Nous recommandons qu'un adulte les découvre avec l'enfant.

Confidentialité : https://kelenix.github.io/histoires-du-soir-site/confidentialite.html
Contact : lionelkelenix@gmail.com

## Classement et coordonnées

- **Catégorie** : Livres et références (repli : Éducation).
- **Tags** : histoires, contes, enfants, coucher.
- **E-mail** : lionelkelenix@gmail.com · **Site web** : https://kelenix.github.io/histoires-du-soir-site/
- **Règles de confidentialité** : https://kelenix.github.io/histoires-du-soir-site/confidentialite.html
- **Suppression du compte** : https://kelenix.github.io/histoires-du-soir-site/suppression-compte.html

## Visuels (`docs/store/visuels/`)

| Fichier | Format | Usage |
|---------|--------|-------|
| `icone-512.png` | 512 × 512 | Icône de la fiche |
| `banniere-1024x500.png` | 1024 × 500 | Image de présentation |
| `capture-1` à `capture-6` | 1080 × 1920 | Captures téléphone, légendées |

## Contenu de l'app (déclarations)

| Rubrique | Réponse | Pourquoi |
|----------|---------|----------|
| Accès à l'app | Toutes les fonctions sans identifiant ; contrôle parental expliqué au réviseur | Pas de compte obligatoire |
| Publicités | Non | Aucune publicité (INTAKE §4) |
| Public cible | Parents (18 ans et +) et enfants de 5 ans et moins, 6 à 8 ans | App familiale : programme Familles de Google Play |
| Classification | Questionnaire IARC : aucune violence, peur, langage ni achat dans l'espace Enfant | Attendu : PEGI 3 / Tout public |
| Sécurité des données | Voir ci-dessous | `docs/security.md` §3 |
| Application gouvernementale, santé, finances, actualités | Non | — |
| Identifiant publicitaire | Non utilisé | Aucun SDK publicitaire |

### Sécurité des données (Data safety)

- **Chiffrement en transit** : oui. **Suppression sur demande** : oui (app + page web).
- **Collectées** (non partagées, sauf prestataires) :
  - Informations personnelles → **Adresse e-mail** (facultatif, compte) ; **Nom** (facultatif : prénom
    du personnage / profil Google) — fonctionnement de l'app, gestion du compte.
  - Informations financières → **Historique des achats** — fonctionnement de l'app.
  - Activité dans l'app → **Contenus générés par l'utilisateur** (histoires, personnages) ;
    **Autres actions** (créations, écoutes) — fonctionnement de l'app, prévention des abus.
  - Identifiants de l'appareil ou autres → **ID utilisateur** (session anonyme) — fonctionnement.
- **Non collectées** : position, contacts, photos, audio du micro, santé, navigation, identifiant
  publicitaire, journaux de plantage.
- **Partage** : aucun partage au sens de Google Play (les prestataires agissent pour notre compte).

## Note au réviseur (accès à l'app)

> L'app s'utilise sans compte. L'Espace Parents (achats, réglages, compte) est protégé par un
> contrôle parental : une addition écrite en toutes lettres (ex. « Combien font sept plus douze ? »),
> à saisir en chiffres. Les achats intégrés passent par Google Play Billing.
