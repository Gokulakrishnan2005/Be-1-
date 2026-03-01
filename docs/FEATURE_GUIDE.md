# Be 1%  — Feature Guide
> *A Life OS for deliberate practice, financial awareness, and habit stacking.*

---

## 🏠 Tab 1: Home (The Timer Dashboard)

### Skill Timers
- Tap **+** to add a new skill (e.g., Coding, Guitar, Reading)
- Each skill gets a **live timer card** showing hours logged
- **Tap the play button** on any card to start tracking time
- Only **one timer runs at a time** — starting a new one auto-pauses the previous

### Skill Categories
Every skill belongs to one of 3 categories:
| Category | Color | Meaning |
|---|---|---|
| **Growth** | 🟢 Green | Skills that improve your life (Coding, Reading) |
| **Maintenance** | ⚪ Grey | Necessary tasks (Cooking, Cleaning) |
| **Entropy** | 🟠 Orange | Time-wasters you want to track (Scrolling, Gaming) |

### Long-Press Menu (on any Skill Card)
- **Edit Skill** → Change name or icon without losing your hours
- **Change Position** → Opens the Position Manager to reorder your grid
- **Delete Skill** → Permanently removes the skill and its history

### Position Manager (Change Position)
- 4 buttons: **Top** | **Up** | **Down** | **Bottom**
- Tap rapidly — the sheet stays open while the grid updates behind it
- New order is saved permanently

### Growth Interrogation
When you **switch away from a Growth timer**, a popup asks:
> "How much of that time was real deep work?"
- Lets you split time between deep work and a waste category
- Keeps your Growth hours honest

### Retroactive Log (Entropy only)
- Long-press an Entropy card → **log wasted time after the fact**
- Example: "I scrolled for 45 min this morning" → logs it retroactively

---

## 📊 Tab 2: Time Analytics (The Reality Audit)

### Daily Breakdown
- See exactly how your day was split between Growth, Maintenance, and Entropy
- **Pie chart** shows the ratio visually
- **Date range selector** lets you audit any time period

### Category Drill-Down
- **Tap any category card** (Growth/Maint./Entropy) to open the **Evidence Log**
- See every session grouped by date (Today, Yesterday, Sept 24, etc.)
- Each row shows: **Icon + Name | Duration | Time Range**
- Sessions created via Retroactive Log or Time Splitter show a ✏️ pencil icon

---

## 💰 Tab 3: Finance (Money Dashboard)

### Income & Expenses
- Tap **+** to log income, expenses, or savings
- **Liquid Balance** = Income − (Expenses + Savings)
- **Net Worth** = Liquid + Savings (shown at the bottom)

### Savings
- Savings are **deducted from your liquid balance** (like a real bank)
- This shows the true cost of saving — you see what you actually have to spend

### Transaction Categories
- Add a category tag (e.g., "Food", "Transport") when logging
- Filter by category in the Ledger History

---

## ✅ Tab 4: Tasks & Habits

### Daily Tasks
- Add one-time tasks with a simple tap
- Check them off as you complete them
- Unfinished tasks are archived (viewable in Profile → Archives)

### Habit Tracker
- Create recurring habits (e.g., "Meditate", "Exercise")
- Check off daily — **streak counter** tracks consecutive days
- Streaks **persist across app restarts**
- 7+ day streaks trigger a heavy haptic celebration 🎉

### Goals
- Set long-term goals with target dates
- Track progress visually

---

## 🧑 Tab 5: Profile & Archives

### The Archives
- **Accomplished Tasks** → Completed tasks history
- **Unfinished Tasks** → Tasks you didn't complete
- **Income/Expense Ledger** → Full transaction history with date range & category filters

### Data Portability
- **Export** your data as JSON
- **Import** data from a backup file
- **Share** your data with others

---

## 🎨 Design Philosophy

- **Cupertino-first**: Native iOS look and feel everywhere
- **Haptic feedback**: Every important action gives tactile confirmation
- **Local-first**: All data stored on-device. No accounts, no cloud, no tracking.
- **Dark entropy tint**: When an Entropy timer is running, the Home screen subtly glows orange as a psychological nudge

---

*Built with Flutter • Designed for intentional living*
