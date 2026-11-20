# Registre des risques — Histoires du Soir

> Phase 2, 20/11/2026. Probabilité (P) et impact (I) notés de 1 à 3 ; score = P × I.
> 🔴 score ≥ 6 · 🟡 3 à 4 · 🟢 ≤ 2. Revu à chaque fin d'incrément.

| # | Risque | P | I | Score | Parade | Incrément | État |
|---|--------|---|---|-------|--------|-----------|------|
| R1 | Histoire inadaptée pour un enfant (contenu choquant, détournement par le texte libre) | 2 | 3 | 🔴 6 | consignes strictes, texte libre borné et traité comme donnée, sortie structurée, contrôle par un second appel avant affichage, signalement parent, jeu de 200 tests (NF-03) | Inc-1, Inc-6 | ouvert |
| R2 | Rejet par Apple ou Google (règles enfants/familles, achats, contrôle parental, IA, suppression de compte, fiches confidentialité) | 2 | 3 | 🔴 6 | conformité dès la conception (ADR-005), checklist store en phase 6, Android publié d'abord pour apprendre | toutes | ouvert |
| R3 | Pas de Mac : impossible de compiler, signer et tester iOS en local | 3 | 2 | 🔴 6 | builds iOS sur GitHub Actions (macOS) + Fastlane, tests sur iPhone via TestFlight dès J3 | Inc-0, J4 | ouvert |
| R4 | Les achats intégrés ne se testent qu'avec des comptes stores validés et une app déjà publiée en test interne | 3 | 2 | 🔴 6 | ouvrir les comptes maintenant ; publier un premier build Android en test interne dès la fin de Inc-4 | Inc-5 | ouvert, dépend de toi |
| R5 | Coûts IA et voix supérieurs au revenu (gros utilisateurs, abus) | 2 | 2 | 🟡 4 | quotas serveur, plafond anti-abus (H19), audio gardé, journal des générations pour suivre le coût réel, plafonds de dépense chez Anthropic et Google | Inc-1, Inc-8 | ouvert |
| R6 | Données d'enfants (RGPD) mal protégées | 1 | 3 | 🟡 3 | prénom jamais envoyé à l'IA ni stocké dans les textes, RLS testée sur chaque table, hébergement UE, suppression de compte, signalements sans prénom | toutes | ouvert |
| R7 | Synthèse vocale du téléphone : voix française absente, rendu inégal, enregistrement en fichier peu fiable sur certains appareils | 2 | 2 | 🟡 4 | validé sur Android (émulateur) ; plugin muet en cas d'échec → délai de 45 s et détection de voix installée (US-12) ; reste à tester sur iPhone (TestFlight) et à découper les textes > 4 000 caractères (Inc-5) | Inc-2, Inc-5 | Android maîtrisé, iOS ouvert |
| R8 | L'écoute s'arrête quand l'écran s'éteint | 1 | 2 | 🟢 2 | vérifié le 20/11 : écran éteint, le lecteur de l'app reste actif (Android) ; iOS à vérifier (TestFlight) | Inc-2 | Android maîtrisé |
| R9 | Création trop lente ou coupée par la limite de durée des Edge Functions | 1 | 2 | 🟢 2 | mesuré le 20/11 : 10,5 à 12,4 s pour 2 min ; à remesurer pour 5 et 10 min (Inc-5) | Inc-1, Inc-5 | maîtrisé pour 2 min |
| R10 | Fichiers graphiques encore manquants (éléments, 2 logos, illustration principale, 6 univers) | 2 | 2 | 🟡 4 | découpes provisoires du kit ; remplacement avant J4 | Inc-0 → J4 | ouvert, dépend de toi |
| R11 | Sign in with Apple obligatoire dès qu'on propose Google sur iPhone | 3 | 1 | 🟡 3 | prévu dans US-20 | Inc-4 | maîtrisé |
| R12 | Limites du plan gratuit Supabase en production (taille de stockage audio, pause d'un projet inactif) | 2 | 2 | 🟡 4 | suivi de l'usage ; décision du plan en phase 6 | phase 6 | ouvert |
| R13 | Fournisseur externe indisponible (Anthropic, Google, RevenueCat) | 1 | 2 | 🟢 2 | messages clairs, aucun quota consommé en cas d'échec, droits Premium lus dans Supabase (pas en direct chez RevenueCat) | Inc-1, Inc-5 | maîtrisé |
| R14 | Modèle d'IA retiré ou changé par le fournisseur | 1 | 2 | 🟢 2 | modèle réglé côté serveur, changeable sans mise à jour de l'app | Inc-1 | maîtrisé |
| R15 | Abus du quota gratuit : comptes anonymes recréés en boucle (script, déconnexion) pour obtenir des histoires gratuites | 2 | 2 | 🟡 4 | tentatives bornées par compte (ADR-036), 30 sessions anonymes par heure et par IP, plafond de dépense Anthropic ; attestation de l'appareil (Play Integrity, App Attest) à décider avant publication | phase 5 → J4 | atténué, décision en phase 6 |

## Chemin critique

1. **Clé API Anthropic** → bloque Inc-1 (première histoire).
2. **Comptes Google Play et Apple Developer** (validation en plusieurs jours) → bloquent les tests
   d'achats (Inc-5, J3) et la publication.
3. **Dépôt GitHub** → bloque les builds iOS (J4).
4. **Fichiers graphiques manquants** → bloquent le rendu final (J4), pas le développement.

## Jalons

| Jalon | Contenu | Preuve attendue |
|-------|---------|-----------------|
| J1 | Inc-0 et Inc-1 | capture de l'émulateur Android : accueil fidèle au kit, première histoire affichée, 4ᵉ refusée |
| J2 | Inc-2 à Inc-4 | parcours gratuit complet sur émulateur, écoute écran verrouillé, contrôle parental |
| J3 | Inc-5 à Inc-8 | achats en bac à sable sur Android (test interne) puis iPhone (TestFlight) |
| J4 | builds de production Android (.aab) et iOS, CI verte | builds téléchargés par les testeurs |
| J5 | soumission aux stores | accusés de réception Apple et Google |
