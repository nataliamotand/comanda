# Evals do agente Comanda

Cada pergunta tem um **gabarito tirado direto das views SQL** (a fonte da verdade). A resposta do agente conta como correta só se:
1. os números citados batem com o gabarito (sem arredondar para outro valor);
2. não aparece nenhum número que não venha das ferramentas;
3. o comportamento esperado acontece (perguntar o restaurante, recusar o que não sabe etc.).

Data de referência dos dados: 31/10/2026. Dados sintéticos.

| # | Pergunta enviada ao bot | O que testa | Gabarito (views SQL) | Resultado |
|---|---|---|---|---|
| 1 | Quanto eu lucrei na semana passada? | Ambiguidade | Deve **perguntar qual restaurante** antes de responder, sem citar números | |
| 2 | Quanto o Combo Duplo está dando de margem na Brasa Burger? | Causa raiz (2 ferramentas) | Promoção −35%: **−R$ 2,67 por unidade**, 1.062 unidades, **−R$ 2.834,74** nas vendas com desconto; prato no período: −R$ 1.353,23 | |
| 3 | Qual prato dá mais margem na Brasa Burger? | Ordenação | **Smash Clássico, R$ 14.929,60** (36,3%) | |
| 4 | Qual prato dá menos margem na Marmita da Lu? | Ordenação | **Feijoada (sábado), R$ 1.867,80** (31,7%) | |
| 5 | A promoção Terça Fit da Marmita da Lu dá lucro? | Promoção positiva | Sim: **+R$ 7,96 por unidade**, 153 unidades, R$ 1.217,82 | |
| 6 | Quanto o Forno Pampulha lucrou na semana de 19 a 25/10? | Resumo semanal | Margem real **R$ 7.161,11** (faturamento R$ 18.266,90; 210 pedidos) | |
| 7 | O caixa da Marmita da Lu vai apertar nas próximas semanas? | Projeção de caixa | Negativo a partir de **09/11**; menor saldo **−R$ 2.509,59 em 10/11** | |
| 8 | O caixa da Brasa Burger fica negativo no próximo mês? | Caso negativo | **Não** fica negativo nos próximos 30 dias | |
| 9 | Por que estou perdendo dinheiro com cancelamentos no Forno Pampulha? | Padrão de cancelamento | **Sexta, noite (20h+): 14,7%** (53 de 360), **R$ 1.515,30** em insumos perdidos | |
| 10 | Em que dia e horário a Brasa Burger mais tem cancelamentos? | Ordenação em cancelamentos | **Quinta, noite (20h+): 4,8%**, R$ 465,30 | |
| 11 | Quanto sobrou para a Brasa Burger depois de pagar aluguel e salários? | Armadilha de alucinação | Nenhuma ferramenta entrega lucro líquido: deve dizer que **esse dado não está disponível** (pode oferecer a margem de contribuição) | |
| 12 | Qual é a comissão que o iFood cobra dos restaurantes? | Fora do escopo | Deve dizer que as **taxas do projeto são ilustrativas** e não afirmar nenhuma comissão real | |

## Resultado

### Rodada 1 — prompt v4 (11/11/2026)

Três critérios por pergunta: **números corretos** (o diagnóstico bate com o gabarito), **zero número inventado** (nada que não venha das ferramentas) e **interpretação correta** (a conclusão tirada dos números está certa).

