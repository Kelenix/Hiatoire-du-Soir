# User stories — Histoires du Soir

> Phase 1 (Produit), 20/11/2026. Sources : `INTAKE.md`, `docs/plan-de-realisation.md`,
> `DECISION_LOG.md`, `docs/design/charte-graphique.md`.
> Chaque story trace vers une exigence (E1 à E13 du plan §1, ou un article de l'INTAKE).
> Format : priorité MoSCoW · taille S/M/L · incrément · dépendance native éventuelle.
> Critères d'acceptation : **Étant donné / Quand / Alors**.

## 1. Personas et contextes d'usage

**Camille, le parent (celui qui paie).** 30 à 45 ans. Le soir, fatiguée, au bord du lit avec son
téléphone, Wi-Fi de la maison. Veut lancer une histoire adaptée en moins d'une minute, sans
publicité, sans inscription au départ, avec la certitude que le contenu convient à son enfant et
que ses données sont protégées. Freins : formulaires, prix flous, contenus douteux.

**Léo, l'enfant (celui qui utilise).** 3 à 8 ans. Ne sait pas forcément lire : il navigue par les
images et les icônes, et l'écoute est essentielle. Utilise le téléphone du parent ou une tablette
familiale. Ne doit jamais pouvoir acheter, quitter l'app vers le web ou tomber sur une publicité.

**Contexte.** Chambre peu éclairée (d'où le fond nuit), téléphone parfois posé sur la table de nuit,
écran éteint pendant l'écoute.

## 2. Nouvelles règles de gestion (hypothèses à valider)

Elles complètent les hypothèses H1 à H12 du plan.

| # | Règle |
|---|-------|
| H13 | **Bibliothèque** : seules les histoires mises en favori sont conservées. La dernière histoire créée reste accessible depuis l'accueil jusqu'à la création suivante. (Sinon la limite de 3 favoris en gratuit n'aurait pas de sens.) |
| H14 | Les **personnages de la famille** (prénom, fille/garçon/neutre, animal, trait de caractère) sont créés par le parent dans l'Espace Parents ; l'enfant les choisit ensuite dans l'Espace Enfant. |
| H15 | **Situation** d'une histoire sur mesure : liste illustrée (premier jour d'école, peur du noir, nouveau bébé, déménagement, chez le dentiste, nuit chez les grands-parents…) ou texte libre de 150 caractères maximum. |
| H16 | **Contenu des packs** : Aventures Premium = 10 crédits utilisables sur les thèmes Premium hors saisonniers ; Pack Noël = 10 crédits sur le thème Noël, personnalisation comprise ; Histoire sur mesure = 1 crédit avec personnalisation sur le thème de son choix ; Pack Famille = 30 crédits valables partout (H8). |
| H17 | **Paramètres** : voix par défaut, vitesse de lecture (lente / normale), taille du texte. |
| H18 | En gratuit, l'accueil de l'enfant montre les **histoires restantes de la semaine sous forme d'étoiles**, sans aucun prix. |
| H19 | **Plafond anti-abus Premium** : 30 histoires par jour, invisible en usage normal, mentionné dans les conditions de vente. Protège les coûts contre un usage automatisé. |
| H20 | Les **crédits n'expirent pas**. |
| H21 | **Versions minimales** : Android 8 et iOS 15. |
| H22 | Quand l'app passe en arrière-plan, elle **revient à l'Espace Enfant** : un parent ne laisse pas l'Espace Parents ouvert par mégarde. |

## 3. Stories

### Épopée A — Démarrage et Espace Enfant

**US-01 — Ouvrir l'app sans inscription** · Must · S · Inc-0 · E7, ADR-010
En tant que parent, je veux utiliser l'app dès son ouverture, afin de découvrir sa valeur sans formulaire.
- Étant donné un premier lancement avec connexion, quand l'app s'ouvre, alors l'Espace Enfant s'affiche sans inscription et une session anonyme est créée en arrière-plan.
- Étant donné un premier lancement sans connexion, alors un écran « Pas de connexion » propose de réessayer.
- Étant donné un nouveau lancement, alors la même session est retrouvée (quota et favoris inchangés).

**US-02 — Accueil de l'Espace Enfant** · Must · M · Inc-0 · E7, INTAKE §5.1
En tant qu'enfant, je veux un accueil que je comprends sans savoir lire, afin de choisir seul une histoire.
- Alors l'accueil propose : « Créer une histoire », Mes histoires, Personnages, Thèmes, la dernière histoire (H13) et un accès discret à l'Espace Parents (icône famille).
- Chaque entrée associe une illustration ou une icône du kit à un libellé lu par le lecteur d'écran.
- Aucun prix, bouton d'achat, lien externe ni publicité n'apparaît sur aucun écran de l'Espace Enfant (vérifié par un test automatisé).

**US-03 — Histoires restantes en étoiles** · Should · S · Inc-1 · E10, H18
En tant qu'enfant, je veux voir combien d'histoires il me reste cette semaine, afin de ne pas être surpris.
- Étant donné un compte gratuit avec 2 histoires restantes, alors l'accueil affiche 2 étoiles allumées sur 3.
- Étant donné un abonné Premium, alors aucun indicateur n'est affiché.

### Épopée B — Créer et lire une histoire

**US-04 — Choisir un thème** · Must · M · Inc-1 / Inc-5 · E2
En tant qu'enfant ou parent, je veux choisir un thème illustré, afin d'obtenir l'histoire qui me fait envie.
- Alors les thèmes s'affichent en cartes illustrées ; Animaux et Forêt magique sont accessibles à tous, les thèmes Premium portent un cadenas doré.
- Quand on touche un thème verrouillé, alors l'écran « Demande à un parent » s'affiche (US-28), sans prix.
- La liste vient du serveur : ajouter ou retirer un thème ne demande pas de mise à jour de l'app.

**US-05 — Générer une histoire** · Must · L · Inc-1 · E1
En tant que parent, je veux qu'une histoire originale soit écrite sur le thème choisi, afin d'avoir une nouvelle histoire chaque soir.
- Étant donné un thème accessible et du quota, quand on touche « Créer une histoire », alors une histoire en français (titre + texte, environ 260 mots pour 2 minutes) est créée et affichée.
- Le contenu convient aux 3-8 ans : ni violence, ni peur intense, ni contenu sexuel, ni marque, ni personne réelle ; la fin est apaisante.
- Deux créations sur le même thème donnent deux histoires différentes.

**US-06 — Attendre la création, gérer les échecs** · Must · S · Inc-1
En tant que parent, je veux savoir que l'histoire arrive, afin de patienter sereinement.
- Pendant la création, une animation apaisante (renard, étoiles) et une phrase rassurante s'affichent.
- 9 histoires de 2 minutes sur 10 arrivent en moins de 15 secondes.
- Quand la création échoue ou dépasse 60 secondes, alors un message clair propose de réessayer et **aucun quota ni crédit n'est consommé**.

**US-07 — 3 histoires gratuites par semaine** · Must · M · Inc-1 · E10, H4, ADR-003
En tant que responsable de l'app, je veux limiter la version gratuite, afin de maîtriser les coûts.
- Étant donné un compte gratuit qui a créé 3 histoires depuis lundi 00:00 (heure de Paris), quand il en demande une 4ᵉ, alors le serveur refuse et l'écran « Demande à un parent » s'affiche.
- Le lundi suivant à 00:00, 3 nouvelles histoires sont disponibles.
- Le quota est vérifié par le serveur : une app modifiée ne peut pas le contourner.

**US-08 — Lire l'histoire** · Must · M · Inc-1 · E4
En tant qu'enfant ou parent, je veux lire confortablement l'histoire, afin de la partager au coucher.
- Alors le texte s'affiche en couleur Crème sur fond nuit, dans la taille choisie (US-18), avec les boutons Écouter, Favori ♥ et Retour.
- La taille de police du téléphone (accessibilité) est respectée.

**US-09 — Retrouver la dernière histoire** · Must · S · Inc-1 · E4, H13
En tant qu'enfant, je veux retrouver l'histoire de ce soir, afin de la relire après avoir fermé l'app.
- Étant donné une histoire créée puis l'app fermée, quand on la rouvre, alors la dernière histoire est proposée sur l'accueil.
- Quand une nouvelle histoire est créée, alors elle remplace la précédente (sauf si celle-ci est en favori).

### Épopée C — Écouter

**US-10 — Écouter avec la voix standard** · Must · M · Inc-2 · E5 · natif : synthèse vocale, audio en arrière-plan
En tant qu'enfant, je veux qu'on me lise l'histoire, afin de l'écouter les yeux fermés.
- Alors on peut lancer, mettre en pause et reprendre la lecture, avec une barre de progression.
- La lecture continue écran verrouillé ou téléphone posé.
- La voix française du téléphone est utilisée, à la vitesse choisie (US-18).

**US-11 — Une écoute par histoire en gratuit** · Must · S · Inc-2 · E5, E10, H5
En tant que responsable de l'app, je veux limiter l'écoute en gratuit, afin de respecter l'offre.
- Étant donné un compte gratuit, quand l'écoute démarre, alors elle est décomptée ; pause et reprise restent libres tant que le lecteur est ouvert ; quitter le lecteur termine l'écoute.
- Quand on tente une 2ᵉ écoute, alors le bouton est grisé et « Demande à un parent » s'affiche ; le texte reste lisible.
- Étant donné un abonné Premium, alors les écoutes sont illimitées.

**US-12 — Pas de voix française sur le téléphone** · Should · S · Inc-2 · E5
En tant que parent, je veux savoir quoi faire s'il n'y a pas de voix, afin que l'écoute fonctionne.
- Étant donné un téléphone sans voix française, quand on lance l'écoute, alors un message explique comment en installer une ; le lien vers les réglages du téléphone passe par le contrôle parental.

### Épopée D — Favoris

**US-13 — Ajouter ou retirer un favori** · Must · S · Inc-3 · E6
En tant qu'enfant, je veux garder mes histoires préférées, afin de les réentendre.
- Quand on touche ♥, alors l'histoire est ajoutée (ou retirée) des favoris, immédiatement et sur le serveur.

**US-14 — 3 favoris maximum en gratuit** · Must · S · Inc-3 · E6, H10
En tant que responsable de l'app, je veux limiter les favoris en gratuit, afin de respecter l'offre.
- Étant donné 3 favoris en gratuit, quand on en ajoute un 4ᵉ, alors le serveur refuse ; un message doux propose d'en retirer un ou de demander à un parent.
- Étant donné un abonnement qui expire avec 8 favoris, alors les 8 restent lisibles, mais aucun ajout n'est possible tant qu'il y en a plus de 3.

**US-15 — Mes histoires** · Must · M · Inc-3 · E6
En tant qu'enfant, je veux voir mes histoires gardées, afin de choisir celle de ce soir.
- Alors la liste montre chaque favori avec son titre et l'illustration de son thème ; le toucher ouvre la lecture.
- Étant donné aucun favori, alors un état vide illustré explique le cœur ♥.

### Épopée E — Espace Parents et contrôle parental

**US-16 — Contrôle parental** · Must · M · Inc-4 · E9, INTAKE §5.3 et §9
En tant que parent, je veux qu'un enfant ne puisse pas acheter ni sortir de l'app, afin d'être serein.
- Le contrôle est exigé avant : l'entrée dans l'Espace Parents, tout achat, tout lien externe, tout réglage.
- Le défi est infaisable pour un enfant de 3 à 8 ans : une opération écrite en toutes lettres (« trente-deux plus quinze ») à résoudre au clavier numérique, différente à chaque fois.
- Après 3 erreurs, retour à l'Espace Enfant.

**US-17 — Accueil de l'Espace Parents** · Must · S · Inc-4 · E8, H22
En tant que parent, je veux un espace de gestion clair, afin de trouver vite ce que je cherche.
- Alors il présente : Abonnement, Packs, Compte, Personnages de la famille, Paramètres, Support, Informations légales, et un bouton de retour à l'Espace Enfant.
- Quand l'app passe en arrière-plan, alors elle revient à l'Espace Enfant.

**US-18 — Paramètres** · Must · S · Inc-4 · E8, H17
En tant que parent, je veux régler la lecture, afin de l'adapter à mon enfant.
- Alors on peut choisir la voix par défaut, la vitesse de lecture (lente / normale) et la taille du texte ; les choix sont appliqués immédiatement.

**US-19 — Support** · Must · S · Inc-4 · E8
En tant que parent, je veux obtenir de l'aide, afin de résoudre un problème.
- Alors une courte FAQ s'affiche, et « Écrire au support » ouvre l'application e-mail (lien externe, donc après contrôle parental).

**US-20 — Compte parent** · Must · L · Inc-4 · E8, ADR-010 · natif : Sign in with Apple, Google Sign-In, stockage sécurisé
En tant que parent, je veux un compte, afin de ne jamais perdre achats, favoris et personnages.
- Alors on peut créer un compte ou se connecter par e-mail (code à 6 chiffres), Apple ou Google.
- La session anonyme est rattachée au compte : quota, favoris et personnages sont conservés.
- Étant donné une connexion sur un 2ᵉ appareil, alors favoris, personnages, crédits et abonnement y sont retrouvés.
- Les jetons de connexion sont rangés dans le stockage sécurisé du téléphone.

**US-21 — Supprimer son compte** · Must · M · Inc-4 · INTAKE §9 (règle des deux stores)
En tant que parent, je veux supprimer mon compte, afin que mes données disparaissent.
- Quand le parent confirme la suppression, alors histoires, personnages et prénoms sont effacés du serveur et la session est fermée.
- Avant confirmation, un message rappelle qu'un abonnement en cours s'annule dans le store (lien après contrôle parental).

**US-22 — Signaler une histoire** · Must · S · Inc-4 · H11 (règle Google Play sur les contenus générés par IA)
En tant que parent, je veux signaler une histoire inadaptée, afin qu'elle soit retirée et le problème corrigé.
- Depuis l'écran de lecture, après contrôle parental, le parent choisit un motif et peut ajouter un commentaire.
- L'histoire signalée disparaît de l'app et le signalement est enregistré pour analyse.

**US-23 — Informations légales** · Must · S · Inc-4 · INTAKE §9
En tant que parent, je veux consulter la politique de confidentialité et les conditions, afin de savoir comment mes données sont utilisées.
- Alors les liens (confidentialité, conditions d'utilisation et de vente, mentions légales) s'ouvrent après contrôle parental.

### Épopée F — Abonnement Premium

**US-24 — Découvrir l'offre Premium** · Must · M · Inc-5 · E11, INTAKE §6 étape 7
En tant que parent, je veux comprendre l'offre, afin de décider en confiance.
- Alors l'écran affiche « Créez des histoires illimitées pour votre enfant. », les avantages, les formules mensuelle (5,99 €) et annuelle (34,99 €, mise en avant avec l'économie réalisée) et l'essai gratuit de 7 jours.
- Les prix affichés viennent du store, dans la devise du parent.
- Cet écran n'existe que dans l'Espace Parents.

**US-25 — S'abonner avec essai gratuit** · Must · L · Inc-5 · E11, ADR-009 · natif : achats intégrés
En tant que parent, je veux m'abonner simplement, afin d'offrir des histoires illimitées.
- Étant donné un parent sans compte, quand il choisit une formule, alors la création du compte lui est d'abord proposée.
- Étant donné un compte store éligible, alors 7 jours gratuits précèdent le premier paiement, annulables à tout moment.
- Quand l'achat aboutit, alors les droits Premium sont actifs en moins de 10 secondes.
- Quand l'achat est annulé ou échoue, alors rien n'est débité et un message l'explique.

**US-26 — Restaurer et gérer l'abonnement** · Must · S · Inc-5 · E11
En tant que parent, je veux retrouver ou annuler mon abonnement, afin de garder la main.
- « Restaurer mes achats » réactive un abonnement ou le Pack Voix déjà payés.
- « Gérer mon abonnement » ouvre la page du store (lien externe, après contrôle parental).

**US-27 — Droits Premium** · Must · M · Inc-5 · E2, E11, ADR-011, H19
En tant qu'abonné, je veux tout débloquer, afin de ne plus penser aux limites.
- Alors sont débloqués : tous les thèmes (dont Noël et Halloween), les durées 2, 5 et 10 minutes, les histoires, favoris et écoutes illimités, les voix Premium et la personnalisation.
- Les packs ne sont pas proposés à un abonné actif.

**US-28 — Limite atteinte : demander à un parent** · Must · M · Inc-5 · INTAKE §6 étapes 6 à 8
En tant qu'enfant, quand quelque chose est verrouillé, je veux être guidé vers mes parents, afin de ne pas rester bloqué.
- Alors l'écran « Demande à un parent » montre le renard et un message doux, sans prix.
- Quand le parent touche « Je suis le parent » et réussit le contrôle, alors l'offre Premium et les packs s'affichent.
- Quand le parent ferme l'offre, alors on revient à l'Espace Enfant.

**US-29 — Fin d'abonnement** · Must · S · Inc-5 · E11, H10
En tant que parent, je veux que la fin d'abonnement soit sans mauvaise surprise, afin de garder ce qui compte.
- Étant donné un abonnement expiré, alors les limites gratuites s'appliquent de nouveau ; les favoris restent lisibles (US-14) et les crédits restants restent utilisables.

### Épopée G — Personnalisation

**US-30 — Personnages de la famille** · Must · M · Inc-6 · E3, H14
En tant que parent, je veux créer le personnage de mon enfant, afin qu'il devienne le héros des histoires.
- Dans l'Espace Parents, on peut créer, modifier et supprimer un personnage : prénom ou surnom (20 caractères maximum), fille / garçon / neutre, animal compagnon et trait de caractère choisis dans des listes illustrées.
- Le personnage apparaît ensuite dans « Personnages » de l'Espace Enfant.

**US-31 — Personnages prêts à l'emploi** · Must · S · Inc-6 · E3, INTAKE §5.1
En tant qu'enfant, je veux choisir un héros, afin de retrouver mes personnages préférés.
- Alors « Personnages » propose quelques héros prêts à l'emploi par thème (dont le renard de la mascotte), utilisables par tous.

**US-32 — Créer une histoire sur mesure** · Must · M · Inc-6 · E3, H15, ADR-004
En tant que parent, je veux adapter l'histoire à la vie de mon enfant, afin de l'aider à vivre un moment précis.
- La création propose, en option : un héros (personnage enregistré ou prêt à l'emploi), un animal et une situation (liste illustrée ou texte libre de 150 caractères maximum).
- Le prénom apparaît dans l'histoire avec les bons accords ; il n'est **jamais** transmis au service d'IA (vérifié par un test du serveur).
- Un texte libre détourné (« ignore tes consignes… ») est sans effet et l'histoire reste adaptée aux enfants.
- Accès : Premium, ou un crédit qui inclut la personnalisation ; sinon l'option est verrouillée (US-28).

### Épopée H — Packs et crédits

**US-33 — Découvrir les packs** · Must · S · Inc-7 · E12, H16
En tant que parent non abonné, je veux voir les packs, afin d'acheter sans m'abonner.
- Dans l'Espace Parents uniquement : Aventures Premium (2,99 €), Pack Noël (3,99 €), Histoire sur mesure (1,99 €), Pack Famille (9,99 €), chacun avec son contenu expliqué ; prix fournis par le store.

**US-34 — Acheter un pack** · Must · M · Inc-7 · E12, E13 · natif : achats intégrés (consommables)
En tant que parent, je veux acheter un pack en toute sécurité, afin d'obtenir des histoires en plus.
- Un compte parent est requis.
- Quand l'achat aboutit, alors les crédits sont ajoutés par le serveur en moins de 10 secondes.
- Quand l'achat est interrompu, alors aucun crédit n'est ajouté et rien n'est débité.

**US-35 — Utiliser ses crédits** · Must · M · Inc-7 · E13, H8, H16, H20
En tant que parent, je veux que les crédits soient utilisés intelligemment, afin de ne pas les gaspiller.
- Ordre de consommation : abonnement, puis quota gratuit si l'histoire reste dans l'offre gratuite, puis crédits du pack du thème, puis crédits génériques.
- Un crédit n'est décompté que si l'histoire est bien créée.
- Le solde s'affiche dans l'Espace Parents ; l'enfant ne voit ni crédit ni prix.

### Épopée I — Voix Premium

**US-36 — Écouter avec une voix apaisante** · Must · M · Inc-8 · E5, ADR-008
En tant que parent, je veux une voix plus douce, afin d'endormir mon enfant en douceur.
- Alors au moins 3 voix apaisantes sont proposées, chacune avec un court extrait d'écoute ; elles sont réservées au Premium et au Pack Voix.
- La première écoute d'une histoire avec une voix Premium démarre en moins de 10 secondes ; les écoutes suivantes sont immédiates (audio gardé sur le serveur).

**US-37 — Acheter le Pack Voix** · Must · S · Inc-8 · E12, H9 · natif : achats intégrés (achat définitif)
En tant que parent non abonné, je veux acheter les voix apaisantes une fois pour toutes, afin d'en profiter sans abonnement.
- Achat définitif à 1,99 €, compte parent requis, restaurable sur un autre appareil (US-26).
- En gratuit, la limite d'une écoute par histoire s'applique toujours.

### Exigences transverses

| ID | Exigence | Priorité | Vérification |
|----|----------|----------|--------------|
| NF-01 | Aucune publicité et aucun outil tiers de publicité ou de statistiques (INTAKE §4, ADR-005) | Must | revue des dépendances à chaque version |
| NF-02 | Confidentialité : prénom jamais envoyé à l'IA, données hébergées dans l'UE, données minimales, accès protégé ligne par ligne (RLS) | Must | tests du serveur et de la RLS |
| NF-03 | Sécurité du contenu : aucune histoire inadaptée sur un jeu de 200 créations de test, dont 50 tentatives de détournement | Must | jeu de test rejoué avant chaque version |
| NF-04 | Performance : ouverture en moins de 2,5 s sur un Android milieu de gamme, animations fluides (60 images/s) | Should | mesure sur appareil réel |
| NF-05 | Accessibilité : zones tactiles ≥ 48 dp, contrastes suffisants, lecteurs d'écran, tailles de texte du téléphone, « réduire les animations » respecté | Must | revue d'accessibilité en phase 5 |
| NF-06 | Sans connexion : message clair, aucune perte de données, aucun quota consommé | Must | test hors-ligne |
| NF-07 | Français uniquement ; prix dans la devise du store | Must | revue |
| NF-08 | Android 8+ et iOS 15+ (H21), téléphones et tablettes en mode portrait | Must | tests sur émulateurs et appareils |

## 4. Priorisation et périmètre

- **MVP (V1)** : toutes les stories **Must**, c'est-à-dire l'intégralité du périmètre de l'INTAKE §11.
- **Should** (prévues en V1, sacrifiables en dernier recours) : US-03, US-12, NF-04.
- **Could, plus tard** (non demandées, idées à proposer) : minuterie d'arrêt de l'écoute, surlignage
  du texte pendant la lecture audio, lecture hors-ligne des favoris.
- **Won't (V1)** : publicité et option de suppression des pubs (INTAKE §11), plusieurs profils
  enfants, autres langues, illustrations générées, notifications, back-office, version web.

## 5. Matrice de couverture

| Exigence | Stories |
|----------|---------|
| E1 Génération par IA | US-05, US-06 |
| E2 Thèmes | US-04, US-27 |
| E3 Personnalisation | US-30, US-31, US-32 |
| E4 Lecture | US-08, US-09 |
| E5 Audio avec voix | US-10, US-11, US-12, US-36 |
| E6 Favoris | US-13, US-14, US-15 |
| E7 Espace Enfant | US-01, US-02, US-03 |
| E8 Espace Parents | US-17, US-18, US-19, US-20, US-21 |
| E9 Contrôle parental | US-16 |
| E10 Gratuit 3/semaine | US-03, US-07, US-11 |
| E11 Abonnements + essai | US-24, US-25, US-26, US-27, US-28, US-29 |
| E12 Packs et voix | US-33, US-34, US-37 |
| E13 Crédits | US-35 |
| INTAKE §4 Pas de publicité | US-02, NF-01 |
| INTAKE §6 Parcours principal | US-04, US-05, US-08, US-10, US-13, US-07, US-28, US-24 |
| INTAKE §8 Maîtrise des coûts | US-07, US-27 (H19), US-36 (audio gardé) |
| INTAKE §9 Conformité stores | US-16, US-21, US-22, US-23, NF-01, NF-02 |

**Contrôle** : les 13 exigences du périmètre V1 et les articles 4, 6, 8 et 9 de l'INTAKE sont
couverts par au moins une story ; aucune story ne sort du périmètre.
