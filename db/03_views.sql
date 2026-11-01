-- =============================================================
-- Comanda — camada de métricas (determinística)
-- Princípio do projeto: QUEM CALCULA É O SQL; o LLM só interpreta e explica.
-- Cada view vira um endpoint REST no Supabase, que o agente consome como ferramenta.
-- =============================================================
-- schema public

insert into parametros values ('hoje', '2026-10-31')
on conflict (chave) do update set valor = excluded.valor;

-- security definer: a função lê 'parametros' com permissão do dono,
-- assim funciona também quando o dashboard consulta com a chave pública
create or replace function hoje() returns date
language sql stable security definer set search_path = public as
$$ select valor::date from public.parametros where chave = 'hoje' $$;

-- 1) Economia de cada item vendido: do preço cheio até a margem de contribuição
create or replace view v_item_economia as
select
  p.id                          as pedido_id,
  p.restaurante_id,
  p.criado_em,
  p.criado_em::date             as dia,
  p.status,
  i.prato_id,
  pr.nome                       as prato,
  i.qtd,
  i.preco_unit * i.qtd          as receita_bruta,
  i.desconto,
  case when p.status = 'entregue' then i.preco_unit * i.qtd - i.desconto else 0 end
                                as receita_liquida,
  case when p.status = 'entregue'
       then (i.preco_unit * i.qtd - i.desconto) * r.comissao_pct else 0 end
                                as comissao,
  case when p.status = 'entregue'
       then (i.preco_unit * i.qtd - i.desconto) * r.taxa_pgto_pct else 0 end
                                as taxa_pgto,
  pr.custo_unitario * i.qtd     as custo_insumos   -- consumido mesmo se cancelado
from pedidos p
join itens_pedido i on i.pedido_id = p.id
join pratos pr      on pr.id = i.prato_id
join restaurantes r on r.id = p.restaurante_id;

-- 2) Margem real por prato (todo o período)
create or replace view v_margem_prato as
select
  restaurante_id,
  prato_id,
  prato,
  sum(qtd) filter (where status = 'entregue')                     as unidades_vendidas,
  round(sum(receita_bruta) filter (where status = 'entregue'), 2) as receita_bruta,
  round(sum(desconto) filter (where status = 'entregue'), 2)      as descontos,
  round(sum(comissao + taxa_pgto), 2)                             as taxas_plataforma,
  round(sum(custo_insumos), 2)                                    as custo_insumos,
  round(sum(receita_liquida - comissao - taxa_pgto - custo_insumos), 2)
                                                                  as margem_contribuicao,
  round(100 * sum(receita_liquida - comissao - taxa_pgto - custo_insumos)
        / nullif(sum(receita_liquida), 0), 1)                     as margem_pct
from v_item_economia
group by restaurante_id, prato_id, prato;

-- 3) Resultado de cada promoção, por unidade vendida
create or replace view v_promocao_resultado as
select
  pm.restaurante_id,
  pm.id                                         as promocao_id,
  pm.nome                                       as promocao,
  pm.desconto_pct,
  sum(e.qtd)                                    as unidades_vendidas,
  round(sum(e.desconto), 2)                     as desconto_total,
  round(sum(e.receita_liquida - e.comissao - e.taxa_pgto - e.custo_insumos), 2)
                                                as margem_contribuicao,
  round(sum(e.receita_liquida - e.comissao - e.taxa_pgto - e.custo_insumos)
        / nullif(sum(e.qtd), 0), 2)             as margem_por_unidade
from promocoes pm
join v_item_economia e
  on e.restaurante_id = pm.restaurante_id
 and e.prato_id = pm.prato_id
 and e.desconto > 0
 and e.status = 'entregue'
group by pm.restaurante_id, pm.id, pm.nome, pm.desconto_pct;

-- 4) Resumo semanal (o "fechamento" que o dono faria na planilha)
create or replace view v_resumo_semanal as
select
  restaurante_id,
  date_trunc('week', dia)::date                                    as semana,
  count(distinct pedido_id) filter (where status = 'entregue')      as pedidos_entregues,
  count(distinct pedido_id) filter (where status = 'cancelado')     as pedidos_cancelados,
  round(sum(receita_bruta) filter (where status = 'entregue'), 2)   as faturamento_bruto,
  round(sum(desconto) filter (where status = 'entregue'), 2)        as descontos,
  round(sum(comissao + taxa_pgto), 2)                               as taxas_plataforma,
  round(sum(custo_insumos), 2)                                      as custo_insumos,
  round(sum(receita_liquida - comissao - taxa_pgto - custo_insumos), 2)
                                                                    as margem_contribuicao
