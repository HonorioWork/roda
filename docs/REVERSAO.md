# Reverter esta atualização

Para reversão rápida, publique novamente a versão anterior de `index.html` e `sw.js`. As tabelas e colunas adicionadas podem permanecer no banco porque não mudam o comportamento do cliente anterior.

Não remova tabelas ou colunas durante uma emergência. A exclusão física só deve acontecer depois de confirmar que nenhum cliente as utiliza e de criar um backup.

# Configuração de voz via Vault (2026-11-03)

Para reverter somente a leitura protegida das credenciais de voz:

```sql
drop function if exists public.roda_voice_config();
select vault.delete_secret(id)
from vault.secrets
where name in ('roda_livekit_url', 'roda_livekit_key', 'roda_livekit_secret');
```

