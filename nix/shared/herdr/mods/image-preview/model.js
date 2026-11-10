export function imagePath(value) {
  let path = value.trim();
  if ((path.startsWith('"') && path.endsWith('"')) || (path.startsWith("'") && path.endsWith("'"))) {
    path = path.slice(1, -1);
  }
  if (!path || /[\r\n\0]/.test(path) || path.includes("://")) {
    throw new Error("Paste one image file path, not a URL.");
  }
  return path;
}

export function fitImage(width, height, availableWidth, availableHeight) {
  const scale = Math.min(availableWidth / width, availableHeight / height);
  return { width: width * scale, height: height * scale };
}

export function previewAsset(result) {
  const name = result?.path?.split("/").at(-1) ?? "";
  if (!/^image-[0-9a-f]{64}\.(png|jpg)$/.test(name)
      || !(result.width > 0 && result.height > 0 && result.width * result.height <= 25_000_000)) {
    throw new Error("Invalid preview asset.");
  }
  return `image-previews/${name}`;
}
