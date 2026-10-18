package cl.backend.tareas_db.model.dto;

import java.time.OffsetDateTime;

public record TareaDTO(Long id, String titulo, boolean completada, OffsetDateTime creadaEn) {
}
