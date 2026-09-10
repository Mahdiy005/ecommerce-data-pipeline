$ErrorActionPreference = "Stop"

$projectDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$environmentFile = Join-Path $projectDirectory ".env"
$environmentExample = Join-Path $projectDirectory ".env.example"

Set-Location -LiteralPath $projectDirectory

if (-not (Test-Path -LiteralPath $environmentFile)) {
    $environmentContents = Get-Content -LiteralPath $environmentExample -Raw

    function New-RandomBase64([int] $byteCount, [bool] $keepPadding) {
        $bytes = New-Object byte[] $byteCount
        $generator = [Security.Cryptography.RandomNumberGenerator]::Create()
        try {
            $generator.GetBytes($bytes)
        }
        finally {
            $generator.Dispose()
        }

        $value = [Convert]::ToBase64String($bytes).Replace("+", "-").Replace("/", "_")
        if (-not $keepPadding) {
            $value = $value.TrimEnd("=")
        }
        return $value
    }

    $environmentContents = $environmentContents.Replace(
        "generate-on-first-start-postgres",
        (New-RandomBase64 24 $false)
    ).Replace(
        "generate-on-first-start-fernet",
        (New-RandomBase64 32 $true)
    ).Replace(
        "generate-on-first-start-jwt",
        (New-RandomBase64 48 $false)
    )

    Set-Content -LiteralPath $environmentFile -Value $environmentContents
    Write-Host "Created .env and generated the Airflow/PostgreSQL secrets."
    Write-Host "Edit .env, enter your Snowflake credentials and choose the Airflow admin password, then run this script again."
    exit 1
}

$environmentContents = Get-Content -LiteralPath $environmentFile -Raw
if ($environmentContents -match "change-me") {
    Write-Host "Replace every change-me value in .env before starting Airflow."
    exit 1
}

docker compose config --quiet
docker compose up --build --detach
docker compose ps

$portMatch = [regex]::Match($environmentContents, "(?m)^AIRFLOW_PORT=(\d+)$")
$airflowPort = if ($portMatch.Success) { $portMatch.Groups[1].Value } else { "8080" }
Write-Host "Airflow is starting at http://localhost:$airflowPort"
