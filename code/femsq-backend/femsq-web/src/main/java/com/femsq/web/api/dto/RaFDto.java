package com.femsq.web.api.dto;

import java.time.LocalDateTime;

/**
 * DTO представление файла для проверки {@code ags.ra_f} для REST API.
 *
 * @param afKey         идентификатор файла
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
public record RaFDto(
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
}
