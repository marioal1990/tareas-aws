package cl.backend.tareas_db.model.entity;

import java.time.OffsetDateTime;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Schema(description = "Una tarea del usuario")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Tarea {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Schema(description = "Identificador", example = "1", accessMode = Schema.AccessMode.READ_ONLY)
    private Long id;

    @NotBlank
    @Size(max = 200)
    @Schema(description = "Título de la tarea", example = "Desplegar el backend en EC2")
    private String titulo;

    @Schema(description = "Indica si la tarea está hecha", example = "false")
    private boolean completada;

    @Column(name = "creada_en", insertable = false, updatable = false)
    @Schema(description = "Fecha de creación", accessMode = Schema.AccessMode.READ_ONLY)
    private OffsetDateTime creadaEn;

    // Dueño de la tarea (sub de Cognito). No se expone en la API.
    @Column(name = "usuario_id", nullable = false, updatable = false, length = 64)
    @Schema(hidden = true)
    private String usuarioId;
}