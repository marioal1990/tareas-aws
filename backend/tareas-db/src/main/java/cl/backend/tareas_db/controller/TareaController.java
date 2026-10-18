package cl.backend.tareas_db.controller;

import cl.backend.tareas_db.model.controller.ControllerResponse;
import cl.backend.tareas_db.model.controller.PageResponse;
import cl.backend.tareas_db.model.dto.TareaDTO;
import cl.backend.tareas_db.service.TareaService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@Slf4j
@Tag(name = "Tareas", description = "Gestión de tareas")
@RequestMapping("/api/v1/tareas")
@RequiredArgsConstructor
public class TareaController {

    private final TareaService tareaService;

    @GetMapping
    @Operation(summary = "Listar tareas", description = "Devuelve todas las tareas registradas")
    public ResponseEntity<ControllerResponse<PageResponse<TareaDTO>>> listar(
            @ParameterObject @PageableDefault(size = 20, sort = "id") Pageable pageable) {
        log.info("GET /api/v1/tareas");
        PageResponse<TareaDTO> page = PageResponse.of(this.tareaService.findAll(pageable));
        return ResponseEntity.ok(new ControllerResponse<>(HttpStatus.OK.value(), "OK", page));
    }

    @GetMapping("/findById/{id}")
    @Operation(summary = "Buscar tarea por ID")
    @ApiResponse(responseCode = "404", description = "Tarea no encontrada")
    public ResponseEntity<ControllerResponse<TareaDTO>> findById(@PathVariable Long id) {
        log.info("GET /api/v1/tareas/findById/{id}", id);
        return ResponseEntity.ok(new ControllerResponse<>(HttpStatus.OK.value(), "OK", this.tareaService.findById(id)));
    }

    @GetMapping("/findByTitulo/{titulo}")
    @Operation(summary = "Buscar tarea por Titulo")
    @ApiResponse(responseCode = "404", description = "Tarea no encontrada")
    public ResponseEntity<ControllerResponse<PageResponse<TareaDTO>>> findByTitulo
            (@PathVariable String titulo,
             @ParameterObject @PageableDefault(size = 20, sort = "titulo") Pageable pageable) {
        log.info("GET /api/v1/tareas/findByTitulo/{titulo}", titulo);
        return ResponseEntity.ok(new ControllerResponse<>(HttpStatus.OK.value(), "OK",
                PageResponse.of(this.tareaService.findByTitulo(titulo, pageable))));
    }

    @GetMapping("/findByCompletada/{completada}")
    @Operation(summary = "Buscar tarea por Completada")
    @ApiResponse(responseCode = "404", description = "Tarea no encontrada")
    public ResponseEntity<ControllerResponse<PageResponse<TareaDTO>>> findByCompletada
            (@PathVariable boolean completada,
             @ParameterObject @PageableDefault(size = 20, sort = "completada") Pageable pageable) {
        log.info("GET /api/v1/tareas/findByCompletada/{completada}", completada);
        return ResponseEntity.ok(new ControllerResponse<>(HttpStatus.OK.value(), "OK",
                PageResponse.of(this.tareaService.findByCompletada(completada, pageable))));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Crear tarea")
    @ApiResponse(responseCode = "201", description = "Tarea creada")
    @ApiResponse(responseCode = "400", description = "Datos inválidos")
    @ApiResponse(responseCode = "409", description = "Ya existe una tarea con ese título")
    public ResponseEntity<ControllerResponse<TareaDTO>> crear(@Valid @RequestBody TareaDTO tareaDTO) {
        log.info("POST /api/v1/tareas");
        return ResponseEntity.ok(new ControllerResponse<>(HttpStatus.OK.value(), "OK", this.tareaService.save(tareaDTO)));
    }

    @PatchMapping("/{id}/completada")
    @Operation(summary = "Marcar o desmarcar una tarea como completada")
    @ApiResponse(responseCode = "404", description = "Tarea no encontrada")
    public ResponseEntity<ControllerResponse<TareaDTO>> cambiarCompletada(
            @PathVariable Long id, @RequestParam boolean valor) {
        log.info("PATCH /api/v1/tareas/{id}", id);
        return ResponseEntity.ok(new ControllerResponse<>(200, "OK", tareaService.cambiarCompletada(id, valor)));
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Eliminar tarea")
    @ApiResponse(responseCode = "204", description = "Tarea eliminada")
    public void borrar(@PathVariable Long id) {
        log.info("DELETE /api/v1/tareas/{id}", id);
        this.tareaService.delete(id);
    }
}