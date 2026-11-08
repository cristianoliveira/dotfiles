export function filterProjects(projects, query) {
  const letters = [...query.toLowerCase().replace(/\s+/g, "")];
  return projects.filter((project) => {
    const label = `${project.machine || "local"} ${project.label}`.toLowerCase();
    let at = 0;
    return letters.every((letter) => {
      const found = label.indexOf(letter, at);
      at = found + 1;
      return found !== -1;
    });
  });
}

export function projectKey(project) {
  return JSON.stringify([project.machine || "", project.folder, project.label]);
}

export function projectCommand(project, spaces) {
  if (!project) return null;

  const machine = project.machine || "";
  const existing = spaces.find((space) => (space.machine || "") === machine && (
    space.id === project.spaceId || space.folder === project.folder
  ));
  if (existing) return ["space.select", { id: existing.id }];

  return ["space.new", { name: project.label, folder: project.folder, machine }];
}
