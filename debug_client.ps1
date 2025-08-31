$tempKey = "C:/Users/fwagner/AppData/Local/Temp/debug-test.key"

$creds1 = New-EryphClientCredentials -Id 'client-one' -IdentityEndpoint 'https://test.example.com/identity' -Configuration 'debug-test' -InputObject (Get-Content $tempKey -Raw)
Add-EryphClientConfiguration -Id 'client-one' -Name 'First Client' -Credentials $creds1 -Configuration 'debug-test'

$creds3 = New-EryphClientCredentials -Id 'client-three' -IdentityEndpoint 'https://test.example.com/identity' -Configuration 'debug-test' -InputObject (Get-Content $tempKey -Raw)
Add-EryphClientConfiguration -Id 'client-three' -Name 'Third Client' -Credentials $creds3 -Configuration 'debug-test' -AsDefault

Write-Host "ALL CLIENTS:"
Get-EryphClientConfiguration -Configuration 'debug-test' | ConvertTo-Json -Depth 3

Write-Host "DEFAULT CLIENT:"
Get-EryphClientConfiguration -Configuration 'debug-test' -Default | ConvertTo-Json -Depth 3

Remove-EryphClientConfiguration -Id 'client-one' -Configuration 'debug-test' -Force -Confirm:$false
Remove-EryphClientConfiguration -Id 'client-three' -Configuration 'debug-test' -Force -Confirm:$false
Remove-Item $tempKey