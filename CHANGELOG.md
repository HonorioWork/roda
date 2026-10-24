## 2026-10-24
- O painel de membros vira uma gaveta lateral até 1399 px, sem empurrar o canal de voz para uma segunda linha.
- Uma nova entrada na chamada agora aguarda o encerramento completo da conexão anterior do LiveKit.
- A pré-entrada limpa câmera, microfone e medidor antes de conectar e permite entrar sem câmera quando a prévia falhar.
- O aplicativo Windows agora abre menor, centralizado e sempre dentro da área útil do monitor.
- O status pode ser alterado na Home e nos servidores entre Disponível, Ausente, Não perturbe e Invisível.
- Amigos e membros sem nenhuma sessão aberta no site ou aplicativo passam a aparecer como invisíveis automaticamente.
- O menu de status agora é maior, escuro, colorido e mostra uma explicação para cada opção.
- Em janelas compactas do aplicativo, o painel de membros abre pela lateral e o canal de voz usa toda a altura disponível.

## 2026-10-23
- A grade da chamada não muda mais de posição quando alguém fala e a tela cheia permanece ativa.
- O botão “Ativar áudio” agora acompanha e libera a reprodução do navegador.
- Servidores podem ser reordenados somente arrastando, com a ordem salva na conta.
- Canais e conversas privadas aceitam imagens e arquivos de até 20 MB.

# Histórico de mudanças do Roda

## Em desenvolvimento — 2026-10-21

### Adicionado
- Recuperação de senha no próprio Roda em três etapas: e-mail, código de uso único e criação da nova senha.
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

