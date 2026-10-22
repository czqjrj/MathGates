# MathGates 回归总入口（换机后第一条命令就该跑它）
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File tools\run_checks.ps1
#   powershell -ExecutionPolicy Bypass -File tools\run_checks.ps1 -Godot "C:\Godot\Godot_v4.7.2-stable_win64_console.exe"
#   powershell -ExecutionPolicy Bypass -File tools\run_checks.ps1 -Fast      # 跳过最慢的三项
#
# 找引擎的顺序：-Godot 参数 → 环境变量 GODOT472 → 常见安装路径 → PATH 里的 godot*
# 每条检查的输出落到 %TEMP%\mg_checks\<名字>.log，失败时打印末尾 15 行。
# 全绿退出码 0，任一条失败退出码 1（可直接当 CI/发版闸门用）。
#
# 为什么输出要落盘再读：Godot 把 SCRIPT ERROR 写 stderr，PowerShell 会把 stderr 当
# terminating error 插进管道，输出顺序被打乱、看着像卡死；重定向到文件最稳。
# 另外控制台代码页会把 Godot 的 UTF-8 中文显示成乱码，所以统一 -- 读文件时按 UTF-8 解码。

param(
    [string]$Godot = "",
    [switch]$Fast,
    [switch]$SkipImport
)

$ErrorActionPreference = "Continue"

# 仓库根：优先用脚本所在目录的上一级；若不是 Godot 工程（比如把脚本单独拷出去跑），
# 退回当前工作目录。两者都不是工程时**直接报错退出**——否则 Godot 会被指向一个
# 空目录、静默挂在项目选择界面上，看起来就是"命令卡死"。
$repo = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $repo "project.godot"))) { $repo = (Get-Location).Path }
if (-not (Test-Path (Join-Path $repo "project.godot"))) {
    Write-Host "当前目录不是 Godot 工程（没有 project.godot）：$repo" -ForegroundColor Red
    Write-Host "请在仓库根目录运行，或用 -File <仓库>\tools\run_checks.ps1 指定脚本位置。" -ForegroundColor DarkGray
    exit 2
}

