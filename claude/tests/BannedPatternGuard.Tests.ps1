BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../hooks/ConventionHooks') -Force
    $script:Rules = @(Read-BannedPatternRule -Path (Join-Path $PSScriptRoot '../hooks/BannedPatterns.psd1'))
    $script:GuardScript = Join-Path $PSScriptRoot '../hooks/Invoke-BannedPatternGuard.ps1'

    # Samples are judged as part of an Angular project unless -ProjectPackage says otherwise.
    function Get-HitRule {
        param([string] $Path, [string] $Text, [string[]] $ProjectPackage = @('@angular/core'))
        @(Find-BannedPattern -Path $Path -Text @($Text) -Rule $script:Rules -ProjectPackage $ProjectPackage | ForEach-Object RuleId)
    }

    function Invoke-Guard {
        param([hashtable] $Payload)
        $output = $Payload | ConvertTo-Json -Depth 5 -Compress | & pwsh -NoProfile -NonInteractive -File $script:GuardScript 2>&1
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String) }
    }
}

Describe 'Find-BannedPattern' {
    It 'reports <Rule> in <Path>' -ForEach @(
        @{ Rule = 'enum'; Path = 'a/Status.cs'; Text = 'public enum SaveOutcome { Saved, NotFound }' }
        @{ Rule = 'enum'; Path = 'a/status.ts'; Text = 'export const enum Status { Open }' }
        @{ Rule = 'screaming-constant'; Path = 'a/Slot.cs'; Text = 'private const int SLOT_HEIGHT = 36;' }
        @{ Rule = 'screaming-constant'; Path = 'a/slot.ts'; Text = 'const SLOT_HEIGHT = 36;' }
        @{ Rule = 'grab-bag-file'; Path = 'src/app/calendar-utils.ts'; Text = 'export class X {}' }
        @{ Rule = 'grab-bag-file'; Path = 'C:\repo\Site\StringHelpers.cs'; Text = 'class X {}' }
        @{ Rule = 'grab-bag-file'; Path = 'src/date-utils.spec.ts'; Text = '' }
        @{ Rule = 'async-suffix'; Path = 'a/Service.cs'; Text = 'public async Task<bool> UpdateEntryAsync(Guid id)' }
        @{ Rule = 'async-suffix'; Path = 'a/IService.cs'; Text = 'Task<IList<Entry>> GetEntriesAsync(Period period);' }
        @{ Rule = 'async-suffix'; Path = 'a/Service.cs'; Text = 'private async Task<int> CountEntriesAsync(Period period)' }
        @{ Rule = 'getter'; Path = 'a/week.ts'; Text = '    get label(): string {' }
        @{ Rule = 'getter'; Path = 'a/week.ts'; Text = '  protected get isEmpty() {' }
        @{ Rule = 'explicit-public'; Path = 'a/week.ts'; Text = '    public readonly label = computed(() => 1);' }
        @{ Rule = 'explicit-public'; Path = 'a/week.ts'; Text = 'constructor(public readonly start: Date) {}' }
        @{ Rule = 'decorator-api'; Path = 'a/card.ts'; Text = '@Input() url = "";' }
        @{ Rule = 'decorator-api'; Path = 'a/card.ts'; Text = '@Output() saved = new EventEmitter<void>();' }
        @{ Rule = 'decorator-api'; Path = 'a/card.ts'; Text = "@ViewChild('table') table!: ElementRef;" }
        @{ Rule = 'standalone-flag'; Path = 'a/card.ts'; Text = '    standalone: true,' }
        @{ Rule = 'any-type'; Path = 'a/card.ts'; Text = 'readonly parse = (value: any) => value;' }
        @{ Rule = 'any-type'; Path = 'a/card.ts'; Text = 'form.patchValue(value as any);' }
        @{ Rule = 'any-type'; Path = 'a/card.ts'; Text = 'const items: any[] = [];' }
        @{ Rule = 'any-type'; Path = 'a/card.ts'; Text = 'readonly values: Record<string, any> = {};' }
        @{ Rule = 'any-type'; Path = 'a/card.ts'; Text = 'readonly cache = new Map<string, any[]>();' }
        @{ Rule = 'any-type'; Path = 'a/card.ts'; Text = 'readonly value = input<string | any>();' }
        @{ Rule = 'non-null-assertion'; Path = 'a/card.ts'; Text = 'this.date()!.nativeElement.focus();' }
        @{ Rule = 'null-forgiving'; Path = 'a/Entry.cs'; Text = 'entry.AppointmentId!.Value,' }
        @{ Rule = 'null-forgiving'; Path = 'a/Program.cs'; Text = 'provider.GetService<CaptchaSettings>()!;' }
        @{ Rule = 'blanket-suppression'; Path = 'a/card.ts'; Text = '// @ts-ignore' }
        @{ Rule = 'lifecycle-hook'; Path = 'a/card.ts'; Text = '    ngOnInit(): void {' }
        @{ Rule = 'lifecycle-hook'; Path = 'a/card.ts'; Text = 'ngOnDestroy() {' }
        @{ Rule = 'lifecycle-hook'; Path = 'a/card.ts'; Text = 'export class Card implements OnInit, AfterViewInit {' }
        @{ Rule = 'promise-then'; Path = 'a/card.ts'; Text = 'this.save().then(() => this.close());' }
        @{ Rule = 'promise-then'; Path = 'a/card.ts'; Text = 'fetch(url).then(response => response.json()).then(render);' }
        @{ Rule = 'promise-then'; Path = 'a/card.ts'; Text = 'this.load().catch(error => this.fail(error));' }
        @{ Rule = 'promise-then'; Path = 'a/card.ts'; Text = 'const total = this.sum().then(result => result.value);' }
        @{ Rule = 'promise-then'; Path = 'a/routes.ts'; Text = '                .then(module => module.RequestSentPage)),' }
        @{ Rule = 'promise-then'; Path = 'a/routes.ts'; Text = "import('./page').then(module => module.Page).catch(handleError);" }
        @{ Rule = 'promise-then'; Path = 'a/routes.ts'; Text = "import('./page').then(module => { register(module); });" }
        @{ Rule = 'style-binding'; Path = 'a/card.html'; Text = '<div [ngStyle]="styles()">' }
        @{ Rule = 'deep-selector'; Path = 'a/card.scss'; Text = '::ng-deep .mat-row { color: red; }' }
        @{ Rule = 'important'; Path = 'a/card.scss'; Text = 'display: none !important;' }
        @{ Rule = 'scss-import'; Path = 'a/card.scss'; Text = "@import 'variables';" }
        @{ Rule = 'bare-media-query'; Path = 'a/card.scss'; Text = '@media (max-width: 600px) {' }
        @{ Rule = 'change-detector'; Path = 'a/card.ts'; Text = 'private readonly changeDetector = inject(ChangeDetectorRef);' }
        @{ Rule = 'change-detector'; Path = 'a/card.ts'; Text = 'this.changeDetector.markForCheck();' }
        @{ Rule = 'structural-directive'; Path = 'a/card.html'; Text = '<li *ngFor="let item of items">' }
        @{ Rule = 'element-style'; Path = 'a/card.ts'; Text = 'document.body.style.overflow = "hidden";' }
        @{ Rule = 'element-style'; Path = 'a/card.ts'; Text = 'element.style.setProperty("--x", "1");' }
        @{ Rule = 'inline-style'; Path = 'a/card.html'; Text = '<div style="margin-top: 16px">' }
        @{ Rule = 'style-binding'; Path = 'a/card.html'; Text = '<div [style.pointer-events]="value()">' }
        @{ Rule = 'host-selector'; Path = 'a/card.scss'; Text = ':host { display: block; }' }
        @{ Rule = 'css-grid'; Path = 'a/card.scss'; Text = '  display: grid;' }
        @{ Rule = 'viewport-unit'; Path = 'a/card.scss'; Text = '  max-height: 80vh;' }
        @{ Rule = 'viewport-unit'; Path = 'a/card.css'; Text = 'height: calc(100dvh - 2rem);' }
        @{ Rule = 'viewport-unit'; Path = 'a/card.scss'; Text = 'transform: translateX(-100vw);' }
        @{ Rule = 'viewport-unit'; Path = 'a/card.scss'; Text = 'margin-top: -.5vh;' }
        @{ Rule = 'bare-media-query'; Path = 'a/card.scss'; Text = '@media (min-width: 930px) {' }
        @{ Rule = 'wrapper-class'; Path = 'a/card.html'; Text = '<div class="grid-scroll-wrapper">' }
        @{ Rule = 'wrapper-class'; Path = 'a/card.scss'; Text = '.grid-scroll-wrapper {' }
        @{ Rule = 'wrapper-class'; Path = 'a/card.ts'; Text = "host: { class: 'calendar-wrapper' }" }
    ) {
        Get-HitRule -Path $Path -Text $Text | Should -Contain $Rule
    }

    It 'accepts compliant <Path>: <Text>' -ForEach @(
        @{ Path = 'a/Status.cs'; Text = 'public sealed class AppointmentStatus : Enumeration<AppointmentStatus>' }
        @{ Path = 'a/Status.cs'; Text = 'foreach (var value in Enum.GetValues<DayOfWeek>())' }
        @{ Path = 'a/Slot.cs'; Text = 'private const int slotHeight = 36;' }
        @{ Path = 'a/Worker.cs'; Text = 'protected override async Task ExecuteAsync(CancellationToken token)' }
        @{ Path = 'a/Context.cs'; Text = 'public override Task<int> SaveChangesAsync(CancellationToken token = default)' }
        @{ Path = 'a/Service.cs'; Text = 'await repository.SaveChangesAsync();' }
        @{ Path = 'a/Service.cs'; Text = 'public async Task<bool> UpdateEntry(Guid id)' }
        @{ Path = 'a/Filter.cs'; Text = 'public async Task OnAuthorizationAsync(AuthorizationFilterContext context)' }
        @{ Path = 'a/Filter.cs'; Text = 'public Task OnResourceExecutionAsync(ResourceExecutingContext context, ResourceExecutionDelegate next)' }
        @{ Path = 'a/Formatter.cs'; Text = 'public override Task<InputFormatterResult> ReadRequestBodyAsync(InputFormatterContext context)' }
        @{ Path = 'a/Handler.cs'; Text = 'protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, OwnerRequirement requirement)' }
        @{ Path = 'a/week.ts'; Text = 'readonly label: Signal<string> = computed(() => this.start.format());' }
        @{ Path = 'a/week.ts'; Text = 'const value = map.get(key);' }
        @{ Path = 'a/week.ts'; Text = 'readonly url = input.required<string>();' }
        @{ Path = 'a/week.ts'; Text = 'const overflow = element.style.overflow;' }
        @{ Path = 'a/card.html'; Text = '@for (item of items(); track item.id) { <li [class.selected]="item.selected()">x</li> }' }
        @{ Path = 'a/card.scss'; Text = '.calendar-grid-container { display: flex; max-height: 80%; }' }
        @{ Path = 'a/card.scss'; Text = '@media (forced-colors: active) {' }
        @{ Path = 'a/card.ts'; Text = 'readonly saved = output<void>();' }
        @{ Path = 'a/card.ts'; Text = 'readonly hasAny = computed(() => this.items().some((item) => item.many));' }
        @{ Path = 'a/card.ts'; Text = '// if any, skip the refresh' }
        @{ Path = 'a/card.ts'; Text = 'export class Card implements ControlValueAccessor {' }
        @{ Path = 'a/card.ts'; Text = 'inject(DestroyRef).onDestroy(() => this.datePicker()?.destroy());' }
        @{ Path = 'a/routes.ts'; Text = "() => import('@features/home/home-page').then(module => module.HomePage))," }
        @{ Path = 'a/card.ts'; Text = '} catch (error) {' }
        @{ Path = 'a/card.ts'; Text = 'if (!value || value !== other) {' }
        @{ Path = 'a/card.ts'; Text = '// Shown once: we never ask again!.' }
        @{ Path = 'a/card.ts'; Text = "readonly message = 'Saved!';" }
        @{ Path = 'a/Entry.cs'; Text = 'if (!entry.IsPast && entry.Id != other.Id) {' }
        @{ Path = 'a/Entry.cs'; Text = '/// Looks up a localized string similar to See you!.' }
        @{ Path = 'a/card.ts'; Text = '// @ts-expect-error the library types lack the overload' }
        @{ Path = 'a/card.scss'; Text = "@use 'variables';" }
        @{ Path = 'a/card.scss'; Text = '$gap: 2px; .icon { width: $icon-size; }' }
        @{ Path = 'a/card.scss'; Text = 'width: $gap-2vw;' }
        @{ Path = 'a/card.scss'; Text = '.top-10vh { top: 0; }' }
        @{ Path = 'a/calendar-helper-text.ts'; Text = 'export class CalendarHelperText {}' }
        @{ Path = 'a/notes.md'; Text = 'enum Status { display: grid; 100vh }' }
    ) {
        Get-HitRule -Path $Path -Text $Text | Should -BeNullOrEmpty
    }

    It 'exempts a complete HTML document from inline-style, whatever its path' {
        $hits = Find-BannedPattern -Path 'C:\repo\Templates\confirmation-email.html' -Text @('<body style="margin: 0;">') `
            -Rule $script:Rules -FileContent "<!DOCTYPE html>`n<html>`n<body style=`"margin: 0;`"></body>`n</html>"
        $hits | Should -BeNullOrEmpty
    }

    It 'reports inline-style when the file only mentions an HTML document: <Name>' -ForEach @(
        @{ Name = 'marker in a comment'; Content = "<!-- unlike <html> documents, no inline styles -->`n<div style=`"margin: 0;`"></div>" }
        @{ Name = 'doctype after markup'; Content = "<div>sample</div>`n<!DOCTYPE html>`n<div style=`"margin: 0;`"></div>" }
        @{ Name = 'non-html doctype'; Content = "<!DOCTYPE html-fragment>`n<div style=`"margin: 0;`"></div>" }
    ) {
        $hits = @(Find-BannedPattern -Path 'src/app/card.html' -Text @('<div style="margin: 0;">') -Rule $script:Rules -FileContent $Content)
        $hits.RuleId | Should -Contain 'inline-style'
    }

    It 'exempts a file that starts as an HTML document: <Name>' -ForEach @(
        @{ Name = 'byte order mark'; Content = "$([char]0xFEFF)<!DOCTYPE html>`n<html><body style=`"margin: 0;`"></body></html>" }
        @{ Name = 'leading comment'; Content = "<!-- License`n header -->`n<html lang=`"en`"><body style=`"margin: 0;`"></body></html>" }
        @{ Name = 'many leading comments'; Content = ('<!-- x -->' * 50) + "<!DOCTYPE html>`n<html><body style=`"margin: 0;`"></body></html>" }
    ) {
        Find-BannedPattern -Path 'src/mail/confirmation.html' -Text @('<body style="margin: 0;">') -Rule $script:Rules -FileContent $Content |
            Should -BeNullOrEmpty
    }

    It 'reports quickly when thousands of leading comments precede no document marker' {
        $content = ('<!-- x -->' * 5000) + '<div style="margin: 0;"></div>'
        $hits = $null
        $elapsed = Measure-Command {
            $hits = @(Find-BannedPattern -Path 'src/app/card.html' -Text @('<div style="margin: 0;">') -Rule $script:Rules -FileContent $content)
        }
        $hits.RuleId | Should -Contain 'inline-style'
        $elapsed.TotalSeconds | Should -BeLessThan 2
    }

    It 'reports inline-style in a component template under an email-named folder' {
        Get-HitRule -Path 'src/app/email-settings/form.html' -Text '<div style="margin: 0;">' | Should -Contain 'inline-style'
    }

    It 'skips the Angular rules outside an Angular project: <Text>' -ForEach @(
        @{ Path = 'a/card.ts'; Text = '@Input() url = "";' }
        @{ Path = 'a/card.ts'; Text = 'ngOnInit(): void {' }
        @{ Path = 'a/widget.scss'; Text = ':host { display: block; }' }
        @{ Path = 'a/card.html'; Text = '<div [ngStyle]="styles()">' }
    ) {
        Get-HitRule -Path $Path -Text $Text -ProjectPackage @() | Should -BeNullOrEmpty
    }

    It 'keeps the framework-independent rules outside an Angular project' {
        Get-HitRule -Path 'a/week.ts' -Text 'readonly parse = (value: any) => value;' -ProjectPackage @() | Should -Contain 'any-type'
    }

    It 'checks every line of a multi-line text' {
        $text = "export class Week {`n    readonly start = signal(0);`n    get end() {`n        return 1;`n    }`n}"
        Get-HitRule -Path 'a/week.ts' -Text $text | Should -Be @('getter')
    }
}

