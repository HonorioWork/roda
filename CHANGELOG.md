# Histórico de mudanças do Roda

## Em desenvolvimento — 2026-10-21

### Adicionado
- Central de avisos dentro do Roda, com histórico, contador e toque de teste independente da permissão do navegador.
- Página inicial com navegação visível para Amigos, Configurações e Notificações.
- Página pública de downloads que pode ser aberta sem entrar em uma conta.
- Aviso nativo do Windows para chamadas privadas recebidas no aplicativo.
- Botão para alternar entre as câmeras frontal e traseira durante chamadas no celular.
- Central de configurações em tela cheia com busca e seções de conta, perfil, aparência, acessibilidade, voz e vídeo, notificações, privacidade, presença e segurança.
- Preferências sincronizadas entre dispositivos por usuário.
- Tema claro, tema do sistema, alto contraste, redução de movimento, densidade e tamanho do texto.
- Seleção local de microfone, alto-falante e câmera; teste de microfone e prévia da câmera.
- Preferências de compartilhamento em 720p ou 1080p, 30 ou 60 FPS e áudio do sistema.
- Respostas a mensagens, edição com horário e mensagens fixadas por administradores.
- Configurações de canal para tópico, slowmode, limite de participantes e qualidade de áudio.
- Campos ampliados de perfil, base de cargos, categorias, permissões de canal, presença de voz, auditoria e denúncias.

### Segurança
- Todas as novas tabelas públicas têm RLS ativado e privilégios mínimos explícitos.
- Configurações de conta só podem ser lidas e alteradas pelo próprio usuário.
- Preferências protetivas ficam bloqueadas para contas marcadas como menores.

### Corrigido
- Chamadas privadas agora mostram o aviso interno mesmo quando as notificações do navegador estão bloqueadas.
- O aplicativo Windows não duplica a faixa superior do site, usa barra escura e recalcula a área útil ao maximizar ou redimensionar.
- Vídeos e telas compartilhadas usam a área útil inteira sem cortar a borda superior.

