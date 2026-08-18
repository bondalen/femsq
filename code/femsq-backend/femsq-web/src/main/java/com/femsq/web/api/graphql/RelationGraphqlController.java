package com.femsq.web.api.graphql;

import com.femsq.database.config.DatabaseConfigurationService.MissingConfigurationException;
import com.femsq.database.exception.DaoException;
import com.femsq.database.model.relation.RelationRow;
import com.femsq.database.service.RelationService;
import java.util.List;
import java.util.logging.Logger;
import org.springframework.graphql.data.method.annotation.Argument;
import org.springframework.graphql.data.method.annotation.QueryMapping;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.web.server.ResponseStatusException;

/**
 * GraphQL обхода связей. Не знает экранов СУДЗ/Договоров.
 */
@Controller
public class RelationGraphqlController {

    private static final Logger log = Logger.getLogger(RelationGraphqlController.class.getName());

    private final RelationService relationService;

    /**
     * @param relationService сервис каталога
     */
    public RelationGraphqlController(RelationService relationService) {
        this.relationService = relationService;
    }

    /**
     * Строка таблицы каталога.
     *
     * @param table имя JSON
     * @param id PK
     * @return строка или {@code null}
     */
    @QueryMapping
    public RelationRow relationNode(@Argument String table, @Argument int id) {
        try {
            return relationService.getNode(table, id).orElse(null);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    /**
     * Раскрытие ребра каталога.
     *
     * @param edge имя JSON
     * @param fromId PK from
     * @return строки to
     */
    @QueryMapping
    public List<RelationRow> relationExpand(@Argument String edge, @Argument int fromId) {
        try {
            return relationService.expand(edge, fromId);
        } catch (IllegalArgumentException exception) {
            throw badRequest(exception);
        } catch (MissingConfigurationException exception) {
            throw unavailable(exception);
        } catch (DaoException exception) {
            throw internal(exception);
        }
    }

    private ResponseStatusException badRequest(IllegalArgumentException exception) {
        log.warning(() -> exception.getMessage());
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, exception.getMessage(), exception);
    }

    private ResponseStatusException unavailable(MissingConfigurationException exception) {
        return new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, exception.getMessage(), exception);
    }

    private ResponseStatusException internal(DaoException exception) {
        return new ResponseStatusException(HttpStatus.INTERNAL_SERVER_ERROR, exception.getMessage(), exception);
    }
}
