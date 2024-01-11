using './AzureBudgets.bicep'

param budgetName = 'TestBudget' // Budget name
param amount = 100      // Amount in USD
param startDate = '2024-1-1' // Start date
param endDate = '' // End date if required
param timeGrain = 'Monthly' // Time grain
param category = 'Cost' // Category
param contactEmails = ['email@microsoft.com'] // Contact emails

param spendThresholdWarning1 = 50 // Spend threshold warning 1
param spendThresholdWarning2 = 75 // Spend threshold warning 2
param notificationType = 'ActualCost' // Notification type
param locale = 'en-us' // Locale


