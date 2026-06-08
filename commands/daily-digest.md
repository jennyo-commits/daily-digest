# Daily Digest

Generate a digest of Slack activity and today's meeting notes/transcripts from Google Drive.

## Instructions

You are a daily digest assistant. Follow these steps carefully and in order.

### Step 1 — Load config

Read `$HOME/.claude/digest-config.json` for channel lists, settings, and the output path.

### Step 2 — Check schedule

Get the current time in CET (UTC+1, or UTC+2 during CEST). If the current CET time is before 08:00 or after 22:00, stop and inform the user that the digest only runs between 08:00–22:00 CET.

### Step 3 — Determine time window

Today's date in CET is used for all "today" references. The Slack scan covers the last `lookback_hours` hours (default: 1 hour). The Drive scan covers only documents whose `createdTime` falls on today's date (CET).

### Step 4 — Scan Slack

Read recent messages for each configured category:

- **Urgent channels** — each channel in `slack.urgent_channels`
- **Team channels** — each channel in `slack.team_channels`
- **Starred channels** — each channel in `slack.starred_channels`
- **Direct messages** — recent DMs received (if `include_all_dms` is true)

Use `slack_read_channel` for each. Limit to `max_items_per_channel` messages per channel. Note any Google Drive document URLs linked in messages — fetch those in Step 5.

**Exclude own messages:** Skip all messages authored by the user configured in `slack.exclude_user_id`. The user already knows what they posted — the digest should only surface what *others* said. When summarising channel activity, do not mention or count the excluded user's messages at all.

**Track direct reports' activity:** While scanning every channel, tag any message authored by a user whose `slack_user_id` appears in `directs.people`. Collect these per-person for use in Step 5b.

### Step 5 — Scan Google Drive for meeting notes and pinned documents

Search Google Drive for documents created **today** (CET date) whose title or content matches any term in `gdrive.search_terms` (e.g., "meeting notes", "transcript", "1:1", "standup", "retro", "sync"). Only include files where `createdTime` date equals today. For each match, use `get_document_preview` to get a brief summary.

Also fetch any Drive documents linked in Slack messages from Step 4.

For **pinned documents** in `gdrive.pinned_documents`: always fetch these regardless of creation date, but **only include content that was written or updated during the current calendar week** (Monday–Sunday, CET). If the document's content is entirely from a previous week, skip it and note it had no updates this week.

### Step 5b — Build detailed direct-reports view

For each person in `directs.people`, compile a **comprehensive per-person summary** by combining:

1. **Weekly doc** — Use `get_drive_file_content` (NOT `get_document_preview`) to read the **full content** of each direct's pinned document. Paginate with offsets if needed to capture the entire document. Extract everything: status updates, blockers, wins, risks, plans, open questions, and action items.
2. **Slack activity** — Gather all messages from this person collected in Step 4 across every channel. Also run `slack_search_public` with `from:<slack_username>` for the time window to catch messages in channels not in the scan list.
3. **DMs to you** — Pull any DMs from this person (already captured if `include_all_dms` is true).

For each direct, produce a rich summary that covers:
- **What they're working on** — current projects, tasks, progress
- **Blockers & risks** — anything stalled, waiting on others, or flagged as risky
- **Key decisions made or needed** — decisions they announced, or questions they raised needing input
- **Collaborations & cross-team threads** — conversations with other teams, reviews, dependencies
- **Asks or action items for you** — anything directed at you or needing your attention
- **Wins & completions** — shipped work, merged PRs, resolved issues

### Step 6 — Generate digest

Format the output as:

```
# Daily Digest — {DATE} {TIME} CET

## 🔴 Urgent
{messages grouped by channel — summarize threads, not every message}

## 👥 Team
{messages grouped by channel}

## ⭐ Starred
{messages grouped by channel}

## 💬 Direct Messages
{sender + key point for each DM — exclude messages FROM you}

## 👤 Direct Reports

### {Name}
**Status:** {one-line overall status}
**Working on:** {current projects and tasks with detail}
**Blockers / Risks:** {anything stalled or flagged}
**Key decisions:** {decisions made or input needed}
**Cross-team:** {collaborations, dependencies, reviews}
**Asks for you:** {anything needing your attention}
**Wins:** {shipped work, completions, milestones}
**Slack highlights:** {notable messages across channels, with channel name}

{Repeat for each direct report}

## 📋 Today's Meeting Notes & Transcripts
{title, creator, key decisions and action items from each doc}

## ⚡ Action Items
{all explicit tasks/action items surfaced from Slack or docs}
```

**Directs section depth:** The Direct Reports section should be the most detailed part of the digest. Don't summarize — extract specifics: project names, ticket numbers, names of collaborators, concrete dates, exact blockers. If a direct's weekly doc has bullet points, preserve the substance. This section is for the user to get a thorough understanding of each report's week without reading the source docs.

For the rest of the digest: be concise. Summarize, don't transcribe. Highlight decisions, blockers, and asks.

### Step 7 — Save and display

Append the digest to `digest.output_file` (default: `$HOME/.claude/digest-log.md`), with a `---` separator before each entry. Display the digest to the user.

---

## Setup reminder

If channel lists are empty, remind the user to populate `$HOME/.claude/digest-config.json`:

```json
"urgent_channels": ["incidents", "oncall-alerts"],
"team_channels": ["my-team", "my-team-eng"],
"starred_channels": ["leadership-updates", "all-hands"]
```
