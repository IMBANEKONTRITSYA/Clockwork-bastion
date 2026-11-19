import { buildHealthcheckResponse, rpcHealthcheck } from "../src/rpc/healthcheck";
import { SERVER_VERSION } from "../src/version";

describe("healthcheck", () => {
  test("отвечает ok с версиями сервера и симуляции", () => {
    expect(buildHealthcheckResponse()).toEqual({
      status: "ok",
      server_version: SERVER_VERSION,
      sim_versions: [1],
    });
  });

  test("RPC возвращает тот же ответ в JSON и игнорирует payload", () => {
    const ctx = {} as nkruntime.Context;
    const logger = {} as nkruntime.Logger;
    const nk = {} as nkruntime.Nakama;
    const parsed: unknown = JSON.parse(rpcHealthcheck(ctx, logger, nk, '{"evil":true}'));
    expect(parsed).toEqual(buildHealthcheckResponse());
  });
});
