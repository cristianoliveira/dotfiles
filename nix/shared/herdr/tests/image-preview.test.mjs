import assert from "node:assert/strict";
import test from "node:test";
import { imagePath, fitImage, previewAsset } from "../mods/image-preview/model.js";

test("path input handles quoted paths without interpreting shell syntax", () => {
  assert.equal(imagePath(' "~/Pictures/a b.png" '), "~/Pictures/a b.png");
  assert.equal(imagePath("/tmp/$(touch NEVER).png"), "/tmp/$(touch NEVER).png");
  for (const path of ["https://example.test/image.png", "a.png\nb.png", "", "a\0.png"]) {
    assert.throws(() => imagePath(path));
  }
});

test("image fits the popup without cropping or stretching", () => {
  assert.deepEqual(fitImage(1600, 800, 800, 600), { width: 800, height: 400 });
  assert.deepEqual(fitImage(800, 1600, 800, 600), { width: 300, height: 600 });
  assert.deepEqual(fitImage(100, 50, 800, 600), { width: 800, height: 400 });
});

test("only staged preview assets may reach the native image loader", () => {
  const name = `image-${"a".repeat(64)}.png`;
  assert.equal(previewAsset({ path: `/app/image-previews/${name}`, width: 1, height: 1 }), `image-previews/${name}`);
  for (const result of [{ path: "https://example.test/a.png" }, { path: "/tmp/random.png", width: 1, height: 1 }]) {
    assert.throws(() => previewAsset(result));
  }
});
