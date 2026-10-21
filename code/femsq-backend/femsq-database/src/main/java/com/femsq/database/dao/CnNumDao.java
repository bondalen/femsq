package com.femsq.database.dao;

import com.femsq.database.model.CnNum;
import com.femsq.database.model.CnNumColumnFilters;
import com.femsq.database.model.CnNumCreate;
import com.femsq.database.model.CnNumPage;
import java.util.List;

/**
 * DAO номеров договоров {@code ags.cnNum}.
 */
public interface CnNumDao {

    /**
     * Все номера с именем типа, сортировка по {@code cnnNum}.
     */
    List<CnNum> findAll();

    /**
     * Страница master-списка. page с 1, rowsPerPage 1…200.
     * sortBy: {@code cnnNum}, {@code cnnTypeName}, {@code cnnKey}, {@code cnnCn}.
     *
     * @param page страница с 1
     * @param rowsPerPage размер страницы
     * @param filter подстрока номера или типа; целое также ищет cnnKey и cnnCn
     * @param columnFilters AND по колонкам
     * @param sortBy колонка сортировки
     * @param descending true — по убыванию
     * @return страница и totalCount
     */
    CnNumPage findPage(
            int page,
            int rowsPerPage,
            String filter,
            CnNumColumnFilters columnFilters,
            String sortBy,
            boolean descending
    );

    /**
     * Номера, привязанные к договору.
     */
    List<CnNum> findByCnKey(int cnKey);

    /**
     * Добавляет номер к существующему договору.
     *
     * @param input cnKey, cnnNum, cnnType
     * @return созданная строка cnNum
     */
    CnNum create(CnNumCreate input);
}
