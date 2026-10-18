package cl.backend.tareas_db.exception;

import org.springframework.http.HttpStatus;

public class BusinessRuleViolationException extends ApiException {
    public BusinessRuleViolationException(String message) {
        super(message, HttpStatus.UNPROCESSABLE_ENTITY);
    }
}
