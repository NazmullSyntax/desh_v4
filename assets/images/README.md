# Image Assets

This folder is referenced by `assets/data/*.json` but ships empty in this
build (see SETUP_INSTRUCTIONS.md, Section 6, for why).

## Expected filenames

Drop real photos in `destinations/` using these exact names to light up
the 9 researched destinations without touching any JSON or Dart code:

```
destinations/coxsbazar_1.jpg, coxsbazar_2.jpg, coxsbazar_3.jpg
destinations/sundarbans_1.jpg, sundarbans_2.jpg, sundarbans_3.jpg
destinations/sreemangal_1.jpg, sreemangal_2.jpg
destinations/paharpur_1.jpg, paharpur_2.jpg
destinations/nilgiri_1.jpg, nilgiri_2.jpg
destinations/shashilodge_1.jpg
destinations/kuakata_1.jpg, kuakata_2.jpg
destinations/tajhat_1.jpg
destinations/lalbagh_1.jpg
destinations/ahsanmanzil_1.jpg

destinations/hotel_placeholder.jpg   (used by all sample hotels)
destinations/place_placeholder.jpg   (used by "nearby" reference cards)

destinations/dhaka_division.jpg, chittagong_division.jpg, khulna_division.jpg,
destinations/sylhet_division.jpg, rajshahi_division.jpg, barisal_division.jpg,
destinations/rangpur_division.jpg, mymensingh_division.jpg

destinations/<district_id>.jpg   (one per district — see districts.json
                                   for the full list of 64 ids; districts
                                   without rich data still show this image
                                   in the district list)
```

## Faster alternative

You don't have to source real photos to demo the app. Open any of the
JSON files in `assets/data/` and replace the asset paths with real
`https://` image URLs (e.g. from Unsplash) — `AppNetworkImage`
(`lib/widgets/common/app_network_image.dart`) transparently supports both
local assets and network URLs, no code changes required.

## Until images are added

`AppNetworkImage` catches the missing-asset error and shows a neutral
placeholder icon instead of crashing, so the app remains fully navigable
without any images in place.
