package com.femsq.web.audit.staging;

import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * Регистрация {@link AuditStagingProperties} в Spring-контексте.
 */
@Configuration
@EnableConfigurationProperties(AuditStagingProperties.class)
public class AuditStagingConfiguration {
}
