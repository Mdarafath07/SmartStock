const functions = require('firebase-functions/v2');
const admin = require('firebase-admin');
const {google} = require('googleapis');

admin.initializeApp();

const SHEET_ID = functions.defineString('SHEET_ID');

exports.syncToSheets = functions.https.onCall(async (request) => {
  const auth = new google.auth.GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/spreadsheets'],
  });
  const sheets = google.sheets({version: 'v4', auth});

  const {type, date, storeName, summary, sales, additions} = request.data;
  const sheetId = SHEET_ID.value();

  if (type === 'daily_sync') {
    // Sales sheet
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

    // Summary sheet
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
