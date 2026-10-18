package cl.backend.tareas_db.model.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.OffsetDateTime;

@Schema(description = "Una tarea del usuario")
public record TareaDTO(
        @Schema(example = "1", accessMode = Schema.AccessMode.READ_ONLY)
        Long id,
        @NotBlank(message = "El título es obligatorio")
        @Size(max = 200, message = "El título no puede superar 200 caracteres")
        @Schema(example = "Desplegar el backend en EC2")
        String titulo,
        @Schema(example = "false")
        boolean completada,
        @Schema(accessMode = Schema.AccessMode.READ_ONLY)
        OffsetDateTime creadaEn) {
}
