Param(
    #
    [ValidateNotNullOrEmpty()]
    $GitRepoName, 

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

try
{
    curl -u "$BitbucketUserName:$BitbucketAppPassword" "https://api.bitbucket.org/2.0/repositories/$GitRepoName"
}
finally
{

}





