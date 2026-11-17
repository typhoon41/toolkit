# Test helper: a throwaway git repository with files and commits. Dot-source it in BeforeAll.

function New-TestRepository {
    param([Parameter(Mandatory)] [string] $Path)
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Push-Location -LiteralPath $Path
    try {
        git init -q -b main
        git config user.email 'test@example.com'
        git config user.name 'Test Author'
        git config core.autocrlf false
        git remote add origin 'https://github.com/owner/demo.git'
    }
    finally {
        Pop-Location
    }
    (Resolve-Path -LiteralPath $Path).Path
}

function Set-TestFile {
    param([Parameter(Mandatory)] [string] $Repository, [Parameter(Mandatory)] [string] $Path, [Parameter(Mandatory)] [string] $Content)
    $full = Join-Path $Repository $Path
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $full) | Out-Null
    [IO.File]::WriteAllText($full, $Content)
}

function Save-TestCommit {
    param([Parameter(Mandatory)] [string] $Repository, [Parameter(Mandatory)] [string] $Message, [string] $Tag)
    Push-Location -LiteralPath $Repository
    try {
        git add -A
        git commit -q --allow-empty -m $Message
        if ($Tag) {
            git tag $Tag
        }
    }
    finally {
        Pop-Location
    }
}

function New-PropsContent {
    param([Parameter(Mandatory)] [string] $Version)
    "<Project>`n  <PropertyGroup>`n    <Version>$Version</Version>`n  </PropertyGroup>`n</Project>`n"
}

function New-ProjectContent {
    param([string] $Version)
    $property = if ($Version) { "`n  <PropertyGroup>`n    <Version>$Version</Version>`n  </PropertyGroup>`n" } else { '' }
    "<Project Sdk=`"Microsoft.NET.Sdk`">$property</Project>`n"
}
