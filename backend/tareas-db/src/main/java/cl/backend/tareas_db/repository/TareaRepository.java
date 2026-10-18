package cl.backend.tareas_db.repository;

import cl.backend.tareas_db.model.dto.TareaDTO;
import cl.backend.tareas_db.model.entity.Tarea;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

@Repository
public interface TareaRepository extends JpaRepository<Tarea, Long> {

    @Query("""
            SELECT new cl.backend.tareas_db.model.dto.TareaDTO(t.id, t.titulo, t.completada, t.creadaEn)
            FROM Tarea t
            """)
    Slice<TareaDTO> findAllDto(Pageable pageable);

    @Query("""
            SELECT new cl.backend.tareas_db.model.dto.TareaDTO(t.id, t.titulo, t.completada, t.creadaEn)
            FROM Tarea t
            WHERE t.titulo = :titulo
            """)
    Slice<TareaDTO> findByTitulo(String titulo, Pageable pageable);

    @Query("""
            SELECT new cl.backend.tareas_db.model.dto.TareaDTO(t.id, t.titulo, t.completada, t.creadaEn)
            FROM Tarea t
            WHERE t.completada = :completada
            """)
    Slice<TareaDTO> findByCompletada(boolean completada, Pageable pageable);

    boolean existsByTitulo(String titulo);
}