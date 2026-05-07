CREATE TABLE IF NOT EXISTS tasks (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tasks_completed ON tasks(completed);
CREATE INDEX idx_tasks_created_at ON tasks(created_at DESC);

-- Insert sample data
INSERT INTO tasks (title, description, completed) VALUES
  ('Setup Docker environment', 'Get Docker and docker-compose installed', true),
  ('Create database schema', 'Design and create PostgreSQL schema', true),
  ('Build backend API', 'Create Express.js API with CRUD operations', true),
  ('Build frontend UI', 'Create React interface for task management', false),
  ('Add caching layer', 'Integrate Redis for performance', false),
  ('Setup monitoring', 'Configure Prometheus and Grafana', false),
  ('Write documentation', 'Document the application and deployment', false);
