# Aprendizados dos primeiros testes do agente (10/11/2026)

Testes manuais no Telegram com as 3 perguntas dos padrões plantados. Cada falha virou uma regra no prompt e, depois, um caso de eval.

| # | O que o agente fez de errado | Por que é grave | Correção |
|---|---|---|---|
| 1 | Inventou metas nas recomendações ("elevar a margem em R$ 200 por dia", "corte de R$ 300 cobre a perda") | Quebra a regra "quem calcula é o código"; a conta nem fechava | Regra: recomendações só citam números vindos das ferramentas; proibido criar metas, preços ou percentuais |
| 2 | Respondeu a margem do Combo Duplo sem olhar a promoção | Perdeu a causa real: −R$ 2,67 por unidade com desconto | Regra: sempre que consultar margem por prato, consultar também resultado das promoções |
| 3 | Misturou a margem só das vendas com desconto (−R$ 2.834,74) com a margem do prato no período (−R$ 1.353,23) | Número certo, rótulo errado: o dono tomaria decisão errada | Regra: dizer de qual total está falando |
| 4 | Afirmou que o desconto "supera a receita" | Comparação falsa | Regra: só comparar valores do mesmo tipo |
| 5 | Repetiu a resposta errada mesmo depois do prompt corrigido | A memória da conversa guardava a resposta antiga | Versionar a chave de sessão da memória a cada mudança de prompt |
| 6 | Bot ficou mudo | Limite de tokens por minuto do plano gratuito do Groq | Retry automático (3 tentativas, 5 s) e janela de memória menor (10 → 4) |
| 7 | Relatório semanal com datas em ISO, números sem formato e dia trocado no alerta de caixa | O LLM reformatava números crus | O código entrega os fatos já formatados (R$, dd/mm, período); a IA só copia e explica |
| 8 | Nos evals (rodada 1), 8 de 12 respostas tinham contas ou cenários inventados nas ações | O padrão estava nas recomendações, não no diagnóstico | Ações qualitativas, sem percentuais, metas ou contas; só quando há problema |
| 9 | Citou para a Brasa Burger uma saída de caixa da Marmita da Lu | A memória da conversa contaminou a resposta | Só citar números de ferramentas chamadas para a pergunta atual |
| 10 | Trocou quinta por quarta | O prompt do agente não explicava a codificação `dia_semana` (1 = segunda) | Mapa explícito no prompt; lição: documentar para o modelo o significado de cada código |
| 11 | Cota diária do Groq esgotada no meio dos testes | 200 mil tokens/dia no plano gratuito | Espaçar testes; registrar a limitação no README |

Resolvidos na rodada 2: o agente passou a ver a recuperação do caixa da Marmita da Lu em 11/11.
