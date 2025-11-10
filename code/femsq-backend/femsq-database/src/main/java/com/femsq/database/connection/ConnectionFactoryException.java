package com.femsq.database.connection;

/**
 * Runtime exception thrown when the {@link ConnectionFactory} fails to create a JDBC connection.
 */
public class ConnectionFactoryException extends RuntimeException {

    public ConnectionFactoryException(String message, Throwable cause) {
        super(message, cause);
    }
}
