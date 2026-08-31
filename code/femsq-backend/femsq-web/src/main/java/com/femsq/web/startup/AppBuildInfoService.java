package com.femsq.web.startup;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.InputStream;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.springframework.boot.info.BuildProperties;
import org.springframework.stereotype.Service;

/**
 * Версия приложения из Spring Boot build-info (приоритет) или lib-manifest.json.
 */
@Service
public class AppBuildInfoService {

    private static final Logger log = Logger.getLogger(AppBuildInfoService.class.getName());
    private static final String MANIFEST_PATH = "META-INF/lib-manifest.json";

    private final String appVersion;

    /**
     * @param buildProperties метаданные сборки Spring Boot ({@code META-INF/build-info.properties})
     */
    public AppBuildInfoService(Optional<BuildProperties> buildProperties) {
        this.appVersion = buildProperties
                .map(BuildProperties::getVersion)
                .filter(version -> version != null && !version.isBlank())
                .orElseGet(AppBuildInfoService::loadAppVersionFromLibManifest);
        log.info(() -> "FEMSQ app version: " + appVersion);
    }

    /**
     * @return строка версии, например {@code 0.1.0.235-SNAPSHOT}
     */
    public String getAppVersion() {
        return appVersion;
    }

    private static String loadAppVersionFromLibManifest() {
        ObjectMapper mapper = new ObjectMapper();
        try (InputStream input = AppBuildInfoService.class.getClassLoader().getResourceAsStream(MANIFEST_PATH)) {
            if (input == null) {
                log.warning("lib-manifest.json not found — app version unknown");
                return "unknown";
            }
            JsonNode root = mapper.readTree(input);
            JsonNode buildInfo = root.get("buildInfo");
            if (buildInfo != null && buildInfo.has("appVersion")) {
                String version = buildInfo.get("appVersion").asText();
                if (version != null && !version.isBlank()) {
                    return version.trim();
                }
            }
        } catch (Exception exception) {
            log.log(Level.WARNING, "Failed to read app version from lib-manifest.json", exception);
        }
        return "unknown";
    }
}
