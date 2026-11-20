// RPC healthcheck: проверка, что модули загружены и сервер отвечает.
import { SERVER_VERSION, SUPPORTED_SIM_VERSIONS } from "../version";

export interface HealthcheckResponse {
  status: "ok";
  server_version: string;
  sim_versions: readonly number[];
}

export function buildHealthcheckResponse(): HealthcheckResponse {
  return { status: "ok", server_version: SERVER_VERSION, sim_versions: SUPPORTED_SIM_VERSIONS };
}

/** Nakama ищет RPC по имени глобальной функции, поэтому это объявление функции, а не стрелка. */
export function rpcHealthcheck(
  _ctx: nkruntime.Context,
  _logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  _payload: string,
): string {
  return JSON.stringify(buildHealthcheckResponse());
}
