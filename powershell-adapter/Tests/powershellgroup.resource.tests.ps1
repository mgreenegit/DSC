# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Describe 'PowerShell adapter resource tests' {

    BeforeAll {
        $OldPSModulePath  = $env:PSModulePath
        $env:PSModulePath += [System.IO.Path]::PathSeparator + $PSScriptRoot

        if ($IsLinux -or $IsMacOS) {
            $cacheFilePath = Join-Path $env:HOME ".dsc" "PSAdapterCache.json"
        }
        else
        {
            $cacheFilePath = Join-Path $env:LocalAppData "dsc" "PSAdapterCache.json"
        }
    }
    AfterAll {
        $env:PSModulePath = $OldPSModulePath
    }

    BeforeEach {
        Remove-Item -Force -ea SilentlyContinue -Path $cacheFilePath
    }

    It 'Discovery includes class-based resources' {

        $r = dsc resource list '*' -a Microsoft.DSC/PowerShell
        $LASTEXITCODE | Should -Be 0
        $resources = $r | ConvertFrom-Json
        ($resources | ? {$_.Type -eq 'TestClassResource/TestClassResource'}).Count | Should -Be 1
    }

    It 'Get works on class-based resource' {

        $r = "{'Name':'TestClassResource1'}" | dsc resource get -r 'TestClassResource/TestClassResource'
        $LASTEXITCODE | Should -Be 0
        $res = $r | ConvertFrom-Json
        $res.actualState.result.properties.Prop1 | Should -BeExactly 'ValueForProp1'
    }

    It 'Get uses enum names on class-based resource' {

        $r = "{'Name':'TestClassResource1'}" | dsc resource get -r 'TestClassResource/TestClassResource'
        $LASTEXITCODE | Should -Be 0
        $res = $r | ConvertFrom-Json
        $res.actualState.result.properties.EnumProp | Should -BeExactly 'Expected'
    }

    It 'Test works on class-based resource' {

        $r = "{'Name':'TestClassResource1','Prop1':'ValueForProp1'}" | dsc resource test -r 'TestClassResource/TestClassResource'
        $LASTEXITCODE | Should -Be 0
        $res = $r | ConvertFrom-Json
        $res.actualState.result.properties.InDesiredState | Should -Be $True
    }

    It 'Set works on class-based resource' {

        $r = "{'Name':'TestClassResource1','Prop1':'ValueForProp1'}" | dsc resource set -r 'TestClassResource/TestClassResource'
        $LASTEXITCODE | Should -Be 0
        $res = $r | ConvertFrom-Json
        $res.afterState.result | Should -Not -BeNull
    }

    It 'Export works on PS class-based resource' {

        $r = dsc resource export -r TestClassResource/TestClassResource
        $LASTEXITCODE | Should -Be 0
        $res = $r | ConvertFrom-Json
        $res.resources[0].properties.result.count | Should -Be 5
        $res.resources[0].properties.result[0].Name | Should -Be "Object1"
        $res.resources[0].properties.result[0].Prop1 | Should -Be "Property of object1"
    }

    It 'Get --all works on PS class-based resource' {

        $r = dsc resource get --all -r TestClassResource/TestClassResource
        $LASTEXITCODE | Should -Be 0
        $res = $r | ConvertFrom-Json
        $res.actualState.result.count | Should -Be 5
        $res.actualState.result| % {$_.Name | Should -Not -BeNullOrEmpty}
    }
}
