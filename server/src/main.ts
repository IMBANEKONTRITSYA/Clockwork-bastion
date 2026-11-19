// Точка входа модулей Nakama. Регистрирует все RPC.
import { rpcHealthcheck } from "./rpc/healthcheck";
import { RPC_IDS } from "./rpc/ids";
import { SERVER_VERSION } from "./version";

function InitModule(
  _ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer,
): void {
  initializer.registerRpc(RPC_IDS.healthcheck, rpcHealthcheck);
  logger.info("Заводной Бастион: модули загружены, версия %s", SERVER_VERSION);
}

// Nakama ищет InitModule в глобальной области; присваивание не даёт сборщику её выбросить.
(globalThis as Record<string, unknown>)["InitModule"] = InitModule;
