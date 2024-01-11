targetScope = 'subscription'

@description('Creates a budget for a subscription.')
param budgetName string

@description('The total amount of cost to track with the budget')
@minValue(1)
param amount int

@description('The start of the time period covered by a budget. The date conforms to the following format: YYYY-MM-DD.')
param startDate string

@description('The end of the time period covered by a budget. If not provided, it will default to 10 years from the start date.')
param endDate string

@description('The time covered by a budget. Tracking of the amount will be reset at the start of the time period on a recurring basis. Possible values include: \'Annually\', \'BillingAnnual\', \'BillingMonth\', \'BillingQuarter\', \'Monthly\', \'Quarterly\'.')
@allowed([
  'Annually'
  'BillingAnnual'
  'BillingMonth'
  'BillingQuarter'
  'Monthly'
  'Quarterly'
])
param timeGrain string = 'Monthly' 

@description('The category of the budget, whether the budget tracks actual cost or forcast cost. Possible values include: \'Cost\', \'Usage\'.')
@allowed([
  'Cost'
  'Usage'
])
param category string = 'Cost'

@description('The email addresses of the subscription administrators to contact when the budget threshold is exceeded and the budget alert is fired. Possible value [\'email@address.net\',\'email2@address.net\']')
param contactEmails string[]

@description('The amount of cost to track with the budget in a percentage. First warning threshold.')
param spendThresholdWarning1 int

@description('The amount of cost to track with the budget in a percentage. Second warning threshold.')
param spendThresholdWarning2 int

@description('The category of the budget, whether the budget tracks actual cost or forcast cost. Possible values include: \'ActualCost\', \'ForecastCost\'.')
@allowed([
  'ActualCost'
  'ForecastCost'
])
param notificationType string

@description('The locale to use for the notification. Possible values include: \'en-us\', \'zh-cn\'.')
@allowed([
  'en-us'
  'zh-cn'
])
param locale string = 'en-us'

 var notificationActualSpend = {
  actualSpendNotification1: {
    enabled: true
    operator: 'GreaterThan'
    threshold: spendThresholdWarning1
    contactEmails: contactEmails
    locale: locale
  }
  actualSpendNotification2: {
    enabled: true
    operator: 'GreaterThan'
    threshold: spendThresholdWarning2
    contactEmails: contactEmails
    locale: locale
  }
}

var notificationForcastSpend = {
  forecastSpend1: {
    enabled: true
    operator: 'GreaterThan'
    threshold: spendThresholdWarning1
    contactEmails: contactEmails
    locale: locale
  }
  forecastSpend2: {
    enabled: true
    operator: 'GreaterThan'
    threshold: spendThresholdWarning2
    contactEmails: contactEmails
    locale: locale
  }
} 

resource budget 'Microsoft.Consumption/budgets@2023-05-01' = {
  name: budgetName
  properties: {
    amount: amount
    timeGrain: timeGrain
    category: category
    timePeriod: {
      startDate: startDate
      endDate: endDate
    }
    notifications:(notificationType == 'ActualCost' ? notificationActualSpend : notificationForcastSpend)

  }
}
