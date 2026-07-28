package com.femsq.database.service;

import com.femsq.database.model.RalpRaAuStatusLookup;
import java.util.List;

/**
 * Константные подписи статусов Au (из логики Access/reconcile computeStatus).
 */
public class DefaultRalpRaAuStatusService implements RalpRaAuStatusService {

    private static final List<RalpRaAuStatusLookup> LOOKUPS = List.of(
            new RalpRaAuStatusLookup(0, "не представлен"),
            new RalpRaAuStatusLookup(1, "в работе"),
            new RalpRaAuStatusLookup(2, "направлен в бухгалтерию"),
            new RalpRaAuStatusLookup(3, "возвращён агенту")
    );

    @Override
    public List<RalpRaAuStatusLookup> getLookups() {
        return LOOKUPS;
    }
}
