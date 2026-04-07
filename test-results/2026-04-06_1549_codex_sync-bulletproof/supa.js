const fs = require('fs');
const path = require('path');
const SupabaseVerifier = require(path.join(process.cwd(), 'tools', 'debug-server', 'supabase-verifier'));
const envPath = path.join(process.cwd(), 'tools', 'debug-server', '.env.test');
const env = Object.fromEntries(
  fs.readFileSync(envPath, 'utf8')
    .split(/\r?\n/)
    .map(line => line.trim())
    .filter(line => line && !line.startsWith('#') && line.includes('='))
    .map(line => { const i = line.indexOf('='); return [line.slice(0, i), line.slice(i + 1)]; })
);
const verifier = new SupabaseVerifier(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY);
async function main() {
  const [mode, ...args] = process.argv.slice(2);
  if (mode === 'query') {
    const [table, filterJson] = args;
    const filters = filterJson ? JSON.parse(filterJson) : {};
    const rows = await verifier.queryRecords(table, filters);
    process.stdout.write(JSON.stringify(rows));
    return;
  }
  if (mode === 'get') {
    const [table, id] = args;
    const row = await verifier.getRecord(table, id);
    process.stdout.write(JSON.stringify(row));
    return;
  }
  if (mode === 'storage') {
    const [bucket, objectPath] = args;
    const exists = await verifier.verifyStorageObject(bucket, objectPath);
    process.stdout.write(JSON.stringify({ exists }));
    return;
  }
  throw new Error('Unknown mode');
}
main().catch(err => { console.error(err.message); process.exit(1); });
