import importlib.util
import io
import random
import unittest
from pathlib import Path
from PIL import Image

spec = importlib.util.spec_from_file_location("photos", Path(__file__).resolve().parents[1] / "backend/nuitee/select_photos.py")
photos = importlib.util.module_from_spec(spec)
spec.loader.exec_module(photos)


def fixture(seed, size=400, format="PNG"):
    rng = random.Random(seed)
    image = Image.new("RGB", (16, 16))
    image.putdata([tuple(rng.randrange(256) for _ in range(3)) for _ in range(256)])
    image = image.resize((size, size), Image.Resampling.BICUBIC)
    output = io.BytesIO()
    image.save(output, format=format)
    return output.getvalue()


class PhotoSelectionTest(unittest.TestCase):
    def test_same_photo_other_url_size_and_encoding(self):
        files = {"a": fixture(1), "b": fixture(1), "c": fixture(1, 200, "JPEG"), "d": fixture(2)}
        result = photos.select([{"url": key} for key in files], files.__getitem__)
        self.assertEqual([p["url"] for p in result["verified_photos"]], ["a", "d"])
        self.assertEqual(len(result["rejected"]), 2)

    def test_maximum_five_and_invalid_image(self):
        files = {"bad": b"not an image", **{str(i): fixture(i) for i in range(10)}}
        result = photos.select([{"url": key} for key in files], files.__getitem__)
        self.assertEqual(len(result["verified_photos"]), 5)
        self.assertEqual(result["rejected"][0]["url"], "bad")

    def test_no_unverified_fallback(self):
        with self.assertRaises(ValueError):
            photos.select([{"url": "broken"}], lambda _: b"invalid")


if __name__ == "__main__":
    unittest.main()
