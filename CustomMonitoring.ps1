#Reference URL https://blog.nowmicro.com/2018/01/22/email-notification-for-security-changes-in-configmgr/
#Status Filter Rules Command Line Variables - https://systemscenter.ru/smsv4.en/html/4c6518c7-92b9-42a2-b94e-cc483fcac3f9.htm
Param($msgdesc,$msgsc,$msgsys,$msgsrc,$msgpid,$msgid,$msgis01)  
############# Variables to modify #############
$getdate = get-date -format g #Grab local date and convert it to DD/MM/YY 00:00:00
$smtpFrom = "" #Specify an account to send the email from
$smtpTo1 = "" #Specify User or group to email to
$smtpServer = "" #Specify your SMTP Server or relay
$messageSubject1 = "MEMCM Configuration Change Alert - $getdate" #Specify subject line for alert 1

###############################################

#Create a dynamic variable that can change what our script outputs in the email depending on the Status Message ID
#Remove the message ID's from line 24 that you do not want to track.
#'30015','30017' - Collection created and deleted
#'40060','40061','40062' - Boundary created, modified, and deleted
#'30000','30001','30002' - Package created, modified, and deleted
#'30006','30007','30008' - Deployments Created, Modified, or Deleted
#'30033','30034','30035','30039','30040','30041' - Server Component Configuration Changes
#'30226','30227','30228' - Application Created, Modified or Deleted
#'40300','40301','40302','40303','40304','40305' - Client Settings Creation/Deployment
#'30152' - Configuration Item Created/Modified
#'31200','31201','31202' - Security Roles
IF ($msgid -in ('30015','30017','40060','40061','40062','30000','30001','30002','30006','30007','30008','30033','30034','30035','30039','30040','30041','30226','30227','30228','40300','40301','40302','40303','40304','40305','30152','31200','31201','31202')) #In statement allows us to specify 1 or more status message id's for the script to send alerts on.  
{
    #Specify the email subject
    $messageSubject = $messageSubject1

    #Who to email this alert to
    $smtpTo = $smtpTo1
}
else {  
    exit
}

#Send email with above parameters
send-mailmessage -from $smtpFrom -to $smtpTo -subject $messageSubject -body "Site: $msgsc <br>Change made by: $msgis01<br>Change made from: $msgsys <br> Message ID: $msgid <br>Summary of change:<br>$MSGDesc" -BodyAsHtml -smtpServer $smtpserver -Priority High -DeliveryNotificationOption OnSuccess, OnFailure


#Teams Card Logic. Remove, if not required.
# Reference URL https://petri.com/how-to-send-a-microsoft-teams-message-using-powershell-7

$JSONBody = [PSCustomObject][Ordered]@{
  "@type"      = "MessageCard"
  "@context"   = "http://schema.org/extensions"
  "summary"    = "Incoming Alert Message!"
  "themeColor" = '0078D7'
  "sections"   = @(
	    @{
				"activityTitle"    = "$messageSubject"
        "activitySubtitle" = "$MSGDesc"
				#"activityImage"    = "https://myalertsystem.com/warning.png"
        "facts"            = @(
					@{
						"name"  = "Change made by"
						"value" = "$msgis01"
					},
					@{
						"name"  = "Change made from"
						"value" = "$msgsys"
					}
				)
				"markdown" = $true
			}
  )
}


$TeamMessageBody = ConvertTo-Json $JSONBody -Depth 100

$parameters = @{ # Teams webhook URI
    "URI"         = '' #Fill in your own Webhook URI
    "Method"      = 'POST'
    "Body"        = $TeamMessageBody
    "ContentType" = 'application/json'
}

Invoke-RestMethod @parameters | Out-Null