package cl.backend.tareas_db.model.controller;

import org.springframework.data.domain.Slice;

import java.util.List;

// Página sin COUNT(*): hasNext indica si existe una página siguiente
public record PageResponse<T>(List<T> content, int page, int size, boolean hasNext) {

    public static <T> PageResponse<T> of(Slice<T> slice) {
        return new PageResponse<>(slice.getContent(), slice.getNumber(), slice.getSize(), slice.hasNext());
    }
}
