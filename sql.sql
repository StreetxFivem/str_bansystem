CREATE TABLE IF NOT EXISTS ban_system (
    id INT AUTO_INCREMENT PRIMARY KEY,
    target_id VARCHAR(50) NOT NULL,
    target_name VARCHAR(255) NOT NULL,
    admin_id VARCHAR(50) NOT NULL,
    admin_name VARCHAR(255) NOT NULL,
    reason TEXT NOT NULL,
    duration INT NOT NULL,
    timestamp INT NOT NULL,
    identifiers TEXT NOT NULL
);