Function Get-IniContent {  
    <#  
    .Synopsis  
        Gets the content of an INI file  
          
    .Description  
        Gets the content of an INI file and returns it as a hashtable  
          
    .Notes  
        Author        : Oliver Lipkau <oliver@lipkau.net>  
        Blog        : http://oliver.lipkau.net/blog/  
        Source        : https://github.com/lipkau/PsIni 
                      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91 
        Version        : 1.0 - 2010/03/12 - Initial release  
                      1.1 - 2014/12/11 - Typo (Thx SLDR) 
                                         Typo (Thx Dave Stiff) 
          
        #Requires -Version 2.0  
          
    .Inputs  
        System.String  
          
    .Outputs  
        System.Collections.Hashtable  
          
    .Parameter FilePath  
        Specifies the path to the input file.  
          
    .Example  
        $FileContent = Get-IniContent "C:\myinifile.ini"  
        -----------  
        Description  
        Saves the content of the c:\myinifile.ini in a hashtable called $FileContent  
      
    .Example  
        $inifilepath | $FileContent = Get-IniContent  
        -----------  
        Description  
        Gets the content of the ini file passed through the pipe into a hashtable called $FileContent  
      
    .Example  
        C:\PS>$FileContent = Get-IniContent "c:\settings.ini"  
        C:\PS>$FileContent["Section"]["Key"]  
        -----------  
        Description  
        Returns the key "Key" of the section "Section" from the C:\settings.ini file  
          
    .Link  
        Out-IniFile  
    #>  
      
    [CmdletBinding()]  
    Param(  
        [ValidateNotNullOrEmpty()]
        [ValidateScript({Test-Path $_})]
  #        [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]  
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]  
        [string]$FilePath  
    )  
      
    Begin  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}  
          
    Process  
    {  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"  
              
        $ini = @{}  
        switch -regex -file $FilePath  
        {  
            "^\[(.+)\]$" # Section  
            {  
                $section = $matches[1]  
                $ini[$section] = @{}  
                $CommentCount = 0  
            }  
            "^(;.*)$" # Comment  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $value = $matches[1]  
                $CommentCount = $CommentCount + 1  
                $name = "Comment" + $CommentCount  
                $ini[$section][$name] = $value  
            }   
            "(.+?)\s*=\s*(.*)" # Key  
            {  
                if (!($section))  
                {  
                    $section = "No-Section"  
                    $ini[$section] = @{}  
                }  
                $name,$value = $matches[1..2]  
                $ini[$section][$name] = $value  
            }  
        }  
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"  
        Return $ini  
    }  
          
    End  
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}  
} 
  
if ($args.Count -lt 4) {
  Write-Output "You have only given $($args.Count) arguments. You need to give 4: (1) Path of AWS credential file; 
  (2) Section of the config; 
  (3) location of notebook files; (4) Docker container image. 
  Example: .\start_pyspark_role.ps1 C:\Users\<User>\.aws\ MyProfile C:\Users\<User>\notebook <docker repository>/<docker image>
  *** Please use trailing slashes ***"
  exit 1
}
  
$cred_filepath=$args[0]
$user_profile=$args[1]
$nb_fileloc=$args[2]
$container=$args[3]
  
$key_id="aws_access_key_id"
$secret_key="aws_secret_access_key"
$profile_name="profile " + $user_profile
$profile_key="role_arn"

$cred_fileloc = $cred_filepath + "config"
$INI_CONTENT = Get-IniContent $cred_fileloc
echo $INI_CONTENT
echo $INI_CONTENT[$profile_name][$profile_key]

$role_arn = $INI_CONTENT[$profile_name][$profile_key]

# Get temporary Credentials
$uuid = New-Guid
$temp_cred = (Use-STSRole -RoleArn $role_arn -RoleSessionName $uuid)

$AWS_ACCESS_KEY_ID = $temp_cred.Credentials.AccessKeyId
$AWS_SECRET_ACCESS_KEY = $temp_cred.Credentials.SecretAccessKey
$AWS_SESSION_TOKEN = $temp_cred.Credentials.SessionToken

$docker_cmd="/bin/bash pyspark"

$docker_run="docker run -d --env AWS_ACCESS_KEY_ID='" + $AWS_ACCESS_KEY_ID + "' --env AWS_SECRET_ACCESS_KEY='" + $AWS_SECRET_ACCESS_KEY + "' --env AWS_SESSION_TOKEN='" + $AWS_SESSION_TOKEN + "' -v " + $cred_filepath + ":/home/glue/.aws -v " + $nb_fileloc + ":/home/glue/notebook -p 8000:8000 --rm " + $container + " '" + $docker_cmd + "'"

#echo $docker_run
Invoke-Expression $docker_run
