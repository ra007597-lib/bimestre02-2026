-- =====================================================================
-- TRABALHO 02 - FUNCTIONS - Sistema de Oficina Mecânica
--
-- Functions:
--   1. fn_total_os(os_id)                    -> valor total de uma OS (serviços + peças)
--   2. fn_faturamento_periodo(inicio, fim)   -> faturamento das OS concluídas no período
--   3. fn_historico_cliente(cliente_id)      -> relatório de OS de um cliente com valor total
--   4. fn_situacao_estoque(peca_id)          -> classifica o estoque da peça (ESGOTADO/CRITICO/BAIXO/NORMAL)
-- =====================================================================

-- 1.Calcula o valor total de uma OS somando serviços e peças.

CREATE OR REPLACE FUNCTION fn_total_os(p_os_id INT)
RETURNS NUMERIC(12,2) AS
$$
DECLARE
    v_servicos NUMERIC(12,2);
    v_pecas    NUMERIC(12,2);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM ordem_servico WHERE id = p_os_id) THEN
        RAISE EXCEPTION 'OS % não encontrada', p_os_id;
    END IF;
 
    SELECT COALESCE(SUM(quantidade * valor_unitario), 0)
      INTO v_servicos
      FROM os_servico
     WHERE os_id = p_os_id;
 
    SELECT COALESCE(SUM(quantidade * valor_unitario), 0)
      INTO v_pecas
      FROM os_peca
     WHERE os_id = p_os_id;
 
    RETURN v_servicos + v_pecas;
END;
$$
LANGUAGE plpgsql;

-- =====================================================================

-- 2.Soma o valor das OS CONCLUIDAS cuja data de saída está no período.

CREATE OR REPLACE FUNCTION fn_faturamento_periodo(p_inicio DATE, p_fim DATE)
RETURNS NUMERIC(12,2) AS
$$
DECLARE
    v_total NUMERIC(12,2);
BEGIN
    IF p_inicio IS NULL OR p_fim IS NULL THEN
        RAISE EXCEPTION 'Informe a data inicial e a data final';
    END IF;
 
    IF p_inicio > p_fim THEN
        RAISE EXCEPTION 'Data inicial (%) maior que a data final (%)', p_inicio, p_fim;
    END IF;
 
    SELECT COALESCE(SUM(fn_total_os(os.id)), 0)
      INTO v_total
      FROM ordem_servico os
     WHERE os.status = 'CONCLUIDA'
       AND os.data_saida BETWEEN p_inicio AND p_fim;
 
    RETURN v_total;
END;
$$
LANGUAGE plpgsql;

-- =====================================================================

-- 3.Relatório: todas as OS dos veículos de um cliente, com o valor total de cada uma. Valida a existência do cliente.

CREATE OR REPLACE FUNCTION fn_historico_cliente(p_cliente_id INT)
RETURNS TABLE (
    r_os      INT,
    r_placa   VARCHAR,
    r_modelo  VARCHAR,
    r_entrada DATE,
    r_status  VARCHAR,
    r_total   NUMERIC
)
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cliente WHERE id = p_cliente_id) THEN
        RAISE EXCEPTION 'Cliente % não encontrado', p_cliente_id;
    END IF;
 
    RETURN QUERY
    SELECT os.id, v.placa, v.modelo, os.data_entrada, os.status, fn_total_os(os.id)
      FROM ordem_servico os
      JOIN veiculo v ON v.id = os.veiculo_id
     WHERE v.cliente_id = p_cliente_id
     ORDER BY os.data_entrada, os.id;
END;
$$
LANGUAGE plpgsql;

-- =====================================================================

-- 4.Classifica o saldo de uma peça para apoiar a decisão de reposição.
-- Faixas: 0 = ESGOTADO | 1-10 = CRITICO | 11-30 = BAIXO | >30 = NORMAL

CREATE OR REPLACE FUNCTION fn_situacao_estoque(p_peca_id INT)
RETURNS TEXT AS
$$
DECLARE
    v_estoque INT;
BEGIN
    SELECT estoque INTO v_estoque
      FROM peca
     WHERE id = p_peca_id;
 
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Peça % não encontrada', p_peca_id;
    END IF;
 
    RETURN CASE
        WHEN v_estoque = 0  THEN 'ESGOTADO'
        WHEN v_estoque <= 10 THEN 'CRITICO'
        WHEN v_estoque <= 30 THEN 'BAIXO'
        ELSE 'NORMAL'
    END;
END;
$$
LANGUAGE plpgsql;


-- =====================================================================
--                               TESTES
-- =====================================================================

-- Teste 1: total de cada OS (OS 4 = 450 + 115 + 4*36,50 + 28,50 + 42 = 781,50)
SELECT id AS os, fn_total_os(id) AS valor_total
FROM ordem_servico
ORDER BY id;


-- Teste 2: faturamento de setembro/2026 e de outubro/2026
SELECT fn_faturamento_periodo('2026-09-01', '2026-09-30') AS faturamento_setembro,
       fn_faturamento_periodo('2026-10-01', '2026-10-31') AS faturamento_outubro;

-- Teste 4: histórico do cliente 1 (Carlos Eduardo Menezes)
SELECT * FROM fn_historico_cliente(1);

-- Teste 5: situação do estoque de todas as peças
SELECT id, nome, estoque, fn_situacao_estoque(id) AS situacao
FROM peca
ORDER BY estoque;