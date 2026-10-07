# Antigravity Skills Manager

A portable, dependency-free Windows utility for toggling, optimizing, inspecting, auto-generating summaries, and backing up skills for Google Antigravity and AI coding agents.

## Features
- **Zero Configuration on Download:** On the first run, the script interactively asks for your folder paths and saves them to `skills_config.cfg`.
- **Auto-Generate SKILLS_SUMMARY.txt:** Scans all `SKILL.md` files across active and archived directories, parses YAML metadata, and rebuilds clean one-liners automatically (Option `[G]` or via `generate_summary.bat`).
- **Token Optimization:** Easily move redundant sub-skills to an archive directory with 1 click to save ~2,000+ context window tokens per agent turn.
- **Skill Info Inspector:** Look up what any skill does in 1 line directly from `SKILLS_SUMMARY.txt` by typing its number or name.
- **Automated Mirror Backups:** Uses Windows `robocopy` with safe retry policies to mirror active skills to your chosen backup destination.
- **Auditable Transaction Log:** Automatically records all move and copy actions with timestamps into `skills_transactions.txt` (capped at the last 100 events).
- **Portable & Multi-User:** No hardcoded paths or personal credentials. Any developer can place this utility anywhere on their PC.

---

## Quick Start

1. Double-click `manage_skills.bat` (or run it in Command Prompt / Windows Terminal).
2. On first launch, follow the prompts:
   - **Active Skills Folder:** The folder your AI agent reads (e.g. `C:\MyProject\.agents\skills`).
   - **Archived Skills Folder:** Where disabled skills are parked (press ENTER to use default `./skills_archive`).
   - **Backup Folder:** Where skills are mirrored (press ENTER to use default `./skills_backup`).
3. Use the menu options `[1-9, G, C]` to manage, toggle, inspect, and backup your skills.
4. Press `[G]` at any time to re-scan your folders and update `SKILLS_SUMMARY.txt`.

---

## Files Included

| File | Purpose |
| :--- | :--- |
| `manage_skills.bat` | Interactive terminal UI for listing, toggling, inspecting, and managing skills. |
| `backup_skills.bat` | Standalone Robocopy mirror backup script (can run independently or via manager). |
| `generate_summary.bat` | Standalone launcher to auto-generate `SKILLS_SUMMARY.txt` from all `SKILL.md` files. |
| `generate_summary.ps1` | PowerShell engine for parsing YAML frontmatter and condensing descriptions. |
| `SKILLS_SUMMARY.txt` | Concise, one-liner reference guide for all workspace skills and global plugins. |
| `README.md` | Comprehensive user guide and documentation. |
| `skills_config.cfg` | *(Auto-generated on first run)* Stores user-specific paths. |
| `skills_transactions.txt` | *(Auto-generated)* Rolling log of the last 100 file transactions. |
