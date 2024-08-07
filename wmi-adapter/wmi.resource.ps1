# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

[CmdletBinding()]
param(
    [ValidateSet('List','Get','Set','Test','Validate')]
    $Operation = 'List',
    [Parameter(ValueFromPipeline)]
    $stdinput
)

$ProgressPreference = 'Ignore'
$WarningPreference = 'Ignore'
$VerbosePreference = 'Ignore'

function IsConfiguration($obj) {
    if ($null -ne $obj.metadata -and $null -ne $obj.metadata.'Microsoft.DSC' -and $obj.metadata.'Microsoft.DSC'.context -eq 'Configuration') {
        return $true
    }

    return $false
}

if ($Operation -eq 'List')
{
    $clases = Get-CimClass

    foreach ($r in $clases)
    {
        $version_string = "";
        $author_string = "";
        $moduleName = "";

        $propertyList = @()
        foreach ($p in $r.CimClassProperties)
        {
            if ($p.Name)
            {
                $propertyList += $p.Name
            }
        }

        $namespace = $r.CimSystemProperties.Namespace.ToLower().Replace('/','.')
        $classname = $r.CimSystemProperties.ClassName
        $fullResourceTypeName = "$namespace/$classname"
        $requiresString = "Microsoft.Windows/WMI"

        $z = [pscustomobject]@{
            type = $fullResourceTypeName;
            kind = 'Resource';
            version = $version_string;
            capabilities = @('Get');
            path = "";
            directory = "";
            implementedAs = "";
            author = $author_string;
            properties = $propertyList;
            requireAdapter = $requiresString
        }

        $z | ConvertTo-Json -Compress
    }
}
elseif ($Operation -eq 'Get')
{
    $inputobj_pscustomobj = $null
    if ($stdinput)
    {
        $inputobj_pscustomobj = $stdinput | ConvertFrom-Json
    }

    $result = @()

    if (IsConfiguration $inputobj_pscustomobj) # we are processing a config batch
    {
        foreach($r in $inputobj_pscustomobj.resources)
        {
            $type_fields = $r.type -split "/"
            $wmi_namespace = $type_fields[0].Replace('.','\')
            $wmi_classname = $type_fields[1]

            #TODO: add filtering based on supplied properties of $r
            $wmi_instances = Get-CimInstance -Namespace $wmi_namespace -ClassName $wmi_classname

            if ($wmi_instances)
            {
                $instance_result = @{}
                $wmi_instance = $wmi_instances[0] # for 'Get' we return just first matching instance; for 'export' we return all instances
                $wmi_instance.psobject.properties | %{
                    if (($_.Name -ne "type") -and (-not $_.Name.StartsWith("Cim")))
                    {
                        $instance_result[$_.Name] = $_.Value
                    }
                }

                $result += @($instance_result)
            }
            else
            {
                $errmsg = "Can not find type " + $r.type + "; please ensure that Get-CimInstance returns this resource type"
                Write-Error $errmsg
                exit 1
            }
        }
    }
    else # we are processing an individual resource call
    {
        $type_fields = $inputobj_pscustomobj.adapted_dsc_type -split "/"
        $wmi_namespace = $type_fields[0].Replace('.','\')
        $wmi_classname = $type_fields[1]

        #TODO: add filtering based on supplied properties of $inputobj_pscustomobj
        $wmi_instances = Get-CimInstance -Namespace $wmi_namespace -ClassName $wmi_classname

        if ($wmi_instances)
        {
            $wmi_instance = $wmi_instances[0] # for 'Get' we return just first matching instance; for 'export' we return all instances
            $result = @{}
            $wmi_instance.psobject.properties | %{
                if (($_.Name -ne "type") -and (-not $_.Name.StartsWith("Cim")))
                {
                    $result[$_.Name] = $_.Value
                }
            }
        }
        else
        {
            $errmsg = "Can not find type " + $inputobj_pscustomobj.type + "; please ensure that Get-CimInstance returns this resource type"
            Write-Error $errmsg
            exit 1
        }
    }

    $result | ConvertTo-Json -Compress
}
elseif ($Operation -eq 'Validate')
{
    # TODO: this is placeholder
    @{ valid = $true } | ConvertTo-Json
}
else
{
    Write-Error "ERROR: Unsupported operation requested from wmigroup.resource.ps1"
}