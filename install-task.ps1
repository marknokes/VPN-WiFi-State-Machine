$taskName = "VPN WiFi State Machine"

$xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">

  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription><![CDATA[
<QueryList>
  <Query Id="0" Path="Microsoft-Windows-WLAN-AutoConfig/Operational">
    <Select Path="Microsoft-Windows-WLAN-AutoConfig/Operational">
      *[System[(EventID=8001 or EventID=8003)]]
    </Select>
  </Query>
</QueryList>
      ]]></Subscription>
    </EventTrigger>
  </Triggers>

  <Actions Context="System">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -File "$PSScriptRoot\vpn-state-machine.ps1"</Arguments>
    </Exec>
  </Actions>

  <Principals>
    <Principal>
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>

</Task>
"@

Register-ScheduledTask -TaskName $taskName -Xml $xml -Force