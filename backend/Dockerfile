# Build context: repository root (needs proto/ and data/). Used by render.yaml.
#   docker build -f backend/Dockerfile -t transmcbo-api .

FROM eclipse-temurin:21-jdk AS build
WORKDIR /src
COPY proto proto
COPY backend/.mvn backend/.mvn
COPY backend/mvnw backend/pom.xml backend/
RUN cd backend && sh mvnw -B -q dependency:go-offline
COPY backend/src backend/src
RUN cd backend && sh mvnw -B -q package -DskipTests && cp target/backend-*.jar /app.jar

# Precompiled GraphHopper graph: the server loads it from disk instead of importing on every start.
COPY data/maracaibo.osm.pbf /osm/maracaibo.osm.pbf
RUN java -Dloader.main=com.transmcbo.routing.GraphImport -cp /app.jar \
    org.springframework.boot.loader.launch.PropertiesLauncher /osm/maracaibo.osm.pbf /graph-cache

FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build /app.jar app.jar
COPY --from=build --chown=app:app /graph-cache graph-cache
USER app

# Render free: 512 MB RAM, 0.1 CPU. Small heap share, serial GC, C1 only (much faster startup on a tiny CPU).
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=65 -XX:+UseSerialGC -XX:TieredStopAtLevel=1 -Xss512k -XX:MaxMetaspaceSize=160m -XX:ReservedCodeCacheSize=48m -XX:+ExitOnOutOfMemoryError" \
    SPRING_PROFILES_ACTIVE=render
EXPOSE 10000
ENTRYPOINT ["java", "-jar", "app.jar"]
