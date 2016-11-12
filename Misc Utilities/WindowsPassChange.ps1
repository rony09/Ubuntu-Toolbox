Write-Host "Password change/ guest disable script: Dirty programming"
Write-Host "Run this in a admin powershell!!!"
Write-Host "USE AT YOUR OWN RISK! I am not responsible to any system harm caused by this script!"
$passin = Read-Host -Prompt "Enter password that all users will be changed to(WARNING: WRITE THIS DOWN!!!)"
Write-Host ""
$userlist = get-wmiobject win32_useraccount
Foreach ($userob in $userlist) {
    if (-not (($userob.name -Match $env:USERNAME) -or ($userob.name -Match "Guest") -or ($userob.name -Match "DefaultAccount"))) {
        $usernm=$userob.name
        Write-Host "Changing password for $usernm"
        ([adsi]("WinNT://"+$userob.caption).replace("\", "/")).SetPassword($passin)
    } 
    if (($userob.name -Match "Guest") -or ($userob.name -Match "Administrator")) {
        $usernm=$userob.name
        Write-Host "Disabling account: $usernm"
        ([adsi]("WinNT://"+$userob.caption).replace("\", "/")).psbase.invokeset("AccountDisabled", "True")
        ([adsi]("WinNT://"+$userob.caption).replace("\", "/")).setinfo()
    }
}
Write-Host "Password change completed!\n"