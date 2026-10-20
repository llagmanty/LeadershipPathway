# Leadership Pathway

An iOS app (SwiftUI) for following a **34-week Bible reading plan** and tracking your progress through it.

## The study plan

The plan comes from the original schedule image ([`docs/source-reading-plan.jpg`](docs/source-reading-plan.jpg)). It's transcribed in [`tools/plan_source.txt`](tools/plan_source.txt) and published as:

- [`docs/STUDY_PLAN.md`](docs/STUDY_PLAN.md): the full plan as readable tables
- [`LeadershipPathway/Resources/reading_plan.json`](LeadershipPathway/Resources/reading_plan.json): the structured data the app loads

**Structure:** 34 weeks × 5 reading days = 170 sessions (339 passages). Three tracks run in parallel through the plan:

| Track | Coverage |
| --- | --- |
| New Testament | Mark → Acts → Romans → Luke → 1–2 Cor → Gal → Eph → Phil → Col → Matthew → Hebrews → James → John → 1–2 Thess → 1–2 Tim → Titus → Philemon → 1–2 Pet → 1–3 John → Jude → Revelation |
| Psalms | 1–150, in order |
| Proverbs | 1–31, in order |

Days 1, 3 and 5 usually pair the New Testament reading with Psalms. Days 2 and 4 pair it with Proverbs.

To change the plan, edit `tools/plan_source.txt` and regenerate. The script validates that there are 34 weeks of 5 days each and that every book name is recognised:

```sh
python3 tools/build_plan.py
```

## The app

| Tab | What it does |
| --- | --- |
| **Today** | Overall progress ring, streak, and on-track status. Shows the next unread day with a checkbox for each passage, plus the current week at a glance. |
| **Plan** | All 34 weeks with per-week progress. You can jump to the current week and hide completed weeks. Open a week to see its days; swipe a day to mark it read or unread. |
| **Progress** | Days, weeks, passages and streak; progress for each track; a 34 × 5 heatmap of the whole plan. |
| **Settings** | Optional start date for on-track/ahead/behind tracking (5 days per week), a daily reminder notification, and a progress reset. |

Each day also has a **notes & reflections** field. Progress is saved on the device as JSON in Application Support.

### Requirements

- Xcode 16 or later
- iOS 17 or later (iPhone and iPad)

### Running

1. Open `LeadershipPathway.xcodeproj` in Xcode.
2. Select the **LeadershipPathway** scheme and an iPhone simulator, then press ⌘R.
3. To run on a physical device, choose your team under *Signing & Capabilities*. If you need a unique bundle identifier, change it from `com.leadershippathway.app`.
4. Run the unit tests with ⌘U.

The project uses Xcode's synchronized folders, so new files added under `LeadershipPathway/` or `LeadershipPathwayTests/` are picked up automatically.

### Layout

```
LeadershipPathway/
  LeadershipPathwayApp.swift   App entry point
  Models/ReadingPlan.swift     Plan model and JSON loading
  Stores/ProgressStore.swift   Progress, streaks, schedule status, persistence
  Services/ReminderScheduler.swift
  Views/                       Today, Plan, Day detail, Progress, Settings
  Resources/reading_plan.json  Generated plan data
LeadershipPathwayTests/        Unit tests for the plan data and progress logic
tools/                         Plan transcription and generator script
docs/STUDY_PLAN.md             Generated human-readable plan
```
