package com.femsq.database.model;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Представляет файл для проверки (таблица {@code ags.ra_f}) для DAO-слоя.
 *
 * @param afKey         идентификатор файла (PRIMARY KEY)
 * @param afName        имя файла
 * @param afDir         идентификатор директории (FK → ra_dir.key)
 * @param afType        тип файла (1-6: отчёт агента, хранение, аренда земли, инвестиции и т.д.)
 * @param afExecute     флаг: подлежит ли файл рассмотрению/выполнению
 * @param afSource      флаг: брать данные из Excel (true) или из промежуточной таблицы БД (false)
 * @param afCreated     дата создания записи
 * @param afUpdated     дата последнего обновления записи
 * @param raOrgSender   идентификатор организации-отправителя
 * @param afNum         номер файла по порядку (для отображения и сортировки)
 */
public record RaF(
        Long afKey,
        String afName,
        Integer afDir,
        Integer afType,
        Boolean afExecute,
        Boolean afSource,
        LocalDateTime afCreated,
        LocalDateTime afUpdated,
        Integer raOrgSender,
        Integer afNum
) {
    public RaF {
        Objects.requireNonNull(afName, "afName");
        Objects.requireNonNull(afDir, "afDir");
        Objects.requireNonNull(afType, "afType");
        Objects.requireNonNull(afExecute, "afExecute");
    }
}
