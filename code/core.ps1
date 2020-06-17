using namespace RestSharp;

## Base Variables

## The final dataset table of finacials, sorted by stock (i.e. $Stock_Table.AMZN)
[Hashtable]$Global:Stock_Table = [Hashtable]::New();

## Counter for progress bar
[int]$Done = 0;

## Last known time stamp.
[DateTime]$Last_Checked = [DateTime]((Get-Content ".\debug\time_stamp.json" | ConvertFrom-Json).Date);

## Directory list of the stats folder. Is a [IO.FileInfo]
$file_list = Get-ChildItem ".\stats";

## The list of stocks to gather.
[String[]]$Get_Stocks = @(); 

## Boolean notifying errors
[bool]$global:IsError = $False;

## Gather Config
try {
    $Config = Get-Content ".\config.json" | ConvertFrom-Json
}
catch {
    Write-Host "Config.json is missing or corrupted!" -BackgroundColor Black -ForegroundColor Red
}

## Load Stock List
. .\code\stocks.ps1

## Only runs if greater than 24 hours since last run
$Checked = ([Datetime]::Now.ToUniversalTime() - $Last_Checked).TotalSeconds

## Check if stats folder isn't empty
## If so, set the flag to gather from site.
if ($file_list.Length -eq 0) {
    $global:New = $true;
}

## Run again the file list is different than stock list
[string[]]$stock_file_list = @()
foreach ($file in $file_list) { 
    $stock_file_list += $file.Name.Replace(".json", "");
}

## Iterates through stock list, add any stock list to the online search that there is no .json file of.
foreach ($stock in $Stock_list) {
    if ($stock -notin $stock_file_list) {
        $global:New = $true;
        $Get_Stocks += $stock
    }
}

## If we last check a day ago, or there is no saved data.
if ($Checked -ge 86400 -or $global:New -eq $true) {
    Write-Host "Online Update Needed: Gather Financials From Yahoo..." -BackgroundColor Black -ForegroundColor Yellow;
    Start-Sleep -Seconds 5
    foreach ($stock in $Get_Stocks) {
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
        $parsed = $null;
        try {
            $parsed = $response.Content | ConvertFrom-Json;
        }
        catch {
            $global:IsError = $true;
            Write-Host "Could Not Read The Response" -ForegroundColor Red -BackgroundColor Black;
        }

        ## Check the status code- Print Errors and end loop.
        if ($response.StatusCode -ne 200 -or $null -eq $parsed) {
            if ($response.StatusCode -eq 429) {
                Write-Host "IP being blocked: Subscription at limit" -ForegroundColor Red -BackgroundColor Black;
                $global:IsError = $true;
                break;
            }
            else {
                Write-Host "Status Code was not 200...It was $($response.StatusCode)" -ForegroundColor Black -BackgroundColor Red
                $global:IsError = $true;
                break
            }
        }
        ## Else all was good- We can add to file and the hashmap.
        else {
            ## Converting to Json again removes compression rather than using original raw data.
            $parsed | ConvertTo-Json -Depth 5 | Set-Content ".\stats\$($parsed.symbol).json";
            if (!$Global:Stock_Table.$($parsed.symbol)) {
                $Global:Stock_Table.Add($parsed.symbol, $parsed);
            }    
        }

        ## Update Progress Bar
        $done++;
        $percent = [Math]::Round(($done / $Stock_list.count) * 100);
        Write-Progress -Activity Loading -Status 'Loading Stocks->' -PercentComplete $percent -CurrentOperation $stock;        
        [GC]::Collect()
    }
}
## else load what we have
else {
    Write-Host "Loading Database..." -BackgroundColor Black -ForegroundColor Yellow;
    Start-Sleep -Seconds 5;

    ## Pull each file, and load to table
    foreach ($file in $file_list) {
        $Data = Get-Content $file.Fullname | ConvertFrom-Json;
        $Global:Stock_Table.Add($Data.symbol, $Data);

        ## Update Progress Bar
        $done++;
        $percent = [Math]::Round(($done / $Stock_list.count) * 100);
        Write-Progress -Activity Loading -Status 'Loading Stocks->' -PercentComplete $percent -CurrentOperation ($file.name.Replace(".json", ""));        
    }
}


## If There was an error, we attempt to pull from file anyway: 
## TODO Make as function/class (so code isn't written twice)
## It's easier to just copy/past what I already wrote for now.
if ($global:IsError -eq $true -and $file_list.Length -gt 0) {
    Write-Host "Loading Database..." -BackgroundColor Black -ForegroundColor Yellow;
    Start-Sleep -Seconds 5;

    foreach ($file in $file_list) {
        $Data = Get-Content $file.Fullname | ConvertFrom-Json;
        $Global:Stock_Table.Add($Data.symbol, $Data);

        ## Update Progress Bar
        $done++;
        $percent = [Math]::Round(($done / $Stock_list.count) * 100);
        Write-Progress -Activity Loading -Status 'Loading Stocks->' -PercentComplete $percent -CurrentOperation ($file.name.Replace(".json", ""));        
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
Write-Host "Stock List has been saved as well: Type " -BackgroundColor Black -ForegroundColor Yellow -NoNewline
Write-Host "`$Stock_List" -BackgroundColor Black -ForegroundColor Green -NoNewline
Write-Host " to view list." -ForegroundColor Yellow -BackgroundColor Black
