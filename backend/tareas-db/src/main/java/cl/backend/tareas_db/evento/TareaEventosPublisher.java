package cl.backend.tareas_db.evento;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import software.amazon.awssdk.services.eventbridge.EventBridgeClient;
import software.amazon.awssdk.services.eventbridge.model.PutEventsRequestEntry;
import software.amazon.awssdk.services.eventbridge.model.PutEventsResponse;

@Slf4j
@Component
@ConditionalOnProperty(name = "eventos.habilitados", havingValue = "true")
public class TareaEventosPublisher {

    private final EventBridgeClient eventBridge = EventBridgeClient.create();  // región y credenciales del entorno (rol de la EC2)
    private final String bus;

    public TareaEventosPublisher(@Value("${eventos.bus}") String bus) {
        this.bus = bus;
    }

    /** Se ejecuta SOLO si la transacción que borró la tarea hizo commit. */
    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void tareaEliminada(TareaEliminadaEvent evento) {
        try {
            PutEventsResponse resp = eventBridge.putEvents(r -> r.entries(PutEventsRequestEntry.builder()
                    .eventBusName(bus)
                    .source("tareas-db")
                    .detailType("TareaEliminada")
                    .detail("{\"tareaId\":" + evento.tareaId() + "}")
                    .build()));

            if (resp.failedEntryCount() > 0) {
                log.error("EventBridge rechazó TareaEliminada {}: {}", evento.tareaId(),
                        resp.entries().get(0).errorMessage());
            } else {
                log.info("Evento TareaEliminada publicado para la tarea {}", evento.tareaId());
            }
        } catch (Exception e) {
            // La tarea ya se borró: no se le devuelve error al usuario, se registra para revisarlo
            log.error("No se pudo publicar TareaEliminada {}", evento.tareaId(), e);
        }
    }
}
