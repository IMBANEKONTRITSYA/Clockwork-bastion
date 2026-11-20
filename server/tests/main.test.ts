import "../src/main";
import { RPC_IDS } from "../src/rpc/ids";

type InitModuleFn = (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer,
) => void;

describe("InitModule", () => {
  test("регистрирует все RPC из списка RPC_IDS", () => {
    const registered: string[] = [];
    const initializer = {
      registerRpc: (id: string) => {
        registered.push(id);
      },
    } as unknown as nkruntime.Initializer;
    const logger = { info: jest.fn() } as unknown as nkruntime.Logger;

    const init = (globalThis as Record<string, unknown>)["InitModule"] as InitModuleFn;
    init({} as nkruntime.Context, logger, {} as nkruntime.Nakama, initializer);

    expect(registered.sort()).toEqual(Object.values(RPC_IDS).sort());
  });
});
