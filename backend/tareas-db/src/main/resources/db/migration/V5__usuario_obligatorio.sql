-- En producción ya no quedan tareas sin dueño (se asignaron con un UPDATE manual).
-- En una BD nueva (CI, local) los datos de ejemplo de V2 no tienen dueño: se eliminan.
DELETE FROM tarea WHERE usuario_id IS NULL;

-- Desde ahora la BD exige que toda tarea tenga dueño
ALTER TABLE tarea ALTER COLUMN usuario_id SET NOT NULL;
