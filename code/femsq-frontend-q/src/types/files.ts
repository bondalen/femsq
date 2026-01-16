/**
 * TypeScript типы для работы с файлами ревизий (ra_f)
 * Соответствуют DTO из backend API
 */

/**
 * DTO файла для проверки (ags.ra_f)
 */
export interface RaFDto {
  /** Идентификатор файла (PK) */
  afKey: number;
  
  /** Имя файла */
  afName: string;
  
  /** Идентификатор директории (FK → ra_dir.key) */
  afDir: number;
  
  /** Тип файла (FK → ra_ft.ft_key, 1-6) */
  afType: number;
  
  /** Флаг: подлежит ли файл рассмотрению/выполнению */
  afExecute: boolean;
  
  /** Флаг: брать данные из Excel (true) или из промежуточной таблицы БД (false) */
  afSource: boolean | null;
  
  /** Дата создания записи */
  afCreated: string | null;
  
  /** Дата последнего обновления записи */
  afUpdated: string | null;
  
  /** Идентификатор организации-отправителя (FK → og.ogKey) */
  raOrgSender: number | null;
  
  /** Номер файла по порядку (для отображения и сортировки) */
  afNum: number | null;
}

/**
 * Request для создания нового файла
 */
export interface RaFCreateRequest {
  /** Имя файла (обязательное) */
  afName: string;
  
  /** Идентификатор директории (обязательное) */
  afDir: number;
  
  /** Тип файла (обязательное) */
  afType: number;
  
  /** Флаг выполнения (обязательное) */
  afExecute: boolean;
  
  /** Флаг источника данных */
  afSource?: boolean | null;
  
  /** Идентификатор организации-отправителя */
  raOrgSender?: number | null;
  
  /** Номер файла по порядку */
  afNum?: number | null;
}

/**
 * Request для обновления существующего файла
 */
export interface RaFUpdateRequest {
  /** Имя файла (обязательное) */
  afName: string;
  
  /** Идентификатор директории (обязательное) */
  afDir: number;
  
  /** Тип файла (обязательное) */
  afType: number;
  
  /** Флаг выполнения (обязательное) */
  afExecute: boolean;
  
  /** Флаг источника данных */
  afSource?: boolean | null;
  
  /** Идентификатор организации-отправителя */
  raOrgSender?: number | null;
  
  /** Номер файла по порядку */
  afNum?: number | null;
}

/**
 * DTO типа файла (ags.ra_ft) - справочник для lookup
 */
export interface RaFtDto {
  /** Идентификатор типа файла */
  ftKey: number;
  
  /** Название типа файла (отображается в UI) */
  ftName: string;
}

/**
 * DTO директории (ags.ra_dir)
 */
export interface DirectoryDto {
  /** Идентификатор директории (PK) */
  key: number;
  
  /** Название директории */
  dirName: string;
  
  /** Путь к директории */
  dir: string;
  
  /** Дата создания */
  created: string | null;
  
  /** Дата обновления */
  updated: string | null;
}

/**
 * DTO организации (ags.og) - для lookup отправителя
 */
export interface OrganizationDto {
  /** Идентификатор организации (PK) */
  ogKey: number;
  
  /** Название организации (именительный падеж) */
  ogNm: string;
  
  /** Название организации (родительный падеж) */
  ogNmOf: string;
  
  /** Полное название организации */
  ogNmFl: string | null;
  
  /** ИНН */
  ogINN: number | null;
  
  /** КПП */
  ogKPP: number | null;
  
  /** ОГРН */
  ogOGRN: number | null;
  
  /** ОКПО */
  ogOKPO: number | null;
}

/**
 * Упрощенная версия OrganizationDto для lookup
 */
export interface OrganizationLookupDto {
  /** Идентификатор организации */
  ogKey: number;
  
  /** Название организации (именительный падеж) */
  ogNm: string;
}
