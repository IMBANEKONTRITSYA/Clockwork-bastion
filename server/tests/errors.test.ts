import { GrpcCode, RpcError } from "../src/errors";

describe("RpcError", () => {
  test("в message только код причины, а code — числовой код gRPC для Nakama", () => {
    const err = new RpcError("LIMIT_REACHED", "user=abc daily=5");
    expect(err.message).toBe("LIMIT_REACHED");
    expect(err.code).toBe(GrpcCode.RESOURCE_EXHAUSTED);
    expect(err.details).toBe("user=abc daily=5");
    expect(err).toBeInstanceOf(Error);
  });

  test("PAYMENTS_DISABLED — отказ по предусловию", () => {
    expect(new RpcError("PAYMENTS_DISABLED").code).toBe(GrpcCode.FAILED_PRECONDITION);
  });
});
