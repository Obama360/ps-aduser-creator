# Create AD-User from list in file.
# Created 2022-3
# Nico Braun

# LIST TEMPLATE:
# basedn=OU=ou,DC=domain,DC=com
# username,name,password,[groups,seperated,by,comma]
# ...

$splitterBasedn = ","

$splitterInfo = ";"
$splitterGroups = ","

$splitterGroupsStart = "["
$splitterGroupsEnd = "]"

# Read list file line by line
foreach($line in Get-Content (Read-Host "List-file path: ") -Encoding UTF8) {
    if($line -match $regex){
        # Check for basedn line
        if($line -like "*basedn=*") {
            # Get basedn
            $basedn = $line.Substring($line.IndexOf("=")+1)
            # Get domain name
            $basednParts = $basedn.Split($splitterBasedn)
            $domain=""
            foreach($part in $basednParts) {
                if($part -like "*DC=*") {
                    $domain += $part.Substring($part.IndexOf("=")+1) + "."
                }
            }
            $domain = $domain.Substring(0,$domain.Length-1)

            echo "==== BASE-DN ===="
            echo "basedn: $basedn"
            echo "domain: $domain"
            echo "=================`n"
        } else {
            # Get user info from line
            $startGroups = $line.IndexOf($splitterGroupsStart)
            $endGroups = $line.IndexOf($splitterGroupsEnd)

            $info = $line.Substring(0,$startGroups).Split($splitterInfo)
            $groups = $line.Substring($startGroups+1,$endGroups-$startGroups-1).Split($splitterGroups)

            # Prepare info for user creation
            $username = $info[0]
            $name = $info[1] + " " + $info[2]
            $firstName = $info[1]
            $surName = $info[2]
            $principalName = $info[0] + "@" + $domain
            $password = ConvertTo-SecureString $info[3] -AsPlainText -Force

            # Create user
            try {
                New-ADUser -Name $name -GivenName $firstName -Surname $surName -SamAccountName $username -UserPrincipalName $principalName -AccountPassword $password -Path $basedn -ChangePasswordAtLogon $false -Enabled $true -DisplayName $name
                echo "Created user $principalName"
                }
            catch {
                Write-Error "Failed to create user $principalName! ($_.Exception)"
            }

            # Add user to groups
            foreach($group in $groups) {
                if($group.Length -gt 1 -And $group -ne " ") {
                    try {
                        Add-ADPrincipalGroupMembership $username -MemberOf $group
                        echo "Added $username to group $group"
                    }
                        catch {Write-Error "Failed to add $username to group $group! ($_.Exception)"}
                }
            }
            echo "`n"
        }
    }
}
