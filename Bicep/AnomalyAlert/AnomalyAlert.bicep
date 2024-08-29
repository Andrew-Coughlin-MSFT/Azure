targetScope ='subscription'

param AnomalyAlertName string 
param ScheduleActionDisplayName string 
param scheduleActionRecipients string

module anomalyAlert 'br/public:cost/subscription-scheduled-action:1.0.2' = {
  name: 'CreateAnomalyAlert'
  scope: subscription()
  params: {
    name: AnomalyAlertName
    kind: 'InsightAlert'
    displayName: ScheduleActionDisplayName
    emailRecipients: [ scheduleActionRecipients ]
    notificationEmail: scheduleActionRecipients
    emailLanguage: 'en'
    emailRegionalFormat: 'en-us'
    
  }
}
