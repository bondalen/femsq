package com.femsq.database.ipglog;

import java.util.function.BiConsumer;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Общие помощники эмиттеров лога загрузки ИП: сборка накопительного HTML и «тихая» запись в БД.
 */
public final class ImpIpgLoadLogSupport {

    /** Максимум примеров строк в свёртке ошибок одного кода. */
    public static final int MAX_ERROR_SAMPLES = 20;

    private ImpIpgLoadLogSupport() {
    }

    /**
     * Собирает накопительный HTML (предыдущий лог сессии + текущая операция) и при необходимости
     * сохраняет его. Сбой записи лога не прерывает бизнес-операцию — только предупреждение.
     *
     * @param ctx          контекст текущей операции
     * @param previousHtml {@code iilResults} до операции (nullable)
     * @param persist      писать в БД (false — только вернуть, например dry-run / превью)
     * @param saver        {@code (loadKey, html)} → запись в {@code iilResults}
     * @param loadKey      ключ сессии
     * @param log          логгер вызывающего класса
     * @return накопительный HTML
     */
    public static String finishAndPersist(
            ImpIpgLoadLogContext ctx,
            String previousHtml,
            boolean persist,
            BiConsumer<Integer, String> saver,
            int loadKey,
            Logger log) {
        String html = ctx.buildHtmlLog(previousHtml);
        if (persist && saver != null) {
            try {
                saver.accept(loadKey, html);
            } catch (RuntimeException ex) {
                log.log(Level.WARNING, "Не удалось сохранить iilResults load=" + loadKey, ex);
            }
        }
        return html;
    }
}
