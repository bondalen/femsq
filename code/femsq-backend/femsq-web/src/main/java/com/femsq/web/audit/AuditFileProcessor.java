package com.femsq.web.audit;

/**
 * Интерфейс обработчика одного файла ревизии.
 *
 * Разные реализации будут отвечать за разные типы файлов (af_type)
 * и логику анализа листов внутри Excel.
 */
public interface AuditFileProcessor {

    /**
     * Проверяет, поддерживает ли обработчик указанный тип файла.
     *
     * @param type значение af_type
     * @return true, если обработчик может обрабатывать этот тип
     */
    boolean supports(Integer type);

    /**
     * Выполняет обработку файла в контексте ревизии.
     * На текущем этапе реализации — только заглушка c логированием.
     *
     * @param context контекст выполнения ревизии
     * @param file    описание файла
     */
    void process(AuditExecutionContext context, AuditFile file);
}
