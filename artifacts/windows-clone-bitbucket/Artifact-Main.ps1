Param(
    #
    [ValidateNotNullOrEmpty()]
    $GitRepo, 

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
    curl -u "$BitbucketUserName:$BitbucketAppPassword" "https://api.bitbucket.org/2.0/repositories/$GitRepo"
}
finally
{

}





