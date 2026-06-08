# Daily Digest Agent

Scheduled agent for end-of-day digest.

## Instructions

### Step 1 — Load config
Read `$HOME/.claude/digest-config.json` for channel lists and settings.

### Step 2 — Determine time window
Use `scheduled_lookback_hours` from config (default: 24 hours) to set the scan window.
Today's date in CET (UTC+1 / UTC+2 in CEST) is used for all "today" references.
Compute `oldest` as: current Unix timestamp minus `scheduled_lookback_hours × 3600`.

### Step 3 — Scan Slack
For each channel across all categories (urgent, team, starred), use `slack_search_channels`
to resolve the channel ID, then `slack_read_channel` with `limit: 10` and the computed `oldest`.
Also fetch DMs if `include_all_dms` is true.
Note any Google Drive document URLs linked in messages.

**Exclude own messages:** Skip all messages authored by the user configured in `slack.exclude_user_id`. The user already knows what they posted — the digest should only surface what *others* said.

**Track direct reports' activity:** While scanning every channel, tag any message authored by a user whose `slack_user_id` appears in `directs.people`. Collect these per-person for use in Step 4b.

### Step 4 — Scan Google Drive
Search for documents whose title or content matches any term in `gdrive.search_terms`
and whose `modifiedTime` falls on today's CET date. Use `get_document_preview` for each match.
Also fetch any Drive docs linked from Slack messages in Step 3.

Always fetch every document listed in `gdrive.pinned_documents`, regardless of modification date.
Use `get_drive_file_content` (with offset pagination if needed) to read the full content of each pinned doc.

### Step 4b — Build detailed direct-reports view

For each person in `directs.people`, compile a **comprehensive per-person summary** by combining:

1. **Weekly doc** — Use `get_drive_file_content` (NOT `get_document_preview`) to read the **full content** of each direct's pinned document. Paginate with offsets if needed to capture the entire document. Extract everything: status updates, blockers, wins, risks, plans, open questions, and action items.
2. **Slack activity** — Gather all messages from this person collected in Step 3 across every channel. Also run `slack_search_public` with `from:<slack_username>` for the time window to catch messages in channels not in the scan list.
3. **DMs to you** — Pull any DMs from this person (already captured if `include_all_dms` is true).

For each direct, produce a rich summary covering: current work, blockers/risks, key decisions, cross-team threads, asks for you, and wins.

### Step 5 — Generate digest
Format:

```
# Daily Digest — {DATE} {TIME} CET

## 🔴 Urgent
{summarise by channel — decisions, blockers, asks only}

## 👥 Team
{summarise by channel}

## ⭐ Starred
{summarise by channel}

## 💬 Direct Messages
{sender + key point per DM — exclude messages FROM you}

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

## 📋 Meeting Notes & Transcripts
{title, key decisions, action items}

## ⚡ Action Items
| # | Item | Owner | Due |
```

**Directs section depth:** The Direct Reports section should be the most detailed part of the digest. Don't summarize — extract specifics: project names, ticket numbers, collaborator names, concrete dates, exact blockers. If a direct's weekly doc has bullet points, preserve the substance.

For the rest: be concise. Summarise, don't transcribe. Skip channels with no activity.
Channels with zero messages in the window: list them in a single "No activity" line at the end of each section.

### Step 6 — Save
Append the digest to `$HOME/.claude/digest-log.md` with a `---` separator before each entry.

### Step 7 — Send to Slack
Send the digest to your configured digest channel (set `slack.digest_channel_id` in `digest-config.json`) using `slack_send_message`.
Use the full formatted digest text as the message body.
If the digest is long, send the `## ⚡ Action Items` section as a follow-up thread reply to the same message.
