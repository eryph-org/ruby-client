$tempKey = 'C:/Users/fwagner/AppData/Local/Temp/debug.key'

$creds1 = New-EryphClientCredentials -Id 'client-one-123' -IdentityEndpoint 'https://test.example.com/identity' -Configuration 'debug-test' -InputObject (Get-Content $tempKey -Raw)
Add-EryphClientConfiguration -Id 'client-one-123' -Name 'First Client' -Credentials $creds1 -Configuration 'debug-test'

$creds2 = New-EryphClientCredentials -Id 'client-two-123' -IdentityEndpoint 'https://test.example.com/identity' -Configuration 'debug-test' -InputObject (Get-Content $tempKey -Raw)
Add-EryphClientConfiguration -Id 'client-two-123' -Name 'Second Client' -Credentials $creds2 -Configuration 'debug-test'

$creds3 = New-EryphClientCredentials -Id 'client-three-123' -IdentityEndpoint 'https://test.example.com/identity' -Configuration 'debug-test' -InputObject (Get-Content $tempKey -Raw)
Add-EryphClientConfiguration -Id 'client-three-123' -Name 'Third Client' -Credentials $creds3 -Configuration 'debug-test' -AsDefault

Write-Host "SETUP COMPLETE"