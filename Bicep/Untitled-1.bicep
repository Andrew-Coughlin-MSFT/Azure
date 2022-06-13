param location string = resourceGroup().location
var shutdownScheduleName = 'shutdown-computevm-labdc01'
param virtualMachines_ADADC01_externalid string = '/subscriptions/fe36c4c6-a339-4e76-91b2-b1679918c996/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachines/LABDC01'

resource vmrebootschedule 'Microsoft.DevTestLab/labs/schedules@2018-09-15'={
    name : shutdownScheduleName
    location: location
    properties:{
      dailyRecurrence:{
        time:'1900'
      }
      status:'Enabled'
      taskType:'ComputeVmShutdownTask'
      timeZoneId:'Central Standard Time'
      notificationSettings:{
        status:'Disabled'
        timeInMinutes: 30
        notificationLocale: 'en'
      }
      targetResourceId: virtualMachines_ADADC01_externalid
    }
  }