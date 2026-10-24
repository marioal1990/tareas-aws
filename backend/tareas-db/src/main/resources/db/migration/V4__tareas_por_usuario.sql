-- Cada tarea pertenece a un usuario de Cognito (claim "sub" del token)
ALTER TABLE tarea ADD COLUMN usuario_id VARCHAR(64);

-- El título ya no es único global: es único por usuario
ALTER TABLE tarea DROP CONSTRAINT uq_tarea_titulo;
ALTER TABLE tarea ADD CONSTRAINT uq_tarea_usuario_titulo UNIQUE (usuario_id, titulo);

-- Todas las consultas filtran por usuario
CREATE INDEX idx_tarea_usuario ON tarea (usuario_id, id);

COMMENT ON COLUMN tarea.usuario_id IS 'sub de Cognito del dueño de la tarea';
