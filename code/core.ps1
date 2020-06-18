## Load Database Codebase
. .\code\database.ps1

## Boolean notifying errors
[bool]$global:IsError = $False;

## Counter for progress bar
[int]$global:Done = 0;

## Build the Database
[Database]$global:Database = [Database]::New();
$Database.build();
$Database.Print_Instructions();

## This is the first technical test.
## We are going to attempt to break down AAPL
## Run test1.ps1 script
. .\code\test1.ps1;


