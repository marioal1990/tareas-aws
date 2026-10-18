package cl.backend.tareas_db.util;

import cl.backend.tareas_db.model.dto.TareaDTO;
import cl.backend.tareas_db.model.entity.Tarea;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class ParseoUtil {

    private ParseoUtil() {}

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
}
