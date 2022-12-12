## Winodws 작업 스케줄러를 이용하여 S3에 Windows Event Log 저장
## Ref: https://www.megazone.com/techblog_20200312_desktop-and-application-streaming-storing-appstream-2-0-windows-event-logs-with-iam-roles-and-windows-task-scheduler/

$S3Bucket = “script-test-y2j” #Replace with the S3 bucket created for storing logs.

$bucketRegion = “ap-northeast-2” #Replace with the S3 bucket region.

$eventLogs = @(“security”,”system”) # $eventLogs = @(“security”,”system”) #Define which Windows Event logs are shipped in a comma-separated list

$EventTypes = @("Information",“error”,”warning”) #Define which event types are shipped in a comma-separated list

$SourceTypes = @("EventLog")

$LogPath = "C:\Users\CG-USER\Desktop\Logs\"

$Period = 7

#Check if user is connected, else sleep

if ((Get-WmiObject win32_computersystem).username) {

        #Get logged in username

        $ActiveUser = (Get-WmiObject win32_computersystem).username.split(“\\”)[1]

        #Set up filter string for getting logged-in user SID

        #$filterstring = “name : ‘” + $ActiveUser + “‘”


        #############################################

        #Process logs

        foreach ($logName in $eventLogs) {

                ## Check Registry Authority Set

                ## 0. 매일 00시에 전날 Log File 생성
                $Yesterday = (Get-Date).AddDays(-1)
                $FileName = $ActiveUser +"_" + $logName + "_" + $Yesterday.ToString('yyyy_MM_dd') + ".log"
                $FilePath = $LogPath + $logName + "\"

                $Begin = [Datetime]::ParseExact($Yesterday.ToString('yyyy-MM-dd 00:00:00'), 'yyyy-MM-dd HH:mm:ss', $null)
                $End = [Datetime]::ParseExact($Yesterday.ToString('yyyy-MM-dd 23:59:59'), 'yyyy-MM-dd HH:mm:ss', $null)


                # $events = Get-Eventlog -LogName $logName -EntryType $EventTypes -Source $SourceTypes -After $Begin -Before $End | Sort-Object -Property Index
                $events = Get-Eventlog -LogName $logName -After $Begin -Before $End | Sort-Object -Property Index
                New-Item -Path $FilePath -name $FileName
                $events > ($FilePath + $FileName)

                ## 1. 매일 00시에 8일차부터 가장 오래된 Log FIle을 S3에 Upload 후에 삭제

                $LogItems = Get-ChildItem -Path $FilePath -File

                ## Log File이 7개 초과한 경우 (7일차 경과한 경우)
                if ($LogItems.Count -gt $Period) {
                        ## 7일이 경과된 FIle 찾기
                        $UploadFile = ($LogItems | Sort-Object -Property LastWriteTime | Select-Object -First 1).fullname

                        ## S3 Upload
                        aws s3api put-object --bucket $S3Bucket --body $UploadFile --key $FileName

                        ## File 삭제
                        $UploadFile | Remove-Item
                }
        }
}