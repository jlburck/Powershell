$day = (get-date).Day
if($day.ToString().Length -lt 2){$day=[string]("0"+$day)}
$month = (get-date).Month
if($month.ToString().Length -lt 2){$month=[string]("0"+$month)}
$values=((select-string -path "C:\inetpub\logs\LogFiles\*\*$($month)$($day).log" -allmatches '[-]\s[3-9][0-9][0-9]\s').Matches | Select-Object -Unique ).Value
foreach($v in $values){
if([int]$v.Substring(2) -notlike "401"){
(select-string -path "C:\inetpub\logs\LogFiles\*\*$($month)$($day).log" -pattern $v -allmatches –simplematch) | select -Last 5
}
}
