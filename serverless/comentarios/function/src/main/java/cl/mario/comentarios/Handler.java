package cl.mario.comentarios;

import cl.mario.comentarios.model.Comentario;
import cl.mario.comentarios.repository.ComentarioRepository;
import cl.mario.comentarios.util.ConstantsUtil;
import cl.mario.comentarios.util.ParseUtil;
import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPEvent;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPResponse;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.crac.Core;
import org.crac.Resource;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.List;
import java.util.Map;

public class Handler implements RequestHandler<APIGatewayV2HTTPEvent, APIGatewayV2HTTPResponse>, Resource {

    private static final String BASE = "/comentarios-api/tareas/{tareaId}/comentarios";
    private static final ObjectMapper JSON = new ObjectMapper();
    private final ComentarioRepository repo = new ComentarioRepository();

    public Handler() {
        // Registra esta clase para recibir los avisos de checkpoint/restore de SnapStart
        Core.getGlobalContext().register(this);
    }

    @Override
    public void beforeCheckpoint(org.crac.Context<? extends Resource> context) {
        try {
            // Consulta real a DynamoDB con una tarea que no existe: carga el SDK,
            // la firma de peticiones y la conexión TLS, sin modificar datos
            repo.listar(-1L);
            // Carga y "calienta" Jackson
            ParseUtil.respuesta(200, "OK", List.of(new Comentario(0, "x", "x", "x")));
        } catch (Exception e) {
            // El priming es una optimización: si falla, la función funciona igual
        }
    }

    @Override
    public void afterRestore(org.crac.Context<? extends Resource> context) {
        // Nada que hacer: el SDK renueva credenciales y conexiones por su cuenta
    }

    @Override
    public APIGatewayV2HTTPResponse handleRequest(APIGatewayV2HTTPEvent event, Context ctx) {
        try {
            String ruta = event.getRouteKey();
            Map<String, String> params = event.getPathParameters();
            long tareaId = Long.parseLong(params.get(ConstantsUtil.TAREA_ID));

            return switch (ruta) {
                case "GET " + BASE -> ParseUtil.respuesta(200, "OK", repo.listar(tareaId));
                case "POST " + BASE -> crear(tareaId, event);
                case "DELETE " + BASE + "/{comentarioId}" -> repo.borrar(tareaId, params.get(ConstantsUtil.COMENTARIO_ID))
                        ? ParseUtil.respuesta(204, null, null)
                        : ParseUtil.respuesta(404, "Comentario no encontrado", null);
                default -> ParseUtil.respuesta(404, "Ruta no encontrada", null);
            };
        } catch (NumberFormatException e) {
            return ParseUtil.respuesta(400, "El tareaId debe ser numérico", null);
        } catch (Exception e) {
            ctx.getLogger().log("ERROR: " + e);   // el detalle va a CloudWatch, no al cliente
            return ParseUtil.respuesta(500, "Error interno del servidor", null);
        }
    }

    private APIGatewayV2HTTPResponse crear(long tareaId, APIGatewayV2HTTPEvent event) throws Exception {
        String body = event.getBody();
        if (body != null && event.getIsBase64Encoded()) {
            body = new String(Base64.getDecoder().decode(body), StandardCharsets.UTF_8);
        }
        JsonNode json = body == null ? null : JSON.readTree(body);
        String texto = json == null || !json.hasNonNull("texto") ? "" : json.get("texto").asText().trim();

        if (texto.isEmpty()) return ParseUtil.respuesta(400, "El texto es obligatorio", null);
        if (texto.length() > 500) return ParseUtil.respuesta(400, "El texto no puede superar 500 caracteres", null);

        return ParseUtil.respuesta(201, "Comentario creado", repo.crear(tareaId, texto));
    }
}