<#
    Skills of this plugin that must be loaded (in the session, or in the subagent doing the edit) before a file
    with the extension is edited. WhenProjectDependsOn adds skills when the file's project depends on the package:
    the nearest package.json for npm, the nearest .csproj (PackageReference, or a ProjectReference to <Package>.csproj)
    and any Directory.Build.props / Directory.Packages.props above it for NuGet. 'package>=major' also requires that
    major version, so a framework or library skill is required only where it applies. Skills that apply only
    conditionally otherwise (accessibility, toolkit-release) are not gated: their descriptions decide.
#>
@{
    Plugin               = 'conventions'
    Extensions           = @{
        '.cs'   = @('code-design', 'dotnet')
        '.ts'   = @('code-design', 'typescript')
        '.html' = @('code-design', 'html-scss')
        '.scss' = @('code-design', 'html-scss')
        '.css'  = @('code-design', 'html-scss')
        '.ps1'  = @('code-design')
        '.psm1' = @('code-design')
        '.psd1' = @('code-design')
        '.yml'  = @('code-design')
        '.yaml' = @('code-design')
    }
    WhenProjectDependsOn = @{
        '@angular/core>=20'         = @{
            '.ts'   = @('angular')
            '.html' = @('angular')
            '.scss' = @('angular')
            '.css'  = @('angular')
        }
        '@typhoon41/scss-solutions' = @{
            '.html' = @('scss-solutions')
            '.scss' = @('scss-solutions')
        }
        'Gmf.DDD.Common'            = @{ '.cs' = @('gmf-ecosystem') }
        'Gmf.Net.Core.Common'       = @{ '.cs' = @('gmf-ecosystem') }
        'Gmf.Mail.Common'           = @{ '.cs' = @('gmf-ecosystem') }
    }
}
