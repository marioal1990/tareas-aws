package cl.backend.tareas_db.service;

import cl.backend.tareas_db.evento.TareaEliminadaEvent;
import cl.backend.tareas_db.exception.DuplicateResourceException;
import cl.backend.tareas_db.exception.ResourceNotFoundException;
import cl.backend.tareas_db.model.dto.TareaDTO;
import cl.backend.tareas_db.model.entity.Tarea;
import cl.backend.tareas_db.repository.TareaRepository;
import cl.backend.tareas_db.util.ParseoUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Todas las operaciones reciben el usuarioId (sub de Cognito) y solo tocan tareas de ese usuario.
 * Si la tarea es de otro usuario se responde 404 (no 403) para no revelar que existe.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class TareaService {

    private final TareaRepository repo;

    private final ApplicationEventPublisher eventos;

    @Transactional(readOnly = true)
    public Slice<TareaDTO> findAll(String usuarioId, Pageable pageable) {
        return this.repo.findAllDto(usuarioId, pageable);
    }

    @Transactional(readOnly = true)
    public Slice<TareaDTO> findByTitulo(String usuarioId, String titulo, Pageable pageable) {
        return this.repo.findByTitulo(usuarioId, titulo, pageable);
    }

    @Transactional(readOnly = true)
    public Slice<TareaDTO> findByCompletada(String usuarioId, boolean completada, Pageable pageable) {
        return this.repo.findByCompletada(usuarioId, completada, pageable);
    }

    @Transactional(readOnly = true)
    public TareaDTO findById(String usuarioId, Long id) {
        return ParseoUtil.parseoTareaDTO(buscarPropia(usuarioId, id));
    }

    @Transactional
    public TareaDTO save(String usuarioId, TareaDTO tareaDTO) {
        if (this.repo.existsByUsuarioIdAndTitulo(usuarioId, tareaDTO.titulo())) {
            throw new DuplicateResourceException("El titulo de la tarea ya existe");
        }
        Tarea tarea = ParseoUtil.parseoTarea(tareaDTO);
        tarea.setId(null);              // el ID siempre lo genera la BD
        tarea.setUsuarioId(usuarioId);  // el dueño sale del token, nunca del body
        return ParseoUtil.parseoTareaDTO(this.repo.save(tarea));
    }

    @Transactional
    public TareaDTO cambiarCompletada(String usuarioId, Long id, boolean completada) {
        Tarea tarea = buscarPropia(usuarioId, id);
        tarea.setCompletada(completada);
        return ParseoUtil.parseoTareaDTO(tarea);   // JPA guarda el cambio al cerrar la transacción
    }

    @Transactional
    public void delete(String usuarioId, Long id) {
        repo.delete(buscarPropia(usuarioId, id));
        eventos.publishEvent(new TareaEliminadaEvent(id));
    }

    private Tarea buscarPropia(String usuarioId, Long id) {
        return repo.findByIdAndUsuarioId(id, usuarioId)
                .orElseThrow(() -> new ResourceNotFoundException("Tarea", id));
    }
}
