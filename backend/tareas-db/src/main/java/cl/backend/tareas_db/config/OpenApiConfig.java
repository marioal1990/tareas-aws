package cl.backend.tareas_db.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI tareasOpenAPI() {
        return new OpenAPI().info(new Info()
                .title("API de Tareas")
                .description("Backend Spring Boot del proyecto de aprendizaje en AWS")
                .version("v1")
                .contact(new Contact().name("Mario Araya Lecaros")));
    }
}
