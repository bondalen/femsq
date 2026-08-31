/**
 * Технический REST-клиент информации о приложении (не доменный API).
 */

import { apiGet } from './http';

export interface AppVersionResponse {
  version: string;
}

/**
 * Возвращает версию backend-сборки FEMSQ.
 */
export async function getAppVersion(): Promise<string> {
  const response = await apiGet<AppVersionResponse>('/api/v1/app/version', {
    timeoutMs: 10_000
  });
  return response.version;
}
