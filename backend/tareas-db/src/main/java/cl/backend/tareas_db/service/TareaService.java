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

@Service
@Slf4j
@RequiredArgsConstructor
public class TareaService {

    private final TareaRepository repo;

    private final ApplicationEventPublisher eventos;

    @Transactional(readOnly = true)
    public Slice<TareaDTO> findAll(Pageable pageable) {
        return this.repo.findAllDto(pageable);
    }

    @Transactional(readOnly = true)
    public Slice<TareaDTO> findByTitulo(String titulo, Pageable pageable) {
        return this.repo.findByTitulo(titulo, pageable);
    }

    @Transactional(readOnly = true)
    public Slice<TareaDTO> findByCompletada(boolean completada, Pageable pageable) {
        return this.repo.findByCompletada(completada, pageable);
    }

    @Transactional(readOnly = true)
    public TareaDTO findById(Long id) {
        Tarea tarea = repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("ID", id));
        return ParseoUtil.parseoTareaDTO(tarea);
    }

    @Transactional
    public TareaDTO save(TareaDTO tareaDTO) {
        if (this.repo.existsByTitulo(tareaDTO.titulo())) {
            throw new DuplicateResourceException("El titulo de la tarea ya existe");
        }
        Tarea tarea = this.repo.save(ParseoUtil.parseoTarea(tareaDTO));
        return ParseoUtil.parseoTareaDTO(tarea);
    }

    @Transactional
    public TareaDTO cambiarCompletada(Long id, boolean completada) {
        Tarea tarea = repo.findById(id).orElseThrow(() -> new ResourceNotFoundException("Tarea", id));
        tarea.setCompletada(completada);
        return ParseoUtil.parseoTareaDTO(tarea);   // JPA guarda el cambio al cerrar la transacción
    }

    @Transactional
    public void delete(Long id) {
        if (!repo.existsById(id)) {
            throw new ResourceNotFoundException("Tarea", id);
        }
        repo.deleteById(id);
        eventos.publishEvent(new TareaEliminadaEvent(id));
    }
}
