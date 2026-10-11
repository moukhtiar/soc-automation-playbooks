# Playbook: pb-sentinel-notify-disabledacct

Logic App (Consumption) with a **system-assigned managed identity**.
The workflow definition was built in the designer; this file documents it.

## Workflow

| # | Step | Connector | Key settings |
|---|------|-----------|--------------|
| 1 | Trigger: **Microsoft Sentinel incident** | Microsoft Sentinel | Connection `sentinel-mi` (managed identity) |
| 2 | **Entities - Get Accounts** | Microsoft Sentinel | Entities list = trigger `Entities` |
| 3 | **For each** account | Control | Loops over the accounts returned in step 2 |
| 3a | **Add comment to incident (V3)** | Microsoft Sentinel | Incident ARM id = `Incident ARM ID`; comment contains incident title, severity, incident number, account name and account SID |
| 3b | **Send an email (V2)** | Office 365 Outlook | Subject: title, severity, number, account; body: title, account, severity, incident URL |

## Permissions (least privilege)

| Principal | Role | Scope | Purpose |
|-----------|------|-------|---------|
| Playbook managed identity | Microsoft Sentinel Responder | Resource group | Read incidents, write comments |
| Azure Security Insights (Sentinel service) | Microsoft Sentinel Automation Contributor | Resource group | Lets Sentinel run the playbook from an automation rule |

## Automation rules

| Order | Name | Trigger | Condition | Actions |
|-------|------|---------|-----------|---------|
| 1 | ar-disabledacct-triage | Incident created | Analytics rule name contains "Attempts to sign in to disabled accounts" | Status = Active; add tag `auto-triaged` |
| 2 | ar-disabledacct-notify | Incident created | Same as above | Run playbook |

No rule closes incidents or changes any identity.

## Known follow-ups

- Use the **Incident number** token (not *Merged Incident Number*), which is empty for unmerged incidents.
- Production: loop only for the comment and send **one** email listing all accounts.
- Production: replace hard-coded recipients and the personal Outlook sign-in with a shared SOC mailbox or Teams webhook.
