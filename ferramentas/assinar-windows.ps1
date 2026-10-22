param(
    [Parameter(Mandatory = $true)]
    [string[]] $Files,
    [string] $PfxPath,
    [string] $Thumbprint,
    [string] $TimestampUrl = "http://timestamp.digicert.com"
)

$ErrorActionPreference = "Stop"

function Find-SignTool {
    $known = Get-Command signtool.exe -ErrorAction SilentlyContinue
    if ($known) { return $known.Source }

    $kits = Join-Path ${env:ProgramFiles(x86)} "Windows Kits\10\bin"
    if (Test-Path $kits) {
        $candidate = Get-ChildItem -LiteralPath $kits -Filter signtool.exe -File -Recurse |
            Where-Object { $_.FullName -match "\\x64\\signtool\\.exe$" } |
            Sort-Object FullName -Descending |
            Select-Object -First 1
        if ($candidate) { return $candidate.FullName }
    }

    throw "SignTool não encontrado. Instale o Windows SDK com as ferramentas de assinatura."
}

if (-not $PfxPath -and -not $Thumbprint) {
    throw "Informe -PfxPath ou -Thumbprint de um certificado de assinatura de código confiável."
}

$signTool = Find-SignTool
foreach ($file in $Files) {
    $resolved = (Resolve-Path -LiteralPath $file).Path
    $arguments = @("sign", "/fd", "SHA256", "/tr", $TimestampUrl, "/td", "SHA256")
    if ($PfxPath) {
        $arguments += @("/f", (Resolve-Path -LiteralPath $PfxPath).Path)
        if ($env:RODA_SIGNING_PFX_PASSWORD) {
            $arguments += @("/p", $env:RODA_SIGNING_PFX_PASSWORD)
        }
    } else {
        $arguments += @("/sha1", $Thumbprint)
    }
    $arguments += $resolved
    & $signTool @arguments
    if ($LASTEXITCODE -ne 0) { throw "Falha ao assinar $resolved" }
    & $signTool verify /pa /all /v $resolved
    if ($LASTEXITCODE -ne 0) { throw "A assinatura não foi validada em $resolved" }
}
