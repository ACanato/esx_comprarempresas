CREATE TABLE IF NOT EXISTS empresas (
    id VARCHAR(50) PRIMARY KEY,
    dono VARCHAR(64) DEFAULT '',
    nivel INT DEFAULT 0 NOT NULL,
    avisos INT NOT NULL DEFAULT 0,
    dinheiro INT DEFAULT 0
);
