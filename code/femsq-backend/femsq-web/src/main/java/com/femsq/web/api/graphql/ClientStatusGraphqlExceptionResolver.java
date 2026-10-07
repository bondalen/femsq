package com.femsq.web.api.graphql;

import graphql.GraphQLError;
import graphql.GraphqlErrorBuilder;
import graphql.schema.DataFetchingEnvironment;
import org.springframework.graphql.execution.DataFetcherExceptionResolverAdapter;
import org.springframework.graphql.execution.ErrorType;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

/**
 * Отдаёт клиенту текст {@link ResponseStatusException} со статусом 4xx.
 * Иначе Spring GraphQL подменяет его на {@code INTERNAL_ERROR} и идентификатор запроса.
 */
@Component
public class ClientStatusGraphqlExceptionResolver extends DataFetcherExceptionResolverAdapter {

    @Override
    protected GraphQLError resolveToSingleError(Throwable ex, DataFetchingEnvironment env) {
        ResponseStatusException status = findStatus(ex);
        if (status == null || !status.getStatusCode().is4xxClientError()) {
            return null;
        }
        String message = status.getReason();
        if (message == null || message.isBlank()) {
            return null;
        }
        return GraphqlErrorBuilder.newError(env)
                .errorType(ErrorType.BAD_REQUEST)
                .message(message)
                .build();
    }

    private static ResponseStatusException findStatus(Throwable error) {
        Throwable current = error;
        while (current != null) {
            if (current instanceof ResponseStatusException status) {
                return status;
            }
            current = current.getCause();
        }
        return null;
    }
}
