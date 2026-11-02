---
name: "macrofactor-workouts-driver"
description: "Use when driving the MacroFactor Workouts app on Michael's Mac (runs as \"Runner\", com.sbs.train) via computer use: build/edit programs (Smart Progression defaults, one program per block), sets, RIR, rest, supersets, notes, log workouts, history, xlsx export/import."
---

# MacroFactor Workouts driver (Mac, computer use)

Verified live on 2026-10-27 and 2026-10-29 against MacroFactor Workouts on macOS. Coordinates below are for one specific window layout. Always take a screenshot and zoom before you click; treat any coordinate here as a hint.

## 0. Michael's defaults for building programs (follow these unless he says otherwise)

1. **Let Smart Progression pick the loads.**
   - Smart Progression is MacroFactor's auto-progression. It learns from logged sets and recommends weight and reps for each set, based on the set's rep range and RIR target.
   - It is already turned on in his app. In a live workout, tap the first tool chip (an arrow icon with a blue dot) to see it. Its settings icon opens: Initial log fill = Smart Progression values, Apply in session ✔, Expand Rep Range ✔, Weight Match ✘.
2. **Never hard-code weights.** The program has no weight field anyway. Never type pounds into a live workout on his behalf.
3. **Don't pin fixed reps either.**
   - Give each set only what Smart Progression needs: a **rep range** (Min–Max, e.g. 8–10) and an **RIR target**.
   - Don't use a single fixed rep count (Min = Max), and don't hand-tune numbers week by week.
   - His existing programs look like this: e.g. 3 sets of 7–9 reps with RIR 3, 2, 1 across the sets.
4. **Leave the Periodization toggle OFF.** Periodization is manual: hand-edited sets, reps and RIR for every cycle, which is the opposite of what he wants.
5. **Exception: hard-coded or periodized numbers only for a specific case he names,** e.g. rehabbing an injury. Then use fixed reps, Periodization, or exact targets as he asks.
6. **Multi-block plans become separate programs, one per block.**
   - Example: an exercise rotation at weeks 5 and 9 gives three programs.
   - Name them `<Plan> – Block 1 (Weeks 1–4)`, `<Plan> – Block 2 (Weeks 5–8)`, `<Plan> – Block 3 (Weeks 9–12)`.
   - Each one has a 7-day cycle (training and rest days laid out across the week) and Number of Cycles = weeks in the block.
   - Save all of them to the Library. He activates Block 1 and switches when a block ends.
   - Why separate programs: a single program can't change *which exercises* appear in different cycles. Periodization and per-cycle Skip only change sets on the same exercises.
