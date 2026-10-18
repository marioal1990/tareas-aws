package cl.backend.tareas_db.exception;

import org.springframework.http.HttpStatus;

public class ResourceNotFoundException extends ApiException {
    public ResourceNotFoundException(String resource, Object id) {
        super(resource + " con id " + id + " no encontrado", HttpStatus.NOT_FOUND);
    }
}