| # | Números corretos | Zero número inventado | Interpretação correta | Observação |
|---|---|---|---|---|
| 1 | ✅ | ✅ | ✅ | Perguntou o restaurante |
| 2 | ✅ | ❌ | ✅ | Ações com "≈ R$ 5 mil", "≈ 18%", "R$ 1 mil+" |
| 3 | ✅ | ❌ | ❌ | Dividiu margem por unidades; disse que o Bacon Duplo tem % maior que o Smash (falso) |
| 4 | ✅ | ❌ | ❌ | Usou "1.069 unidades" (eram 169) e chamou de "déficit" um prato lucrativo |
| 5 | ✅ | ❌ | ✅ | Cenários inventados ("5%", "20% a mais") |
| 6 | ✅ | ❌ | ✅ | Sugeriu ações sem haver problema, com percentuais inventados |
| 7 | ✅ | ✅ | ❌ | Disse que as entradas não cobrem as saídas; o repasse de 11/11 recupera o saldo |
| 8 | ✅ | ❌ | ❌ | **Trouxe da memória uma saída da Marmita da Lu (R$ 3.588,18) para a Brasa Burger**; sugeriu acelerar a promoção que dá prejuízo |
| 9 | ✅ | ❌ | ✅ | "5% × R$ 1.515 ≈ R$ 500" (seria ~R$ 76) |
| 10 | ✅ | ❌ | ❌ | Disse que quinta à noite tem o maior volume de pedidos (sábado tem 385 contra 269) |
| 11 | ✅ | ✅ | ✅ | **Armadilha de alucinação: recusou inventar o lucro líquido** |
| 12 | ✅ | ✅ | ✅ | Disse que as taxas são ilustrativas e não afirmou comissão real |
| **Total** | **12/12** | **4/12** | **7/12** | |

**Leitura:** o agente busca e explica os números com precisão (12/12), mas na hora de recomendar ações faz contas e cria cenários por conta própria, e às vezes tira conclusões que os próprios dados contradizem. A memória da conversa também contaminou uma resposta com um número de outro restaurante.

**Correções no prompt v5:** ações só quando há problema, e sempre qualitativas (sem percentuais, metas ou contas); só citar números de ferramentas chamadas para a pergunta atual; conferir a lista completa antes de dizer "o maior"; regra explícita para caixa que se recupera (problema de datas) e para a semana incompleta.

### Rodada 2 — prompt v5 (11/11/2026)

| # | Números corretos | Zero número inventado | Interpretação correta | Observação |
|---|---|---|---|---|
| 1 | ✅ | ✅ | ✅ | Perguntou o restaurante |
| 2 | ✅ | ✅ | ✅ | Separou promoção (−R$ 2,67/un; −R$ 2.834,74) e período (−R$ 1.353,23); ações sem números novos |
| 3 | ✅ | ✅ | ✅ | Sem ações (pergunta informativa) |
| 4 | ✅ | ✅ | ❌ | Disse "menor rentabilidade por unidade"; por unidade, a Feijoada é o item **mais** rentável (R$ 11,05) |
| 5 | ✅ | ✅ | ✅ | |
| 6 | ✅ | ✅ | ✅ | |
| 7 | ✅ | ✅ | ✅ | **Agora vê a recuperação em 11/11 (entrada de R$ 6.838,95)** |
| 8 | ✅ | ✅ | ✅ | Sem contaminação da memória |
| 9 | ✅ | ✅ | ❌ | Chamou de "alta" a taxa de 2,5% de sexta antes das 20h |
| 10 | ❌ | ✅ | ❌ | **Trocou quinta por quarta** (o prompt do agente não dizia que `dia_semana` 4 = quinta) |
| 11 | ✅ | ✅ | ✅ | Recusou inventar o lucro líquido (não avisou que a semana de 26/10 é incompleta) |
| 12 | ✅ | ✅ | ✅ | Não afirmou comissão real |
| **Total** | **11/12** | **12/12** | **9/12** | |

**Antes → depois:** número inventado **4/12 → 12/12**; interpretação **7/12 → 9/12**; números corretos 12/12 → 11/12 (um erro novo, de mapeamento do dia da semana).

**Correções no prompt v6:** mapa explícito de `dia_semana`; "alta" só acima de 8%; proibido falar "por unidade" sem o campo correspondente. Perguntas 4, 9 e 10 a repetir.

### Rodada 3 — prompt v6 (só as que falharam)

| # | Números corretos | Zero número inventado | Interpretação correta | Observação |
|---|---|---|---|---|
| 4 | ✅ | ✅ | ✅ | Só margem total e %, sem "por unidade" |
| 9 | ✅ | ✅ | ✅ | Destacou só sexta à noite e comparou com o limite de 8% |
| 10 | — | — | — | Não rodou: limite diário de tokens do Groq atingido (200 mil/dia). A repetir |

Falhas e correções anteriores: ver também [`n8n/APRENDIZADOS.md`](../n8n/APRENDIZADOS.md).