7. **Exercise Notes for the exercise, Program Notes for this program** (Michael's call, 2026-10-29).
   - **Exercise Note**: anything true of the exercise wherever it appears. This covers technique and setup cues, depth limits, and the shoulder rule block on presses ("Pain-free = 2/10 or less…", the >3/10 rule). It follows the exercise into every block and every future program, so write it once.
   - **Program Note**: only what belongs to this program's slot:
     - the general warm-up on each day's first exercise, as a line starting "WARM-UP:". Michael asked for it, and it was lost once before.
     - superset flow ("A1 → go straight to EZ curls", "A2 → rest, then back to triceps").
     - block-specific instructions: grip per set, "only if Block N passed the shoulder rule", fallbacks, and "Replaces X" reasons.
   - Don't repeat an Exercise Note cue in a Program Note.
   - **Michael writes Exercise Notes himself too.** Keep his text word for word and append only missing cues, in his "- " bullet style. If a cue of his conflicts with one of yours, his wins.
   - Neither note type ever holds **ramp-up sets** (exercise-specific warm-up sets), percentages, drop-set weights, loads, rest or RIR. The app calculates or shows those itself.
   - Both are capped at 300 characters.
8. **Supersets: never two machines.** Each A1/A2 pair is one machine + one free-weight exercise (dumbbell or EZ bar).
9. **Read the project docs before changing exercises:** `claude/exercise-preferences.md` (likes, dislikes, swaps) and `claude/injuries-and-irritants.md`.

## 1. Connect to the app

- The app is the **iPhone app running natively on macOS**. It is **not** iPhone Mirroring.
  - App name in `computer_list_apps`: **Runner**
  - Bundle id: **`com.sbs.train`**
  - Window title: "Workouts"
  - Resolving the names "MacroFactor" or "MacroFactor Workouts" fails. Resolve `com.sbs.train` instead.
- Access sequence:
  1. Call `computer_resolve_access(["com.sbs.train"])`, then `computer_request_access`.
  2. If computer use is off, call `computer_request_access` with only `reason` first.
  3. Access expires after 30 minutes without computer-use activity. Resolve and request again when a call says so.
- The app is often **hidden**. In background mode, call `computer_app_list_windows` and then `computer_app_bring_to_current_space` with the window id. Under full-screen control, call `computer_open_application("com.sbs.train")`, then `computer_screenshot`.
- **What works in the background (verified 2026-10-29):**
  - `computer_app_click` (AXPress) works on buttons, tabs, the ⋮ menus, Swap rows, smart-substitution swap buttons, program headers and note cards. Use it for any click-only task, such as swapping exercises, so the user keeps their screen.
  - `computer_app_scroll` (dy 20) is the only scroll that works. Mouse-wheel `scroll` and click-drag do nothing.
  - **Typing does not work in the background.** `computer_app_type` reports success but the field doesn't change, even with `overwrite_existing`, a cleared field, or `target: focused`.
- **Typing (notes, reps, search) needs full-screen control.**
  - Ask the user for screen takeover in chat first. Then call `computer_request_full_control`.
  - Use `computer_batch` with `left_click`, `key cmd+a` and `type`.
  - Release with `computer_release_full_control` when done.
  - While full control is held, scroll with `computer_app_screenshot` → `computer_app_scroll` → `computer_app_release`, then go back to the display tools.
- **Typing glitch:** the word "rotation" consistently comes out as "roation t…" (one keystroke lands late). Type it in two chunks, e.g. "… DB ext. ro" then "tation 15/arm …". Zoom on the field and check every note before saving.
- **Window layout.** Background screenshots use a 1371×896 frame. Full-screen screenshots use 1344×896, with the app filling the screen: sidebar on the left, content column at about x 485–860.
  - The Left layout (menu bar **Window → Move & Resize → Left**) also works.
  - With **Window → Fill**, the user's always-on-top Superhuman window can block clicks at the top right.
- **Reading the screen.** Take a `screenshot` at scale 0.5 to orient, then `zoom` into the region you need. Zoom coordinates convert back to full-frame coordinates by linear scaling: full = region origin + zoom px × (region size / image size).
- **Text entry.** Click the field, press `cmd+a` to select existing text, then `type`.
- **Wheel pickers** (rest timer): click the visible row value (e.g. "3 min") to select it, then press Save.
- **Bottom sheets** can extend past the bottom of the screen. Sheets don't scroll, and dragging them doesn't help. The visible options were enough for everything below.
- **Save dialogs (macOS).** The tool refuses Save, Return and `cmd+a` in system Save sheets ("cannot be verified"). Ask the user to click **Save**. You can still `type` a filename first.
- Finish every turn that used computer use with `computer_release_lock`.

## 2. App map

Left sidebar (Left layout, approx. full-frame coordinates):

| Item | Approx. position |
|---|---|
| Dashboard | (18,403) |
| Workout | (18,438) |
| **+** (Shortcuts) | (18,471) |
| Levels | (18,500) |
| More | (18,536) |

### Dashboard
Weekly rings (Muscles / Sets / Exercises vs. targets) with an Active Program / All Workouts toggle. Below: Insights (Workouts, Weight Trend), Habits, Body Metrics, Muscle Groups, Exercises, General (Steps).

### Workout tab
- **Top row:** a date strip, plus three icons at top right: calendar, **+** (Create), **⋮** (More).
- **Active Program card:** the program's day list. Each day has a checkbox, and greyed days are completed. A "Week N" link sits top right.
- **Workout Library:** saved but inactive programs. Tap the program header (name and icon) to open its editor. Tap a day row to open that day's preview with a **Start Workout** button.

**+ (Create) sheet:** New Section · New Program · New Workout.

**⋮ (More) sheet:** Start Empty Workout · Workout History · Customize Sections · Archive.

**Sidebar + (Shortcuts):** Weight · Photos · Metrics · History · "Up Next" · Empty Workout · New Program · New Workout.

### Program editor (full-screen frame, verified 2026-10-29)
- Back arrow: top left, about (14,54).
- Day tabs at y≈76: Full Body ≈506, Rest, Upper ≈576, Rest, Lower ≈640, Rest, Rest, Add Day.
- **Add Exercises** link: about (824,202).
- The first exercise's Program Note card is at about (640,335).
- A ⋮ is at the right of each exercise header (x≈845).
- After scrolling to the bottom, the last exercise's set card is at about (640,872) and its ⋮ at about (845,838).
- **Note editor sheet:**
  - The text field is at about y 800–830. Click it, then `cmd+a`, then `type`.
  - The **Save Note** / **Add Note** button is at about (672,876).
  - The character counter (x/300) is at the top right of the sheet.
- **Exercise picker:** the search box is at about (650,871), **Done** at about (834,872), and the ⊕ buttons sit at the right edge of each result (x≈842).
- **Set editor sheet:**
  - Set 1 fields: Reps Min (620,123), Reps Max (722,123), RIR dot (786,123).
  - "+" to add a set: (556,146).
  - RIR picker row along the bottom: 0, 1, **2 ≈ (624,882)**, 3, 4, 5, 6+, ?.
  - **Save** button: about (672,847).

### More tab
- **General:** Account, Subscription, Integrations, Units, Language.
- **Feature Settings:** Dashboard, Workout, Shortcuts, Weight Trend, **Exercises** (the full exercise library; **+** at top right = Create Custom Exercise), **Gym Profiles**.
- **Theme.**
- **Data Management:** Data Export, Data Visibility, Account & Data Deletion.
- **Support.**

Custom exercise form fields: Exercise Name (required), Trackable Metric (two dropdowns, required), Type (e.g. Compound Upper), Laterality (Bilateral …), then Next.

## 3. Data model (how the app thinks)

- **Program** = an ordered list of **days**. Each day is either a workout or a **Rest** day.
  - That list is one **cycle**.
  - **Number of Cycles** sets how many times the cycle repeats. The default is 7.
  - To get a weekly calendar, make the cycle 7 days long (e.g. Full Body, Rest, Upper, Rest, Lower, Rest, Rest). Cycles then equal weeks.
- **Exercise slot**: the exercise plus a list of sets. The same settings apply to every cycle unless Periodization is on.
- **Periodization** (Program Settings toggle, verified):
  - When it's on, each exercise shows one card per cycle (Cycle 1, Cycle 2, …).
  - Clicking a card opens that cycle's own set editor. Its subtitle reads "Cycle N", and it has its own **Skip Exercise** ("skipped on <Day>, Cycle N").
  - The editor's buttons are **Save** (this cycle only) and **Save To All Cycles**.
  - It changes sets, reps, RIR and rest per cycle. It **can't** swap in a different exercise for some cycles.
  - Off by default. Keep it off for Michael (§0).
- **Blocks:** the export file has a "Block 1" row, but no screen for adding a second block was found. Use separate programs per block (§0).
- **Set fields:**
  - Set number or type marker.
  - Reps Min/Side and Reps Max/Side, both optional. Min 8, Max 10 displays as "8–10 reps".
  - **RIR** target: 0, 1, 2, 3, 4, 5, 6+ or ?.
  - Optional **Rest**: only shown after you enable "Set Rest Timers". The default is 2:00.
- **The app uses RIR, not RPE.**

  | RPE | RIR |
  |---|---|
  | 10 | 0 |
  | 9 | 1 |
  | 8 | 2 |
  | 7 | 3 |

  For an RPE range such as 8–9, pick the harder end (RIR 1) unless told otherwise.
- **Set types** (tap the set-number circle): **Standard**, **Drop Set**, **Myo Set**, **Failure Set**.
  - Choosing Drop Set turns that row into **"D"**. A "+" row then appears for drop segments: optional reps, 0:00 rest, RIR 0.
  - When logging, the app suggests about 50% of the weight for the drop.
- **Warm-ups:**
  - Ramp-up sets are not set in the program. During a live workout, the **Warm Up** button opens a Set Calculator (Smart / Scheme) or "Add empty warm-up set". MacroFactor handles ramp-up sets, so don't put them in notes.
  - The general warm-up (cardio and mobility drills) goes in the first exercise's Program Note (§0 rule 7).
- **Note types** (each max 300 characters; none of them is saved to history):
  - **Program Note**: pinned to the exercise's slot in one program, and shown every time you do it there. You can edit it in the program editor or in a live workout.
  - **Exercise Note**: pinned to the exercise itself, so it shows in every program that uses it. You can edit it only in a live workout (recipe F2).
  - **Session Note**: this workout only.
- **Gym profile** (e.g. "Anytime Fitness") filters exercise search to that gym's equipment.

## 4. Recipes

Coordinates are approximate. Zoom first.

### A. Create a program from scratch
1. Go to Workout tab → **+** (top right) → **New Program**.
2. On the "Create Program" splash, tap **Next**.
3. Select **Build From Scratch**, then Next. The other options are "Use Smart Generation" and "Import From File" (.xlsx exported from MacroFactor).
4. In Name, click the field, `cmd+a`, type the name, then Next.
5. Color/icon grid: pick one if you like, then Next.
6. You're now in the **program editor**. It starts with one "Rest" day tab plus an "Add Day +" tab.
   - Toolbar: Remove · Gym dropdown · Rename · Re-order · Duplicate · Change to Rest.
   - Body: "Rest Day" and "0 Exercises", with an **Add Exercises** link.
   - Bottom buttons: **Save to Library** and **Activate Program**.
7. Tap **Add Exercises** on a day. Adding exercises turns a Rest day into a workout day and auto-names it "Workout A", "Workout B", ….
8. To rename a day, tap **Rename**. In the "Rename Day" sheet, click the field, `cmd+a`, type, then **Save**.
9. To add another day, tap **Add Day +**. New days are Rest until exercises are added. The tab order is the day order.
10. Tap **Save to Library**. The program appears under Workout Library and the active program is unchanged.
    - **Activate Program** replaces the user's active program. Only use it when the user asked for that.

Edits to an existing program save automatically. There is no save button; press the back arrow to leave.

### B. Add exercises (picker)
- The picker has a search box at the **bottom**, **Done** to its right, and filter chips at the top: Gym, Type, Laterality, Resistance, Support, Range of Motion, plus muscle icons.
- Results are grouped into Free Weights / Machines / Bodyweight & Personal / Cardio, each with "See N More".
- Steps:
  1. Click the search box and type a query, e.g. "incline dumbbell press" or "external rotation". Typing needs full-screen control.
  2. Press the **⊕** on the right of each result you want. A small thumbnail appears in the top tray; nothing else visibly changes.
  3. Repeat the search for more exercises.
  4. Press **Done**. Exercises are added at the end of the day, in the order you picked them.
- MacroFactor's names differ from program PDFs. Examples:
  - "Incline DB Press" → **45° Incline Dumbbell Press**
  - "Hack Squat" → **Hack Squat** (Machines)
  - ATG elbow-on-knee external rotation → **Seated Dumbbell Shoulder External Rotation**
  - Standing landmine press → **Single Arm Landmine Press**
  - Search with plain words and choose the closest match. Check the muscle tags under each name.
- Tapping a result's name (not its ⊕ or swap button) opens its details sheet (muscles, equipment, joint action) with a **Swap Exercise** button at the bottom.

### C. Configure sets / reps / RIR / rest for an exercise
1. In the editor, click the exercise's grey set box (the "N Weeks / 1 Standard Set" card). A sheet opens titled with the exercise name.
2. Set the reps and RIR:
   - Row 1: click **Reps Min/Side** and type the low number. Click **Reps Max/Side** and type the high number.
   - Click the **RIR** dot, then pick the value in the "RIR Targets" sheet at the bottom.
3. Click **+** under the rows to add a set. The new set **copies** the previous set's values.
4. To set rest, turn on **Set Rest Timers**. A Rest column appears (2:00).
   - Click a Rest cell, click the minutes row (e.g. "3 min"), then **Save**.
   - Changing rest updated every set's rest in testing.
5. To change a set's type, click the **set-number circle** and choose Standard / Drop / Myo / Failure.
6. Click **Save**. **More Options** opens "Saving Options", which applies the settings to:
   - this exercise only (default),
   - all exercises for the day, or
   - all exercises in the program.
7. **Skip Exercise** toggle: skips this exercise on this day for all cycles.

### D. Exercise options (⋮ on the exercise row)
Options: Info · Swap · Superset · Move to a different day · **Program Note (Add/Edit)** · Duplicate Exercise · Remove from workout.

- **Note:** click the Program Note card itself to edit an existing note. For a new note, use ⋮ → Program Note **Add** (about (785,821) in the options sheet). Then click the text box, type (≤300 chars), and press **Add Note** / **Save Note**. The editor has no Exercise Note option; use recipe F2 for those.
- **Superset:** on the **second** exercise, open ⋮ → Superset → **Superset with previous**. A "Superset" group header appears with its own ⋮ menu: Add Exercises · Re-order · Remove Superset (also deletes its exercises) · **Ungroup Exercises** (the safe way to undo).
- **Swap** replaces the exercise and **keeps its sets and its Program Note**. Update the note afterwards if its cues no longer fit.
  - The Swap sheet lists Smart Substitutions, each with a swap button on the right, plus **Find Other Replacements**.
  - Swapping is click-only, so it works with background tools.

### E. Program settings (open the program from the Library, then the sliders icon at top right)
Options: Number of Cycles (− / +) · Name (Edit) · Color & Icon · **Day Order** (Edit; shows "N-Day Cycle", drag handles, Save/Cancel) · Deload · Periodization toggle · Duplicate Program · **Export Program** · Activate Program · Archive Program · **Delete Program**.

- **Export Program** opens the macOS share menu. Choose **Save**, and the file is named "MacroFactor-YYYYMMDDHHMMSS.xlsx" (Documents by default). The user has to click Save in that dialog (see §1).

### F. Start, log, finish or discard a workout
1. Workout tab → tap a day row → day preview → **Start Workout**. Alternatively: ⋮ → Start Empty Workout.
2. The logging screen shows:
   - Elapsed timer at top left and ☰ menu.
   - Rest timer at top right (it starts automatically when a set is checked).
   - Exercise thumbnails in a row with **+** to add an exercise.
   - Tool chips: the **Smart Progression** chip (first, arrow icon) and then Info, Warm Up, Targets, Swap, Note, Superset, Equipment, ….
   - Tapping the column header "Auto ⇄" toggles it between the program's targets (Auto) and **Previous** (last session's numbers).
   - Set table: Set | Auto (target) | **Lb/Side** | **Reps/Side** | ☐.
