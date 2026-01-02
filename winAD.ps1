# Запускать на Windows Server с ролью AD DS (от администратора)

$ErrorActionPreference = "Stop"
$domain = Get-ADDomain
$domainDN = $domain.DistinguishedName
$domainName = $domain.DNSRoot

$ous = @("Финансы", "Продажи", "Администраторы")
foreach ($ou in $ous) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'")) {
        New-ADOrganizationalUnit -Name $ou -Path $domainDN -ProtectedFromAccidentalDeletion $true
        Write-Host "✅ Создано OU: $ou"
    }
}

$gpoName = "Restrict_NonAdmin_Users"
if (-not (Get-GPO -Name $gpoName -ErrorAction SilentlyContinue)) {
    New-GPO -Name $gpoName | Out-Null
    Write-Host "✅ Создана GPO: $gpoName"

    Set-GPRegistryValue -Name $gpoName -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "NoControlPanel" -Type DWord -Value 1 | Out-Null
    Set-GPRegistryValue -Name $gpoName -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "NoRun" -Type DWord -Value 1 | Out-Null
    Set-GPRegistryValue -Name $gpoName -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" -ValueName "DisableRegistryTools" -Type DWord -Value 2 | Out-Null
    Set-GPRegistryValue -Name $gpoName -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "NoSetFolders" -Type DWord -Value 1 | Out-Null
    Set-GPRegistryValue -Name $gpoName -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -ValueName "NoWindowsUpdate" -Type DWord -Value 1 | Out-Null
}

Link-GPO -Name $gpoName -Target "OU=Финансы,$domainDN" -LinkEnabled Yes -Enforced No
Link-GPO -Name $gpoName -Target "OU=Продажи,$domainDN" -LinkEnabled Yes -Enforced No

Write-Host "GPO применена к Финансам и Продажам"
Write-Host "Администраторы НЕ получают ограничения"
Write-Host "Готово Структура AD развёрнута."
