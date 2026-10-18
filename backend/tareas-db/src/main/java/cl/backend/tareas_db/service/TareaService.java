package cl.backend.tareas_db.service;

import cl.backend.tareas_db.exception.BusinessRuleViolationException;
import cl.backend.tareas_db.exception.DuplicateResourceException;
import cl.backend.tareas_db.exception.ResourceNotFoundException;
import cl.backend.tareas_db.model.dto.TareaDTO;
import cl.backend.tareas_db.model.entity.Tarea;
import cl.backend.tareas_db.repository.TareaRepository;
import cl.backend.tareas_db.util.ParseoUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@Slf4j
@RequiredArgsConstructor
public class TareaService {

    private final TareaRepository repo;

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
        return new TareaDTO(tarea.getId(), tarea.getTitulo(), tarea.isCompletada(), tarea.getCreadaEn());
    }

    @Transactional
    public TareaDTO save(TareaDTO tareaDTO) {
        if (this.repo.existsByTitulo(tareaDTO.titulo())) {
            throw new DuplicateResourceException("El titulo de la tarea ya existe");
        }
        Tarea tarea = ParseoUtil.parseoTarea(tareaDTO);
        tarea = this.repo.save(tarea);
        TareaDTO tareaDTO1 = ParseoUtil.parseoTareaDTO(tarea);
        return tareaDTO1;
    }

    @Transactional
    public void delete(Long id) {
        this.repo.deleteById(id);
    }
}
