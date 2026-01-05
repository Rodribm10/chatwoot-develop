# Fix: assets antigos por volume em /app/public

## Sintoma
- Build da imagem passava, mas o front em producao (arm64) nao mostrava mudancas novas.
- Dentro do container, o codigo fonte tinha os componentes novos, mas os assets servidos nao tinham as alteracoes.

## Causa
- O stack montava um volume em `/app/public`, sobrescrevendo os assets gerados na imagem.
- Resultado: mesmo com imagem nova, o container servia assets antigos do volume.

## Como confirmar
No container:
- `grep -R -n "i-lucide-brain" /app/public 2>/dev/null | head -n 5`
  - Se nao retorna nada, os assets no volume estao desatualizados.

No Portainer (Inspect do container):
- Ver se existe mount com `Destination: /app/public`.

## Resolucao (Portainer)
1. Portainer -> Stacks -> `chatwoot-wuzapi` -> **Stop**.
2. Portainer -> Volumes -> remover `chatwoot-wuzapi_chatwoot_public`.
3. Portainer -> Stacks -> **Start/Deploy**.
4. Validar no front se as mudancas apareceram.

## Observacoes
- `assets:precompile` nao roda no container final (nao tem pnpm/vite). Os assets devem vir prontos da imagem.
- Se precisar manter volume, e necessario copiar os assets da imagem para o volume na hora do deploy.

## Prevencao
- Evitar montar volume em `/app/public` em producao, a menos que exista processo explicito para atualizar os assets.
