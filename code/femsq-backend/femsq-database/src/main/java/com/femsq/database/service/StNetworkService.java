package com.femsq.database.service;

import com.femsq.database.model.StNetwork;
import java.util.List;

/** Сервис для справочника структур сети. */
public interface StNetworkService {

    /** Возвращает все структуры сети, отсортированные по имени. */
    List<StNetwork> getAll();
}
