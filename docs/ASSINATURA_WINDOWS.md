# Assinatura do Roda para Windows

O Windows SmartScreen considera a assinatura digital e a reputação do editor. Apenas mudar o nome do instalador ou criar um certificado próprio não remove o aviso.

## Requisito

Use um certificado público de assinatura de código emitido para a HonorioWork, com chave privada disponível como arquivo PFX ou no repositório de certificados do Windows. Certificados EV costumam ganhar reputação mais rapidamente; certificados comuns também são válidos, mas podem precisar construir reputação.

## Como assinar

1. Compile o `Roda.exe`.
2. Assine o executável antes de montar o MSI:
   `powershell -File ferramentas/assinar-windows.ps1 -Files aplicativo-windows/dist/Roda.exe -PfxPath C:\seguro\certificado.pfx`
3. Monte o MSI.
4. Assine o MSI:
   `powershell -File ferramentas/assinar-windows.ps1 -Files downloads/Roda-Setup-1.4.4.msi -PfxPath C:\seguro\certificado.pfx`
5. Confira em Propriedades > Assinaturas Digitais antes de publicar.

Coloque a senha do PFX somente na variável de ambiente `RODA_SIGNING_PFX_PASSWORD`. Não grave certificado, senha ou chave privada no repositório.

O script usa SHA-256, carimbo de tempo e valida cada assinatura. Sem certificado público confiável, o instalador continuará podendo exibir o alerta do SmartScreen.
