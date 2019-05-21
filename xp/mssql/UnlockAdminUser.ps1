# Unlocks the admin user
$databaseName = "sitecore_core"
$sqlcmd = "USE [$databaseName] UPDATE aspnet_Membership SET IsLockedOut = 0, FailedPasswordAttemptCount = 0 WHERE UserId IN (SELECT UserId FROM aspnet_Users WHERE UserName = 'sitecore\Admin')"
Invoke-Sqlcmd -Query $sqlcmd -Querytimeout 65535 -ConnectionTimeout 65535