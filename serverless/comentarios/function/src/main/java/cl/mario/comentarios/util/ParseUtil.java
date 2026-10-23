package cl.mario.comentarios.util;

import cl.mario.comentarios.model.Comentario;
import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;

import java.util.LinkedHashMap;
import java.util.Map;

public class ParseUtil {

    private static final ObjectMapper JSON = new ObjectMapper();

    private ParseUtil() {}

    public static APIGatewayV2HTTPResponse respuesta(int code, String message, Object data) {
        try {
            String body = null;
            if (code != 204) {
                Map<String, Object> r = new LinkedHashMap<>();
                r.put(ConstantsUtil.CODE, code);
                r.put(ConstantsUtil.MESSAGE, message);
                r.put(ConstantsUtil.DATA, data);
                body = JSON.writeValueAsString(r);
            }
            return APIGatewayV2HTTPResponse.builder()
                    .withStatusCode(code)
                    .withHeaders(Map.of("Content-Type", "application/json"))
                    .withBody(body)
                    .build();
        } catch (Exception e) {
            return APIGatewayV2HTTPResponse.builder().withStatusCode(500).build();
        }
    }

    public static Comentario aComentario(Map<String, AttributeValue> item) {
        return new Comentario(
                Long.parseLong(item.get(ConstantsUtil.TAREA_ID).n()),
                ParseUtil.texto(item, ConstantsUtil.COMENTARIO_ID, ""),
                ParseUtil.texto(item, ConstantsUtil.TEXTO, ""),
                ParseUtil.texto(item, ConstantsUtil.CREADO_EN, ""),
                ParseUtil.texto(item, ConstantsUtil.USUARIO, "anónimo"));
    }

    /** Lee un atributo String; si el item no lo tiene, devuelve el valor por defecto. */
    public static String texto(Map<String, AttributeValue> item, String nombre, String porDefecto) {
        AttributeValue v = item.get(nombre);
        return v != null && v.s() != null ? v.s() : porDefecto;
    }
}
