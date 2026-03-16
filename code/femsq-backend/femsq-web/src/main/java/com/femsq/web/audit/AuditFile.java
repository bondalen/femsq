package com.femsq.web.audit;

/**
 * Описание файла, участвующего в ревизии (строка из ags.ra_f).
 *
 * На текущем этапе содержит только минимальный набор полей, достаточный
 * для заглушек обработчиков.
 */
public class AuditFile {

    private final long id;       // ключ ra_f.af_key
    private final String path;   // полный путь к файлу на диске
    private final Integer type;  // af_type (тип файла)
    private final Integer source; // af_source или аналогичный признак

    public AuditFile(long id, String path, Integer type, Integer source) {
        this.id = id;
        this.path = path;
        this.type = type;
        this.source = source;
    }

    public long getId() {
        return id;
    }

    public String getPath() {
        return path;
    }

    public Integer getType() {
        return type;
    }

    public Integer getSource() {
        return source;
    }
}
