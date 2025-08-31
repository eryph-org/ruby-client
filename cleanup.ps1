Remove-EryphClientConfiguration -Id 'client-one-123' -Configuration 'debug-test' -Force -Confirm:$false
Remove-EryphClientConfiguration -Id 'client-two-123' -Configuration 'debug-test' -Force -Confirm:$false  
Remove-EryphClientConfiguration -Id 'client-three-123' -Configuration 'debug-test' -Force -Confirm:$false
Remove-Item 'C:/Users/fwagner/AppData/Local/Temp/debug.key' -ErrorAction SilentlyContinue