3. Click Lb/Side, type the weight, adjust Reps if needed, then click ☐ to complete the set. A grey placeholder reps value is accepted as entered.
4. ☰ menu: Pause · Minimize · **Finish workout** · Workout settings · Gym settings · **Discard workout**.
   - Discard asks for confirmation ("Discard this workout?"). Discarded workouts don't reach history.
   - Only discard sessions you started yourself for testing or editing.
   - Full-screen coordinates: ☰ about (14,54) → **Discard workout** about (596,880) → **Discard** about (672,840).

### F2. Edit Exercise Notes (and Program Notes) in a live workout (verified 2026-10-29)
Exercise Notes can only be edited here. This is also the fastest way to fix both note types for a whole day at once.
1. Get Michael's OK for screen takeover, since typing needs full-screen control.
2. Start the day's workout from the program (recipe F). This works for Library programs as well as the active one.
3. On each exercise, click the **Note** chip. A sheet opens with **Session / Exercise / Program** tabs.
   - The text field focuses on its own. Type without clicking: Grammarly Desktop's overlay can block clicks near the field.
   - Before typing in the Exercise tab, read what's already there. If Michael wrote it, append rather than replace (§0 rule 7).
   - Edit the Exercise tab and the Program tab, then press **Save** once. That one Save commits both tabs.
   - Clearing a Program Note (`cmd+a`, delete, Save) removes it.
