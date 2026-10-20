package cl.mario.comentarios.util;

import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPResponse;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.util.LinkedHashMap;
import java.util.Map;

public class ParseUtil {

    private ParseUtil() {}

    public static APIGatewayV2HTTPResponse respuesta(int code, String message, Object data) {
        ObjectMapper JSON = new ObjectMapper();
        try {
            String body = null;
            if (code != 204) {
                Map<String, Object> r = new LinkedHashMap<>();
                r.put("code", code);
                r.put("message", message);
                r.put("data", data);
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
}
