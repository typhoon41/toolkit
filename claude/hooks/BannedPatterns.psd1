<#
    Rules of the banned-pattern guard. Each rule:
      Id          short name shown in the report
      Extensions  file extensions the rule applies to
      Target      'Text' (default): the written text; 'Path': the file path
      Pattern     .NET regular expression, matched per line of the target
      ExcludePath optional regular expression; the rule is skipped for file paths it matches
      Message     what to do instead
      Skill       the plugin skill that owns the rule
    A rule belongs here only when a regular expression can find it without false positives in normal code.
#>
@{
    Rules = @(
        @{
            Id = 'enum'; Extensions = @('.cs', '.ts'); Skill = 'code-design'
            Pattern = '(?<![\w.])enum\s+[A-Za-z_]\w*'
            Message = 'enum is banned: put the rule on a model; not found is bool/null, a broken invariant an exception'
        }
        @{
            Id = 'screaming-constant'; Extensions = @('.cs', '.ts'); Skill = 'code-design'
            Pattern = '\bconst\s+(?:[\w<>\[\]?]+\s+)?[A-Z][A-Z0-9]*_[A-Z0-9_]+\b'
            Message = 'constants are camelCase, never SCREAMING_SNAKE_CASE'
        }
        @{
            Id = 'grab-bag-file'; Extensions = @('.cs', '.ts', '.scss', '.ps1'); Skill = 'code-design'; Target = 'Path'
            Pattern = '(?i)(?:^|[\\/])[^\\/]*(?:utils?|utilities|helpers?|misc)(?:\.[a-z]+)+$'
            Message = 'name the file after the abstraction it holds, not "utils"/"helpers"'
        }
        @{
            Id = 'async-suffix'; Extensions = @('.cs'); Skill = 'csharp'
            Pattern = '\b(?:Task|ValueTask)(?:<[^()]*>)?\s+(?!(?:ExecuteAsync|StartAsync|StopAsync|SaveChangesAsync|OnActionExecutionAsync|OnResultExecutionAsync|InvokeAsync|DisposeAsync|InitializeAsync)\b)\w+Async\s*[(<]'
            Message = 'no Async suffix on Task-returning methods (framework overrides excepted)'
        }
        @{
            Id = 'getter'; Extensions = @('.ts'); Skill = 'angular'
            Pattern = '^\s*(?:(?:private|protected|public|static|override|readonly)\s+)*get\s+\w+\s*\('
            Message = 'derived state is a computed() signal, never a get accessor'
        }
        @{
            Id = 'explicit-public'; Extensions = @('.ts'); Skill = 'angular'
            Pattern = '(?:^|[(,])\s*public\s+(?!class\b)'
            Message = 'public is the default: omit it (template-only members are protected readonly)'
        }
        @{
            Id = 'input-decorator'; Extensions = @('.ts'); Skill = 'angular'
            Pattern = '@Input\s*\('
            Message = 'use input() / input.required(), never @Input()'
        }
        @{
            Id = 'change-detector'; Extensions = @('.ts'); Skill = 'angular'
            Pattern = '\bChangeDetectorRef\b|\.detectChanges\s*\(|\.markForCheck\s*\('
            Message = 'zoneless: make the template state a signal; post-render DOM work goes in afterNextRender'
        }
        @{
            Id = 'structural-directive'; Extensions = @('.html', '.ts'); Skill = 'angular'
            Pattern = '\*ng(?:If|For|Switch\w*)\b'
            Message = 'use @if / @for / @switch control flow'
        }
        @{
            Id = 'element-style'; Extensions = @('.ts'); Skill = 'html-scss'
            Pattern = '\.style\.(?:setProperty\s*\(|[A-Za-z]\w*\s*=(?!=))'
            Message = 'never set styles from TypeScript: toggle a class and style it in SCSS'
        }
        @{
            Id = 'inline-style'; Extensions = @('.html'); Skill = 'html-scss'
            Pattern = '\sstyle\s*=\s*["'']|\[style[.\]]'
            ExcludePath = '(?i)[\\/][^\\/]*e-?mails?[^\\/]*[\\/]'
            Message = 'no style attribute or [style] binding: use a class (an @for-generated one for runtime values)'
        }
        @{
            Id = 'host-selector'; Extensions = @('.scss', '.css'); Skill = 'html-scss'
            Pattern = ':host\b'
            Message = 'no :host: give the host a class in the decorator and style it where the element is rendered'
        }
        @{
            Id = 'css-grid'; Extensions = @('.scss', '.css'); Skill = 'html-scss'
            Pattern = '\bdisplay\s*:\s*(?:inline-)?grid\b'
            Message = 'display: grid is banned: use flex, the layout utilities, or nested flex with positioned children'
        }
        @{
            Id = 'viewport-unit'; Extensions = @('.scss', '.css'); Skill = 'html-scss'
            Pattern = '(?<![\w#$-])-?\d*\.?\d+(?:[dsl]?v[hwib]|vmin|vmax)\b'
            Message = 'no viewport units (iOS Safari): use % (it resolves against the viewport for dialogs/overlays)'
        }
        @{
            Id = 'bare-media-query'; Extensions = @('.scss'); Skill = 'html-scss'
            Pattern = '@media[^{]*\b(?:min|max)-width\b'
            Message = 'use the project breakpoint mixins, not a bare width @media'
        }
        @{
            Id = 'wrapper-class'; Extensions = @('.html', '.scss', '.css', '.ts'); Skill = 'html-scss'
            Pattern = '(?:^|[\s,>+~])\.[\w-]*wrapper\b|\bclass\s*[:=]\s*["''][^"'']*wrapper'
            Message = 'no "wrapper": use "container" (content height) or "placeholder" (fixed height), or the host element'
        }
    )
}
