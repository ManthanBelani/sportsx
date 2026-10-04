// ============================================
// SPORTX FORM HANDLER - Apps Script
// ============================================

// CONFIGURATION - Fill these values
const CONFIG = {
  emailTo: 'sportxconnect@gmail.com',
  emailSubject: 'New SportX Registration',
  sheetName: 'Registrations'
};

// ============================================
// DO NOT EDIT BELOW UNLESS YOU KNOW WHAT YOU'RE DOING
// ============================================

function doPost(e) {
  const sheet = getSheet();
  let data;
  
  if (e.postData && e.postData.contents) {
    try {
      data = JSON.parse(e.postData.contents);
    } catch (parseError) {
      const params = new URLSearchParams(e.postData.contents);
      data = JSON.parse(decodeURIComponent(params.get('data')));
    }
  } else {
    data = e.parameter;
  }
  
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
    data.type || 'registration'
  ];
  
  // Append to sheet
  sheet.appendRow(rowData);
  
  // Send email notification
  if (data.type === 'registration') {
    sendRegistrationEmail(rowData);
  } else if (data.type === 'contact') {
    sendContactEmail(rowData);
  }
  
  // Return response
  return ContentService
    .createTextOutput(JSON.stringify({ status: 'success', message: 'Form submitted successfully!' }))
    .setMimeType(ContentService.MimeType.JSON);
}

function doGet(e) {
  return HtmlService.createHtmlOutputFromFile('Index')
    .setTitle('SportX Form');
}

function getSheet() {
  const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = spreadsheet.getSheetByName(CONFIG.sheetName);
  
  if (!sheet) {
    sheet = spreadsheet.insertSheet(CONFIG.sheetName);
    // Create headers
    sheet.getRange(1, 1, 1, 15).setValues([['Timestamp', 'Category', 'Name/Org', 'Phone', 'Email', 'City', 'State', 'Primary Sport', 'Other Sports', 'Role', 'Experience Level', 'Social Media', 'Website', 'Description', 'Form Type']]);
    sheet.getRange(1, 1, 1, 15).setFontWeight('bold');
    sheet.autoResizeColumns(1, 15);
  }
  
  return sheet;
}

function sendRegistrationEmail(rowData) {
  const [timestamp, category, name, phone, email, city, state, primarySport, otherSports, role, expLevel, social, website, description] = rowData;
  
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
          <td style="padding: 12px; border: 1px solid #ddd; font-weight: bold;">Description</td>
          <td style="padding: 12px; border: 1px solid #ddd;">${description || 'Not provided'}</td>
        </tr>
        <tr style="background: #f9f9f9;">
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
    <h2>📩 New Contact Form Submission</h2>
    <table style="border-collapse: collapse; width: 100%; max-width: 500px;">
      <tr><td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Name</td><td style="padding: 10px; border: 1px solid #ddd;">${name}</td></tr>
      <tr><td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Phone</td><td style="padding: 10px; border: 1px solid #ddd;">${phone}</td></tr>
      <tr><td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Email</td><td style="padding: 10px; border: 1px solid #ddd;">${email}</td></tr>
      <tr><td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Message</td><td style="padding: 10px; border: 1px solid #ddd;">${message}</td></tr>
      <tr><td style="padding: 10px; border: 1px solid #ddd; font-weight: bold;">Timestamp</td><td style="padding: 10px; border: 1px solid #ddd;">${timestamp}</td></tr>
    </table>
  `;
  
  MailApp.sendEmail({
    to: CONFIG.emailTo,
    subject: `📩 Contact from ${name}`,
    htmlBody: htmlBody,
    name: 'SportX Website'
  });
}

// Test function to manually send a test email
function testEmail() {
  sendRegistrationEmail(['Test', 'Athlete', 'Test User', '1234567890', 'test@test.com', 'Mumbai', 'Maharashtra', 'Cricket', 'Football, Hockey', 'Batsman', 'Advanced', '@test', 'www.test.com', 'Test description']);
}
