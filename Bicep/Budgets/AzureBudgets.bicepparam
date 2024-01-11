using './AzureBudgets.bicep'

param budgetName = 'TestBudget'
param amount = 100
param startDate = '2024-1-1'
param endDate = ''
param timeGrain = 'Monthly'
param category = 'Cost'
param contactEmails = ['ancoughl@microsoft.com']

param spendThresholdWarning1 = 50
param spendThresholdWarning2 = 75
param notificationType = 'ActualCost'
param locale = 'en-us'


