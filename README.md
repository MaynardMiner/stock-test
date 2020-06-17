# STOCK-TEST
This is a beginning script that creates a table for Proof Of Concept.


This is written with powershell, so that the object $Stock_Table can be edited from commandline for testing.
The final version will be a C# (.NET) application, hopefully with a GUI to assist.

## DATA
The stocks currently used are listed in ``".\code\stocks.ps1"``. I am currently using all stocks within Nasdaq 100 as initial dataset for POC.

## TODO
Create mutliple threads to gather each stock, so that it can be done much faster. However, you only need to do it once, and then will run
again if program if the last time it has gathered data > 24 hours. All stock data is saved under each ticker in the "stats" folder (is created).
Everytime you restart the program- It will load the saved data rather than contact the sites.

## Setup
Edit config.json with your subscription key:


https://rapidapi.com/apidojo/api/yahoo-finance1


Then create a subscription. This will generate an api key. Add that key from the code snippet to config.json. It is best that each user has there own key,
as there is a limitation on the number of times we can contact site for data (free is 500).


Install Powershell Core:

https://github.com/PowerShell/PowerShell/releases/tag/v7.0.2


Install (ideally) Visual Studio Code:

https://code.visualstudio.com/?wt.mc_id=DX_841432


Install Powershell Extension:

https://code.visualstudio.com/docs/languages/powershell


### Steps in Visual Studio Code:
* Download and/or clone project
* Open project folder in visual studio code
* Select start.ps1
* Press f5 OR Select ```Debug``` > ```Run```


### Steps In Command Line:
* Download and/or clone project
* In search box: Type "pwsh": Press Enter. This open a powershell window.
* Navigate to folder.
* Type ```.\start.ps1```
