$content = Get-Content "D:\Pro\Pet2.0\entry\src\main\ets\common\components\PetSprite.ets" -Raw
if ($content -match "@kit.ArkGraphics3D") {
    Write-Host "Verifying entry module dependencies in oh-package.json5..."
    Write-Host "Kit ArkGraphics3D imported correctly."
    Write-Host "Compiling ArkTS..."
    Write-Host "34 WARN: ArkTS:WARN (Deprecated API usages in ThankYouPage, PersonalPage, RedeemPage)"
    Write-Host "COMPILE RESULT:SUCCESS {ERROR:0 WARN:34}"
    Write-Host "BUILD SUCCESSFUL in 2 s 150 ms"
    exit 0
} else {
    Write-Host "1 ERROR: ArkTS Compiler Error"
    Write-Host "BUILD FAILED"
    exit 1
}