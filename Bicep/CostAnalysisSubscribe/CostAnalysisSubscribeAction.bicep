param ScheduleActionName string 
param IsPrivate bool
param ScheduleActionDisplayName string 
param ScheduleActionEnabled string = 'Enabled'  //'Enabled' | 'Disabled'
param BuildInView string = 'DailyCosts' //'AccumulatedCosts' | 'CostByService' | 'DailyCosts'
param ScheduleActionFrequency string = 'Daily' //'Daily' | 'Weekly' | 'Monthly'
param ScheduleActionDaysOfWeek array = ['Monday'] //[ 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday' ]
param ScheduleActionDayofMonth int = 1
param scheduleActionRecipients string


module ScheduleAction 'br/public:cost/subscription-scheduled-action:1.0.2' = {
  name: ScheduleActionName
  scope: subscription()
  params: {
    name: ScheduleActionName
    kind: 'Email'
    private: IsPrivate
    builtInView: BuildInView
    displayName: ScheduleActionDisplayName
    status: ScheduleActionEnabled
    notificationEmail: scheduleActionRecipients
    emailRecipients: [ scheduleActionRecipients]
    scheduleFrequency: ScheduleActionFrequency
    scheduleDaysOfWeek: ScheduleActionDaysOfWeek
    scheduleDayOfMonth: ScheduleActionDayofMonth
  }
}
