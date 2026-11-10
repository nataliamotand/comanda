# Workflows do n8n

| Arquivo | O que faz |
|---|---|
| `comanda-agente.json` | Agente no Telegram: o dono pergunta em linguagem natural, o agente (Groq · `openai/gpt-oss-120b`) chama as views do Supabase como ferramentas e responde citando a fonte |
| `comanda-relatorio-semanal.json` | Toda segunda às 8h: busca as métricas, monta a "comanda da semana" de cada restaurante (números formatados por código, sem LLM) e pede à IA só a seção "Atenção esta semana" |
| `prompt_agente.md` | Prompt de sistema do agente (o mesmo que está dentro do workflow) |

## Princípio
**Quem calcula é o código, quem explica é a IA.** O LLM nunca soma nem estima valores: o agente só cita números devolvidos pelas ferramentas, e no relatório a comanda inteira é montada por código antes de a IA escrever as recomendações.

## Credenciais necessárias (criadas no n8n, nunca no repositório)
| Credencial | Tipo no n8n | Conteúdo |
|---|---|---|
| Supabase | **Custom Auth** | `{"headers": {"apikey": "<service_role>", "Authorization": "Bearer <service_role>"}}` |
| Groq | **Groq** | API key do console.groq.com |
| Telegram | **Telegram** | Token do bot do @BotFather |

Os workflows exportados neste repositório **não contêm chaves**: ao importar, selecione as credenciais em cada nó.
