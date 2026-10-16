# Katabump Server Auto-Renewal Tool

[English Version](README_EN.md) | [中文说明](README.md)

This project is an automation script for renewing Katabump servers. It utilizes Playwright and CDP (Chrome DevTools Protocol) to simulate user interactions, effectively specifically targeting the Cloudflare Turnstile CAPTCHA to ensure continuous server service.

It supports both **Windows Local Execution** and **GitHub Actions Cloud Execution**.

## ✨ Features

- **Smart Bypass**: Uses CDP to simulate realistic mouse trajectories and clicks, combined with screen coordinate spoofing, to achieve a high success rate in bypassing Cloudflare Turnstile.
- **Auto-Retry**: Built-in strict verification retry mechanism. It automatically restarts the verification flow if the CAPTCHA check fails.
- **Multi-User**: Supports batch renewal for multiple accounts.
- **Cloud/Local**: Can run on your local machine or automatically on part of a daily schedule using GitHub Actions.

---

## 🚀 GitHub Actions Cloud Run (Recommended)

This is the easiest way to set it up once and have it run automatically every day.

1.  **Fork this repository** to your GitHub account.
2.  Go to your repository settings: **Settings** -> **Secrets and variables** -> **Actions**.
3.  Click **New repository secret** and add a secret named `USERS_JSON`.
4.  The **Value** must be a JSON array (condensed into a single line is best):
    ```json
    [{"username": "your_email@example.com", "password": "your_password"}, {"username": "another@example.com", "password": "pwd"}]
    ```
5.  **(Optional) Configure Proxy**:
    If you need to run behind a proxy (e.g. to avoid IP blocks), add a Secret named `HTTP_PROXY`.
    -   **Format**:
        -   No Auth: `http://ip:port`
        -   With Auth: `http://username:password@ip:port`
    -   **Note**: The script validates the proxy before use. Default is disabled.
6.  **(Optional) Telegram Notifications**:
    If you want to receive Telegram notifications (with screenshots) upon renewal success, failure, or skip, add the following Secrets:
    -   `TG_BOT_TOKEN`: Your Telegram Bot Token (from @BotFather).
    -   `TG_CHAT_ID`: Your Chat ID (User ID or Group ID).
    > If not configured, notifications will be skipped.
7.  Save it. Then, go to the **Actions** tab and enable the workflow. It is scheduled to run automatically at **08:00 Beijing Time (00:00 UTC)**.
8.  You can also manually click "Run workflow" to test it immediately.

### Results & Screenshots

- **Logs**: Check real-time logs in the `Run Renew Script` step.
- **Screenshots**: Screenshots are automatically captured for each user (success or failure) and uploaded as artifacts.
  - Download the `screenshots` zip file from the **Artifacts** section of the workflow run summary.
  - Files are named `username.png`.

---

## 💻 Windows Local Execution Guide

Follow these steps if you want to run the script locally on your computer for debugging or monitoring.

### 1. Prerequisites
Ensure you have [Node.js](https://nodejs.org/) installed (version v18+ recommended).

### 2. Install Dependencies
Open a terminal (PowerShell or CMD) in the project root directory and run:
```bash
npm install
```

### 3. Configure Credentials
The project contains a `login.json.template` file.
1. **Rename** it to `login.json`.
2. Open it with a text editor and fill in your account credentials:
   ```json
   [
       {
           "username": "myemail@gmail.com",
           "password": "mypassword123"
       }
   ]
   ```
   > **Note**: `login.json` is included in `.gitignore` and will NOT be uploaded to GitHub.

### 4. Runtime Settings

**No manual Chrome path setup needed**: `renew.js` probes `CHROME_PATH` → `%LOCALAPPDATA%` → `Program Files` → `Program Files (x86)`. Set `CHROME_PATH` explicitly only if Chrome lives somewhere unusual:

```powershell
$env:CHROME_PATH = '<full path to chrome.exe>'
node renew.js
```

**Browser data directory** (`USER_DATA_DIR`, i.e. `ChromeData_Katabump` in the project root):

*   Stores cookies, cache and login state produced by the script.
*   **Purpose**: keeps your login session so you do not re-enter credentials every run.
*   **Can it be deleted?**: **Yes**. Delete it to reset all state; the script recreates it on the next run.

**Run modes** (headed and visible by default; override with environment variables):

| Variable | Effect |
| --- | --- |
| (unset) | A visible Chrome window, so you can watch every step |
| `HEADLESS=true` | Fully headless, nothing visible |
| `OFFSCREEN=1` | Still headed, but the window is moved off-screen (used by the scheduled task) |

> The scheduled task uses `OFFSCREEN=1` rather than `HEADLESS=true` because Cloudflare Turnstile detects pure headless browsers far more aggressively.

**Manual debugging**: double-click `start_chrome.bat` to open Chrome with debug port 9222 on the **same** `ChromeData_Katabump` profile. If the script finds that instance, it reuses it and closes it when finished.

### 5. Run Script

If you need to use a proxy, set the `HTTP_PROXY` environment variable:

**Powershell:**
```powershell
$env:HTTP_PROXY="http://user:pass@127.0.0.1:7890"
node renew.js
```

**CMD:**
```cmd
set HTTP_PROXY=http://user:pass@127.0.0.1:7890
node renew.js
```

Or just run without proxy:
```bash
node renew.js
```
The script will auto-launch Chrome (if needed), process each account, and save a screenshot (`username.png`) in the `photo/` directory upon completion. It runs headed by default so you can watch, and closes the Chrome it started when done, leaving no stray windows behind.

---

## 🛠️ Project Structure

*   `renew.js`: Main script for Windows local execution.
*   `action_renew.js`: Dedicated script for GitHub Actions environment (Linux/Headless adapted).
*   `.github/workflows/renew.yml`: Configuration file for GitHub Actions scheduled tasks.
*   `login.json`: (Manually created) Stores account info for local runs.
*   `start_chrome.bat`: Opens Chrome with debug port 9222 on the same profile as the script.
