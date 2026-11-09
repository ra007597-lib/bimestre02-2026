-- =====================================================
-- TRABALHO 01 - Sistema de Oficina Mecânica

-- JUSTIFICATIVA: A oficina mecânica tem fluxo operacional claro e relações naturais 1:N e N:N (cliente → veículo → ordem de serviço → serviços e peças), além de regras de validação reais (valores, estoque,
-- status, datas)

-- CONTEXTO: A oficina recebe veículos de clientes, abre uma ordem de serviço (OS) para cada entrada e a atribui a um mecânico. A OS registra os serviços executados e as peças usadas, com o preço gravado em cada
-- item para preservar o histórico financeiro. O total da OS é calculado por consulta a partir dos itens. O banco atende histórico por cliente, produtividade por mecânico e faturamento/estoque.
-- =====================================================


-- =====================================================================
-- 0. LIMPEZA (permite reexecutar o script do zero)
-- =====================================================================

DROP TABLE IF EXISTS os_peca, os_servico, ordem_servico, peca, servico, mecanico, veiculo, cliente CASCADE;


-- =====================================================================
--                      1. CRIAÇÃO DAS TABELAS
-- =====================================================================

-- Tabela: Cliente
-- Objetivo: Guarda os dados dos clientes, donos dos veículos atendidos