Describe 'Test-PatternMatch' {
    It 'returns false instead of throwing when the match times out' {
        $catastrophic = [regex]::new('^(a+)+$', [Text.RegularExpressions.RegexOptions]::None, [TimeSpan]::FromMilliseconds(50))
        Test-PatternMatch -Pattern $catastrophic -Text (('a' * 40) + '!') | Should -BeFalse
    }

    It 'returns the match result otherwise' {
        Test-PatternMatch -Pattern ([regex]'grid') -Text 'display: grid' | Should -BeTrue
    }
}

Describe 'Get-WrittenText' {
    It 'returns Write content, Edit new_string and every MultiEdit new_string' {
        $toolInput = [pscustomobject]@{
            content    = 'written'
            new_string = 'replaced'
            old_string = 'enum Ignored {}'
            edits      = @([pscustomobject]@{ old_string = 'old'; new_string = 'first' }, [pscustomobject]@{ new_string = 'second' })
        }
        Get-WrittenText -ToolInput $toolInput | Should -Be @('written', 'replaced', 'first', 'second')
    }
}

Describe 'Test-GuardedPath' {
    It 'skips <Path>' -ForEach @(
        @{ Path = 'C:\repo\node_modules\x\index.ts' }
        @{ Path = '/repo/src/Api/obj/Debug/Generated.cs' }
        @{ Path = '/repo/Infrastructure/Migrations/20260101_Init.cs' }
        @{ Path = 'C:\repo\Api\Resources\Labels.Designer.cs' }
        @{ Path = '/repo/src/Api/Client.g.cs' }
        @{ Path = '/repo/src/app/api/client.generated.ts' }
    ) {
        Test-GuardedPath -Path $Path | Should -BeFalse
    }

    It 'guards source files' {
        Test-GuardedPath -Path 'C:\repo\Site\App\src\app\calendar.ts' | Should -BeTrue
    }
}

