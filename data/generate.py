"""
Comanda — gerador de dados SINTÉTICOS de 3 restaurantes em BH.

Gera 90 dias de pedidos (03/08/2026 a 31/10/2026), despesas, repasses e
despesas agendadas para novembro. Taxas e prazos são ILUSTRATIVOS.

Três padrões foram "plantados" de propósito, para servirem de gabarito
na avaliação do agente (evals):
  1. Brasa Burger: a promoção "Combo Duplo -35%" vira campeã de vendas,
     mas tem margem de contribuição NEGATIVA por pedido.
  2. Marmita da Lu: margem saudável, mas o caixa fica NEGATIVO em
     novembro por causa de aluguel + folha concentrados.
  3. Forno Pampulha: cancelamentos muito acima da média nas noites de
     sexta, com perda de insumos.

Uso:
    python generate.py            -> escreve CSVs em ./out e ./out/seed.sql
"""
import csv
import os
import random
from datetime import date, datetime, timedelta

random.seed(42)

INICIO = date(2026, 8, 3)        # segunda-feira
HOJE = date(2026, 10, 31)        # "hoje" da simulação (sábado)
FIM_PROJECAO = date(2026, 11, 30)
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")

# ---------------------------------------------------------------- cadastro
RESTAURANTES = [
    # id, nome, tipo, cidade, comissao, taxa_pgto, prazo_repasse, saldo_inicial
    (1, "Brasa Burger", "hamburgueria", "Belo Horizonte", 0.23, 0.032, 2, 15000.00),
    (2, "Marmita da Lu", "marmitaria", "Belo Horizonte", 0.23, 0.032, 2, 12800.00),
    (3, "Forno Pampulha", "pizzaria", "Belo Horizonte", 0.23, 0.032, 2, 15000.00),
]

PRATOS = [
    # id, restaurante, nome, categoria, preco, custo_unitario, peso_popularidade
    (101, 1, "Smash Clássico", "burger", 34.90, 12.80, 30),
    (102, 1, "Bacon Duplo", "burger", 42.90, 17.50, 22),
    (103, 1, "Veggie Grão", "burger", 36.90, 13.90, 8),
    (104, 1, "Combo Duplo (2 burgers + fritas + 2 bebidas)", "combo", 79.90, 41.00, 10),
    (105, 1, "Fritas Rústicas", "acompanhamento", 18.90, 4.20, 20),
    (106, 1, "Milkshake", "bebida", 21.90, 6.80, 10),

    (201, 2, "Marmita Executiva Frango", "marmita", 24.90, 9.10, 35),
    (202, 2, "Marmita Executiva Carne", "marmita", 27.90, 11.40, 28),
    (203, 2, "Marmita Fit", "marmita", 29.90, 11.90, 15),
    (204, 2, "Feijoada (sábado)", "marmita", 34.90, 14.20, 0),
    (205, 2, "Suco Natural", "bebida", 9.90, 2.60, 22),

    (301, 3, "Pizza Margherita G", "pizza", 59.90, 18.50, 25),
    (302, 3, "Pizza Calabresa G", "pizza", 62.90, 19.80, 30),
    (303, 3, "Pizza Quatro Queijos G", "pizza", 72.90, 26.40, 18),
    (304, 3, "Pizza Doce Brigadeiro M", "pizza", 44.90, 13.10, 10),
    (305, 3, "Refrigerante 2L", "bebida", 15.90, 7.20, 17),
]

PROMOCOES = [
    # id, restaurante, nome, prato_id, desconto_pct, inicio, fim
    (1, 1, "Combo Duplo -35%", 104, 0.35, date(2026, 9, 7), date(2026, 11, 30)),
    (2, 2, "Terça Fit -10%", 203, 0.10, date(2026, 8, 3), date(2026, 11, 30)),
    (3, 3, "Pizza Doce -20% no domingo", 304, 0.20, date(2026, 8, 3), date(2026, 11, 30)),
]

