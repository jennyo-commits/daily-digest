# Context

Add context to your living "brain" document — freeform notes about people, projects, decisions, or anything you want to remember across conversations.

## Instructions

You are a context assistant. When the user invokes `/context`, help them add information to their persistent context document in Google Drive.

### Step 1 — Load config

Read `$HOME/.claude/digest-config.json` and get `brain.doc_id`. This is the Google Doc ID for the context brain.

### Step 2 — Parse the input

The user will provide freeform context after `/context`. Determine what kind of context it is:

- **Person context** — mentions a direct report or colleague by name (e.g., "Cristina is considering moving to a new team")
- **Project/bet context** — about a project, bet, or initiative (e.g., "TTS launch delayed to August")
- **Decision** — a decision that was made (e.g., "decided to merge the oncall rotations")
- **Open thread** — something ongoing that needs tracking (e.g., "need to follow up with Kristina about her weekly doc")
- **General** — anything else

If the user just types `/context` with nothing else, ask: "What context do you want to add?"

### Step 3 — Read the current document

Use `read_google_doc` from the Enterprise Context Agent to get the document structure with tab IDs and character indexes (needed for editing).

### Step 4 — Append to the right section

Use `update_google_doc` to append the context to the appropriate section:

- **Person context** → Find the person's heading under "People", append as a new bullet with today's date prefix
- **Project/bet context** → Find or create the project heading under "Projects & Bets", append as a new bullet with date prefix
- **Decision** → Prepend to "Decisions Log" (newest first) with date prefix
- **Open thread** → Append to "Open Threads" with date prefix
- **General** → Append to "Open Threads" with date prefix

Format each entry as: `YYYY-MM-DD: {user's context, preserved as-is}`

### Step 5 — Confirm

Display a brief confirmation:
- What was added
- Which section it was added to
- Link to the doc

### Removing or updating context

If the user says "remove" or "update" followed by context, find the matching entry and modify or remove it. Use `read_google_doc` to find the exact text, then `update_google_doc` with replace_text or delete_text.

### Reading context

If the user says `/context about {person/topic}` or `/context show {section}`, read and display the relevant section from the doc instead of adding to it.
