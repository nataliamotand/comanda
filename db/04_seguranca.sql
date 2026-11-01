-- =============================================================
-- Comanda — segurança (Row Level Security)
-- Sem isso, qualquer pessoa com a chave pública (anon) poderia apagar dados.
--  * Tabelas: RLS ligado e sem política => a chave pública NÃO lê nem escreve.
--  * Views de métricas: leitura pública (só agregados de dados sintéticos).
--  * Feedback: a chave pública só pode INSERIR avaliações.
--  * O n8n usa a chave secreta (service_role), que ignora o RLS.
-- =============================================================

alter table restaurantes           enable row level security;
alter table pratos                 enable row level security;
alter table promocoes              enable row level security;
alter table pedidos                enable row level security;
alter table itens_pedido           enable row level security;
alter table despesas               enable row level security;
alter table repasses               enable row level security;
alter table parametros             enable row level security;
alter table feedback_recomendacoes enable row level security;

-- leitura pública só dos nomes dos restaurantes (para o dashboard)
create policy "leitura publica restaurantes" on restaurantes
  for select to anon, authenticated using (true);

-- o dashboard pode registrar feedback, mas não ler nem apagar
create policy "inserir feedback" on feedback_recomendacoes
  for insert to anon, authenticated with check (true);

-- views de métricas: somente leitura
revoke all on v_item_economia, v_margem_prato, v_promocao_resultado, v_resumo_semanal,
  v_cancelamentos, v_fluxo_caixa, v_alerta_caixa from anon, authenticated;
grant select on v_margem_prato, v_promocao_resultado, v_resumo_semanal,
  v_cancelamentos, v_fluxo_caixa, v_alerta_caixa to anon, authenticated;

-- permite gerar o id automático do feedback
grant usage on sequence feedback_recomendacoes_id_seq to anon, authenticated;