4. Move to the next exercise using the thumbnail row.
5. When the day is done, discard the workout (☰ → Discard workout → Discard).
   - Exercise-tab and Program-tab edits **stay saved after the discard**.
   - Nothing reaches history. Check Workout History afterwards to confirm.
6. An Exercise Note edited on one day already shows on that exercise in every other day and block. Check it there instead of retyping.

### G. History
Workout tab → ⋮ → **Workout History** shows a list by date.

- Tap an entry to open the detail view: muscle map, PRs, Volume, Start Time (Edit), Duration (Edit), **Edit Workout**, and per-exercise volumes. Close it with **X** at top left.

## 5. Program export format (.xlsx), read from a real export

The workbook has one sheet, named **"Training Programs"**. Every cell is a string except the RIR and Rest numbers.

| Row | Content |
|---|---|
| 1 (bold) | `Program: <name>` · `Cycles: 7` · `Deload: None` · `Color: Red` · `Icon: Rocket` (columns A–E) |
| 2 | `Block 1` |
| 3 (header) | `Cycle 1` · `Exercise` · `Skipped` · `Notes` · then for each set N: `Set N Type` · `Set N Rep Range` · `Set N RIR` · `Set N Rest` |
| 4+ | One row per exercise |

How the exercise rows (row 4 onward) work:
- **Column A** is the day label `<Day Name> @ <Gym>`, e.g. `Full Body @ Anytime Fitness`. It is **merged down** across that day's exercise rows (A4:A5).
- A rest day is a single row containing just `Rest` in column A.
- **Exercise** must be the exact MacroFactor library name, e.g. `45° Incline Dumbbell Press`.
- **Skipped** is `No` or `Yes`.
- **Notes** holds the Program Note text. Exercise Notes belong to the exercise, not the program; whether they export hasn't been checked.
- **Set N Type** is one of `Standard Set`, `Drop Set` (also expected: `Myo Set`, `Failure Set`).
- **Rep Range** is a string `"min - max"`, e.g. `"8 - 10"`. A drop set showed `"8 - 8"`.
- **RIR** is a number (`1`). A drop set showed the string `"0 (0)"`, which reads as the set's RIR followed by the drop segment's RIR.
- **Rest** is in **seconds** (`180`). It is blank when the exercise uses default rest timers.
- An exercise with no reps or RIR has only `Set 1 Type = Standard Set` filled in.

