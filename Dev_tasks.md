# Pillo Development Tasks

## In Progress


## Backlog

- [ ] **Fix endless vitamin recommendations** — Implement diminishing + cross-goal aware recommendations. Recs decrease as user adds supplements (3→2→1→0). At 3+ per goal, show "Solid foundation!" Cross-goal counting so Vitamin D satisfies Energy, Immunity, and Skin goals simultaneously. Files: `GoalsListView.swift`, `SupplementDatabaseService.swift`. Open question: show "Show more" for power users or hard cutoff?


## Completed

- [x] **Enhanced supplement metadata & keyword search** — Added 4 new fields to all 199 supplements with NIH-sourced data: `keywords` (searchable tags), `benefits` (WHY it matters), `demographics` (who should consider it), `deficiencySigns` (hidden behind "Learn more"). Search matches keywords + goals with context shown. Benefits displayed as hero section in detail view.

