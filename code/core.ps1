using namespace RestSharp;

## Base Variables
$Global:Stock_Table = @{} ## The final dataset table of finacials, sorted by stock (i.e. $Stock_Table.AMZN)
$Done = 0; ## Counter for progress bar
$Last_Checked = [DateTime]((Get-Content ".\debug\time_stamp.json" | ConvertFrom-Json).Date) ## Last known time stamp.

## Gather Config
try{
    $Config = Get-Content ".\config.json" | ConvertFrom-Json
} catch {
    Write-Host "Config.json is missing or corrupted!" -BackgroundColor Black -ForegroundColor Red
}

## Load Stock List
. .\code\stocks.ps1

## Only runs if greater than 24 hours since last run
$Checked = ([Datetime]::Now.ToUniversalTime() - $Last_Checked).TotalSeconds

## Check if stats folder isn't empty
## If so, set the flag to gather from site.
if ((Get-ChildItem ".\stats").Length -eq 0) {
    $global:New = $true;
}

## If we last check a day ago, or there is no saved data.
if ($Checked -ge 86400 -or $global:New -eq $true) {
    Write-Host "Has been 24 hours since last check on financials: Gather Financials From Yahoo..." -BackgroundColor Black -ForegroundColor Yellow;
    Start-Sleep -Seconds 5
    foreach ($stock in $Global:stock_list) {
        ## Create net client
        $client = [RestClient]::New("$($Config.endpoint)$stock");

        ## Create net request
        $request = [RestRequest]::new([Method]::GET);
        $request.AddHeader("x-rapidapi-host", $Config.'rapidapi-host') | Out-Null;
        $request.AddHeader("x-rapidapi-key", $Config.'rapidapi-key') | Out-Null;

        ## Execute Request
        [IRestResponse]$response = $client.Execute($request);

        ## Convert Json data to an object- Parse back to .json and send to file (fixes compressed formatting)
        ## Add object data to current hashtable
        $parsed = $response.Content | ConvertFrom-Json;
        $parsed | ConvertTo-Json -Depth 5 | Set-Content ".\stats\$($parsed.symbol).json";

        if(!$Global:Stock_Table.$($parsed.symbol)){
            $Global:Stock_Table.Add($parsed.symbol,$parsed);
        }

        ## Update Progress Bar
        $done++;
        $percent = [Math]::Round(($done / $Stock_list.count) * 100);
        Write-Progress -Activity Loading -Status 'Loading Stocks->' -PercentComplete $percent -CurrentOperation $stock;        
        [GC]::Collect()
    }
}
else {
    Write-Host "Loading Database..." -BackgroundColor Black -ForegroundColor Yellow;
    Start-Sleep -Seconds 5;
    $Files = Get-ChildItem -Path ".\stats";

    ## Pull each file, and load to table
    foreach ($file in $Files) {
        $Data = Get-Content $file.Fullname | ConvertFrom-Json;
        $Global:Stock_Table.Add($Data.symbol,$Data);

        ## Update Progress Bar
        $done++;
        $percent = [Math]::Round(($done / $Stock_list.count) * 100);
        Write-Progress -Activity Loading -Status 'Loading Stocks->' -PercentComplete $percent -CurrentOperation ($file.name.Replace(".json",""));        
    }
}
Write-Progress -Activity Loading -Status 'Loading Stocks->' -Completed;        
Start-Sleep -S 1
[GC]::Collect()
[Console]::Clear()
Write-Host "Done Loading!" -BackgroundColor Black -ForegroundColor Green
Write-Host "EXAMPLES:" -BackgroundColor Black -ForegroundColor Yellow
Write-Host "Type " -NoNewline -BackgroundColor Black -ForegroundColor Yellow
Write-Host "`$Stock_Table.AMZN " -NoNewLine -BackgroundColor Black -ForegroundColor Green  
Write-Host "to begin viewing Amazon's Financials." -BackgroundColor Black -ForegroundColor Yellow
Write-Host "Or maybe " -NoNewline -BackgroundColor Black -ForegroundColor Yellow
Write-Host "`$Stock_Table.AMZN.Price " -BackgroundColor Black -ForegroundColor Green -NoNewline
Write-Host "To See Amazon's Pricing Data." -BackgroundColor Black -ForegroundColor Yellow