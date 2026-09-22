# Créer le projet Xcode (2 minutes)

Le code est prêt dans `Sources/Agenda/`. Il ne manque que l'enveloppe
projet Xcode, qu'Xcode génère mieux que quiconque — voici comment relier
les deux.

1. **Xcode → File → New → Project…**
2. Choisis **Multiplatform → App**.
3. Nom du produit : `Agenda`. Interface : **SwiftUI**. Langage : **Swift**.
   Décoche "Include Tests" si tu veux (facultatif).
4. Enregistre le projet **à la racine de ce repo** (`agenda-app/`), à
   côté du dossier `Sources/`.
5. Dans le navigateur de projet Xcode, **supprime** les fichiers par
   défaut générés (`ContentView.swift`, `AgendaApp.swift` du template)
   — on va utiliser les nôtres.
6. **Glisse le dossier `Sources/Agenda`** (avec ses sous-dossiers
   `Models`, `Services`, `ViewModels`, `Views`, `Extensions`) dans le
   navigateur de projet Xcode, sous la cible `Agenda`. Coche "Copy items
   if needed" **décoché** (les fichiers sont déjà au bon endroit) et
   "Create groups".

## Autoriser l'accès au calendrier

Dans les réglages de la cible (**Signing & Capabilities** puis
**Info**), ajoute ces clés Info.plist (onglet **Info**, "+"):

- `NSCalendarsFullAccessUsageDescription` (iOS 17+ / macOS 14+) :
  `Agenda a besoin d'accéder à ton calendrier pour afficher et créer tes activités.`
- `NSCalendarsUsageDescription` (compatibilité versions antérieures) :
  même texte.

Si la cible macOS est **sandboxée** (App Sandbox activé, ce qui est le
cas par défaut) : dans **Signing & Capabilities**, sous "App Sandbox",
coche **Calendars**.

## Cible minimale

Le code utilise `requestFullAccessToEvents()` (EventKit moderne) : règle
le déploiement minimum sur **iOS 17** et **macOS 14** dans les réglages
de la cible (onglet "General").

## Lancer

Sélectionne le simulateur ou "My Mac" comme destination, puis ▶️. La
première fois, macOS/iOS demandera l'autorisation d'accéder au
calendrier — accepte-la pour voir tes calendriers existants apparaître
en couleurs.

## Pistes d'évolution

- Glisser pour **déplacer/redimensionner** un bloc existant (aujourd'hui
  seule la création par glissé est câblée ; modifier passe par le
  formulaire).
- Vue **Mois**.
- Widgets iOS/macOS (aperçu du jour).
- Catégories/tags internes en plus des calendriers (actuellement la
  couleur suit le calendrier, comme dans Calendar.app).
