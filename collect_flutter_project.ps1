# ===========================
# سكربت لجمع كل ملفات Flutter في ملف واحد
# ===========================

# تحديد مسار مشروع Flutter
$ProjectPath = "D:\FCIS\3rd\2nd term\OS\proj\EaseUp\EaseUp_Flutter_Project"

# تحديد اسم ملف الإخراج
$OutputFile = Join-Path $ProjectPath "FullFlutterProjectCode.txt"

# حذف الملف القديم إذا كان موجودًا
if (Test-Path $OutputFile) {
    Remove-Item -Path $OutputFile -Force
}

# تحديد أنواع الملفات الخاصة بمشاريع Flutter
$Extensions = @(
    "*.dart",        # ملفات الكود
    "*.yaml",        # مثل pubspec.yaml
    "*.json",        # إعدادات مختلفة
    "*.gradle",      # إعدادات Android
    "*.xml",         # ملفات Android
    "*.kt", "*.java",# كود Android
    "*.swift",       # كود iOS
    "*.m", "*.mm",   # Objective-C
    "*.plist",       # إعدادات iOS
    "*.html", "*.css", "*.js", # لدعم الويب
    "*.md"           # ملفات التوثيق
)

# استبعاد المجلدات غير الضرورية
$ExcludeDirs = @(
    "\.git\",
    "\build\",
    "\.dart_tool\",
    "\.idea\",
    "\.vscode\"
)

# البحث عن الملفات وتجميعها
Get-ChildItem -Path $ProjectPath -Recurse -File -Include $Extensions |
Where-Object {
    $exclude = $false
    foreach ($dir in $ExcludeDirs) {
        if ($_.FullName -like "*$dir*") {
            $exclude = $true
            break
        }
    }
    -not $exclude
} |
Sort-Object FullName |
ForEach-Object {
    $RelativePath = $_.FullName.Substring($ProjectPath.Length + 1)
    $fileHeader = "===========================`nFILE: $RelativePath`n===========================`n"
    $fileContent = Get-Content $_.FullName -Raw
    "$fileHeader$fileContent`n`n" | Out-File -Append $OutputFile -Encoding UTF8
}

# تأكيد إنشاء الملف وفتحه
if (Test-Path $OutputFile) {
    Write-Host "All Flutter project files collected successfully in:"
    Write-Host $OutputFile
    Invoke-Item $OutputFile
} else {
    Write-Host "File was not created."
}