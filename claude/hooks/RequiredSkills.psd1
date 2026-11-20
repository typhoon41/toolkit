<#
    Skills of this plugin that must be loaded (in the session, or in the subagent doing the edit) before a file
    with the extension is edited. WhenProjectDependsOn adds skills when the nearest package.json above the file
    depends on the package, so a framework skill is required only in that framework's projects. Skills that apply
    only conditionally otherwise (gmf-packages, scss-solutions, accessibility) are not gated: their descriptions
    decide.
#>
@{
    Plugin               = 'conventions'
    Extensions           = @{
        '.cs'   = @('code-design', 'csharp')
        '.ts'   = @('code-design', 'typescript')
        '.html' = @('code-design', 'html-scss')
        '.scss' = @('code-design', 'html-scss')
        '.css'  = @('code-design', 'html-scss')
    }
    WhenProjectDependsOn = @{
        '@angular/core' = @{
            '.ts'   = @('angular')
            '.html' = @('angular')
            '.scss' = @('angular')
        }
    }
}
