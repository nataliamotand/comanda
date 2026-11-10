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

_(preencher depois da rodada)_

Acurácia: __ de 12.

Falhas encontradas e o que foi feito: ver também [`n8n/APRENDIZADOS.md`](../n8n/APRENDIZADOS.md).
