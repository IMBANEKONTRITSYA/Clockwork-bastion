// Ошибки RPC. Клиент получает код причины в `message` и сам выбирает текст по ключу локализации.

/** Числовые коды gRPC, которые понимает Nakama (см. nkruntime.Codes). */
export const GrpcCode = {
  INVALID_ARGUMENT: 3,
  NOT_FOUND: 5,
  ALREADY_EXISTS: 6,
  PERMISSION_DENIED: 7,
  RESOURCE_EXHAUSTED: 8,
  FAILED_PRECONDITION: 9,
  INTERNAL: 13,
  UNAUTHENTICATED: 16,
} as const;

export type GrpcCodeValue = (typeof GrpcCode)[keyof typeof GrpcCode];

/** Причины ошибок игры и соответствующий им код gRPC. */
export const ErrorReason = {
  BAD_REQUEST: GrpcCode.INVALID_ARGUMENT,
  NOT_AUTHENTICATED: GrpcCode.UNAUTHENTICATED,
  FORBIDDEN: GrpcCode.PERMISSION_DENIED,
  NOT_FOUND: GrpcCode.NOT_FOUND,
  ALREADY_DONE: GrpcCode.ALREADY_EXISTS,
  LIMIT_REACHED: GrpcCode.RESOURCE_EXHAUSTED,
  NOT_ENOUGH_CURRENCY: GrpcCode.FAILED_PRECONDITION,
  PAYMENTS_DISABLED: GrpcCode.FAILED_PRECONDITION,
  INTERNAL: GrpcCode.INTERNAL,
} as const;

export type ErrorReasonName = keyof typeof ErrorReason;

/**
 * Ошибка RPC. Nakama читает у брошенного объекта поля `message` и `code`.
 * В `message` — только код причины (без персональных данных), подробности — в `details` для логов.
 */
export class RpcError extends Error {
  readonly code: GrpcCodeValue;
  readonly reason: ErrorReasonName;
  readonly details: string;

  constructor(reason: ErrorReasonName, details = "") {
    super(reason);
    this.name = "RpcError";
    this.reason = reason;
    this.code = ErrorReason[reason];
    this.details = details;
  }
}
