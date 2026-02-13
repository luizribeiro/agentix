const { VM } = require("@earendil-works/gondolin");

async function main() {
  if (!process.env.GONDOLIN_GUEST_DIR) {
    throw new Error("GONDOLIN_GUEST_DIR must be set");
  }

  const vm = await VM.create();
  let ssh;
  try {
    ssh = await vm.enableSsh();
    if (!ssh.host || !ssh.port || !ssh.user || !ssh.identityFile) {
      throw new Error("vm.enableSsh() returned incomplete access info");
    }

    const probe = await vm.exec(["/bin/sh", "-lc", "echo ssh-ready"]);
    if (probe.exitCode !== 0 || probe.stdout.trim() !== "ssh-ready") {
      throw new Error(`unexpected probe result: exit=${probe.exitCode}, stdout=${JSON.stringify(probe.stdout)}`);
    }

    console.log(`[gondolin-ssh-smoke] ssh forward ready at ${ssh.user}@${ssh.host}:${ssh.port}`);
  } finally {
    if (ssh) {
      await ssh.close();
    }
    await vm.close();
  }
}

main().catch((error) => {
  console.error("[gondolin-ssh-smoke] FAILED", error);
  process.exit(1);
});