$logDir = Join-Path $env:TEMP "mg_checks"
if (Test-Path $logDir) { Remove-Item $logDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

# ---------------------------------------------------------------- 找引擎
function Find-Godot {
    param([string]$Explicit)
    if ($Explicit -ne "" -and (Test-Path $Explicit)) { return (Resolve-Path $Explicit).Path }
    if ($env:GODOT472 -and (Test-Path $env:GODOT472)) { return $env:GODOT472 }
    $candidates = @(
        "$env:ProgramFiles\Godot\Godot_v4.7.2-stable_win64_console.exe",
        "C:\Godot\Godot_v4.7.2-stable_win64_console.exe",
        "C:\Godot\Godot_v4.7.2-stable_win64.exe",
        "D:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe",
        "D:\Godot\Godot_v4.7.2-stable_win64_console.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    $cmd = Get-Command "godot*4.7*", "godot" -ErrorAction SilentlyContinue |
        Where-Object { $_.Source -like "*.exe" } | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    return ""
}

$exe = Find-Godot -Explicit $Godot
if ($exe -eq "") {
    Write-Host "找不到 Godot 4.7.2。请用 -Godot <路径> 指定，或设置环境变量 GODOT472。" -ForegroundColor Red
    Write-Host "例：`$env:GODOT472='C:\Godot\Godot_v4.7.2-stable_win64_console.exe'" -ForegroundColor DarkGray
    exit 2
}
Write-Host "引擎：$exe" -ForegroundColor DarkGray
Write-Host "仓库：$repo" -ForegroundColor DarkGray

# ---------------------------------------------------------------- 预导入
# 换机首次、或新增 class_name 文件后必做：否则会连锁报
# Parse Error: Could not find type "XXX"（第三方 res://third_party/ 的 Parse Error 是历史噪音，忽略）。
if (-not $SkipImport) {
    Write-Host "`n[0/11] --import（生成全局类缓存，首次/换机必做）" -ForegroundColor Cyan
    & $exe --headless --path $repo --import *> (Join-Path $logDir "00_import.log")
    $cache = Join-Path $repo ".godot\global_script_class_cache.cfg"
    if (Test-Path $cache) {
        Write-Host "      全局类缓存 OK" -ForegroundColor Green
    } else {
        Write-Host "      全局类缓存未生成 → 后面的检查会连锁报错，先解决这个" -ForegroundColor Red
        exit 1
    }
}

# ---------------------------------------------------------------- 检查表
# Name / 参数数组 / 必须出现的正则 / 不得出现的正则（空串=不检查）
$checks = @(
    @{ n = "check_all";        a = @("--script", "res://tools/check_all.gd");                 must = "CHECKED \d+ scripts, 0 failures";        deny = "OVERLIMIT" },
    @{ n = "Tests";            a = @("res://tests/Tests.tscn");                                must = "TESTS: \d+ passed, 0 failed";            deny = "" },
    @{ n = "SMOKE";            a = @("res://tools/smoke_scene.tscn");                          must = "SMOKE: \d+ ok, 0 fail";                  deny = "" },
    @{ n = "UI-SMOKE";         a = @("res://tests/UiSmoke.tscn");                              must = "UI-SMOKE: \d+ ok, 0 fail";               deny = "" },
    @{ n = "LabSmoke";         a = @("res://tests/LabSmoke.tscn");                             must = "TMP_OK";                                 deny = "" },
    @{ n = "QUESTION-CHECK";   a = @("--script", "res://tools/check_questions.gd");            must = "QUESTION-CHECK: [0-9]+ files";           deny = "QUESTION-CHECK-FAIL" },
    @{ n = "CONTENT-HEALTH";   a = @("--script", "res://tools/check_content_health.gd");       must = "CONTENT-HEALTH: .* 0 problems";          deny = "CONTENT-HEALTH-FAIL" },
    @{ n = "KNOWLEDGE";        a = @("--script", "res://tools/check_knowledge.gd");            must = "KNOWLEDGE: [0-9]+ chapters";             deny = "KNOWLEDGE-FAIL" },
    @{ n = "ASSETS";           a = @("--script", "res://tools/check_assets.gd");               must = "ASSETS: [0-9.]+ MB";                     deny = "ASSETS-FAIL" },
    @{ n = "PARAM-CHECK";      a = @("--script", "res://tools/check_param_masters.gd");        must = "PARAM-CHECK: [0-9]+ files";              deny = "PARAM-CHECK-FAIL" },
    @{ n = "LEVEL-PREVIEW";    a = @("res://tools/LevelPreview.tscn", "--", "--smoke");        must = "LEVEL-PREVIEW-SMOKE: \d+ ok, 0 fail";    deny = "" }
)
$slow = @("UI-SMOKE", "LEVEL-PREVIEW")

$pass = 0
$fail = 0
$failed = @()
$i = 0
foreach ($c in $checks) {
    $i++
    if ($Fast -and ($slow -contains $c.n)) {
        Write-Host ("[{0}/{1}] {2}  —— 跳过（-Fast）" -f $i, $checks.Count, $c.n) -ForegroundColor DarkGray
        continue
    }
    $log = Join-Path $logDir ("{0:D2}_{1}.log" -f $i, $c.n)
    $sw = [Diagnostics.Stopwatch]::StartNew()
    & $exe --headless --path $repo @($c.a) *> $log
    $sw.Stop()
    $text = ""
    if (Test-Path $log) { $text = Get-Content $log -Raw -Encoding UTF8 }
    $ok = ($text -match $c.must) -and ($c.deny -eq "" -or -not ($text -match $c.deny))
    if ($ok) {
        $pass++
        $hint = ""
        if ($text -match $c.must) { $hint = $Matches[0] }
        Write-Host ("[{0}/{1}] {2,-15} OK   ({3:N1}s)  {4}" -f $i, $checks.Count, $c.n, $sw.Elapsed.TotalSeconds, $hint) -ForegroundColor Green
    } else {
        $fail++
        $failed += $c.n
        Write-Host ("[{0}/{1}] {2,-15} FAIL ({3:N1}s)  日志：{4}" -f $i, $checks.Count, $c.n, $sw.Elapsed.TotalSeconds, $log) -ForegroundColor Red
        if ($text -ne "") { ($text -split "`n" | Select-Object -Last 15) | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray } }
    }
}

# ---------------------------------------------------------------- 收尾
Write-Host ""
if ($fail -eq 0) {
    Write-Host ("全部通过：{0}/{0} 项（日志在 {1}）" -f $pass, $logDir) -ForegroundColor Green
    Write-Host "注意：docs/知识点覆盖矩阵.md 与 project.godot 可能被工具改写为等价的换行符差异，提交前 git checkout -- 掉。" -ForegroundColor DarkGray
    exit 0
} else {
    Write-Host ("失败 {0} 项：{1}" -f $fail, ($failed -join ", ")) -ForegroundColor Red
    exit 1
}
