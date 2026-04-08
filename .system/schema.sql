CREATE TABLE IF NOT EXISTS global_knowledge (
    id INT AUTO_INCREMENT PRIMARY KEY,
    context_tag VARCHAR(50),
    pattern_name VARCHAR(100),
    problem_signature TEXT,
    solution_payload LONGTEXT,
    source_url VARCHAR(255),
    reliability_index INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
