package cl.backend.tareas_db.exception;

import cl.backend.tareas_db.model.controller.ControllerResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.util.LinkedHashMap;
import java.util.Map;

@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ControllerResponse<Void>> handleApi(ApiException e) {
        return ResponseEntity.status(e.getStatus())
                .body(new ControllerResponse<>(e.getStatus().value(), e.getMessage(), null));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ControllerResponse<Map<String, String>>> handleValidation(MethodArgumentNotValidException e) {
        Map<String, String> errores = new LinkedHashMap<>();
        e.getBindingResult().getFieldErrors()
                .forEach(f -> errores.put(f.getField(), f.getDefaultMessage()));
        return ResponseEntity.badRequest()
                .body(new ControllerResponse<>(400, "Datos inválidos", errores));
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ControllerResponse<Void>> handleNotFound(NoResourceFoundException e) {
        log.error("Recurso no encontrado", e);
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ControllerResponse<>(404, "Recurso no encontrado", null));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ControllerResponse<Void>> handleGeneric(Exception e) {
        log.error("Error no controlado", e);   // el detalle queda en el log, no en la respuesta
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ControllerResponse<>(500, "Error interno del servidor", null));
    }
}
