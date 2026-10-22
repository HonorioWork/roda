# Relatório do lote — Prioridade A

## Itens concluídos

- A1 — `theme.css`: tokens centrais de cor, espaço, raio, sombra e tipografia; testar alternando o tema do sistema.
- A2 — `index.html`, `theme.css`: layout fluido sem esmagar conteúdo; testar em 360, 390, 768, 1280, 1920 e 2560 px.
- A3 — `index.html`, `theme.css`: nomes longos truncados com título completo; testar servidor, canal e usuário longos.
- A4 — `theme.css`: áreas seguras e teclado móvel respeitados; testar o compositor no celular.
- A5 — `index.html`, `theme.css`: Skeleton reutilizável em servidores, canais, mensagens e Início; testar com rede lenta.
- A6 — `index.html`: EmptyState com ação em servidores, mensagens, amigos e busca; testar listas vazias.
- A7 — `index.html`: Início com saudação, Continuar, Ativos agora, criar e convite; testar nas seis larguras.
- A8 — `index.html`: servidores reordenáveis por arrasto, toque longo e botões; recarregar para validar persistência.
- A9 — `index.html`: categoria recolhível com estado salvo e canal ativo visível; recolher e recarregar.
- A10 — `index.html`: canais fixados no topo com ordem estável; fixar e desafixar um canal.
- A11 — `index.html`, `theme.css`: barra móvel com cinco destinos e indicador; testar abaixo de 768 px e em tela cheia.
- A12 — `index.html`: último canal por servidor com fallback; alternar servidores e apagar/perder acesso ao canal.
- A13 — `index.html`, migration de presença: participantes e estados da call em tempo real; observar de outra conta.
- A14 — `index.html`: mini player com sala, contagem, mudo, sair e voltar; navegar mantendo a call.
- A15 — `index.html`: pré-entrada com câmera, medidor e dispositivos; testar permissão aceita e negada.
- A16 — `index.html`, `theme.css`: falante com destaque suave e prioridade na grade; falar com redução de movimento ativa.
- A17 — `index.html`: volume individual de 0–200% persistido; ajustar, sair e voltar à chamada.
- A18 — `index.html`: exclusão adiada por 6 segundos com Desfazer; apagar e restaurar mensagem.
- A19 — `index.html`: rascunho por canal e DM; digitar, trocar conversa e voltar.
- A20 — `index.html`, migration de leitura: divisor e botão para novas mensagens; entrar com mensagens não lidas.
- A21 — `index.html`: amigos online e em chamada no Início, respeitando invisível; testar com duas contas.
- A22 — `index.html`: ErrorState com Tentar de novo em servidor, mensagens e voz; simular falha de rede.
- A23 — `index.html`, `theme.css`: confirmação segura para servidor, canal, membro e saída; servidor exige nome exato.
- A24 — `index.html`, migration de denúncias: denúncia em mensagem, perfil e participante, sem envio duplo.

## Pendências e decisões

- Prioridade B não iniciada para respeitar o limite de orçamento e reservar a validação.
- `TODO(decisão)`: o banco atual não possui entidade de categoria; a categoria única exibida é estrutural e não pode ser excluída sem definir primeiro categorias reais.

## Migrations

- `20261022_voice_presence_details.sql`: estados de mudo, ensurdecido, câmera e tela + Realtime. Rollback documentado no arquivo.
- `20261022_read_states.sql`: posição de leitura por usuário/canal, RLS própria. Rollback: remover `read_states`.
- `20261022_reports_moderation.sql`: função e política para leitura por moderadores. Rollback documentado no arquivo.
- As três alterações foram aplicadas com sucesso ao projeto Supabase `vrqqvfhggugyrtboxklz` em 22/10/2026.

## Dependências e flags

- Dependências novas: nenhuma.
- Flags novas: nenhuma; recursos conservam fallback local quando o banco está indisponível.

## Cinco testes manuais essenciais

1. Em duas contas, entrar/sair de uma sala e conferir a lista externa, mini player, falante e volume.
2. Em 360 e 390 px, abrir chat, teclado, barra inferior e pré-entrada; confirmar que nada cobre o compositor.
3. Fixar, recolher e reordenar; recarregar e conferir a persistência e o último canal.
4. Apagar uma mensagem, desfazer dentro de 6 segundos e repetir deixando o prazo terminar.
5. Enviar uma denúncia e confirmar que somente uma é criada mesmo com clique duplo.

## Validação e orçamento

- JavaScript validado com `node --check`; whitespace com `git diff --check`; nenhum gerenciador de build, lint ou testes existe neste projeto estático.
- CSS responsivo auditado nos breakpoints 360, 390, 768, 1280, 1920 e 2560 px, em tema claro e escuro.
- Orçamento estimado usado: ~70% do restante; a reserva foi usada para migrations, revisão, correções e este relatório.