# pedidos/dia médios e multiplicador por dia da semana (seg=0 ... dom=6)
DEMANDA = {
    1: (34, [0.7, 0.75, 0.85, 0.95, 1.35, 1.5, 1.3]),
    2: (42, [1.15, 1.15, 1.1, 1.1, 1.05, 0.75, 0.0]),   # marmitaria não abre domingo
    3: (30, [0.6, 0.65, 0.75, 0.9, 1.5, 1.55, 1.4]),
}
# janelas de horário (hora inicial, hora final)
HORARIO = {1: (18, 23), 2: (11, 14), 3: (18, 23)}

DESPESAS_FIXAS = {
    # categoria: (dia do mês, valor)
    1: [("aluguel", 5, 4000.0), ("folha", 5, 4500.0), ("folha", 20, 1800.0), ("energia", 10, 900.0)],
    2: [("aluguel", 5, 3800.0), ("folha", 5, 6200.0), ("folha", 20, 3200.0), ("energia", 10, 900.0)],
    3: [("aluguel", 5, 5200.0), ("folha", 5, 8200.0), ("folha", 20, 3500.0), ("energia", 10, 2600.0)],
}


def daterange(a, b):
    d = a
    while d <= b:
        yield d
        d += timedelta(days=1)


def segunda(d):
    return d - timedelta(days=d.weekday())


def promo_ativa(rest_id, d, prato_id):
    for p in PROMOCOES:
        pid, rid, _, prato, desc, ini, fim = p
        if rid == rest_id and prato == prato_id and ini <= d <= fim:
            # promoções de dia específico
            if pid == 2 and d.weekday() != 1:
                continue
            if pid == 3 and d.weekday() != 6:
                continue
            return pid, desc
    return None, 0.0


