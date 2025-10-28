// utils/waitForPrimary.js
export async function waitForPrimary(conn, timeoutMs = 30000) {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    try {
      const hello = await conn.db.admin().command({ hello: 1 });
      if (hello.isWritablePrimary) return true;
    } catch (_) {}
    await new Promise((r) => setTimeout(r, 1000));
  }
  throw new Error('Replica set is not PRIMARY after timeout');
}
