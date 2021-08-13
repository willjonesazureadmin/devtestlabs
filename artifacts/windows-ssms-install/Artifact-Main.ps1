$filePath = ".\ssms.exe"

Invoke-WebRequest https://aka.ms/ssmsfullsetup -OutFile $filePath

# Set parameters
$params = " /Install /Passive"
        
# Run the install
Start-Process -FilePath $filePath -ArgumentList $params -Wait
