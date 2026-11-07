function summary(space) {
  return {
    id: space.id,
    name: space.name,
    machine: space.machine,
    tabs: space.tabs.map((tab) => ({ id: tab.id, panes: tab.panes })),
  };
}

export function filterSpaces(spaces, query) {
  const words = query.toLowerCase().trim().split(/\s+/);
  return spaces.filter((space) => {
    const label = `${space.machine ?? "local"} ${space.name} ${space.folder}`.toLowerCase();
    return words.every((word) => label.includes(word));
  });
}

export class SpaceCloser {
  constructor() {
    this.selected = new Set();
    this.review = null;
    this.submitted = false;
  }

  toggle(id, spaces) {
    if (this.review || this.submitted || !spaces.some((space) => space.id === id)) return;
    if (this.selected.has(id)) this.selected.delete(id);
    else this.selected.add(id);
  }

  beginReview(spaces) {
    if (this.submitted) return false;
    const selected = spaces.filter((space) => this.selected.has(space.id));
    this.selected = new Set(selected.map((space) => space.id));
    this.review = selected.length ? selected.map(summary) : null;
    return this.review !== null;
  }

  back() {
    this.review = null;
  }

  cancel() {
    this.selected.clear();
    this.review = null;
    this.submitted = true;
  }

  confirm(spaces) {
    if (!this.review || this.submitted) return { status: "unconfirmed", commands: [] };

    const current = this.review.map((reviewed) => spaces.find((space) => space.id === reviewed.id));
    if (current.some((space) => !space) ||
        JSON.stringify(current.map(summary)) !== JSON.stringify(this.review)) {
      this.back();
      return { status: "changed", commands: [] };
    }

    this.submitted = true;
    return {
      status: "ready",
      commands: this.review.map((space) => ["space.close", { id: space.id, confirmed: true }]),
    };
  }
}
