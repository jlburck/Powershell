########################################################################################################################
# 
# This script will send automated email notifications to Users who's password is about to expire.
#
# **Requires: Windows PowerShell Module for Active Directory (enable features in control panel)
#   Remote Server Administration Tools > Role Administration Tools > AD DS and AD LDS Tools >
#   Active Directory Module for Windows PowerShell
#
# **Requires: the following command given in CMD before executing script on any operating system 
#   other than Windows Server 2012: powershell Set-ExecutionPolicy RemoteSigned
#
########################################################################################################################
# Following variables manually configured by an administrator
#
$smtpServer="outlook.domain.com" # Email server belonging to the “from” address
#
$From = "Administrator <ServiceDesk@email.com>" # Who users get the notification email from
#
$Log = $true # true to keep a log of email notifications sent
#
$LogFile = "c:\pwexplog.csv" # Log file resides here
#
$Test = $true # true to send to tester any other setting will send to users
#
$Tester = "User@email.com" # Account that is emailed when test is enabled
#
$NoAddressRecipient = "lburckhard@resurgent.com" # Account that is emailed when users dont have an email assigned in AD
#
$Date = Get-Date -format ddMMyyyy # Set date and date format for csv log file
#
########################################################################################################################
# Programmatically configured variables
#
$TwoDayNotify = 2 # User gets a notification if their password expires two days
#
$FiveDayNotify = 5 # User gets a notification if their password expires five days
#
$TenDayNotify = 10 # User gets a notification if their password expires ten days
#
########################################################################################################################

# If log is enabled, check to see if log file exists and if not create it
if (($Log) -eq $true)
{
    # Check log file path
    $LogPath = (Test-Path $LogFile)
    # If file doesnt exist in path
    if (($LogPath) -ne $true)
    {
        # Create file
        New-Item $LogFile -ItemType File
        # Create headers (first row of CSV file)
        Add-Content $LogFile "Date,LastName,FirstName,EmailAddress,DaysUntilExpire,ExpiresOn"
    }
}

# Import Active Directory Module in order to pull information from AD
Set-Location C:\
Import-Module ActiveDirectory

# Collect user info - filter to only users in AD who are enabled, passwords expire and password is not already expired
$Users = get-aduser -filter * -properties Name, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress |where {$_.Enabled -eq $true -and $_.PasswordNeverExpires -eq $false -and $_.passwordexpired -eq $false}
# Save password default age policy
$DefaultPwAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

# Collect all users described in filter and find password expiry time remaining
foreach ($User in $Users)
{
    $Name = $User.Name
    $EmailAddress = $User.EmailAddress
    $PwSetDate = $User.PasswordLastSet
    $PasswordPol = (Get-AduserResultantPasswordPolicy $User)
    
    # Fine grained check for password age policy for each user
    if (($PasswordPol) -ne $null)
    {
        $MaxPasswordAge = ($PasswordPol).MaxPasswordAge
    }
    else {
        $MaxPasswordAge = $DefaultPWage
        }
    
    # Check number of days until password expires
    $ExpiresOn = $PwSetDate + $MaxPasswordAge
    $Today = (get-date)
    $DaysUntilExpire = (New-TimeSpan -Start $Today -End $ExpiresOn).Days

    # Create message for days until password expires
    $Message = $DaysUntilExpire

    if (($Message) -ge "1")
    {
        $Message = "$DaysUntilExpire" + " days."
    }
    else
    {
        $Message = " a day or less."
    }

    # Email Subject
    $Subject="Warning: your password will expire in $($Message)"
  
    # Email Body
    $Body ="Dear $($name),
    <p> Your password is due to expire in $($message)<br>
    Press CTRL ALT Delete now and click Change Password. <br>
    <p>Thanks, <br> 
    </P>"

   
    # If test is enabled - email tester
    if (($Test) -eq $true)
    {
        $EmailAddress = $Tester
    }

    # If a user has no email address listed, email administrator
    if (($EmailAddress) -eq $null)
    {
        $EmailAddress = $NoAddressRecipient    
    }

    # Send email message and update log file
    if (($DaysUntilExpire -ge "0") -and ($DaysUntilExpire -eq $TwoDayNotify) –or ($DaysUntilExpire –eq $FiveDayNotify) –or ($DaysUntilExpire –eq $TenDayNotify))
    {
         # If log is enabled add details to csv file
        if (($Log) -eq $true)
        {
            Add-Content $LogFile "$Date,$Name,$EmailAddress,$DaysUntilExpire,$ExpiresOn" 
        }
        # Send email  
        $BodyTwo = "<p>List of Users<br> $($EmailAddress), $($DaysUntilExpire)"
        Send-Mailmessage -smtpServer $smtpServer -from $From -to $Emailaddress -subject $Subject -body $Body -bodyasHTML -priority High  
        
    }
    
}
$SubjectTwo = 'User Password Report' 
Send-Mailmessage -smtpServer $smtpServer -from $From -to $Tester -subject $SubjectTwo -body $BodyTwo -bodyasHTML -priority High 