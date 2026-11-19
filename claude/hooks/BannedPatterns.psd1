<#
    Rules of the banned-pattern guard. Each rule:
      Id          short name shown in the report
      Extensions  file extensions the rule applies to
      Target      'Text' (default): the written text; 'Path': the file path
      Pattern     .NET regular expression, matched per line of the target
      ExcludeWhenFileMatches  optional regular expression; the rule is skipped for a file whose content it matches
                              (inline-style: a file that starts with <!DOCTYPE html> / <html> is a complete
                              document such as an email template, which needs inline styles)
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
            Id = 'decorator-api'; Extensions = @('.ts'); Skill = 'angular'
            Pattern = '@(?:Input|Output|ViewChild|ViewChildren|ContentChild|ContentChildren)\s*\('
            Message = 'use the signal APIs input() / output() / viewChild() / contentChild(), never the decorators'
        }
        @{
            Id = 'standalone-flag'; Extensions = @('.ts'); Skill = 'angular'
            Pattern = '\bstandalone\s*:\s*true\b'
            Message = 'standalone is the default: remove standalone: true'
        }
        @{
            Id = 'any-type'; Extensions = @('.ts'); Skill = 'angular'
            Pattern = '(?:[:<,|&]\s*|\bas\s+)any\b(?=\s*(?:[\[\]>,;)=|&{]|$))'
            Message = 'no any: use unknown and narrow it'
        }
        @{
            Id = 'non-null-assertion'; Extensions = @('.ts'); Skill = 'angular'
            Pattern = '^(?!\s*(?:/[/*]|\*)).*?(?<=[\w)\]])!(?=[.;,)\[])'
            Message = 'no non-null assertion (!): handle the absent case'
        }
        @{
            Id = 'null-forgiving'; Extensions = @('.cs'); Skill = 'csharp'
            Pattern = '^(?!\s*(?:/[/*]|\*)).*?(?<=[\w)\]])!(?=[.;,)\[])'
            Message = 'no null-forgiving operator (!): fix the cause of the nullability warning'
        }
        @{
            Id = 'blanket-suppression'; Extensions = @('.ts'); Skill = 'code-design'
            Pattern = '@ts-(?:ignore|nocheck)\b'
            Message = 'never silence the compiler: fix the error, or use @ts-expect-error with the reason'
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
            Pattern = '\sstyle\s*=\s*["'']|\[style[.\]]|\[ngStyle\]'
            ExcludeWhenFileMatches = '(?is)\A\uFEFF?\s*(?><!--(?:(?!-->).)*-->\s*)*(?:<!doctype\s+html(?=[\s>])|<html[\s>])'
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
            Message = 'mobile-first: use the project min-width breakpoint mixins, never a bare width @media'
        }
        @{
            Id = 'deep-selector'; Extensions = @('.scss', '.css'); Skill = 'html-scss'
            Pattern = '::ng-deep\b'
            Message = 'never ::ng-deep: use the library theming API or the global vendor overrides partial'
        }
        @{
            Id = 'important'; Extensions = @('.scss', '.css'); Skill = 'html-scss'
            Pattern = '!important\b'
            Message = 'no !important: fix the specificity instead'
        }
        @{
            Id = 'scss-import'; Extensions = @('.scss'); Skill = 'html-scss'
            Pattern = '^\s*@import\b'
            Message = 'use @use / @forward, never @import'
        }
        @{
            Id = 'wrapper-class'; Extensions = @('.html', '.scss', '.css', '.ts'); Skill = 'html-scss'
            Pattern = '(?:^|[\s,>+~])\.[\w-]*wrapper\b|\bclass\s*[:=]\s*["''][^"'']*wrapper'
            Message = 'no "wrapper": use "container" (content height) or "placeholder" (fixed height), or the host element'
        }
    )
}