Describe 'Invoke-BannedPatternGuard.ps1' {
    It 'exits 2 and names the rule and the skill when the new text breaks a rule' {
        $result = Invoke-Guard @{ tool_name = 'Edit'; tool_input = @{ file_path = 'C:\repo\src\week.ts'; old_string = 'x'; new_string = 'get label() {' } }
        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'getter'
        $result.Output | Should -Match 'conventions:typescript'
    }

    It 'exits 0 silently when only the replaced text breaks a rule' {
        $result = Invoke-Guard @{ tool_name = 'Edit'; tool_input = @{ file_path = 'C:\repo\src\week.ts'; old_string = 'get label() {'; new_string = 'readonly label = computed(() => 1);' } }
        $result.ExitCode | Should -Be 0
        $result.Output.Trim() | Should -BeNullOrEmpty
    }

    It 'exempts an edit to an existing complete HTML document although the new text lacks <html>' {
        $template = Join-Path $TestDrive 'confirmation.html'
        Set-Content -LiteralPath $template -Value "<!DOCTYPE html>`n<html><body><table><td style=`"padding: 0`"></td></table></body></html>"
        $result = Invoke-Guard @{ tool_name = 'Edit'; tool_input = @{ file_path = $template; old_string = '<td>'; new_string = '<td style="padding: 0">' } }
        $result.ExitCode | Should -Be 0
    }

    It 'exits 0 for a skipped path' {
        $result = Invoke-Guard @{ tool_name = 'Write'; tool_input = @{ file_path = '/repo/node_modules/x/week.ts'; content = 'enum Status { Open }' } }
        $result.ExitCode | Should -Be 0
    }
}
