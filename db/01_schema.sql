-- =============================================================
-- Comanda — copiloto financeiro do restaurante
-- Schema (PostgreSQL / Supabase)
-- Todos os dados são SINTÉTICOS; taxas são ILUSTRATIVAS e configuráveis.
-- =============================================================

-- tudo no schema public (o Supabase expõe o public na API REST)
-- pode rodar de novo sem medo: apaga e recria tudo
drop table if exists feedback_recomendacoes, repasses, despesas, itens_pedido,
  pedidos, promocoes, pratos, restaurantes, parametros cascade;
drop function if exists hoje();

-- Restaurante parceiro e suas condições (ilustrativas)
create table restaurantes (
  id               int primary key,
  nome             text not null,
  tipo             text not null,             -- hamburgueria, marmitaria, pizzaria...
  cidade           text not null,
  comissao_pct     numeric(5,4) not null,     -- comissão da plataforma sobre o subtotal
  taxa_pgto_pct    numeric(5,4) not null,     -- taxa de pagamento online
  prazo_repasse_d  int not null,              -- dias entre o fechamento semanal e o repasse
  saldo_inicial    numeric(12,2) not null     -- saldo em conta no início do período
);

-- Cardápio com custo unitário de insumos (o dono informa)
create table pratos (
  id              int primary key,
  restaurante_id  int not null references restaurantes(id),
  nome            text not null,
  categoria       text not null,
  preco           numeric(10,2) not null,
  custo_unitario  numeric(10,2) not null
);

-- Promoções ativas no período
create table promocoes (
  id              int primary key,
  restaurante_id  int not null references restaurantes(id),
  nome            text not null,
  prato_id        int references pratos(id),  -- prato em promoção (null = pedido todo)
  desconto_pct    numeric(5,4) not null,
  inicio          date not null,
  fim             date not null
);

create table pedidos (
  id              bigint primary key,
  restaurante_id  int not null references restaurantes(id),
  criado_em       timestamp not null,
  status          text not null check (status in ('entregue','cancelado')),
  promocao_id     int references promocoes(id),
  subtotal        numeric(10,2) not null,     -- soma dos itens a preço cheio
  desconto        numeric(10,2) not null default 0
);

create table itens_pedido (
  pedido_id   bigint not null references pedidos(id),
  prato_id    int not null references pratos(id),
  qtd         int not null,
  preco_unit  numeric(10,2) not null,
  desconto    numeric(10,2) not null default 0,
  primary key (pedido_id, prato_id)
);

-- Despesas fixas e variáveis fora da plataforma (realizadas e agendadas)
create table despesas (
  id              bigint primary key,
  restaurante_id  int not null references restaurantes(id),
  data            date not null,
  categoria       text not null,              -- aluguel, folha, insumos, energia, outros
  descricao       text,
  valor           numeric(12,2) not null,
  agendada        boolean not null default false  -- true = futura (ainda não paga)
);

-- Repasses da plataforma para o restaurante (realizados e previstos)
create table repasses (
  id              bigint primary key,
  restaurante_id  int not null references restaurantes(id),
  semana_ref      date not null,              -- segunda-feira da semana de vendas
  data_prevista   date not null,
  valor           numeric(12,2) not null,
  realizado       boolean not null
);

-- Loop de feedback: o dono avalia cada recomendação do agente
create table feedback_recomendacoes (
  id              bigserial primary key,
  restaurante_id  int not null references restaurantes(id),
  criado_em       timestamp not null default now(),
  recomendacao    text not null,
  util            boolean,
  comentario      text
);

-- Data de referência do "hoje" na simulação
create table parametros (chave text primary key, valor text not null);
