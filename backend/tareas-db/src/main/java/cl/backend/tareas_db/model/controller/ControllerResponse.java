package cl.backend.tareas_db.model.controller;

public record ControllerResponse<T>(int code, String message, T data) {
}
