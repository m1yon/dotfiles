---
name: recipes
description: Add or edit recipes in Michael's Obsidian vault using the live Recipe Template, keep the Recipes index in sync, and add requested recipe ingredients to a Walmart pickup cart through Chrome. Use only when explicitly invoked as $recipes or /recipes, or asked to use the recipes skill.
---

# Recipes

Add and edit recipe notes in Michael's Obsidian vault. Keep recipes concise and readable while cooking. When requested, add recipe ingredients to a Walmart pickup cart and stop before checkout.

## Choose the flow

- For recipe additions or edits, follow the note workflow below and keep the index in sync.
- For a recipe shopping request, follow [Walmart pickup cart](references/walmart-cart.md). Read the requested recipes without changing their notes or the index.
- For a combined request, finish and verify the recipe and index changes first, then build the cart from the saved recipes.

Shopping requires a request to add ingredients to the cart. Merely adding or editing a recipe does not start shopping. This skill remains explicitly invoked.

## Vault locations

Use the `obsidian-vault` skill for CLI syntax, filesystem fallbacks, and vault conventions.

- Recipes are notes in `6 - Full Notes/`, named for the dish, with `Tags: [[recipes]]`.
- The index is `4 - Indexes/Recipes.md`.
- The template is `5 - Templates/Recipe Template.md`.
- The tag stub is `3 - Tags/recipes.md`.

Target the index and tag stub with `path=`. Their names differ only by case, and both `file=Recipes` and `[[Recipes]]` resolve to the empty tag stub. Link to the index as `[[4 - Indexes/Recipes|Recipes]]`.

List recipes with `obsidian vault="My Vault" backlinks path="3 - Tags/recipes.md"`. Exclude the template and any note whose content is not a recipe.

Read the index and live template before adding or editing a recipe. Follow changes to the template instead of keeping a local copy. If either file is missing, report it and ask. Do not create a replacement automatically.

Use this collection unless the user specifies another destination. Edit the template itself only when the user asks to change it.

## Add a recipe

1. Read the supplied recipe or source. For a URL, retrieve the recipe itself rather than relying on a search snippet. If the source cannot be read, ask for the recipe text.
2. List the recipes and check likely matches before creating a duplicate. Update an existing recipe when requested. Ask if multiple matches leave the target unclear.
3. Create the note with `obsidian vault="My Vault" create path="6 - Full Notes/<Dish Name>.md" template="Recipe Template" silent`, then fill it in place. Remove template instructions and replace its example rows and steps with the actual recipe. Add as many ingredients and steps as the recipe needs.
4. Retain the source link or author when supplied. Preserve quantities, units, temperatures, timing, yield, and preparation details. For imported recipes, use "Not specified" for missing nonessential facts rather than inventing them. Ask when missing information prevents a usable recipe. For a newly developed recipe, label estimated timing and yield.

## Edit a recipe

Read the target note before editing. Resolve it from the user's link, the note they name, or the recipe listing. The Recipe Template is not a recipe target.

Apply the requested change in place using the template as the formatting guide. Preserve unrelated content, personal notes, source attribution, and existing checklist state. Do not rewrite the whole recipe merely to make a small correction.

When changing servings, update ingredient quantities and amounts repeated in the method. Do not multiply cooking time automatically. When changing ingredients, update affected method steps and notes so the recipe stays consistent.

## Recipe readability

Keep servings and timing near the top. Use ingredient checklists with amounts, units, and preparation details. List ingredients in their order of use and group them only when separate components need it.

Use numbered method steps with one main action per step. Include relevant quantities, temperatures, timing, and doneness cues supported by the source or requested adaptation. Keep optional notes brief. Remove unused optional sections and template placeholders from finished recipes. Link other recipes with wikilinks, such as `[[Cajun Garlic Butter Sauce]]`.

Use blank lines only between paragraphs and sections. Do not add one under a heading, between list items, or between consecutive links.

## Keep the index in sync

After every successful recipe addition or edit, reconcile `4 - Indexes/Recipes.md` before reporting completion. For a user-specified collection elsewhere, update that collection's own index instead.

List the recipes and read each one's saved content. Treat the note file as the identity, so a rename updates the existing row rather than creating a duplicate.

Keep the index concise:

- Group recipes under populated category headings, such as Mains and Sauces. Keep existing useful groups and add others only when needed.
- Use one Markdown table per category with columns Recipe, Prep time, Cook time, and Ingredients. List each recipe once, alphabetically within its category. The first cell is a wikilink to the note. Do not add a total time column.
- Read prep time and cook time separately from the saved recipe. Preserve estimates, ranges, and settings such as high or low. Do not fold prep, resting, chilling, or other waiting time into the cook time. Use "Not specified" in either time cell when that value is missing.
- Count required ingredient entries from the recipe's Ingredients sections. Prepared sauces and spice blends each count as one listed item. Alternative choices count as one entry. Exclude optional extras and items mentioned only in notes. Keep a brief explanation of this counting convention above the category tables.
- Keep the template link in the separate Add a recipe section. Preserve unrelated notes and instructions on the index.

Add missing rows and refresh titles, groups, prep time, cook time, and ingredient counts after changes. Remove duplicate rows and links confirmed to be obsolete. If a recipe cannot be read, preserve its row and report the gap instead of assuming the recipe disappeared.

Read back the index and compare its wikilinks with the complete recipe listing. Confirm every recipe appears exactly once, its row agrees with the saved recipe, and the template has no row. If the recipe saved but index synchronization failed, report those outcomes separately.

## Finish recipe additions and edits

Read back the saved recipe. For a new recipe, confirm it appears in the recipe listing. Check that the requested changes agree across ingredients, servings, and method.

Complete index synchronization, then return the recipe path, the index path, and a brief account of what was added or changed. State any incomplete synchronization or verification.
