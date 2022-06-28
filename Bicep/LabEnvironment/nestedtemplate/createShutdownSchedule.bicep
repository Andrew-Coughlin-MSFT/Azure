@description('Location for all resources.')
param location string

@description('Shutdown schedule name')
param shutdownScheduleName string

@description('Schedule shutdown scheduled status.')
@allowed([
  'Enabled'
  'Disable'
])
param shutdownStatus string

@description('Time when the machine should shutdown. (\'19:00\')')
param shutdownTime string

@description('Time zone Id')
@allowed([
'West Samoa Time'
'Niue Time'
'Samoa Standard Time'
'Hawaii-Aleutian Standard Time'
'Hawaii Standard Time'
'Tokelau Time'
'Cook Is. Time'
'Tahiti Time'
'Marquesas Time'
'Alaska Standard Time'
'Gambier Time'
'Pacific Standard Time'
'Pitcairn Standard Time'
'Mountain Standard Time'
'Central Standard Time'
'Easter Is. Time'
'Galapagos Time'
'Colombia Time'
'Eastern Standard Time'
'Ecuador Time'
'Peru Time'
'Acre Time'
'GMT-05:00'
'Atlantic Standard Time'
'Paraguay Time'
'Venezuela Time'
'Amazon Standard Time'
'Guyana Time'
'Bolivia Time'
'Chile Time'
'Falkland Is. Time'
'Newfoundland Standard Time'
'Argentine Time'
'French Guiana Time'
'Brazil Time'
'Western Greenland Time'
'Pierre & Miquelon Standard Time'
'Uruguay Time'
'Suriname Time'
'Fernando de Noronha Time'
'South Georgia Standard Time'
'Eastern Greenland Time'
'Azores Time'
'Cape Verde Time'
'Greenwich Mean Time'
'Western European Time'
'Coordinated Universal Time'
'Central European Time'
'Western African Time'
'Eastern European Time'
'Central African Time'
'South Africa Standard Time'
'Israel Standard Time'
'Eastern African Time'
'Arabia Standard Time'
'Moscow Standard Time'
'Iran Time'
'Aqtau Time'
'Azerbaijan Time'
'Gulf Standard Time'
'Georgia Time'
'Armenia Time'
'Samara Time'
'Seychelles Time'
'Mauritius Time'
'Reunion Time'
'Afghanistan Time'
'Aqtobe Time'
'Turkmenistan Time'
'Kirgizstan Time'
'Tajikistan Time'
'Pakistan Time'
'Uzbekistan Time'
'Yekaterinburg Time'
'Indian Ocean Territory Time'
'French Southern & Antarctic Lands Time'
'Maldives Time'
'India Standard Time'
'Nepal Time'
'Mawson Time'
'Alma-Ata Time'
'Sri Lanka Time'
'Bangladesh Time'
'Novosibirsk Time'
'Bhutan Time'
'Myanmar Time'
'Cocos Islands Time'
'Indochina Time'
'Java Time'
'Krasnoyarsk Time'
'Christmas Island Time'
'Western Standard Time (Australia)'
'Brunei Time'
'Hong Kong Time'
'Irkutsk Time'
'Malaysia Time'
'China Standard Time'
'Philippines Time'
'Singapore Time'
'Borneo Time'
'Ulaanbaatar Time'
'Jayapura Time'
'Korea Standard Time'
'Japan Standard Time'
'Yakutsk Time'
'Palau Time'
'Central Standard Time (Northern Territory)'
'Central Standard Time (South Australia)'
'Central Standard Time (South Australia/New South Wales)'
'Eastern Standard Time (New South Wales)'
'Dumont-d Urville Time'
'Vladivostok Time'
'Eastern Standard Time (Queensland)'
'Eastern Standard Time (Tasmania)'
'Chamorro Standard Time'
'Papua New Guinea Time'
'Truk Time'
'Load Howe Standard Time'
'Magadan Time'
'Vanuatu Time'
'Solomon Is. Time'
'Kosrae Time'
'New Caledonia Time'
'Ponape Time'
'Norfolk Time'
'New Zealand Standard Time'
'Anadyr Time'
'Petropavlovsk-Kamchatski Time'
'Fiji Time'
'Tuvalu Time'
'Marshall Islands Time'
'Nauru Time'
'Gilbert Is. Time'
'Wake Time'
'Wallis & Futuna Time'
'Chatham Standard Time'
'Phoenix Is. Time'
'Tonga Time'
'Line Is. Time'
])
param timeZoneId string

@description('Notification settings status, determines if an email notification gets set before shutdown.')
@allowed([
'Disabled'
'Enabled'
])
param notificationSettingsStatus string

@description('Virtual machine object')
param vmid string

resource vm_shutdownResourceName 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: shutdownScheduleName
  location: location
  properties: {
    status: shutdownStatus
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: shutdownTime
    }
    timeZoneId: timeZoneId
    notificationSettings: {
      status: notificationSettingsStatus
      timeInMinutes: 30
    }
    targetResourceId: vmid
  }
}
