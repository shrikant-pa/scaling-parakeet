$date= Get-Date

#Header inputs
$BaseURL = "http://icedq.eastus2.cloudapp.azure.com:8300/ice/api/2.0"
$Repository = "DEMO-RETAIL-MS"
$BearerToken = "Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VySUQiOjgyMjksInJlcG9zaXRvcnkiOiJjdXN0b21lci10cmFpbmluZyIsInVzZXJOYW1lIjoic2hyaWthbnQucCIsImNhbGxlZEZyb20iOiJSRVNUX0FQSSIsInJhbmRvbSI6InBlZHB1NWhlbHM4ZnNzdGhuanRoajRrZ2g0In0.-BCJU4MEo0PZHIRv2kDSYdvPxBnMYiLtx8yayCzmJIM"
$Client = "Web service"

#Body element inputs
$ruleid = 8373

#Creating header array for the request

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("accesstoken", $BearerToken)
$headers.Add("Content-Type", "application/json")
$headers.Add("repository", $Repository)
$headers.Add("Accept", "application/json")
$headers.Add("client",$Client)

#Creating Body
$body=[ordered]@{ruleId=$ruleid}
$body = $body | ConvertTo-Json -Depth 4 -Compress  
#Script Output
Write-Host "$date INFO: API Endpoint: $BaseURL"
Write-Host "$date INFO: Repository: $Repository"
write-Host "$date INFO: Request Body: "
write-Host "$body"
#sending rulerun request
$response = try { Invoke-WebRequest "$baseURL/rulerun" -Method 'POST' -Headers $headers -Body $body} catch {$_.Exception.Response.StatusCode.Value__}
#rqeuset output
Write-Host "$date $response"
#instanceid for other API calls
$instanceid = $response.Content | ConvertFrom-Json
$instanceid = $instanceid.instanceId
#checking httpd response for rule run
if ($response.StatusCode -eq 200) 
{
    Write-Host "$date  INFO: The rulerun api is triggered"
    Write-Host "$date  INFO: The rule is running over the instance ID: $instanceid"
    $run_get_status = "success"
}
else
{
    Write-Host "$date ERROR: Error encountered in executing rule"
    Write-Host "$date ERROR: HTTP Code Returned: $response"
}

#Loop to trigger the status api until the rule is finished execution
if ($run_get_status -eq "success") 
{
    Write-Host "$date INFO: Sending Status API Request--"
    $response = try { Invoke-WebRequest "$baseURL/rulerun/status/$instanceid" -Method 'GET' -Headers $headers} catch {$_.Exception.Response.StatusCode.Value__}
    Write-Host "$date INFO: The status api is triggered"
    if ($response.StatusCode -eq 200) {
        $run_status = $response.content | ConvertFrom-Json
        $run_status = $run_status.status
        Write-Host "$date INFO: Checking for status other than Running....."
        Write-Host "$response"
    WHILE ($run_status.ToUpper() -eq "RUNNING") 
    {
        Write-Host "$date INFO: Checking for status other than Running....."
        $response = try { Invoke-WebRequest "$baseURL/rulerun/status/$instanceid" -Method 'GET' -Headers $headers} catch {$_.Exception.Response.StatusCode.Value__}
        if ($response.StatusCode -eq 200)
        {
            $response = $response
            Write-Host "$date INFO: The status api is triggered"
        }else 
        {
            Write-Host "$date ERROR: Error encountered $response"
        }
        $run_status = $response.content | ConvertFrom-Json
        $run_status = $run_status.status
        Write-Host "$date INFO: Rule status: $run_status"
        Start-Sleep -Seconds 5
        $run_get_summary = 'success'
    }
  }
}else 
{
    Write-Output "$date ERROR: HTTP Code Returned: $response"
}

#Detailed API summary request
if ($run_get_summary -eq 'success')
{
    Write-Host "$date INFO: Sending detailed result api request"
    $response = try { Invoke-WebRequest $baseURL"/rulerun/instance/"$instanceid"?result=detail" -Method 'GET' -Headers $headers} catch {$_.Exception.Response.StatusCode.Value__}
    if ($response.StatusCode -eq 200)
    {
        Write-Host "$date INFO: The result summary of the rule"
        Write-Host $response.Content
    }
    else {
        Write-Output "$date ERROR: HTTP Code Returned: $response"
        }
}
else 
{
    Write-Host "ERROR: Error getting status: $response"
}
