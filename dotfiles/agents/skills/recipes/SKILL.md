---
name: recipes
description: Add or edit recipes in Michael's Recipes Pages collection using the live template and keep its directory in sync. Use only when explicitly invoked as $recipes or asked to use the recipes skill.
---

# Recipes

Add and edit recipe Pages in Michael's collection. Keep recipes concise and readable while cooking.

## Collection and template

- [Recipes](https://chatgpt.com/space/page_1cff941853c08191ac74bc8512314b2b) is the default parent and recipe directory. Its Page ID is `page_1cff941853c08191ac74bc8512314b2b`.
- [Recipe template](https://chatgpt.com/space/page_1189000c1f4881919969682d7ee3f65e) is the format source. Its Page ID is `page_1189000c1f4881919969682d7ee3f65e`.

Use the available Pages write-page skill for Page reads, guarded edits, and verification. Read the collection and live template before adding or editing a recipe. Follow changes to the template instead of keeping a local copy. If either Page is inaccessible, report the missing access and ask for a replacement link when needed. Do not create a replacement collection or template automatically.

Use this collection unless the user specifies another destination. A recipe is a child Page, not a section added to the template. Edit the template itself only when the user asks to change it.

## Add a recipe

1. Read the supplied recipe or source. For a URL, retrieve the recipe itself rather than relying on a search snippet. If the source cannot be read, ask for the recipe text.
2. List the collection's child Pages and follow pagination. Check likely matches before creating a duplicate. Update an existing recipe when requested. Ask if multiple matches leave the target unclear.
3. Create a child Page under Recipes with the dish name as its native title. Use the live template's structure. Remove template instructions and replace its example rows and steps with the actual recipe. Add as many ingredients and steps as the recipe needs.
4. Retain the source link or author when supplied. Preserve quantities, units, temperatures, timing, yield, and preparation details. For imported recipes, use "Not specified" for missing nonessential facts rather than inventing them. Ask when missing information prevents a usable recipe. For a newly developed recipe, label estimated timing and yield.

## Edit a recipe

Read the target Page before editing. Resolve it from the user's link, the selected recipe Page, or the collection's children. The selected Recipe template is not an ordinary recipe target.

Apply the requested change in place using the template as the formatting guide. Preserve unrelated content, personal notes, source attribution, and existing checklist state. Do not rewrite the whole recipe merely to make a small correction.

When changing servings, update ingredient quantities and amounts repeated in the method. Do not multiply cooking time automatically. When changing ingredients, update affected method steps and notes so the recipe stays consistent.

## Recipe readability

Keep servings and timing near the top. Use ingredient checklists with amounts, units, and preparation details. List ingredients in their order of use and group them only when separate components need it.

Use numbered method steps with one main action per step. Include relevant quantities, temperatures, timing, and doneness cues supported by the source or requested adaptation. Keep optional notes brief. Remove unused optional sections and template placeholders from finished recipes.

## Keep the directory in sync

After every successful recipe addition or edit, reconcile the root Recipes Page before reporting completion. For a user-specified collection elsewhere, update that collection's own index instead.

Refresh the index and list the collection's child Pages, following pagination and any nested grouping Pages. Identify actual recipe Pages from their content. Exclude the template and organizational Pages from recipe entries. Treat Page IDs as the identity so renames update existing entries rather than creating duplicates.

Keep the directory concise and native to Pages:

- Group recipes under populated category headings, such as Mains and Sauces. Keep existing useful groups and add others only when needed.
- Use one native table per category with columns Recipe, Total time, and Ingredients. List each recipe once, alphabetically within its category. The first cell is its current title linked to its canonical Page URL. Give this column most of the table width.
- Show approximate total time, including prep and any waiting time. Preserve qualifiers such as "about" or "estimated". Use "Not specified" when timing is missing. Read saved recipe content rather than copying truncated listing previews.
- Count required ingredient entries from the recipe's Ingredients sections. Prepared sauces and spice blends each count as one listed item. Alternative choices count as one entry. Exclude optional extras and items mentioned only in notes. Keep a brief explanation of this counting convention above the category tables.
- Keep the template link in the separate Add a recipe section. Preserve unrelated notes and instructions on the index.

Add missing rows and refresh titles, groups, timing, and ingredient counts after changes. Remove duplicate rows and links confirmed to be obsolete. If access or listings are incomplete, preserve unverified entries and report the gap instead of assuming those recipes disappeared. Update index blocks with fresh edit guards using the Pages write-page workflow.

Read back the index and compare its recipe links by Page ID with the complete recipe listing. Confirm every accessible recipe appears exactly once, its summary agrees with the saved recipe, and the template remains separate. If the recipe saved but index synchronization failed, report those outcomes separately.

## Finish

Inspect write receipts and read back the saved recipe. For a new recipe, confirm its parent in the collection's child listing. Check that the requested changes agree across ingredients, servings, and method. Inspect the rendered layout when available and report any verification gap.

Complete directory synchronization, then return the recipe link, the index link, and a brief account of what was added or changed. State any incomplete synchronization or verification.
