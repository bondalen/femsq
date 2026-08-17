package com.femsq.database.service;

import com.femsq.database.model.Cn;
import java.util.Optional;

/**
 * Сервис договоров {@code ags.cn}.
 */
public interface CnService {

    Optional<Cn> getById(int cnKey);

    /**
     * Обновляет поля карточки {@code cn} ({@code cn_date}, примечание, метка).
     */
    Cn update(Cn cn);
}
