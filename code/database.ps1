using namespace RestSharp;

Class Database {
    ## Base Variables

    ## Counter for progress bar
    hidden [int]$Done = 0;

    ## The final dataset table of financials, sorted by stock (i.e. $Stock_Table.AMZN)
    [Hashtable]$Stock_Table

    ## List of Stock Symbols We are Using
    [String[]]$Stock_List

    ## Method to build the database
    [void] build() {

        ## Set Intitial Values:
        $this.Stock_Table = [hashtable]::Synchronized(@{});

        ## Last known time stamp.
        [DateTime]$Last_Checked = [DateTime]((Get-Content ".\debug\time_stamp.json" | ConvertFrom-Json).Date);

        ## Directory list of the stats folder. Is a [IO.FileInfo]
        $file_list = Get-ChildItem ".\stats";

        ## The list of stocks to gather.
        [String[]]$Get_Stocks = @();    

        ## Array list of stock symbols currently saved on drive.
        [string[]]$stock_file_list = @();

        ## Object Holder For Config
        [Object]$Config = $Null;

        ## Array list of stock symbols currently saved on drive.
        try {
            $Config = Get-Content ".\config.json" | ConvertFrom-Json
        }
        catch {
            Write-Host "Config.json is missing or corrupted!" -BackgroundColor Black -ForegroundColor Red
        }

        ##Load Stocks
        $this.load_stocks();

        ## Only runs if greater than 24 hours since last run
        $Checked = ([Datetime]::Now.ToUniversalTime() - $Last_Checked).TotalSeconds
        
        ## Check if stats folder isn't empty
        ## If so, set the flag to gather from site.
        if ($file_list.Length -eq 0) {
            $global:New = $true;
        }

        ## Make an array of symbols (only) that are inside the database/drive
        foreach ($file in $file_list) { 
            $stock_file_list += $file.Name.Replace(".json", "");
        }

        ## Iterates through stock list, add any stock list to the online search that there is no .json file of.
        foreach ($stock in $this.Stock_list) {
            if ($stock -notin $stock_file_list) {
                $global:New = $true;
                $Get_Stocks += $stock
            }
        }

        ## If we last check a day ago, or there is no saved data on stock(s).
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
                ## Add object data to current hashmap (hashtable)
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
                    if (!$this.Stock_Table.$($parsed.symbol)) {
                        $this.Stock_Table.Add($parsed.symbol, $parsed);
                    }    
                }

                ## Update Progress Bar
                $this.done++;
                $percent = [Math]::Round(($this.done / $this.Stock_list.count) * 100);
                Write-Progress -Activity Loading -Status 'Loading Stocks->' -PercentComplete $percent -CurrentOperation $stock;        
                [GC]::Collect()
            }
        }
        ## else load what we have
        else {
            $this.gather_local($file_list);
        }


        ## If There was an error, we attempt to pull from file anyway: 
        ## TODO Make as function/class (so code isn't written twice)
        ## It's easier to just copy/past what I already wrote for now.
        if ($global:IsError -eq $true -and $file_list.Length -gt 0) {
            Write-Host "Loading Database..." -BackgroundColor Black -ForegroundColor Yellow;
            Start-Sleep -Seconds 5;
            $this.gather_local($file_list);
        }

        ## If it has been 24 hours from the timestamp: Reset the time stamp;
        if ($Checked -ge 86400) {
            @{"Date" = [datetime]::Now.ToUniversalTime() } | ConvertTo-Json | Set-Content $global:last_check | Out-Null
        }

        Write-Progress -Activity Loading -Status 'Loading Stocks->' -Completed;        
        Start-Sleep -S 1
        [GC]::Collect()
        [Console]::Clear()
    }

    ## Method to load stock list
    hidden [void] load_stocks() {
        $this.Stock_List = . .\code\stocks.ps1;
        $this.Stock_List | Sort-Object;
    }    

    ## Method to pull each file, and load to table
    hidden [void] gather_local([object]$list) {
        Write-Host "Loading Database..." -BackgroundColor Black -ForegroundColor Yellow;
        Start-Sleep -Seconds 5;
        ## Pull each file, and load to table
        foreach ($file in $list) {
            $Data = Get-Content $file.Fullname | ConvertFrom-Json;
            $this.Stock_Table.Add($Data.symbol, $Data);

            ## Update Progress Bar
            $this.Done++;
            $percent = [Math]::Round(($this.Done / $this.Stock_list.count) * 100);
            Write-Progress -Activity Loading -Status 'Loading Stocks->' -PercentComplete $percent -CurrentOperation ($file.name.Replace(".json", ""));        
        }
    }

    [void] Print_Instructions() {
        Write-Host "Done Loading!" -BackgroundColor Black -ForegroundColor Green
        Write-Host "EXAMPLES:" -BackgroundColor Black -ForegroundColor Yellow
        Write-Host "Type " -NoNewline -BackgroundColor Black -ForegroundColor Yellow
        Write-Host "`$Database.Stock_Table.AMZN " -NoNewLine -BackgroundColor Black -ForegroundColor Green  
        Write-Host "to begin viewing Amazon's Financials." -BackgroundColor Black -ForegroundColor Yellow
        Write-Host "Or maybe " -NoNewline -BackgroundColor Black -ForegroundColor Yellow
        Write-Host "`$Database.Stock_Table.AMZN.Price " -BackgroundColor Black -ForegroundColor Green -NoNewline
        Write-Host "To See Amazon's Pricing Data." -BackgroundColor Black -ForegroundColor Yellow
        Write-Host "Stock List has been saved as well: Type " -BackgroundColor Black -ForegroundColor Yellow -NoNewline
        Write-Host "`$Database.Stock_List" -BackgroundColor Black -ForegroundColor Green -NoNewline
        Write-Host " to view list." -ForegroundColor Yellow -BackgroundColor Black
    }

}