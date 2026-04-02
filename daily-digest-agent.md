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

### Step 4 — Scan Google Drive
Search for documents whose title or content matches any term in `gdrive.search_terms`
and whose `modifiedTime` falls on today's CET date. Use `get_document_preview` for each match.
Also fetch any Drive docs linked from Slack messages in Step 3.

Always fetch every document listed in `gdrive.pinned_documents`, regardless of modification date.
Use `get_drive_file_content` (with offset pagination if needed) to read the full content of each pinned doc.

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
{sender + key point per DM}

## 📋 Meeting Notes & Transcripts
{title, key decisions, action items}

## ⚡ Action Items
| # | Item | Owner | Due |
```

Be concise. Summarise, don't transcribe. Skip channels with no activity.
Channels with zero messages in the window: list them in a single "No activity" line at the end of each section.

### Step 6 — Save
Append the digest to `$HOME/.claude/digest-log.md` with a `---` separator before each entry.

### Step 7 — Send to Slack
Send the digest to your configured digest channel (set `slack.digest_channel_id` in `digest-config.json`) using `slack_send_message`.
Use the full formatted digest text as the message body.
If the digest is long, send the `## ⚡ Action Items` section as a follow-up thread reply to the same message.
