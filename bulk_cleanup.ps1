# Clean up all test configurations
$configs = @(
    "test-clients-0402af02",
    "test-clients-0abce11c", 
    "test-clients-b6fc4726",
    "test-creds-ae6a7746",
    "test-endpoints-729fbfb2",
    "test-endpoints-d0547c18",
    "debug-test"
)

foreach ($config in $configs) {
    Write-Host "Cleaning up configuration: $config"
    try {
        Get-EryphClientConfiguration -Configuration $config -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "  Removing client: $($_.Id)"
            Remove-EryphClientConfiguration -Id $_.Id -Configuration $config -Force -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Host "  Error cleaning $config`: $_"
    }
}