package cl.backend.tareas_db.controller;

import cl.backend.tareas_db.model.controller.ControllerResponse;
import cl.backend.tareas_db.model.controller.PageResponse;
import cl.backend.tareas_db.model.dto.TareaDTO;
import cl.backend.tareas_db.service.TareaService;
import cl.backend.tareas_db.util.ParseoUtil;
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
            @ParameterObject @PageableDefault(size = 20, sort = "titulo") Pageable pageable) {
        log.debug("GET /api/v1/tareas");
        try {
            PageResponse<TareaDTO> page = PageResponse.of(this.tareaService.findAll(pageable));
            return ResponseEntity.ok(new ControllerResponse<>(HttpStatus.OK.value(), "OK", page));
        } catch (Exception e) {
            return ParseoUtil.error(e);
        }
    }

    @GetMapping("/findByTitulo/{titulo}")
    public ResponseEntity<ControllerResponse<PageResponse<TareaDTO>>> findByTitulo(@PathVariable String titulo,
                                                                                   @ParameterObject @PageableDefault(size = 20, sort = "titulo") Pageable pageable) {
        log.debug("GET /api/v1/tareas/findByTitulo/{titulo}", titulo);
        try {
            PageResponse<TareaDTO> page = PageResponse.of(this.tareaService.findByTitulo(titulo, pageable));
            return ResponseEntity.ok(new ControllerResponse<>(HttpStatus.OK.value(), "OK", page));
        } catch (Exception e) {
            return ParseoUtil.error(e);
        }
    }

    @GetMapping("/findByCompletada/{completada}")
    public ResponseEntity<ControllerResponse<PageResponse<TareaDTO>>> findByCompletada(@PathVariable boolean completada,
                                                                                       @ParameterObject @PageableDefault(size = 20, sort = "completada") Pageable pageable) {
        log.debug("GET /api/v1/tareas/findByCompletada/{completada}", completada);
        try {
            PageResponse<TareaDTO> page = PageResponse.of(this.tareaService.findByCompletada(completada, pageable));
            return ResponseEntity.ok(new ControllerResponse<>(HttpStatus.OK.value(), "OK", page));
        } catch (Exception e) {
            return ParseoUtil.error(e);
        }
    }

    @GetMapping("/findById/{id}")
    public ResponseEntity<ControllerResponse<TareaDTO>> findById(@PathVariable Long id) {
        log.debug("GET /api/v1/tareas/findById/{id}", id);
        try {
            TareaDTO tarea = this.tareaService.findById(id);
            return ResponseEntity.ok(new ControllerResponse<>(HttpStatus.OK.value(), "OK", tarea));
        } catch (Exception e) {
            return ParseoUtil.error(e);
        }
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Crear tarea")
    @ApiResponse(responseCode = "201", description = "Tarea creada")
    @ApiResponse(responseCode = "400", description = "Datos inválidos (título vacío o mayor a 200 caracteres)")
    public ResponseEntity<ControllerResponse<TareaDTO>> crear(@Valid @RequestBody TareaDTO tareaDTO) {
        log.debug("POST /api/v1/tareas");
        try {
            TareaDTO tarea = this.tareaService.save(tareaDTO);
            return ResponseEntity.ok(new ControllerResponse<>(HttpStatus.OK.value(), "OK", tarea));
        } catch (Exception e) {
            return ParseoUtil.error(e);
        }
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Eliminar tarea")
    @ApiResponse(responseCode = "204", description = "Tarea eliminada")
    public void borrar(@PathVariable Long id) {
        log.debug("DELETE /api/v1/tareas/{id}", id);
        this.tareaService.delete(id);
    }
}