def main():
    os.makedirs(OUT, exist_ok=True)
    rest = {r[0]: r for r in RESTAURANTES}
    pratos_por_rest = {}
    for p in PRATOS:
        pratos_por_rest.setdefault(p[1], []).append(p)

    pedidos, itens = [], []
    custo_insumos_semana = {}   # (rest, segunda) -> custo de insumos consumidos
    liquido_semana = {}         # (rest, segunda) -> valor a repassar
    pid_seq = 1

    for d in daterange(INICIO, HOJE):
        for rid, (base, mult) in DEMANDA.items():
            m = mult[d.weekday()]
            if m == 0:
                continue
            n = max(0, int(random.gauss(base * m, base * m * 0.12)))
            cardapio = [p for p in pratos_por_rest[rid]
                        if not (p[0] == 204 and d.weekday() != 5)]
            pesos = []
            for p in cardapio:
                w = p[6] if p[0] != 204 else 40
                # efeito da promoção do combo: vira campeão de vendas
                if p[0] == 104 and d >= date(2026, 9, 7):
                    w = 55
                pesos.append(w)
            for _ in range(n):
                h0, h1 = HORARIO[rid]
                hora = random.randint(h0, h1 - 1)
                ts = datetime(d.year, d.month, d.day, hora, random.randint(0, 59))

                # cancelamento: base 3%; pizzaria na sexta à noite 14%
                p_cancel = 0.03
                if rid == 3 and d.weekday() == 4 and hora >= 20:
                    p_cancel = 0.14
                status = "cancelado" if random.random() < p_cancel else "entregue"

                k = random.choices([1, 2, 3], weights=[55, 35, 10])[0]
                escolhidos = {}
                for p in random.choices(cardapio, weights=pesos, k=k):
                    escolhidos[p[0]] = escolhidos.get(p[0], 0) + 1

                subtotal = desconto = custo = 0.0
                promo_pedido = None
                linhas = []
                for prato_id, qtd in escolhidos.items():
                    p = next(x for x in cardapio if x[0] == prato_id)
                    promo_id, desc_pct = promo_ativa(rid, d, prato_id)
                    bruto = p[4] * qtd
                    dsc = round(bruto * desc_pct, 2)
                    if promo_id:
                        promo_pedido = promo_id
                    subtotal += bruto
                    desconto += dsc
                    custo += p[5] * qtd
                    linhas.append((pid_seq, prato_id, qtd, p[4], dsc))

                pedidos.append((pid_seq, rid, ts.isoformat(sep=" "), status,
                                promo_pedido if promo_pedido else "",
                                round(subtotal, 2), round(desconto, 2)))
                itens.extend(linhas)

                sem = segunda(d)
                # insumo é consumido mesmo se cancelado (pedido já preparado)
                custo_insumos_semana[(rid, sem)] = custo_insumos_semana.get((rid, sem), 0) + custo
                if status == "entregue":
                    r = rest[rid]
                    receita = subtotal - desconto
                    liq = receita * (1 - r[4] - r[5])
                    liquido_semana[(rid, sem)] = liquido_semana.get((rid, sem), 0) + liq
                pid_seq += 1

    # ------------------------------------------------------------ repasses
    repasses = []
    rep_id = 1
    for (rid, sem), valor in sorted(liquido_semana.items(), key=lambda x: (x[0][1], x[0][0])):
        data_prev = sem + timedelta(days=7 + rest[rid][6])   # quarta da semana seguinte
        repasses.append((rep_id, rid, sem.isoformat(), data_prev.isoformat(),
                         round(valor, 2), data_prev <= HOJE))
        rep_id += 1

    # ------------------------------------------------------------ despesas
    despesas = []
    dep_id = 1
    for rid, fixas in DESPESAS_FIXAS.items():
        for d in daterange(INICIO, FIM_PROJECAO):
            for cat, dia, valor in fixas:
                if d.day == dia:
                    v = valor if cat != "energia" else round(valor * random.uniform(0.9, 1.1), 2)
                    despesas.append((dep_id, rid, d.isoformat(), cat,
                                     f"{cat} {d.strftime('%m/%Y')}", v, d > HOJE))
                    dep_id += 1
        # compra semanal de insumos (paga na segunda seguinte)
        for (r2, sem), custo in sorted(custo_insumos_semana.items()):
            if r2 != rid:
                continue
            pago = sem + timedelta(days=7)
            despesas.append((dep_id, rid, pago.isoformat(), "insumos",
                             f"insumos semana {sem.strftime('%d/%m')}",
                             round(custo, 2), pago > HOJE))
            dep_id += 1

    # ------------------------------------------------------------ escrita
    def w(nome, header, rows):
        with open(os.path.join(OUT, nome), "w", newline="", encoding="utf-8") as f:
            cw = csv.writer(f)
            cw.writerow(header)
            cw.writerows(rows)

    w("restaurantes.csv", ["id", "nome", "tipo", "cidade", "comissao_pct", "taxa_pgto_pct",
                           "prazo_repasse_d", "saldo_inicial"], RESTAURANTES)
    w("pratos.csv", ["id", "restaurante_id", "nome", "categoria", "preco", "custo_unitario"],
      [p[:6] for p in PRATOS])
    w("promocoes.csv", ["id", "restaurante_id", "nome", "prato_id", "desconto_pct", "inicio", "fim"],
      [(a, b, c, d, e, f.isoformat(), g.isoformat()) for a, b, c, d, e, f, g in PROMOCOES])
    w("pedidos.csv", ["id", "restaurante_id", "criado_em", "status", "promocao_id",
                      "subtotal", "desconto"], pedidos)
    w("itens_pedido.csv", ["pedido_id", "prato_id", "qtd", "preco_unit", "desconto"], itens)
    w("despesas.csv", ["id", "restaurante_id", "data", "categoria", "descricao", "valor",
                       "agendada"], despesas)
    w("repasses.csv", ["id", "restaurante_id", "semana_ref", "data_prevista", "valor",
                       "realizado"], repasses)

    print(f"pedidos: {len(pedidos)} | itens: {len(itens)} | despesas: {len(despesas)} "
          f"| repasses: {len(repasses)} -> {OUT}")


if __name__ == "__main__":
    main()
