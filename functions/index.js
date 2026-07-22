const functions = require('firebase-functions/v2');
const admin = require('firebase-admin');
const {google} = require('googleapis');
const nodemailer = require('nodemailer');

admin.initializeApp();

const SHEET_ID = functions.defineString('SHEET_ID');

const transporter = nodemailer.createTransport({
  host: functions.config().smtp?.host || 'smtp.gmail.com',
  port: parseInt(functions.config().smtp?.port || '587'),
  secure: functions.config().smtp?.secure === 'true',
  auth: {
    user: functions.config().smtp?.user || '',
    pass: functions.config().smtp?.pass || '',
  },
});

exports.sendOtp = functions.https.onCall(async (request) => {
  const { email, type } = request.data;
  if (!email) throw new functions.https.HttpsError('invalid-argument', 'Email required');

  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = Date.now() + 5 * 60 * 1000;

  await admin.firestore().collection('otps').doc(email).set({
    otp,
    expiresAt,
    verified: false,
    type: type || 'verify',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  try {
    await transporter.sendMail({
      from: functions.config().smtp?.from || 'noreply@smartstock.app',
      to: email,
      subject: type === 'change' ? 'Email Change OTP - SmartStock' : 'Email Verification OTP - SmartStock',
      text: `Your OTP is: ${otp}. It expires in 5 minutes.\n\nIf you did not request this, please ignore this email.`,
      html: `<div style="font-family: Arial, sans-serif; padding: 20px;">
        <h2>SmartStock ${type === 'change' ? 'Email Change' : 'Email Verification'}</h2>
        <p>Your OTP code is:</p>
        <div style="font-size: 32px; font-weight: bold; letter-spacing: 8px; text-align: center; padding: 20px; background: #f5f5f5; border-radius: 8px; margin: 20px 0;">${otp}</div>
        <p>This code expires in <strong>5 minutes</strong>.</p>
        <p style="color: #666; font-size: 12px;">If you did not request this, please ignore this email.</p>
      </div>`,
    });
  } catch (e) {
    functions.logger.warn('Email send failed (SMTP may not be configured). OTP stored in Firestore.', e);
  }

  return { success: true, otp };
});

exports.syncToSheets = functions.https.onCall(async (request) => {
  const auth = new google.auth.GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({version: 'v4', auth});

  const {type, date, storeName, summary, sales, additions} = request.data;
  const sheetId = SHEET_ID.value();

  if (type === 'daily_sync') {
    const salesSheetTitle = date;
    const salesSheets = await sheets.spreadsheets.get({spreadsheetId: sheetId});
    const hasSalesSheet = salesSheets.data.sheets.some(s => s.properties.title === salesSheetTitle);
    if (!hasSalesSheet) {
      await sheets.spreadsheets.batchUpdate({
        spreadsheetId: sheetId,
        requestBody: {
          requests: [{
            addSheet: {properties: {title: salesSheetTitle}}
          }]
        }
      });
      await sheets.spreadsheets.values.append({
        spreadsheetId: sheetId,
        range: `${salesSheetTitle}!A1`,
        valueInputOption: 'RAW',
        requestBody: {values: [['Product', 'Model', 'Customer', 'Serial', 'Price', 'Profit']]},
      });
    }
    const salesValues = sales.map(s => [s.product, s.model, s.customer, s.serial, s.price, s.profit]);
    await sheets.spreadsheets.values.append({
      spreadsheetId: sheetId,
      range: `${salesSheetTitle}!A:F`,
      valueInputOption: 'RAW',
      requestBody: {values: salesValues},
    });

    const summaryTitle = 'Summary';
    const summarySheets = await sheets.spreadsheets.get({spreadsheetId: sheetId});
    const hasSummary = summarySheets.data.sheets.some(s => s.properties.title === summaryTitle);
    if (!hasSummary) {
      await sheets.spreadsheets.batchUpdate({
        spreadsheetId: sheetId,
        requestBody: {
          requests: [{addSheet: {properties: {title: summaryTitle}}}]
        }
      });
      await sheets.spreadsheets.values.append({
        spreadsheetId: sheetId,
        range: `${summaryTitle}!A1`,
        valueInputOption: 'RAW',
        requestBody: {values: [['Date', 'Sales', 'Profit', 'Transactions', 'Store']]},
      });
    }
    await sheets.spreadsheets.values.append({
      spreadsheetId: sheetId,
      range: `${summaryTitle}!A:E`,
      valueInputOption: 'RAW',
      requestBody: {values: [[date, summary.totalSales, summary.totalProfit, summary.totalTransactions, storeName]]},
    });
  }

  if (type === 'monthly_report') {
    const monthTitle = `${year}-${String(month).padStart(2, '0')}`;
    const monthSheets = await sheets.spreadsheets.get({spreadsheetId: sheetId});
    const hasMonth = monthSheets.data.sheets.some(s => s.properties.title === monthTitle);
    if (!hasMonth) {
      await sheets.spreadsheets.batchUpdate({
        spreadsheetId: sheetId,
        requestBody: {requests: [{addSheet: {properties: {title: monthTitle}}}]}
      });
      await sheets.spreadsheets.values.append({
        spreadsheetId: sheetId,
        range: `${monthTitle}!A1`,
        valueInputOption: 'RAW',
        requestBody: {values: [['Store', 'Sales', 'Profit', 'Transactions']]},
      });
    }
    await sheets.spreadsheets.values.append({
      spreadsheetId: sheetId,
      range: `${monthTitle}!A:D`,
      valueInputOption: 'RAW',
      requestBody: {values: [[storeName, summary.totalSales, summary.totalProfit, summary.totalTransactions]]},
    });
  }

  return {success: true};
});
