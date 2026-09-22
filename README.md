# Agenda

Une appli d'agenda native macOS / iOS (SwiftUI) : planning journalier et
hebdomadaire, activités colorées par calendrier, création à la volée en
glissant sur la timeline. Elle lit et écrit directement dans le calendrier
système (EventKit) — donc tout se synchronise nativement avec l'app
Calendar de ton Mac (et iCloud, si tes calendriers y sont).

## Fonctionnalités (v1)

- Vue **Jour** : timeline verticale 24h, blocs colorés par calendrier,
  ligne "maintenant", glisser sur une plage horaire vide pour créer une
  activité.
- Vue **Semaine** : grille 7 jours, tap sur un jour pour revenir en vue Jour.
- Filtres en pastilles colorées pour afficher/masquer chaque calendrier.
- Création / édition / suppression d'activités, avec choix du
  calendrier (= couleur).
- Rafraîchissement automatique quand un événement change ailleurs
  (app Calendar, autre appareil via iCloud).
- Petits retours haptiques pour un rendu ludique (tap, création réussie).

## Structure

```
Sources/Agenda/
  AgendaApp.swift            point d'entrée
  Models/                    (réservé — catégories/tags futurs)
  Services/
    CalendarService.swift    accès EventKit (lecture/écriture/sync)
    Haptics.swift            retours tactiles iOS/macOS
  ViewModels/
    PlannerViewModel.swift   état de navigation (jour/semaine, édition)
  Views/
    ContentView.swift        écran racine (header, filtres, contenu)
    DayView.swift             timeline jour + geste glisser-pour-créer
    WeekView.swift             grille semaine
    ActivityBlockView.swift   bloc coloré d'une activité
    ActivityEditorView.swift  formulaire de création/édition
    CalendarFilterChips.swift filtres par calendrier
    TimelineRuler.swift       règle des heures + grille
  Extensions/
    Date+Agenda.swift        aides de dates/temps
```

## Mise en route

Voir `SETUP.md` — création du projet Xcode en ~2 minutes, puis lancement.

Écrit dans un environnement Linux sans Xcode disponible : le code n'a
donc pas pu être compilé ici. Première étape sur ton Mac : ouvrir le
projet dans Xcode et corriger les éventuelles coquilles de compilation
(peu probables mais possibles sur un projet de cette taille écrit sans
build local).
