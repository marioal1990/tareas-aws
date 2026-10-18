package cl.backend.tareas_db.util;

import cl.backend.tareas_db.model.controller.ControllerResponse;
import cl.backend.tareas_db.model.dto.TareaDTO;
import cl.backend.tareas_db.model.entity.Tarea;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

@Slf4j
@NoArgsConstructor
public class ParseoUtil {

    public static Tarea parseoTarea(TareaDTO tareaDTO) {
        Tarea tarea = new Tarea();
        tarea.setId(tareaDTO.id());
        tarea.setTitulo(tareaDTO.titulo());
        tarea.setCompletada(tareaDTO.completada());
        tarea.setCreadaEn(tareaDTO.creadaEn());
        return tarea;
    }

    public static TareaDTO parseoTareaDTO(Tarea tarea) {
        return new TareaDTO(tarea.getId(), tarea.getTitulo(), tarea.isCompletada(), tarea.getCreadaEn());
    }

    public static <T> ResponseEntity<ControllerResponse<T>> error(Exception e) {
        log.error("Error en ProductoController", e);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ControllerResponse<>(HttpStatus.INTERNAL_SERVER_ERROR.value(), e.getMessage(), null));
    }
}
