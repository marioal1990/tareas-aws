# syntax=docker/dockerfile:1

# ------------------------------------------------------------
# Etapa 1: compilar. Corre en la arquitectura de quien construye
# (amd64 en GitHub): el JAR es el mismo para cualquier CPU, así
# que no hace falta compilar emulando arm64 (sería muy lento)
# ------------------------------------------------------------
FROM --platform=$BUILDPLATFORM maven:3.9-amazoncorretto-21 AS build
WORKDIR /build

# Primero solo el pom: las dependencias quedan en una capa cacheada
# y no se vuelven a descargar si solo cambia el código
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q -DskipTests package \
 && cp target/tareas-db-*.jar app.jar \
 # Separa el JAR en capas: las dependencias cambian poco, el código cambia siempre
 && java -Djarmode=tools -jar app.jar extract --layers --destination extraido \
 && mkdir -p extraido/dependencies extraido/spring-boot-loader \
             extraido/snapshot-dependencies extraido/application

# ------------------------------------------------------------
# Etapa 2: imagen final. Solo el JRE y la app (sin Maven ni código fuente)
# ------------------------------------------------------------
FROM amazoncorretto:21-al2023-headless
WORKDIR /app

# De la capa que menos cambia a la que más cambia
COPY --from=build /build/extraido/dependencies/ ./
COPY --from=build /build/extraido/spring-boot-loader/ ./
COPY --from=build /build/extraido/snapshot-dependencies/ ./
COPY --from=build /build/extraido/application/ ./

# Sin privilegios de root dentro del contenedor
USER 65532

EXPOSE 8888

# La JVM usa hasta el 75% de la memoria asignada al contenedor (--memory)
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -XX:+ExitOnOutOfMemoryError"

ENTRYPOINT ["java", "-jar", "app.jar"]
