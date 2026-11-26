# Coding and Design Standards (Always On)

Whenever designing, writing, editing, or refactoring code in this project, you MUST automatically apply the following two skills:

## 1. Skill: codebase-design
- **Goal:** Design deep modules with small, clear interfaces that hide complex implementations behind them.
- **Seams & Boundaries:** Place seams cleanly between layers (Domain Entity & Repository, Data Source, Presentation BLoC).
- **Testability & Leverage:** Ensure modules provide high leverage for callers, have high locality for maintainers, and are easily unit-testable.
- **Avoid:** Shallow pass-through modules or leaky abstractions.

## 2. Skill: frontend-design
- **Goal:** Create intentional, distinctive visual design tailored for FretMaster (music & computer vision on mobile).
- **Aesthetic Direction:** Use high-contrast dark theme with premium gold/amber accents appropriate for guitar players and stage/ambient lighting.
- **Typography & Layout:** Structure visual hierarchy deliberately; avoid generic AI-generated templates (such as repetitive rounded cards with gray drop-shadows or cliché layouts).
- **Responsive & Performance:** Keep camera previews, custom painters, and UI widgets buttery-smooth at 60 FPS without memory bloat.
