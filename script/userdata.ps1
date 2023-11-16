===================================Windows 2019==============================
<powershell>
net user Administrator “koreanre12!”
$port = 2073
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-TCP' -name "PortNumber" -Value $port
New-NetFirewallRule -DisplayName 'RDPPORTLatest' -Direction Inbound -Action Allow -Protocol TCP -LocalPort $port
set-TimeZone -Id "Korea Standard Time"
Rename-LocalUser -name "administrator" -NewName "sysadmin"
$UnSecurePassword = "k@reanre12!"
$SecurePassword = ConvertTo-SecureString $UnSecurePassword -AsPlainText -Force
Set-LocalUser -Name "sysadmin" -Password $SecurePassword
Restart-Service termservice -Force
Restart-Computer -Force
</powershell>
=============================================================================