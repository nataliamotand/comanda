"""
Converte os CSVs de data/out em arquivos SQL prontos para colar no
SQL Editor do Supabase (alternativa ao import de CSV pela interface).

Gera:
  db/02a_dados_cadastro.sql   restaurantes, pratos, promocoes, despesas, repasses
  db/02b_dados_pedidos.sql    pedidos
  db/02c_dados_itens.sql      itens_pedido
"""
import csv
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(BASE, "data", "out")
DB = os.path.join(BASE, "db")

NUMERICAS = {"id", "restaurante_id", "prato_id", "pedido_id", "promocao_id", "qtd",
             "comissao_pct", "taxa_pgto_pct", "prazo_repasse_d", "saldo_inicial", "preco",
             "custo_unitario", "desconto_pct", "subtotal", "desconto", "preco_unit", "valor"}
BOOLEANAS = {"agendada", "realizado"}


def lit(col, v):
    if v == "":
        return "null"
    if col in NUMERICAS:
        return v
    if col in BOOLEANAS:
        return "true" if v.lower() == "true" else "false"
    return "'" + v.replace("'", "''") + "'"


def inserts(tabela, lote=1000):
    with open(os.path.join(OUT, tabela + ".csv"), encoding="utf-8") as f:
        r = csv.reader(f)
        cols = next(r)
        linhas = ["(" + ",".join(lit(c, v) for c, v in zip(cols, row)) + ")" for row in r]
    blocos = []
    for i in range(0, len(linhas), lote):
        blocos.append(f"insert into {tabela} ({','.join(cols)}) values\n"
                      + ",\n".join(linhas[i:i + lote]) + ";\n")
    return f"-- {tabela}: {len(linhas)} linhas\n" + "".join(blocos)


def escreve(nome, tabelas):
    with open(os.path.join(DB, nome), "w", encoding="utf-8") as f:
        f.write("-- Gerado por data/to_sql.py — dados SINTÉTICOS\n")
        for t in tabelas:
            f.write(inserts(t) + "\n")
    print(nome, os.path.getsize(os.path.join(DB, nome)) // 1024, "KB")


if __name__ == "__main__":
    escreve("02a_dados_cadastro.sql", ["restaurantes", "pratos", "promocoes", "despesas", "repasses"])
    escreve("02b_dados_pedidos.sql", ["pedidos"])
    escreve("02c_dados_itens.sql", ["itens_pedido"])
