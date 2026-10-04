# SportX Form Setup Guide

## Files Created
- `Code.gs` - Google Apps Script for handling form submissions
- `Index.html` - Standalone HTML form (optional use)

---

## Setup Instructions

### Step 1: Create Google Apps Script Project
1. Go to [script.google.com](https://script.google.com)
2. Click **New Project**
3. Delete any existing code
4. Copy & paste the contents of `Code.gs` into the editor

### Step 2: Configure the Script
Open `Code.gs` and update these values at the top:
```javascript
const CONFIG = {
  emailTo: 'YOUR_EMAIL@gmail.com',        // Change to your email
  emailSubject: 'New SportX Registration', // Email subject
  sheetName: 'Registrations'               // Name of your sheet tab
};
```

### Step 3: Create Google Sheet
1. Create a new Google Sheet in Google Drive
2. Copy the sheet URL - you'll need the sheet ID
3. In your Apps Script project, click **File** → **Add a file** → **Spreadsheet bound to the current document**
4. Or go to **Resources** → **Google Sheets** to link your sheet

### Step 4: Deploy as Web App
1. Click **Deploy** → **New deployment**
2. Click **Select type** → **Web app**
3. Configure:
   - **Description**: SportX Form Handler
   - **Execute as**: Me
   - **Who has access**: Anyone
4. Click **Deploy**
5. Copy the **Web app URL**

### Step 5: Update Your Website
In your HTML file, replace `YOUR_GOOGLE_APPS_SCRIPT_WEB_APP_URL` with the URL from Step 4:
```javascript
const SCRIPT_URL = 'https://script.google.com/macros/s/YOUR_DEPLOYMENT_ID/exec';
```

---

## How It Works

1. User submits form on website
2. JavaScript sends POST request to Apps Script
3. Apps Script:
   - Saves data to Google Sheet
   - Sends email notification to you
4. User sees success message

---

## Testing

1. Open your website
2. Fill out the form
3. Check your Google Sheet for new entries
4. Check your email for notification

---

## Notes

- The web app URL format: `https://script.google.com/macros/s/.../exec`
- If you update the code, create a **New deployment** (not edit the existing one)
- First time users will need to authorize permissions
