[Console]::Clear()

## Test for Restsharp.dll. If not loaded- Load it.
try { 
    if ([unirest_net.http.Unirest]) {
        Write-Host "RestSharp is already loaded" -BackgroundColor Black -ForegroundColor Green
    }
} 
catch { 
    Write-Host "Loading RestSharp..." -BackgroundColor Black -ForegroundColor Green
    Add-Type -Path ".\lib\RestSharp.dll" 
    Write-Host "RestSharp Loaded!" -BackgroundColor Black -ForegroundColor Green
}

## Check for folders- Create if neccessary
$dir = split-path $MyInvocation.MyCommand.Path
$debug = [IO.Path]::Combine($dir, "debug")
$stats = [IO.Path]::Combine($dir, "stats")
$last_check = [IO.Path]::Combine($debug, "time_stamp.json")
$global:New = $false;

if (![IO.Directory]::Exists($debug)) {
    [IO.Directory]::CreateDirectory($debug) | Out-Null;
}

if (![IO.Directory]::Exists($stats)) {
    [IO.Directory]::CreateDirectory($stats) | Out-Null;
}

## Make a timestamp if not created.
if (![IO.File]::Exists($last_check)) {
    @{"Date" = [datetime]::Now.ToUniversalTime() } | ConvertTo-Json | Set-Content $last_check | Out-Null
    $global:New = $true;
}

## Start base script
. .\code\core.ps1