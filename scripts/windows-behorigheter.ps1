#Requires -RunAsAdministrator
# Kor i WindowsLab med 64-bitars Windows PowerShell.
# Konfigurerar labbkonton och projektmapparnas behorigheter.
# Befintliga filers innehall och losenord andras inte.

$ErrorActionPreference = "Stop"

# Skapa grupper om de saknas.
foreach ($group in @("g_ledare", "g_personal")) {
    if (-not (Get-LocalGroup -Name $group -ErrorAction SilentlyContinue)) {
        New-LocalGroup -Name $group | Out-Null
    }
}

# Skapa saknade konton med losenord som anges dolt.
foreach ($name in @("alice", "bob")) {
    if (-not (Get-LocalUser -Name $name -ErrorAction SilentlyContinue)) {
        $password = Read-Host "Valj labblosenord for $name" -AsSecureString
        New-LocalUser -Name $name -Password $password | Out-Null
        Remove-Variable password
    }
}

# Sakerstall gruppmedlemskap.
$memberships = @{
    g_ledare   = "alice"
    g_personal = "bob"
}

foreach ($group in $memberships.Keys) {
    $user = Get-LocalUser -Name $memberships[$group]
    $members = @(Get-LocalGroupMember -Group $group)

    if ($user.SID.Value -notin @($members.SID.Value)) {
        Add-LocalGroupMember -Group $group -Member $user
    }
}

# Skapa mappar utan att skriva over filer.
foreach ($path in @(
    "C:\Projekt",
    "C:\Projekt\Gemensamt",
    "C:\Projekt\Ledning"
)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
}

# SID gor att inbyggda konton fungerar oavsett Windows-sprak.
$admins = [System.Security.Principal.SecurityIdentifier]::new(
    "S-1-5-32-544"
)
$system = [System.Security.Principal.SecurityIdentifier]::new(
    "S-1-5-18"
)
$leaders = [System.Security.Principal.NTAccount]::new(
    "$env:COMPUTERNAME\g_ledare"
)
$staff = [System.Security.Principal.NTAccount]::new(
    "$env:COMPUTERNAME\g_personal"
)

function Add-AllowRule {
    param($Acl, $Identity, $Rights, $Inheritance)

    $rule = [System.Security.AccessControl.FileSystemAccessRule]::new(
        $Identity,
        [System.Security.AccessControl.FileSystemRights]$Rights,
        [System.Security.AccessControl.InheritanceFlags]$Inheritance,
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Allow
    )
    $Acl.AddAccessRule($rule)
}

# Rotmapp: ersatt DACL och blockera arv fran C:\.
$rootAcl = [System.Security.AccessControl.DirectorySecurity]::new()
$rootAcl.SetAccessRuleProtection($true, $false)

Add-AllowRule $rootAcl $admins "FullControl" "ContainerInherit, ObjectInherit"
Add-AllowRule $rootAcl $system "FullControl" "ContainerInherit, ObjectInherit"
Add-AllowRule $rootAcl $leaders "ReadAndExecute" "None"
Add-AllowRule $rootAcl $staff "ReadAndExecute" "None"

Set-Acl -LiteralPath "C:\Projekt" -AclObject $rootAcl

# Gemensamt: arv av administration samt Modify for bada grupperna.
$sharedAcl = [System.Security.AccessControl.DirectorySecurity]::new()
$sharedAcl.SetAccessRuleProtection($false, $false)

Add-AllowRule $sharedAcl $leaders "Modify" "ContainerInherit, ObjectInherit"
Add-AllowRule $sharedAcl $staff "Modify" "ContainerInherit, ObjectInherit"

Set-Acl -LiteralPath "C:\Projekt\Gemensamt" -AclObject $sharedAcl

# Ledning: arv av administration samt Modify for g_ledare.
$managementAcl = [System.Security.AccessControl.DirectorySecurity]::new()
$managementAcl.SetAccessRuleProtection($false, $false)

Add-AllowRule $managementAcl $leaders "Modify" "ContainerInherit, ObjectInherit"

Set-Acl -LiteralPath "C:\Projekt\Ledning" -AclObject $managementAcl

Write-Output "Konfiguration klar. Kontrollera medlemskap och behorigheter:"
Get-LocalGroupMember -Group "g_ledare"
Get-LocalGroupMember -Group "g_personal"

foreach ($path in @(
    "C:\Projekt",
    "C:\Projekt\Gemensamt",
    "C:\Projekt\Ledning"
)) {
    Get-Acl -LiteralPath $path |
        Format-List Path, Owner, AccessToString
}