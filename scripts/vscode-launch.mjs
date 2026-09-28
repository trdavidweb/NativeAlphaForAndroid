import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const mode = process.argv[2];
if (!["full", "release", "install"].includes(mode)) {
  process.stderr.write("Usage: vscode-launch.mjs {full|release|install}\n");
  process.exit(2);
}

const script = fileURLToPath(new URL("./android-vscode.sh", import.meta.url));
const child = spawn("bash", [script, mode], { stdio: "inherit" });
child.on("error", (error) => {
  process.stderr.write(`Unable to start Android command: ${error.message}\n`);
  process.exitCode = 1;
});
child.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
  } else {
    process.exitCode = code ?? 1;
  }
});
