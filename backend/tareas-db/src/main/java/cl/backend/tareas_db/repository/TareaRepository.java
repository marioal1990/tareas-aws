package cl.backend.tareas_db.repository;

import cl.backend.tareas_db.model.dto.TareaDTO;
import cl.backend.tareas_db.model.entity.Tarea;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TareaRepository extends JpaRepository<Tarea, Long> {

    @Query("""
            SELECT new cl.backend.tareas_db.model.dto.TareaDTO(t.id, t.titulo, t.completada, t.creadaEn)
            FROM Tarea t
            WHERE t.usuarioId = :usuarioId
            """)
    Slice<TareaDTO> findAllDto(String usuarioId, Pageable pageable);

    @Query("""
            SELECT new cl.backend.tareas_db.model.dto.TareaDTO(t.id, t.titulo, t.completada, t.creadaEn)
            FROM Tarea t
            WHERE t.usuarioId = :usuarioId AND t.titulo = :titulo
            """)
    Slice<TareaDTO> findByTitulo(String usuarioId, String titulo, Pageable pageable);

    @Query("""
            SELECT new cl.backend.tareas_db.model.dto.TareaDTO(t.id, t.titulo, t.completada, t.creadaEn)
            FROM Tarea t
            WHERE t.usuarioId = :usuarioId AND t.completada = :completada
            """)
    Slice<TareaDTO> findByCompletada(String usuarioId, boolean completada, Pageable pageable);

    Optional<Tarea> findByIdAndUsuarioId(Long id, String usuarioId);

    boolean existsByUsuarioIdAndTitulo(String usuarioId, String titulo);
}
