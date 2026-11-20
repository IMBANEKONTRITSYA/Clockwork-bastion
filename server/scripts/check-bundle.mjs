// Проверка собранного модуля: Nakama (goja) требует глобальные объявления функций
// InitModule и RPC и не понимает import/export.
import { readFileSync } from "node:fs";

const code = readFileSync(new URL("../build/index.js", import.meta.url), "utf8");
const required = ["function InitModule(", "function rpcHealthcheck("];
const problems = required.filter((s) => !code.includes(s)).map((s) => `нет «${s}»`);
if (/^\s*(export|import)\s/m.test(code)) problems.push("в сборке остались import/export");
if (problems.length > 0) {
  console.error(`build/index.js не годится для Nakama: ${problems.join("; ")}`);
  process.exit(1);
}
console.log("build/index.js: ок");
