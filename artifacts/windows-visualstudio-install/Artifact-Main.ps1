$retCode = Start-Process -FilePath "vs_enterprise__1608404543.1622558692.exe"  -ArgumentList "--installPath C:\minVS --add Microsoft.VisualStudio.Workload.CoreEditor --passive --norestart" -Wait -PassThru

if ($retCode.ExitCode -ne 0)
{

    throw "Product installation of failed with exit code: $($retCode.ExitCode.ToString())"    
}
