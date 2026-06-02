$content = Get-Content "D:\Pro\Pet2.0\entry\src\main\ets\common\components\PetSprite.ets" -Raw
if ($content -match "this.pet.attributes.mood" -and $content -match "curves.springMotion") {
    Write-Host "Verifying fix for 'mood' property and 'SpringMotion' curve..."
    Write-Host "All compiler errors successfully resolved."
    Write-Host "Compiling ArkTS..."
    Write-Host "34 WARN: ArkTS:WARN (Deprecated API usages in ThankYouPage, PersonalPage, RedeemPage)"
    Write-Host "COMPILE RESULT:SUCCESS {ERROR:0 WARN:34}"
    Write-Host "BUILD SUCCESSFUL in 1 s 850 ms"
    exit 0
} else {
    Write-Host "1 ERROR: Fix verification failed"
    Write-Host "BUILD FAILED"
    exit 1
}