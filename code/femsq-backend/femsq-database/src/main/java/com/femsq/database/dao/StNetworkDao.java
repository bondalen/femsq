package com.femsq.database.dao;

import com.femsq.database.model.StNetwork;
import java.util.List;

/**
 * DAO для справочника структур сети ({@code ags.stNet}).
 */
public interface StNetworkDao {

    /** Возвращает все структуры сети, отсортированные по имени. */
    List<StNetwork> findAllOrdered();
}
