// ============================================
// SPORTX FORM HANDLER - Apps Script
// ============================================

// CONFIGURATION
const CONFIG = {
  emailTo: 'sportxconnect@gmail.com',
  emailSubject: 'New SportX Registration',
  sheetName: 'Registrations',
  spreadsheetId: '1JGzfn_ezZTxnhQMh3K6r4uO9JHlyb4n5L0TyxtotBtY'
};

// ============================================
// DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING
// ============================================

function doPost(e) {
  const sheet = getSheet();
  let data;

  console.log('Received request');
  console.log(e.postData ? e.postData.contents : 'No postData');

  if (e.postData && e.postData.contents) {
    try {
      data = JSON.parse(e.postData.contents);
    } catch (parseError) {
      try {
        const params = new URLSearchParams(e.postData.contents);
        data = JSON.parse(decodeURIComponent(params.get('data')));
      } catch (e) {
        data = { error: 'Failed to parse' };
      }
    }
  } else if (e.parameter) {
    data = e.parameter;
  } else {
    data = { error: 'No data received' };
  }

  console.log('Parsed data: ' + JSON.stringify(data));

  // Add timestamp
  const timestamp = new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' });

  // Prepare row data
  const rowData = [
    timestamp,
    data.category || '',
    data.name || '',
    data.phone || '',
    data.email || '',
    data.city || '',
    data.state || '',
    data.primarySport || '',
    data.otherSports || '',
    data.role || '',
    data.experienceLevel || '',
    data.socialMedia || '',
    data.website || '',
    data.description || '',
    data.profilePhoto || '',
    data.type || 'registration'
  ];

  // Append to sheet
  sheet.appendRow(rowData);
  console.log('Row appended successfully');

  // Send email notification
  if (data.type === 'registration') {
    sendRegistrationEmail(rowData);
  } else if (data.type === 'contact') {
    sendContactEmail(rowData);
  }

  // Return success response
  return ContentService
    .createTextOutput(JSON.stringify({ status: 'success', message: 'Form submitted successfully!' }))
    .setMimeType(ContentService.MimeType.JSON);
}

function doGet(e) {
  return ContentService
    .createTextOutput('SportX Form is running')
    .setMimeType(ContentService.MimeType.TEXT);
}

function getSheet() {
  const spreadsheet = SpreadsheetApp.openById(CONFIG.spreadsheetId);
  let sheet = spreadsheet.getSheetByName(CONFIG.sheetName);

  if (!sheet) {
    sheet = spreadsheet.insertSheet(CONFIG.sheetName);
    // Create headers
    sheet.getRange(1, 1, 1, 16).setValues([[
      'Timestamp',
      'Category',
      'Name/Org',
      'Phone',
      'Email',
      'City',
      'State',
      'Primary Sport',
      'Other Sports',
      'Role',
      'Experience Level',
      'Social Media',
      'Website',
      'Description',
      'Profile Photo',
      'Form Type'
    ]]);
    sheet.getRange(1, 1, 1, 16).setFontWeight('bold');
    sheet.autoResizeColumns(1, 16);
  }

  return sheet;
}

function sendRegistrationEmail(rowData) {
  const [timestamp, category, name, phone, email, city, state, primarySport, otherSports, role, expLevel, social, website, description, profilePhoto] = rowData;

  const htmlBody = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #FFC800; border-bottom: 2px solid #FFC800; padding-bottom: 10px;">🏃 New SportX Registration</h2>

      <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
        <tr style="background: #f9f9f9;">
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold; width: 40%;">Category</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${category}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Name / Organization</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${name}</td>
        </tr>
        <tr style="background: #f9f9f9;">
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Phone</td>
          <td style="padding: 12px; border: 1px solid #ddd;"><a href="tel:${phone}">${phone}</a></td>
        </tr>
        <tr>
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Email</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${email || 'Not provided'}</td>
        </tr>
        <tr style="background: #f9f9f9;">
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Location</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${city}, ${state}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Primary Sport</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${primarySport}</td>
        </tr>
        <tr style="background: #f9f9f9;">
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Other Sports</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${otherSports || 'Not specified'}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Role / Specialization</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${role || 'Not specified'}</td>
        </tr>
        <tr style="background: #f9f9f9;">
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Experience Level</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${expLevel || 'Not specified'}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Social Media</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${social || 'Not provided'}</td>
        </tr>
        <tr style="background: #f9f9f9;">
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Website</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${website || 'Not provided'}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Profile Photo</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${profilePhoto || 'Not provided'}</td>
        </tr>
        <tr style="background: #f9f9f9;">
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Description</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${description || 'Not provided'}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Timestamp</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${timestamp}</td>
        </tr>
      </table>

      <p style="color: #666; font-size: 12px; margin-top: 20px;">
        This registration was submitted through the SportX website.
      </p>
    </div>
  `;

  MailApp.sendEmail({
    to: CONFIG.emailTo,
    subject: `🏃 New SportX Registration - ${name} (${category})`,
    htmlBody: htmlBody,
    name: 'SportX Website'
  });
}

function sendContactEmail(rowData) {
  const [timestamp, , name, phone, email, , , , , , , , , message] = rowData;

  const htmlBody = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #FFC800; border-bottom: 2px solid #FFC800; padding-bottom: 10px;">📩 New SportX Contact</h2>

      <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
        <tr style="background: #f9f9f9;">
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold; width: 40%;">Name</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${name}</td>
        </tr>
        <tr>
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Phone</td>
          <td style="padding: 12px; border: 1px solid #ddd;"><a href="tel:${phone}">${phone}</a></td>
        </tr>
        <tr style="background: #f9f9f9;">
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Email</td>
          <td style="padding: 12px; border: 1px solid #ddd;"><a href="mailto:${email}">${email}</a></td>
        </tr>
        <tr>
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Message</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${message}</td>
        </tr>
        <tr style="background: #f9f9f9;">
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Timestamp</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${timestamp}</td>
        </tr>
      </table>

      <p style="color: #666; font-size: 12px; margin-top: 20px;">
        This message was submitted through the SportX website contact form.
      </p>
    </div>
  `;

  MailApp.sendEmail({
    to: CONFIG.emailTo,
    subject: `📩 Contact from ${name}`,
    htmlBody: htmlBody,
    name: 'SportX Website'
  });
}

// Test function
function testSetup() {
  const sheet = getSheet();
  console.log('Sheet found: ' + sheet.getName());
  console.log('Spreadsheet ID: ' + CONFIG.spreadsheetId);
  return 'Setup OK - Sheet: ' + sheet.getName();
}
