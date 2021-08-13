 $retCode = Start-Process -FilePath "./SQL2019-SSEI-Dev.exe"  -ArgumentList "/Q /IACCEPTSQLSERVERLICENSETERMS /ACTION='install'" -Wait -PassThru

if ($retCode.ExitCode -ne 0)
{

    throw "Product installation of failed with exit code: $($retCode.ExitCode.ToString())"    
}
