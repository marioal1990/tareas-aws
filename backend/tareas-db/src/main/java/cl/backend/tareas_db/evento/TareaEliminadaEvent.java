package cl.backend.tareas_db.evento;

/** Evento de dominio: una tarea fue eliminada. */
public record TareaEliminadaEvent(Long tareaId) {
}
