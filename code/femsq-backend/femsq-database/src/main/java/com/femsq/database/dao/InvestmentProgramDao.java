package com.femsq.database.dao;

import com.femsq.database.model.InvestmentProgram;
import java.util.List;

/**
 * DAO для справочника инвестиционных программ с отформатированными названиями.
 */
public interface InvestmentProgramDao {

    /**
     * Возвращает все инвестиционные программы с отформатированными названиями.
     * Название формируется как: "Организация, Год № Номер. Название; с дата по дата"
     */
    List<InvestmentProgram> findAllWithDisplayName();
}
