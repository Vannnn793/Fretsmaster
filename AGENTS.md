# Antigravity Rules - Always Active

Whenever designing, writing, editing, or refactoring code in this project, you MUST automatically apply the following two skills:

## 1. Skill: codebase-design
- **Goal:** Design deep modules with small, clean interfaces hiding complex implementations behind them.
- **Seams & Boundaries:** Maintain clean seams between layers (Domain Entity & Repository, Data Source, Presentation BLoC).
- **Testability & Leverage:** Ensure high leverage for callers, locality for maintainers, and direct unit-testability.
- **Avoid:** Shallow pass-through modules or leaky abstractions.

## 2. Skill: frontend-design
- **Goal:** Create intentional, distinctive visual design tailored for FretMaster (music & mobile computer vision).
- **Aesthetic Direction:** Use high-contrast dark theme with premium gold/amber accents appropriate for guitarists and stage lighting.
- **Typography & Layout:** Structure visual hierarchy deliberately; avoid generic AI-generated templates (such as cliché rounded cards with gray drop-shadows).
- **Responsive & Performance:** Keep camera previews, custom painters, and UI widgets buttery-smooth at 60 FPS without memory bloat.
