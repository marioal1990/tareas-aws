package cl.mario.comentarios;

import cl.mario.comentarios.repository.ComentarioRepository;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;

import java.util.Map;

/** Reacciona al evento TareaEliminada borrando los comentarios de esa tarea. */
public class LimpiezaHandler implements RequestHandler<Map<String, Object>, Void> {

    private final ComentarioRepository repo = new ComentarioRepository();

    @Override
    @SuppressWarnings("unchecked")
    public Void handleRequest(Map<String, Object> evento, Context ctx) {
        Map<String, Object> detalle = (Map<String, Object>) evento.get("detail");
        long tareaId = ((Number) detalle.get("tareaId")).longValue();

        int borrados = repo.borrarTodos(tareaId);
        ctx.getLogger().log("TareaEliminada " + tareaId + ": " + borrados + " comentario(s) borrado(s)");
        return null;
    }
}