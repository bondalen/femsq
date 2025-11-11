package com.femsq.web.api.rest;

import com.femsq.database.config.ConfigurationFileManager.ConfigurationFileOperationException;
import com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException;
import com.femsq.database.connection.ConnectionFactoryException;
import com.femsq.database.exception.DaoException;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import java.util.logging.Level;
import java.util.logging.Logger;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

/**
 * Глобальный обработчик исключений REST API.
 */
@RestControllerAdvice
public class ApiExceptionHandler {

    private static final Logger log = Logger.getLogger(ApiExceptionHandler.class.getName());

    @ExceptionHandler(ResponseStatusException.class)
    public ResponseEntity<ApiError> handleResponseStatus(ResponseStatusException exception, HttpServletRequest request) {
        HttpStatus status = HttpStatus.resolve(exception.getStatusCode().value());
        return buildError(status != null ? status : HttpStatus.INTERNAL_SERVER_ERROR, exception.getReason(), request);
    }

    @ExceptionHandler(MissingConfigurationException.class)
    public ResponseEntity<ApiError> handleMissingConfiguration(MissingConfigurationException exception, HttpServletRequest request) {
        log.log(Level.WARNING, "Database configuration is missing: {0}", exception.getMessage());
        return buildError(HttpStatus.SERVICE_UNAVAILABLE, exception.getMessage(), request);
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ApiError> handleNoResource(NoResourceFoundException exception, HttpServletRequest request) {
        log.log(Level.FINE, "Static resource not found: {0}", exception.getMessage());
        return buildError(HttpStatus.NOT_FOUND, "Ресурс не найден", request);
    }

    @ExceptionHandler({IllegalArgumentException.class, ConfigurationFileOperationException.class})
    public ResponseEntity<ApiError> handleBadRequest(RuntimeException exception, HttpServletRequest request) {
        log.log(Level.WARNING, "Bad request: " + exception.getMessage(), exception);
        return buildError(HttpStatus.BAD_REQUEST, exception.getMessage(), request);
    }

    @ExceptionHandler({DaoException.class, ConnectionFactoryException.class})
    public ResponseEntity<ApiError> handleInfrastructure(RuntimeException exception, HttpServletRequest request) {
        log.log(Level.SEVERE, "Infrastructure error", exception);
        return buildError(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), request);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleUnknown(Exception exception, HttpServletRequest request) {
        log.log(Level.SEVERE, "Unexpected error", exception);
        return buildError(HttpStatus.INTERNAL_SERVER_ERROR, "Непредвиденная ошибка", request);
    }

    private ResponseEntity<ApiError> buildError(HttpStatus status, String message, HttpServletRequest request) {
        ApiError error = new ApiError(
                Instant.now(),
                status.value(),
                status.getReasonPhrase(),
                message,
                request.getRequestURI()
        );
        return ResponseEntity.status(status).body(error);
    }
}
