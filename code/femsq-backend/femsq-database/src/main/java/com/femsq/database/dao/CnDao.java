package com.femsq.database.dao;

import com.femsq.database.model.Cn;
import java.util.Optional;

/**
 * DAO договоров {@code ags.cn}.
 */
public interface CnDao {

    Optional<Cn> findById(int cnKey);

    /**
     * Обновляет {@code cn_date}, {@code cn_note}, {@code cnMark} (не computed {@code cn_number}).
     */
    Cn update(Cn cn);
}