CREATE TABLE cliente (
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    cpf           CHAR(11) NOT NULL UNIQUE,
    telefone      VARCHAR(15) NOT NULL,
    data_cadastro DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Tabela: Mecanico
-- Objetivo: Guarda os dados dos mecânicos que executam as ordens de serviço

CREATE TABLE mecanico (
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome          VARCHAR(100) NOT NULL,
    especialidade VARCHAR(100) NOT NULL,
    salario       NUMERIC(10,2) NOT NULL CHECK (salario > 0),
    ativo         BOOLEAN NOT NULL DEFAULT true
);

-- Tabela: Servico
-- Objetivo: Guarda o catálogo de serviços (mão de obra) e o preço base de cada um

CREATE TABLE servico (
    id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    descricao  VARCHAR(100) NOT NULL UNIQUE,
    valor_base NUMERIC(10,2) NOT NULL CHECK (valor_base >= 0)
);

-- Tabela: Peca
-- Objetivo: Guarda as peças e insumos vendidos, com preço e saldo em estoque

CREATE TABLE peca (
    id      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome    VARCHAR(100) NOT NULL UNIQUE,
    preco   NUMERIC(10,2) NOT NULL CHECK (preco > 0),
    estoque INT NOT NULL DEFAULT 0 CHECK (estoque >= 0)
);

-- Tabela: Veiculo
-- Objetivo: Guarda os veículos que entram na oficina, cada um ligado ao seu dono

CREATE TABLE veiculo (
    id         INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    placa      VARCHAR(8) NOT NULL UNIQUE,
    marca      VARCHAR(40) NOT NULL,
    modelo     VARCHAR(60) NOT NULL,
    ano        INT NOT NULL CHECK (ano BETWEEN 1980 AND 2027),
    cliente_id INT NOT NULL REFERENCES cliente(id) ON DELETE RESTRICT
);

-- Tabela: Ordem_Servico
-- Objetivo: Registra cada entrada de um veículo na oficina, com mecânico, datas e status

CREATE TABLE ordem_servico (
    id           INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    veiculo_id   INT NOT NULL REFERENCES veiculo(id) ON DELETE RESTRICT,
    mecanico_id  INT NOT NULL REFERENCES mecanico(id) ON DELETE RESTRICT,
    data_entrada DATE NOT NULL DEFAULT CURRENT_DATE,
    data_saida   DATE,
    status       VARCHAR(15) NOT NULL DEFAULT 'ABERTA' CHECK (status IN ('ABERTA','EM_ANDAMENTO','CONCLUIDA','CANCELADA')),
    CHECK (data_saida IS NULL OR data_saida >= data_entrada)
);

-- Tabela: OS_Servico
-- Objetivo: Liga cada ordem de serviço aos serviços realizados, guardando quantidade e preço cobrado

CREATE TABLE os_servico (
    os_id          INT NOT NULL REFERENCES ordem_servico(id) ON DELETE CASCADE,
    servico_id     INT NOT NULL REFERENCES servico(id) ON DELETE RESTRICT,
    quantidade     INT NOT NULL CHECK (quantidade > 0),
    valor_unitario NUMERIC(10,2) NOT NULL CHECK (valor_unitario >= 0),
    PRIMARY KEY (os_id, servico_id)
);

-- Tabela: OS_Peca
-- Objetivo: Liga cada ordem de serviço às peças utilizadas, guardando quantidade e preço cobrado

CREATE TABLE os_peca (
    os_id          INT NOT NULL REFERENCES ordem_servico(id) ON DELETE CASCADE,
    peca_id        INT NOT NULL REFERENCES peca(id) ON DELETE RESTRICT,
    quantidade     INT NOT NULL CHECK (quantidade > 0),
    valor_unitario NUMERIC(10,2) NOT NULL CHECK (valor_unitario > 0),
    PRIMARY KEY (os_id, peca_id)
);


-- =====================================================================
--                       2. INSERÇÃO DE DADOS
-- =====================================================================

INSERT INTO cliente (nome, cpf, telefone, data_cadastro) VALUES
('Carlos Eduardo Menezes', '12345678901', '35998110001', '2025-03-10'),
('Mariana Souza Lima',     '23456789012', '35998110002', '2025-05-22'),
('João Pedro Alves',       '34567890123', '35998110003', '2025-07-14'),
('Fernanda Oliveira',      '45678901234', '35998110004', '2025-09-01'),
('Ricardo Barbosa',        '56789012345', '35998110005', '2025-11-30'),
('Patrícia Gomes',         '67890123456', '35998110006', '2026-01-18'),
('Lucas Ferreira',         '78901234567', '35998110007', '2026-02-27'),
('Aline Carvalho',         '89012345678', '35998110008', '2026-04-05'),
('Bruno Teixeira',         '90123456789', '35998110009', '2026-06-12'),
('Camila Ribeiro',         '01234567890', '35998110010', '2026-08-20');

INSERT INTO mecanico (nome, especialidade, salario, ativo) VALUES
('Roberto Almeida',  'Motor',               3800.00, true),
('Fernando Costa',   'Suspensão e freios',  3500.00, true),
('Marcos Vinícius',  'Elétrica automotiva', 3600.00, true),
('Paulo Henrique',   'Injeção eletrônica',  4200.00, true),
('Juliana Ribeiro',  'Ar-condicionado',     3400.00, true),
('André Luiz',       'Revisão geral',       3000.00, true),
('Thiago Santos',    'Motor',               3900.00, true),
('Ricardo Pereira',  'Funilaria e pintura', 3300.00, false);

INSERT INTO servico (descricao, valor_base) VALUES
('Troca de óleo e filtro',          120.00),
('Alinhamento e balanceamento',     150.00),
('Revisão completa',                450.00),
('Troca de pastilhas de freio',     180.00),
('Troca de correia dentada',        380.00),
('Diagnóstico eletrônico',          100.00),
('Higienização de ar-condicionado', 160.00),
('Troca de amortecedores',          420.00),
('Troca de bateria',                 60.00),
('Regulagem de motor',              250.00);

INSERT INTO peca (nome, preco, estoque) VALUES
('Óleo 5W30 (litro)',           38.90, 120),
('Filtro de óleo',              29.90,  80),
('Pastilha de freio dianteira', 89.90,  40),
('Correia dentada',            119.00,  25),
('Amortecedor dianteiro',      249.00,  16),
('Bateria 60Ah',               429.00,  12),
('Vela de ignição',             24.50, 200),
('Filtro de ar',                42.00,  60),
('Filtro de cabine',            35.00,  50),
('Fluido de freio DOT4',        28.00,  45);

INSERT INTO veiculo (placa, marca, modelo, ano, cliente_id) VALUES
('ABC1D23', 'Fiat',       'Uno',      2012, 1),
('BCD2E34', 'Volkswagen', 'Gol',      2018, 1),
('CDE3F45', 'Chevrolet',  'Onix',     2020, 2),
('DEF4G56', 'Honda',      'Civic',    2016, 3),
('EFG5H67', 'Toyota',     'Corolla',  2019, 4),
('FGH6I78', 'Hyundai',    'HB20',     2021, 5),
('GHI7J89', 'Ford',       'Ka',       2015, 6),
('HIJ8K90', 'Renault',    'Kwid',     2022, 7),
('IJK9L01', 'Jeep',       'Renegade', 2017, 8),
('JKL0M12', 'Fiat',       'Strada',   2023, 9);

INSERT INTO ordem_servico (veiculo_id, mecanico_id, data_entrada, data_saida, status) VALUES
(1, 1, '2026-09-02', '2026-09-02', 'CONCLUIDA'),
(2, 2, '2026-09-05', '2026-09-06', 'CONCLUIDA'),
(3, 3, '2026-09-10', '2026-09-12', 'CONCLUIDA'),
(4, 1, '2026-09-15', '2026-09-18', 'CONCLUIDA'),
(5, 4, '2026-09-22', '2026-09-22', 'CONCLUIDA'),
(6, 5, '2026-10-01', '2026-10-03', 'CONCLUIDA'),
(7, 2, '2026-10-08', '2026-10-09', 'CONCLUIDA'),
(8, 3, '2026-10-20', NULL,         'EM_ANDAMENTO'),
(1, 1, '2026-10-27', NULL,         'ABERTA'),
(3, 6, '2026-10-14', '2026-10-14', 'CANCELADA');

-- valor_unitario é diferente do valor_base em alguns itens: o preço é histórico
INSERT INTO os_servico (os_id, servico_id, quantidade, valor_unitario) VALUES
(1, 1, 1, 120.00),
(2, 4, 1, 180.00),
(3, 8, 2, 420.00),
(4, 3, 1, 450.00),
(4, 1, 1, 115.00),
(5, 6, 1, 100.00),
(6, 7, 1, 160.00),
(7, 9, 1,  60.00),
(8, 5, 1, 380.00),
(9, 1, 1, 125.00);

INSERT INTO os_peca (os_id, peca_id, quantidade, valor_unitario) VALUES
(1,  1, 4,  38.90),
(1,  2, 1,  29.90),
(2,  3, 1,  89.90),
(2, 10, 1,  28.00),
(3,  5, 2, 249.00),
(4,  1, 4,  36.50),
(4,  2, 1,  28.50),
(4,  8, 1,  42.00),
(7,  6, 1, 429.00),
(8,  4, 1, 119.00);


-- =====================================================================
--                          3. CONSULTAS
-- =====================================================================

-- 1º Consulta. INNER JOIN (5 tabelas): visão completa de cada OS
-- Demonstra: junção entre ordem, veículo, cliente e mecânico

SELECT os.id AS os, c.nome AS cliente, v.placa, v.modelo, m.nome AS mecanico, os.data_entrada, os.status
FROM ordem_servico os
INNER JOIN veiculo  v ON v.id = os.veiculo_id
INNER JOIN cliente  c ON c.id = v.cliente_id
INNER JOIN mecanico m ON m.id = os.mecanico_id
ORDER BY os.id;

-- 2º Consulta. LEFT JOIN: clientes que nunca tiveram uma OS
-- Demonstra: junção externa com filtro IS NULL

SELECT c.id, c.nome
FROM cliente c
LEFT JOIN veiculo v ON v.cliente_id = c.id
LEFT JOIN ordem_servico os ON os.veiculo_id = v.id
WHERE os.id IS NULL
ORDER BY c.nome;

-- 3ºConsulta. GROUP BY + COUNT: quantidade de OS por mecânico (inclui quem tem zero)
-- Demonstra: agrupamento com LEFT JOIN para não perder mecânicos sem OS

SELECT m.nome, m.especialidade, COUNT(os.id) AS qtd_os
FROM mecanico m
LEFT JOIN ordem_servico os ON os.mecanico_id = m.id
GROUP BY m.id, m.nome, m.especialidade
ORDER BY qtd_os DESC, m.nome;

-- 4º Consulta. GROUP BY + SUM: valor total de cada OS (serviços + peças)
-- Demonstra: total derivado dos itens, sem coluna redundante

WITH itens AS (
    SELECT os_id, quantidade * valor_unitario AS subtotal FROM os_servico
    UNION ALL
    SELECT os_id, quantidade * valor_unitario AS subtotal FROM os_peca
)
SELECT os.id AS os, c.nome AS cliente, os.status, COALESCE(SUM(i.subtotal), 0) AS valor_total
FROM ordem_servico os
JOIN veiculo v ON v.id = os.veiculo_id
JOIN cliente c ON c.id = v.cliente_id
LEFT JOIN itens i ON i.os_id = os.id
GROUP BY os.id, c.nome, os.status
ORDER BY os.id;

-- 5º Consulta. GROUP BY por mês: faturamento das OS concluídas
-- Demonstra: filtro condicional + agregação temporal

WITH itens AS (
    SELECT os_id, quantidade * valor_unitario AS subtotal FROM os_servico
    UNION ALL
    SELECT os_id, quantidade * valor_unitario AS subtotal FROM os_peca
)
SELECT TO_CHAR(os.data_saida, 'YYYY-MM') AS mes, COUNT(DISTINCT os.id) AS qtd_os, SUM(i.subtotal) AS faturamento
FROM ordem_servico os
JOIN itens i ON i.os_id = os.id
WHERE os.status = 'CONCLUIDA'
GROUP BY TO_CHAR(os.data_saida, 'YYYY-MM')
ORDER BY mes;

-- 6º Consulta. GROUP BY + HAVING: clientes com gasto total acima de R$ 500
-- Demonstra: filtro sobre resultado agregado

WITH itens AS (
    SELECT os_id, quantidade * valor_unitario AS subtotal FROM os_servico
    UNION ALL
    SELECT os_id, quantidade * valor_unitario AS subtotal FROM os_peca
)
SELECT c.nome, SUM(i.subtotal) AS total_gasto
FROM cliente c
JOIN veiculo v        ON v.cliente_id = c.id
JOIN ordem_servico os ON os.veiculo_id = v.id
JOIN itens i          ON i.os_id = os.id
WHERE os.status <> 'CANCELADA'
GROUP BY c.id, c.nome
HAVING SUM(i.subtotal) > 500
ORDER BY total_gasto DESC;

-- 7º Consulta. Filtro composto: OS concluídas em setembro/2026 com mecânicos ativos
-- Demonstra: WHERE com AND, BETWEEN e condição booleana

SELECT os.id, v.placa, m.nome AS mecanico, os.data_entrada, os.data_saida
FROM ordem_servico os
JOIN veiculo v  ON v.id = os.veiculo_id
JOIN mecanico m ON m.id = os.mecanico_id
WHERE os.status = 'CONCLUIDA'
  AND os.data_entrada BETWEEN '2026-09-01' AND '2026-09-30'
  AND m.ativo = true
ORDER BY os.data_entrada;

-- 8º Consulta. Subconsulta: peças com preço acima da média do catálogo
-- Demonstra: subconsulta escalar no WHERE

SELECT nome, preco, estoque
FROM peca
WHERE preco > (SELECT AVG(preco) FROM peca)
ORDER BY preco DESC;

-- 9º Consulta. LEFT JOIN: peças que nunca foram usadas em nenhuma OS
-- Demonstra: apoio à decisão de estoque (itens parados)

SELECT p.id, p.nome, p.estoque
FROM peca p
LEFT JOIN os_peca op ON op.peca_id = p.id
WHERE op.os_id IS NULL
ORDER BY p.nome;