from v_item_economia
group by restaurante_id, date_trunc('week', dia);

-- 5) Cancelamentos por dia da semana e turno
create or replace view v_cancelamentos as
select
  restaurante_id,
  extract(isodow from criado_em)::int                       as dia_semana,  -- 1=seg ... 7=dom
  case when extract(hour from criado_em) >= 20 then 'noite (20h+)' else 'antes das 20h' end
                                                            as turno,
  count(*)                                                  as pedidos,
  count(*) filter (where status = 'cancelado')              as cancelados,
  round(100.0 * count(*) filter (where status = 'cancelado') / count(*), 1)
                                                            as taxa_cancelamento_pct,
  round(sum(case when status = 'cancelado' then custo else 0 end), 2)
                                                            as insumos_perdidos
from (
  select p.restaurante_id, p.criado_em, p.status,
         sum(pr.custo_unitario * i.qtd) as custo
  from pedidos p
  join itens_pedido i on i.pedido_id = p.id
  join pratos pr on pr.id = i.prato_id
  group by p.id, p.restaurante_id, p.criado_em, p.status
) x
group by restaurante_id, 2, 3;

-- 6) Fluxo de caixa: saldo de hoje + projeção diária dos próximos 30 dias
--    Entradas: repasses já previstos + repasses futuros estimados pela média das 4 últimas semanas
--    Saídas:   despesas agendadas + insumos futuros estimados pela média das 4 últimas semanas
create or replace view v_fluxo_caixa as
with r as (select * from restaurantes),
saldo_hoje as (
  select r.id as restaurante_id,
         r.saldo_inicial
         + coalesce((select sum(valor) from repasses x
                     where x.restaurante_id = r.id and x.realizado), 0)
         - coalesce((select sum(valor) from despesas d
                     where d.restaurante_id = r.id and not d.agendada), 0) as saldo
  from r
),
medias as (
  select r.id as restaurante_id,
         (select avg(valor) from (select valor from repasses x
            where x.restaurante_id = r.id and x.realizado
            order by data_prevista desc limit 4) a) as repasse_medio,
         (select avg(valor) from (select valor from despesas d
            where d.restaurante_id = r.id and d.categoria = 'insumos' and not d.agendada
            order by data desc limit 4) b) as insumos_medio
  from r
),
dias as (
  select r.id as restaurante_id, g::date as dia
  from r, generate_series(hoje() + 1, hoje() + 30, interval '1 day') g
),
movimentos as (
  select d.restaurante_id, d.dia,
    -- repasses já calculados (semanas vendidas, ainda não pagas)
    coalesce((select sum(valor) from repasses x
              where x.restaurante_id = d.restaurante_id and not x.realizado
                and x.data_prevista = d.dia), 0)
    -- repasses estimados de semanas futuras (quartas após o último repasse conhecido)
    + case when extract(isodow from d.dia) = 3
            and d.dia > (select max(data_prevista) from repasses x
                         where x.restaurante_id = d.restaurante_id)
           then m.repasse_medio else 0 end                          as entradas,
    coalesce((select sum(valor) from despesas e
              where e.restaurante_id = d.restaurante_id and e.agendada
                and e.data = d.dia), 0)
    + case when extract(isodow from d.dia) = 1
            and d.dia > (select max(data) from despesas e
                         where e.restaurante_id = d.restaurante_id and e.categoria = 'insumos')
           then m.insumos_medio else 0 end                          as saidas
  from dias d join medias m using (restaurante_id)
)
select
  mv.restaurante_id,
  mv.dia,
  round(mv.entradas, 2) as entradas,
  round(mv.saidas, 2)   as saidas,
  round(s.saldo + sum(mv.entradas - mv.saidas)
        over (partition by mv.restaurante_id order by mv.dia), 2) as saldo_projetado
from movimentos mv join saldo_hoje s using (restaurante_id);

-- 7) Alerta de caixa: primeiro dia em que o saldo projetado fica negativo
create or replace view v_alerta_caixa as
select restaurante_id,
       min(dia) filter (where saldo_projetado < 0) as primeiro_dia_negativo,
       min(saldo_projetado)                        as menor_saldo_projetado,
       (array_agg(dia order by saldo_projetado))[1] as dia_menor_saldo
from v_fluxo_caixa
group by restaurante_id;
