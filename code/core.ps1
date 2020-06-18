
## Load Database Codebase
. .\code\database.ps1

## Boolean notifying errors
[bool]$global:IsError = $False;

## Build the Database
[Database]$global:Database = [Database]::New();
$Database.build();
$Database.Print_Instructions();

## This is the first technical test.
## We are going to attempt to break down AAPL
$AAPL = $Database.Stock_Table.AAPL
