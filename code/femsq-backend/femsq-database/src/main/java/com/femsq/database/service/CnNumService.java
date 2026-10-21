package com.femsq.database.service;

import com.femsq.database.model.CnNum;
import com.femsq.database.model.CnNumColumnFilters;
import com.femsq.database.model.CnNumCreate;
import com.femsq.database.model.CnNumPage;
import java.util.List;

/**
 * Сервис номеров договоров {@code ags.cnNum}.
 */
public interface CnNumService {

    List<CnNum> getAll();

    /**
     * Страница master-списка номеров.
     *
     * @param page страница с 1
     * @param rowsPerPage размер страницы
     * @param filter общий фильтр
     * @param columnFilters фильтры колонок
     * @param sortBy колонка
     * @param descending направление
     * @return страница
     */
    CnNumPage page(
            int page,
            int rowsPerPage,
            String filter,
            CnNumColumnFilters columnFilters,
            String sortBy,
            boolean descending
    );

    List<CnNum> getByCnKey(int cnKey);

    /**
     * Добавляет номер к существующему договору.
     */
    CnNum create(CnNumCreate input);
}
