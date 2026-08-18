package com.femsq.database.service;

import com.femsq.database.dao.RelationDao;
import com.femsq.database.model.relation.RelationRow;
import com.femsq.database.relation.RelationEdgeCatalog;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Сервис relation*: только имена из {@link RelationEdgeCatalog}.
 */
public class DefaultRelationService implements RelationService {

    private static final Logger log = Logger.getLogger(DefaultRelationService.class.getName());

    private final RelationDao relationDao;

    /**
     * @param relationDao JDBC
     */
    public DefaultRelationService(RelationDao relationDao) {
        this.relationDao = Objects.requireNonNull(relationDao, "relationDao");
    }

    @Override
    public Optional<RelationRow> getNode(String table, int id) {
        log.log(Level.FINE, "relationNode table={0} id={1}", new Object[] {table, id});
        return relationDao.findNode(RelationEdgeCatalog.requireTable(table), id);
    }

    @Override
    public List<RelationRow> expand(String edge, int fromId) {
        log.log(Level.FINE, "relationExpand edge={0} fromId={1}", new Object[] {edge, fromId});
        return relationDao.expand(RelationEdgeCatalog.requireEdge(edge), fromId);
    }
}
