# Antigravity Skills Manager (`manage-skills-script`)

A lightweight, robust command-line management system and transaction engine for **Google Antigravity & Gemini Skills**.

Enables instant global activation, archiving, token optimization, automatic reference summaries, and transactional Undo / Redo for agent skills across all projects on Windows.

---

## 🌟 Features

- **Global Antigravity Integration**: Automatically wires into `~/.gemini/config/skills.json` so enabled skills are immediately active across every project on your machine.
- **Auto-Maximized Console**: Launches maximized on double-click for spacious view of wide menus, paths, and transaction logs.
- **Context Token Optimization**: Archive heavy specialized skills when not in use to save thousands of LLM context window tokens while keeping master umbrella skills active.
- **Transactional State Engine**: Push / Pop history stack with atomic `Undo` and `Redo` across all move and toggle operations.
- **One-Click Discovery Inspection**:
  - `[1]` List all active vs. archived skills.
  - `[2]` Look up one-line summaries of any skill on demand.
  - `[3]` View the auto-compiled `SKILLS_SUMMARY.txt` guide.
  - `[J]` Open and inspect `~/.gemini/config/skills.json` for live verification.
- **Auto Summary Generator**: Automatically parses YAML frontmatter (`name` and `description`) from all `SKILL.md` files into a single quick-reference sheet.
- **Robocopy Mirror Backup**: Fast 1-click delta mirror of active skills with exit code handling.
- **Rolling Transaction Log**: Keeps the last 100 move/copy events cleanly formatted with timestamps.
- **Zero-Dependency Portability**: Built using native Windows Batch (`cmd.exe`) and PowerShell (`powershell.exe`). No Node.js or Python runtime required.

---

## 📁 Repository Structure

```text
manage-skills-script/
├── manage_skills.bat       # Interactive Terminal Manager CLI
├── backup_skills.bat       # Mirror backup utility (Robocopy)
├── generate_summary.bat    # Batch launcher for summary generation
├── generate_summary.ps1    # Parser for SKILL.md YAML frontmatters
├── skills_history.ps1      # Transaction state engine (Undo / Redo)
├── .gitignore              # Ignores runtime states, logs, and skill files
└── README.md               # Documentation
```

---

## 🚀 Quick Start

1. Clone or download this repository:
   ```bash
   git clone https://github.com/omrzgit/manage-skills-script.git
   cd manage-skills-script
   ```

2. Place your custom skill folders into the `active/` directory:
   ```text
   active/
   ├── my-custom-skill/
   │   └── SKILL.md
   └── another-skill/
       └── SKILL.md
   ```

3. Launch the manager:
   ```cmd
   manage_skills.bat
   ```

4. The script will automatically verify and connect your skills to Google Antigravity globally via `~/.gemini/config/skills.json`.

---

## 🎮 Menu Overview

```text
==============================================================================
              ANTIGRAVITY GLOBAL SKILLS MANAGER (Enable / Disable)
==============================================================================
  Active (GLOBAL) : active\            [17 active across ALL projects]
  Archived (OFF)  : archived\          [0 disabled / 0 context tokens]
  Global Sync     : ~/.gemini/config/skills.json [LINKED]
  Log File        : skills_transactions.txt
==============================================================================

  -- [ EXPLORE & INSPECT ] ---------------------------------------------------
  [1] List All Skills              View active vs archived skills
  [2] Inspect Skill Details        Look up what any skill does (one-liner)
  [3] Open Summary Guide           Open full SKILLS_SUMMARY.txt in text editor
  [J] Open Global skills.json      Open and inspect ~/.gemini/config/skills.json
  [G] Auto-Generate Summary        Rebuild SKILLS_SUMMARY.txt from all SKILL.md files

  -- [ TOGGLE & OPTIMIZE ] ---------------------------------------------------
  [4] Disable a Skill              Move: Active   -> Archived
  [5] Enable a Skill               Move: Archived -> Active
  [6] Optimize Web Sub-Skills      Archive sub-skills (Save ~2,000 tokens)
  [7] Enable All Skills            Move all archived skills to active

  -- [ HISTORY & UNDO / REDO ] -----------------------------------------------
  [U] Undo Last Action             Revert previous move/toggle transaction
  [R] Redo Last Action             Re-apply previously undone transaction

  -- [ BACKUP & LOGS ] -------------------------------------------------------
  [8] Run Backup Utility           Mirror active skills to BACKUP\
  [9] Open Transaction Log         View last 100 move/copy events in text editor

  -- [ SYSTEM ] --------------------------------------------------------------
  [0] Exit Manager
==============================================================================
```

---

## ⚙️ How Global Antigravity Linking Works

Google Antigravity supports a global discovery registry at:
`%USERPROFILE%\.gemini\config\skills.json`

When you run `manage_skills.bat`, it ensures this file contains:
```json
{
  "entries": [
    {
      "path": "C:/path/to/manage-skills-script/active"
    }
  ]
}
```

- Any skill placed in `active/` is automatically available in **every project** in the Antigravity IDE (`SCOPE_GLOBAL`).
- Moving a skill to `archived/` removes it from Antigravity's active memory without deleting your files.

---

## 📄 License

MIT License. Free to use, modify, and distribute.
