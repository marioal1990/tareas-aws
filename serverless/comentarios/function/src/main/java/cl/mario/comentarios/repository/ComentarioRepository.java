package cl.mario.comentarios.repository;

import cl.mario.comentarios.model.Comentario;
import cl.mario.comentarios.util.ConstantsUtil;
import cl.mario.comentarios.util.ParseUtil;
import software.amazon.awssdk.http.urlconnection.UrlConnectionHttpClient;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.*;

import java.time.Instant;
import java.util.ArrayList;
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

    /** Lista los comentarios de la tarea que pertenecen al usuario (sub de Cognito). */
    public List<Comentario> listar(long tareaId, String usuarioId) {
        QueryResponse resp = dynamo.query(QueryRequest.builder()
                .tableName(tabla)
                .keyConditionExpression("tareaId = :t")
                .filterExpression("usuarioId = :u")   // se aplica después de leer: no ahorra lecturas
                .expressionAttributeValues(Map.of(
                        ":t", AttributeValue.fromN(String.valueOf(tareaId)),
                        ":u", AttributeValue.fromS(usuarioId)))
                .scanIndexForward(false)   // más recientes primero
                .limit(50)
                .build());
        return resp.items().stream().map(ParseUtil::aComentario).toList();
    }

    public Comentario crear(long tareaId, String texto, String autor, String usuarioId) {
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
                        ConstantsUtil.USUARIO, AttributeValue.fromS(c.autor()),
                        ConstantsUtil.USUARIO_ID, AttributeValue.fromS(usuarioId)))
                .build());
        return c;
    }

    /** Borra el comentario solo si es del usuario. false si no existe o es de otro. */
    public boolean borrar(long tareaId, String comentarioId, String usuarioId) {
        try {
            dynamo.deleteItem(DeleteItemRequest.builder()
                    .tableName(tabla)
                    .key(Map.of(
                            ConstantsUtil.TAREA_ID, AttributeValue.fromN(String.valueOf(tareaId)),
                            ConstantsUtil.COMENTARIO_ID, AttributeValue.fromS(comentarioId)))
                    // Falla si el item no existe o si su dueño es otro: ambos casos son 404
                    .conditionExpression("usuarioId = :u")
                    .expressionAttributeValues(Map.of(":u", AttributeValue.fromS(usuarioId)))
                    .build());
            return true;
        } catch (ConditionalCheckFailedException e) {
            return false;
        }
    }

    /** Borra todos los comentarios de una tarea. Devuelve cuántos borró. */
    public int borrarTodos(long tareaId) {
        // Solo pedimos las llaves: no necesitamos el texto para borrar
        var paginas = dynamo.queryPaginator(QueryRequest.builder()
                .tableName(tabla)
                .keyConditionExpression("tareaId = :t")
                .expressionAttributeValues(Map.of(":t", AttributeValue.fromN(String.valueOf(tareaId))))
                .projectionExpression("tareaId, comentarioId")
                .build());

        List<WriteRequest> lote = new ArrayList<>();
        int total = 0;
        for (Map<String, AttributeValue> llave : paginas.items()) {   // recorre todas las páginas
            lote.add(WriteRequest.builder()
                    .deleteRequest(DeleteRequest.builder().key(llave).build())
                    .build());
            if (lote.size() == 25) {
                total += borrarLote(lote);
                lote = new ArrayList<>();
            }
        }
        if (!lote.isEmpty()) total += borrarLote(lote);
        return total;
    }

    private int borrarLote(List<WriteRequest> lote) {
        Map<String, List<WriteRequest>> pendientes = Map.of(tabla, lote);
        // DynamoDB puede devolver items "no procesados" si está bajo carga: se reintentan con espera creciente
        for (int intento = 0; !pendientes.isEmpty() && intento < 5; intento++) {
            BatchWriteItemResponse resp = dynamo.batchWriteItem(BatchWriteItemRequest.builder()
                    .requestItems(pendientes).build());
            pendientes = resp.unprocessedItems();
            if (!pendientes.isEmpty()) {
                try { Thread.sleep(100L << intento); } catch (InterruptedException e) { Thread.currentThread().interrupt(); }
            }
        }
        if (!pendientes.isEmpty()) {
            // Al lanzar la excepción, EventBridge reintentará el evento completo
            throw new IllegalStateException("No se pudieron borrar todos los comentarios");
        }
        return lote.size();
    }
}