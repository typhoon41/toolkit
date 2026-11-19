<#
    Skills of this plugin that must be loaded (in the session, or in the subagent doing the edit) before a file
    with the extension is edited. Skills that apply only conditionally (gmf-packages, scss-solutions,
    accessibility) are not gated: their descriptions decide.
#>
@{
    Plugin     = 'conventions'
    Extensions = @{
        '.cs'   = @('code-design', 'csharp')
        '.ts'   = @('code-design', 'angular')
        '.html' = @('code-design', 'angular', 'html-scss')
        '.scss' = @('code-design', 'html-scss')
        '.css'  = @('code-design', 'html-scss')
    }
}
