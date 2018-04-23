import-module ActiveDirectory

##########################################Private

#Function Print-Input ($input, $text = "Your input ") { ###Huge WIP
#    $i = $input
#    while (!$i) {
#    
#    Write-Host  "Please enter the needed input..." -ForegroundColor Green
#        $i = Read-Host $text
#    }
#    return $i
#}

Function Print-Output ($query, $search="Query Output"){
    Function Get-Input ($query = $query) {
        $r = (Read-Host "Export as csv? y/n").ToLower()
        switch ($r){ #y,n,default
            y {
                $f = Read-Host "Name of the file?`nDefault: $search.csv"
                if (!$f) {
                    Write-Host "Defaulting name."
                    $f = $search
                }
                Write-Host "Exporting csv as $f.csv..."
                $query | Export-Csv -Path "$f.csv"
            }
            n {
                Write-Host "Outputting in a grid..."
                $query | Out-Gridview -Title $search #-PassThru #<-needs user input
            }
            default {
                Write-Host "Error: Bad input!" -ForegroundColor Red
                Get-Input
            }
        }
    }
    $c = $query.count
    Write-Host #Line Break
    if ($c -gt 1 -or $c -eq 0) {
        Write-Host "Found $c" -ForegroundColor Green #How many items?
        if ($c -ne 0) { #If nothing is found, no need to output anything
            Get-Input #Output dialogue
        }
    } else {
        Write-Host "Found 1" -ForegroundColor Green #One item returns customPSobject which is nullvalued
        if (($query -split '=').count -gt 1) {
            $result = (($query -split '=')[1] -split '}')[0]
        } else {
            $result = $query
        }
        Write-Host $result -ForegroundColor Yellow
    }
}

Function Get-InvertedName ($name) { #put first name last or vice versa
    $namearr = $name -split ' '
    $lastname = $namearr[1..($namearr.count-1)] -join ' '
    return $lastname + ' ' + $namearr[0] 
}

Function Get-Name ($logon, $swap) { #add 's' to change to firstname name
    Write-Host "Getting username..."
    $q = Get-ADUser -Filter {SAMAccountName -Like $logon} | Select-Object Name #query for name from samaccountname
    $s = (($q -split '=')[1] -split '}')[0] #no more regex, just splitting on '=' and '}'
    switch ($swap) {
        s { #Needs to default but it doesn't?
            <#Write-Host "Reversed"
            return Get-Invertedname ($s)#>
            return $s
        }
        default {
            return $s
        }
    }
}

Function Get-Logon ($name) { #Input name firstname
    #query for samaccountname
    Write-Host "Getting userid..."
    $q = Get-ADUser -Filter {Name -Like $name} | Select-Object SAMAccountName
    $s = (($q -split '=')[1] -split '}')[0]
    return $s
}

Function Get-Email ($logon) { #get the email using logon, returns technical address, not named address.
    #query for email
    Write-Host "Getting email..."
    $q = Get-ADUser -Filter {SAMAccountName -Like $logon} | Select-Object UserPrincipalName
    $s = (($q -split '=')[1] -split '}')[0]
    return $s
}

##########################################Public

#Get

Function Get-Groups ($name, $sv) {
    while (!$name) { #Print-Input $name "Groep name "
        Write-Host  "Please enter the needed input..." -ForegroundColor Green
        $name = Read-Host "Name "
    }
    if ($sv -eq "d") {
        $svr = "argenta.be"
    }
    elseif (!$sv) {
        $svr = "CORPARG.LAN"
    }
    else {
        Write-Host "Something in your search went wrong, look at your syntax highlighting!" -ForegroundColor Red
        break
    }
    Write-Host $svr -ForegroundColor DarkGreen
    $identifier = "Get-Groups $name"
    #query the groups
    $i = "*$name*"
    $q = Get-Adgroup -Filter {name -like $i} -Server $svr | Select-Object Name
   Print-Output $q $identifier
}

