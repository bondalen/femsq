package com.femsq.web.config;

import graphql.scalars.ExtendedScalars;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.graphql.execution.RuntimeWiringConfigurer;

/**
 * Конфигурация GraphQL скаляров.
 */
@Configuration
public class GraphQlConfig {

    /**
     * Регистрирует поддержку UUID-скаляра для схемы GraphQL.
     *
     * @return конфигуратор RuntimeWiring
     */
    @Bean
    public RuntimeWiringConfigurer uuidScalarConfigurer() {
        return builder -> builder.scalar(ExtendedScalars.UUID);
    }
}
