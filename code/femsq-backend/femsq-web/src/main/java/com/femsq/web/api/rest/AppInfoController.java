package com.femsq.web.api.rest;

import com.femsq.web.api.dto.AppVersionResponse;
import com.femsq.web.startup.AppBuildInfoService;
import java.util.logging.Logger;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST-контроллер технической информации о приложении (не доменный API).
 */
@RestController
@RequestMapping("/api/v1/app")
public class AppInfoController {

    private static final Logger log = Logger.getLogger(AppInfoController.class.getName());

    private final AppBuildInfoService appBuildInfoService;

    public AppInfoController(AppBuildInfoService appBuildInfoService) {
        this.appBuildInfoService = appBuildInfoService;
    }

    /**
     * Возвращает версию текущей сборки FEMSQ.
     */
    @GetMapping("/version")
    public AppVersionResponse getVersion() {
        String version = appBuildInfoService.getAppVersion();
        log.fine(() -> "Handling GET /api/v1/app/version -> " + version);
        return new AppVersionResponse(version);
    }
}
