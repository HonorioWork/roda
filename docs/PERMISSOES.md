# Permissões do Roda

Os bits abaixo serão usados pela evolução de cargos e permissões do Roda. Eles ficam documentados antes de a interface de cargos ser ativada para impedir divergências entre o banco e o cliente.

| Bit | Permissão |
| ---: | --- |
| 0 | VIEW_CHANNEL |
| 1 | MANAGE_CHANNELS |
| 2 | MANAGE_ROLES |
| 3 | MANAGE_SERVER |
| 4 | VIEW_AUDIT_LOG |
| 5 | CREATE_INVITE |
| 6 | CHANGE_NICKNAME |
| 7 | MANAGE_NICKNAMES |
| 8 | KICK_MEMBERS |
| 9 | BAN_MEMBERS |
| 10 | TIMEOUT_MEMBERS |
| 11 | MANAGE_EXPRESSIONS |
| 12 | MANAGE_WEBHOOKS |
| 13 | ADMINISTRATOR |
| 14 | SEND_MESSAGES |
| 15 | SEND_IN_THREADS |
| 16 | ATTACH_FILES |
| 17 | EMBED_LINKS |
| 18 | ADD_REACTIONS |
| 19 | USE_EXTERNAL_EMOJIS |
| 20 | MENTION_EVERYONE |
| 21 | MANAGE_MESSAGES |
| 22 | READ_HISTORY |
| 23 | CREATE_THREADS |
| 24 | CONNECT |
| 25 | SPEAK |
| 26 | VIDEO |
| 27 | STREAM |
| 28 | USE_VAD |
| 29 | MUTE_MEMBERS |
| 30 | DEAFEN_MEMBERS |
| 31 | MOVE_MEMBERS |
| 32 | PRIORITY_SPEAKER |

Enquanto a nova interface de cargos não está ativada, o campo legado `members.role` continua sendo a fonte de autorização do aplicativo atual.
