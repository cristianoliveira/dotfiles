// Cache each machine independently; publish results as each bounded scan finishes.
export const CACHE_TTL_MS = 60_000;

function validResult(value) {
  return value && Array.isArray(value.projects) && Array.isArray(value.warnings)
    && value.warnings.every(warning => typeof warning === "string")
    && value.projects.every(project => project
      && typeof project.label === "string" && project.label
      && typeof project.folder === "string" && project.folder
      && (project.spaceId == null || typeof project.spaceId === "string"));
}

export function restoreProjectCache(value) {
  if (value?.version !== 1 || !Array.isArray(value.entries)) return [];
  return value.entries.filter(entry => entry && typeof entry.machine === "string"
    && Number.isFinite(entry.updatedAt) && validResult(entry));
}

export async function refreshProjects({ cache, machines, now = Date.now, scan, publish, persist }) {
  const entries = new Map(cache.map(entry => [entry.machine, entry]));
  const names = [...new Set(machines)];
  const errors = new Map();
  const pending = names.filter(machine => {
    const entry = entries.get(machine);
    const age = entry ? now() - entry.updatedAt : Infinity;
    return age < 0 || age >= CACHE_TTL_MS;
  });
  let remaining = pending.length;
  const emit = () => publish({
    projects: names.flatMap(machine => (entries.get(machine)?.projects ?? [])
      .map(project => ({ ...project, machine }))),
    warnings: names.flatMap(machine => [
      ...(entries.get(machine)?.warnings ?? []).map(warning => `${machine || "local"}: ${warning}`),
      ...(errors.has(machine) ? [errors.get(machine)] : []),
    ]),
    loading: remaining > 0,
  });
  emit();

  let next = 0;
  const worker = async () => {
    while (next < pending.length) {
      const machine = pending[next++];
      try {
        const result = await scan(machine);
        if (!validResult(result)) throw new Error("Invalid project discovery result");
        const entry = { machine, updatedAt: now(), projects: result.projects, warnings: result.warnings };
        entries.set(machine, entry);
        persist(entry);
      } catch (error) {
        const kept = entries.has(machine) ? " (cached projects retained)" : "";
        errors.set(machine, `${machine || "local"}: ${error.message}${kept}`);
      }
      remaining--;
      emit();
    }
  };
  await Promise.all(Array.from({ length: Math.min(4, pending.length) }, worker));
}
