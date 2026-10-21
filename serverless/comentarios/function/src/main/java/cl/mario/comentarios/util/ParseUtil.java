package cl.mario.comentarios.util;

import com.amazonaws.services.lambda.runtime.events.APIGatewayV2HTTPResponse;
import com.fasterxml.jackson.databind.ObjectMapper;

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
}
