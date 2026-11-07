export function filterProjects(projects, query) {
  const letters = [...query.trim().toLowerCase()];
  return projects.filter((project) => {
    const label = project.label.toLowerCase();
    let at = 0;
    return letters.every((letter) => {
      const found = label.indexOf(letter, at);
      at = found + 1;
      return found !== -1;
    });
  });
}

export function projectCommand(project, spaces) {
  if (!project) return null;

  const existing = spaces.find((space) => !space.machine && (
    space.id === project.spaceId || space.folder === project.folder
  ));
  if (existing) return ["space.select", { id: existing.id }];

  return ["space.new", { name: project.label, folder: project.folder, machine: "" }];
}
