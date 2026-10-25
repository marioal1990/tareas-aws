package cl.backend.tareas_db.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

@Configuration
public class OpenApiConfig {

    private static final String BEARER = "bearer";

    @Bean
    public OpenAPI tareasOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                .title("API de Tareas")
                .description("Backend Spring Boot del proyecto de aprendizaje en AWS")
                .version("v1")
                .contact(new Contact().name("Mario Araya Lecaros")))
                .servers(List.of(new Server().url("/tareas-db").description("Mismo dominio")))
                // OAUTH 2
                .components(new Components().addSecuritySchemes(BEARER,
                        new SecurityScheme().type(SecurityScheme.Type.HTTP).scheme(BEARER).bearerFormat("JWT")))
                .addSecurityItem(new SecurityRequirement().addList(BEARER));
    }
}
