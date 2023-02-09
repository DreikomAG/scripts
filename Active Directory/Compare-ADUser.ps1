Function Compare-ADUser {
    [cmdletbinding(SupportsShouldProcess)]

    Param(
        [parameter(Mandatory = $true)]
        [string]$ReferenceUser,

        [parameter(Mandatory = $true)]
        [string]$DifferenceUser,

        [parameter()]
        [string[]]$Property  
    )

    begin {}

    process {
        if ($pscmdlet.ShouldProcess("$ReferenceUser & $DifferenceUser", "Comparing users")) {
            $ReferenceUserSplat = @{ Identity  = $ReferenceUser }
            $DifferenceUserSplat = @{ Identity = $DifferenceUser }

            if ($PSBoundParameters.ContainsKey("Property")) {
                $ReferenceUserSplat.Properties  = $Property
                $DifferenceUserSplat.Properties = $Property
            }

            $ReferenceObject  = Get-ADUser @ReferenceUserSplat
            $DifferenceObject = Get-ADUser @DifferenceUserSplat

            $properties  =  $ReferenceObject.GetEnumerator() | % { $_.Key }
            $properties += $DifferenceObject.GetEnumerator() | % { $_.Key }

            foreach ($prop in $properties | Sort | Select -Unique ) {
                $ReferenceProperty = $ReferenceObject.($prop)
                $DifferenceProperty = $DifferenceObject.($prop)
                    
                try {
                    Remove-Variable comparison -ErrorAction SilentlyContinue
                    $comparison = Compare-Object -ReferenceObject $ReferenceProperty -DifferenceObject $DifferenceProperty -IncludeEqual -ErrorAction SilentlyContinue            
                }
                catch {
                }
                finally {
                    if ( (($comparison.sideindicator -notcontains "<=") -and ($comparison.sideindicator -notcontains "=>")) -and -not
                            ($null -eq $ReferenceProperty -xor $null -eq $DifferenceProperty)) {
                        $comparison = "Equal"
                    }
                    else {
                        $comparison = "Different"
                    }
                }

                [pscustomobject]@{
                    Property = $prop
                    Comparison = $comparison
                    ReferenceUser = $ReferenceProperty
                    DifferenceUser = $DifferenceProperty
                }
            } 
        }
    }

    end {}   
}

# Usage
# Compare-ADUser -ReferenceUser <username> -DifferenceUser <username> -Property * | fl