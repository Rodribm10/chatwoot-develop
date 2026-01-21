---
description: interface_frontend
---

## Regra de Ouro de UI e i18n

Nunca entregue ou sugira código de interface (Frontend) sem garantir que TODAS as strings visíveis tenham suas chaves de tradução devidamente criadas nos arquivos de locale (pt_BR e en). É proibido deixar chaves cruas (ex: `CAPTAIN.BRANDS...`) ou textos hardcoded na UI. Se criar uma nova feature, crie o arquivo JSON de tradução correspondente imediatamente.
