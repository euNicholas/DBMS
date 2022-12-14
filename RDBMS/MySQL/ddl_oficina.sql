CREATE DATABASE IF NOT EXISTS oficina;

USE oficina;

CREATE TABLE IF NOT EXISTS cliente(
cpf CHAR(11),
nome VARCHAR(45) NOT NULL UNIQUE,
genero ENUM('M', 'F', 'Outro') NOT NULL,
dataNascimento DATE NOT NULL,
endereco VARCHAR(100) NOT NULL,
cnh CHAR(10) NOT NULL UNIQUE,
CONSTRAINT pk_cliente PRIMARY KEY (cpf)
);

CREATE TABLE IF NOT EXISTS veiculo(
placa CHAR(7),
cpfCliente CHAR(11) NOT NULL,
modelo VARCHAR(30) NOT NULL,
marca VARCHAR(30) NOT NULL,
ano CHAR(4) NOT NULL,
PRIMARY KEY (placa),
CONSTRAINT fk_veiculo FOREIGN KEY (cpfCliente) REFERENCES cliente(cpf) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS mecanico(
cpf CHAR(11),
nome VARCHAR(45) NOT NULL,
genero ENUM('M', 'F', 'Outro') NOT NULL,
dataNascimento DATE NOT NULL,
endereco VARCHAR(100) NOT NULL,
especialidade VARCHAR(30) NOT NULL,
UNIQUE(nome)
);

ALTER TABLE mecanico ADD PRIMARY KEY (cpf);

-- ALTER TABLE mecanico ADD UNIQUE (nome);
-- ALTER TABLE mecanico ADD CONSTRAINT u_nome UNIQUE (nome);

CREATE TABLE IF NOT EXISTS equipe(
id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
responsavel VARCHAR(45) NOT NULL
);

-- ALTER TABLE equipe ADD CONSTRAINT pk_equipe PRIMARY KEY (id);
ALTER TABLE equipe ADD CONSTRAINT fk_equipe FOREIGN KEY (responsavel) REFERENCES mecanico(nome) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE IF NOT EXISTS equipe_mecanico(
idEquipe TINYINT UNSIGNED,
mecanico VARCHAR(45),
PRIMARY KEY (idEquipe, mecanico),
FOREIGN KEY (idEquipe) REFERENCES equipe(id) ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (mecanico) REFERENCES mecanico(nome) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS pedido(
id MEDIUMINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
cpfCliente CHAR(11) NOT NULL,
placaVeiculo CHAR(7) NOT NULL,
idEquipe TINYINT UNSIGNED,
tipoRequisicao VARCHAR(45) NOT NULL,
FOREIGN KEY (cpfCliente) REFERENCES cliente(cpf) ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (placaVeiculo) REFERENCES veiculo(placa) ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (idEquipe) REFERENCES equipe(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS ordemDeServico(
id MEDIUMINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
idEquipe TINYINT UNSIGNED NOT NULL,
idPedido MEDIUMINT UNSIGNED NOT NULL,
dataEntrega DATE NOT NULL,
dataEmissao DATE NOT NULL,
valor FLOAT NOT NULL DEFAULT 0,
FOREIGN KEY (idEquipe) REFERENCES equipe(id) ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (idPedido) REFERENCES pedido(id) ON DELETE CASCADE ON UPDATE CASCADE
);

ALTER TABLE ordemDeServico ADD CHECK (dataEmissao <= dataEntrega);

CREATE TABLE IF NOT EXISTS servico(
id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
nome VARCHAR(45) NOT NULL,
descricao VARCHAR(45) NOT NULL,
valor FLOAT NOT NULL,
CHECK (valor>=0)
);

CREATE TABLE IF NOT EXISTS servico_ordemDeServico(
idOrdemDeServico MEDIUMINT UNSIGNED,
idServico TINYINT UNSIGNED,
quantidade TINYINT UNSIGNED NOT NULL,
valor FLOAT NOT NULL,
autorizado CHAR(3),
PRIMARY KEY (idOrdemDeServico, idServico),
FOREIGN KEY (idOrdemDeServico) REFERENCES ordemDeServico(id) ON DELETE CASCADE ON UPDATE CASCADE,
FOREIGN KEY (idServico) REFERENCES servico(id) ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT ch_valor CHECK (valor>=0)
);

-- ALTER TABLE servico ADD CONSTRAINT ck_valor CHECK (valor>0);

CREATE VIEW vw_carro_cliente AS
(
SELECT placa, modelo, marca, ano, nome
FROM veiculo
INNER JOIN cliente ON cliente.cpf = veiculo.cpfCliente
);

-- DROP VIEW vw_carro_cliente;

CREATE INDEX servico_nome ON servico (nome);

-- ALTER TABLE servico DROP INDEX servico_nome;

DELIMITER $$
CREATE PROCEDURE count_veiculo_cpf (IN cpf CHAR(11), OUT qtd INT)
BEGIN
	SELECT COUNT(*) INTO qtd
	FROM veiculo
	WHERE cpfCliente = cpf;
END $$
DELIMITER ;

-- DROP PROCEDURE count_veiculo_cpf;

DELIMITER //
CREATE FUNCTION desconto (o_s TINYINT, d FLOAT)
RETURNS FLOAT
DETERMINISTIC
BEGIN
	DECLARE valor_final FLOAT;
	SELECT valor*(1-d) INTO valor_final 
    FROM ordemDeServico
    WHERE id = o_s;
    RETURN valor_final;
END //
DELIMITER ;

-- DROP FUNCTION desconto;

DELIMITER //
CREATE TRIGGER ins_ordemDeServico AFTER INSERT ON servico_ordemDeServico
FOR EACH ROW
BEGIN
	UPDATE ordemDeServico SET ordemDeServico.valor = ordemDeServico.valor + (NEW.valor * NEW.quantidade)
    WHERE ordemDeServico.id = NEW.idOrdemDeServico;
END //
DELIMITER ;

-- DROP TRIGGER ins_ordemServico;

CREATE USER 'dono'@'localhost' IDENTIFIED BY 'dono';
CREATE USER 'gerente'@'localhost' IDENTIFIED BY 'gerente';
CREATE USER 'mecanico'@'localhost' IDENTIFIED BY 'mecanico';
CREATE USER 'responsavel_equipe'@'localhost' IDENTIFIED BY 'responsavel_equipe';

CREATE ROLE role_ins_del_upt_sel;

-- DROP USER 'responsavel_equipe'@'localhost';

-- DROP DATABASE oficina;
