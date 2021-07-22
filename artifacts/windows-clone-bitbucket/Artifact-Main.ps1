Param(
    #
    [ValidateNotNullOrEmpty()]
    $GitRepoUrl, 

    #
    [ValidateNotNullOrEmpty()] 
    $GitLocalRepoLocation = $($env:SystemDrive + "\Repos"),

    #
    [ValidateNotNullOrEmpty()] 
    $GitBranch = "master",

    #
    [ValidateNotNullOrEmpty()] 
    $BitbucketUserName,

    #
    [ValidateNotNullOrEmpty()] 
    $BitbucketAppPassword
)


   $cmd = "git clone -q https://$($BitbucketUsername):$($BitbucketAppPassword)@$($GitRepoUrl)"
   Invoke-Expression $cmd -ErrorAction SilentlyContinue




