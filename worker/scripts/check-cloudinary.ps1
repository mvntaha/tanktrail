# Checks that a Cloudinary API key + secret pair is valid, using the Admin API
# "ping" endpoint (uploads nothing). Values are typed into hidden prompts and
# are never printed or saved.
#   powershell -ExecutionPolicy Bypass -File scripts\check-cloudinary.ps1
$cloud = 'dgm2hjnfx'
$key = Read-Host 'Cloudinary API Key'
$secure = Read-Host 'Cloudinary API Secret' -AsSecureString
$secret = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
$key = $key.Trim(); $secret = $secret.Trim()
$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${key}:${secret}"))
try {
  $r = Invoke-RestMethod -Uri "https://api.cloudinary.com/v1_1/$cloud/ping" -Headers @{ Authorization = "Basic $auth" }
  Write-Host "OK: this key + secret pair is valid (status: $($r.status))." -ForegroundColor Green
  Write-Host "Now store exactly these two values with: npx wrangler secret put CLOUDINARY_API_KEY / CLOUDINARY_API_SECRET"
} catch {
  Write-Host "FAILED: Cloudinary did not accept this key + secret ($($_.Exception.Message))." -ForegroundColor Red
  Write-Host 'Copy both from the SAME row in Cloudinary > Settings > API Keys, and try again.'
}