Function Get-User ($in, $type <#, $multiple#>) {
    while (!$in) { #Print-Input $name "Groep name "
        Write-Host  "Please enter the needed input..." -ForegroundColor Green
        $in = Read-Host "Logon or Name "
    }
    while (!$type) { #Print-Input $name "Groep name "
        Write-Host  "Please enter the needed input..." -ForegroundColor Green
        $type = Read-Host "What data do you need? i/n/e "
    }
    $identifier = "Get-User $in"
    $iarr = $in -split ","
    $oarr = New-Object System.Collections.ArrayList
    foreach ($i in $iarr) {
        switch ($type) {
            i {
                $q = Get-Logon $i
            }
            n {
                $q = Get-Name $i s
            }
            e {
                $q = Get-Email $i
            }
            default {
                Write-Host "Error: Bad input!" -ForegroundColor Red
            }
        }
        $oarr.Add($q) | Out-Null
    }
    Print-Output $oarr $identifier
}

Function Get-GroupMembers ($group, $rec) {
    while (!$group) {
        Write-Host  "Please enter the needed input..." -ForegroundColor Green
        $group = Read-Host "AD Group "
    }
    $identifier = "Get-GroupMembers $group"
    switch ($rec) {
        r {
            $q = Get-Adgroupmember $group -Recursive | Select-Object Name
        }
        default {
            $q = Get-Adgroupmember $group | Select-Object Name
        }
    }
    Print-Output $q $identifier
}

Function Get-GroupMemberships ($logon) {
    while (!$logon) {
        Write-Host  "Please enter the needed input..." -ForegroundColor Green
        $logon = Read-Host "User login "
    }
    $identifier = "Get-GroupsMemberships $logon"
    Write-Host "Fetching users groups... "
    $q = Get-AdPrincipalGroupMembership $logon | Select-Object Name
    Print-Output $q $identifier
}

#Clip

function Clip-NewFolder ($path) {
    while (!$path) {
		Write-Host "Please enter the needed input..." -ForegroundColor Green
        $path = Read-Host "Folder name "
	}
	$output = "Naam Nieuwe AD groep(en) incl. domeinnaam (max. 15): Alles in CORPARG`nDLG_{0}_M`nGG_PROJECT_{0}_M`nNesting in groep(en): GG_PROJECT_{0}_M member maken van DLG_{0}_M`nDLG_{0}_M schrijfrechten geven op gedeelde folder GRPARG\#GRPARG\{0}" -f ($path)
    Write-Host $output -ForegroundColor Green
	Write-Output $output | clip
}

function Clip-NewMailbox ($name) {
    while (!$name) {
		Write-Host "Please enter the needed input..." -ForegroundColor Green
        $name = Read-Host "Mailbox name "
	}
    $output = "Naam Nieuwe AD groep(en) incl. domeinnaam (max. 15): Alles in CORPARG`nDLG_MBX_{0}`nGG_PROJECT_MBX_{0}`nNesting in groep(en): GG_PROJECT_MBX_{0} member maken van`nDLG_MBX_{0}`n`nGelieve DLG_MBX_{0} te koppelen aan emailbox {0}@argenta.be" -f ($name)
    Write-Host $output -ForegroundColor Green
	Write-Output $output | clip
}

function Clip-Sft ($name) {
    while (!$name) {
		Write-Host "Please enter the needed input..." -ForegroundColor Green
        $name = Read-Host "Name "
	}
    #$name = Get-User $name n #lookup with logon instead of name
    #$email = Get-User $name e
    $first,$last = $name.split(" ")
    $last = $last -join ""
    $email = "{0}.{1}@argenta.be" -f ($first, $last)
    $output = "Pseudo Code:`nnew; $name; $email"
    Write-Host $output -ForegroundColor Green
    Write-Output $output | clip
}

#Aliases

Set-Alias gg Get-Groups
Set-Alias gus Get-User
Set-Alias ggm Get-GroupMembers
Set-Alias gum Get-GroupMemberships

Set-Alias cnf Clip-NewFolder
Set-Alias cnm Clip-NewMailbox
Set-Alias sft Clip-Sft