Not yet seen: how supersets, more than one cycle/block (periodization), deloads or Myo/Failure sets are written. Export a program that uses them to learn the format before generating them.

## 6. Safety rules for this app
- Never press **Activate Program**, **Delete Program**, Archive, Remove Superset, or Discard on the user's real data without explicit approval.
- Build new programs with **Save to Library** and leave activation to the user unless asked.
- Name test data with a "ZZ" prefix so it's easy to spot and clean up.
- Check the result after each recipe with a zoom. Read back the exercise cards ("8–10 reps", RIR badge, set count) and the note text before moving on.

## 7. Loading a full program (e.g. the Essentials 3x plan in the Workout Plan project)
- Use one program per block (§0). For example, "Essentials 3x – Block 1 (Weeks 1–4)" has a 7-day cycle (Full Body, Rest, Upper, Rest, Lower, Rest, Rest) with Number of Cycles = 4 and Periodization OFF. Blocks 2 and 3 follow the same pattern.
- Convert the source plan to rep ranges plus RIR only (RPE → RIR, harder end). Drop any prescribed loads, and let Smart Progression handle weight and progression.
- The **Import From File** (.xlsx) path (section 5) is probably much faster than tapping. Generate a file in the export format, have the user attach or save it where the app can reach it, then use New Program → Import From File.
  - Importing an *edited* file has **not been tested yet**.
  - On the first run, import a small file, then open the result in the editor and confirm the sets, RIR, rest, notes and day order before relying on it.
- Heavy + Back-off pairs: **one exercise with two sets**, not a duplicated exercise. Set 1 gets the heavy rep range, set 2 the back-off rep range, each with its own RIR. Weight Match is off, so Smart Progression suggests a separate load per set.
- A "dropset" line: change that set's type to **Drop Set**.
  - Its row becomes "D", holding the main reps.
  - The "+" row below it holds the reps after the drop.
  - In testing, changing set 2 of 2 gave rows `1`, `D`, `+`.
- A1/A2 pairs: use Superset with previous. Never pair two machines; one half must be a free-weight exercise.
- Notes follow §0 rule 7:
  - Exercise Notes: cues and safety rules. Most exercises already have one, so check before writing.
  - Program Notes: the general warm-up line on each day's first exercise, superset flow and block-specific instructions.
  - Never ramp-up sets or numbers the app calculates.