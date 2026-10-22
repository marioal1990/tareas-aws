package cl.mario.comentarios.repository;

import cl.mario.comentarios.model.Comentario;
import cl.mario.comentarios.util.ConstantsUtil;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.*;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class ComentarioRepository {

    private final DynamoDbClient dynamo;
    private final String tabla;

    public ComentarioRepository() {
        // Se crea una sola vez: SnapStart lo deja listo en la "foto" de la JVM
        this.dynamo = DynamoDbClient.builder()
                .httpClient(UrlConnectionHttpClient.create())
                .region(Region.of(System.getenv("AWS_REGION")))
                .build();
        this.tabla = System.getenv("TABLE_NAME");
    }

    public List<Comentario> listar(long tareaId) {
        QueryResponse resp = dynamo.query(QueryRequest.builder()
                .tableName(tabla)
                .keyConditionExpression("tareaId = :t")
                .expressionAttributeValues(Map.of(":t", AttributeValue.fromN(String.valueOf(tareaId))))
                .scanIndexForward(false)   // más recientes primero
                .limit(50)
                .build());
        return resp.items().stream().map(this::aComentario).toList();
    }

    public Comentario crear(long tareaId, String texto, String autor) {
        Instant ahora = Instant.now();
        // ID ordenable por fecha y seguro para URLs: 0001792...-a1b2c3d4
        String id = String.format("%013d-%s", ahora.toEpochMilli(), UUID.randomUUID().toString().substring(0, 8));
        Comentario c = new Comentario(tareaId, id, texto, ahora.toString(), autor);

        dynamo.putItem(PutItemRequest.builder()
                .tableName(tabla)
                .item(Map.of(
                        ConstantsUtil.TAREA_ID, AttributeValue.fromN(String.valueOf(c.tareaId())),
                        ConstantsUtil.COMENTARIO_ID, AttributeValue.fromS(c.comentarioId()),
                        ConstantsUtil.TEXTO, AttributeValue.fromS(c.texto()),
                        ConstantsUtil.CREADO_EN, AttributeValue.fromS(c.creadoEn()),
                        ConstantsUtil.USUARIO, AttributeValue.fromS(c.autor())))
                .build());
        return c;
    }

    public boolean borrar(long tareaId, String comentarioId) {
        DeleteItemResponse resp = dynamo.deleteItem(DeleteItemRequest.builder()
                .tableName(tabla)
                .key(Map.of(
                        ConstantsUtil.TAREA_ID, AttributeValue.fromN(String.valueOf(tareaId)),
                        ConstantsUtil.COMENTARIO_ID, AttributeValue.fromS(comentarioId)))
                .returnValues(ReturnValue.ALL_OLD)   // para saber si existía
                .build());
        return resp.hasAttributes() && !resp.attributes().isEmpty();
    }

    private Comentario aComentario(Map<String, AttributeValue> item) {
        return new Comentario(
                Long.parseLong(item.get(ConstantsUtil.TAREA_ID).n()),
                item.get(ConstantsUtil.COMENTARIO_ID).s(),
                item.get(ConstantsUtil.TEXTO).s(),
                item.get(ConstantsUtil.CREADO_EN).s(),
                item.get(ConstantsUtil.USUARIO).s());
    }
}