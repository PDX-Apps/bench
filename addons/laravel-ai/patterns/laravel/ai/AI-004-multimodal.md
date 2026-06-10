# AI-004-multimodal

## Pattern

`laravel/ai` ships first-class **image generation**, **text-to-speech**, **transcription (speech-to-text)**, and **prompt attachments** (send files/images *into* an agent). These are standalone entry points — not Agent classes — each with the same `->queue()->then(...)` and `::fake()` ergonomics as agents.

## Image generation

```php
use Laravel\Ai\Image;

$image = Image::of('A watercolor fox in a misty forest')
    ->landscape()           // ->portrait() / ->square()
    ->quality('high')
    ->generate();           // (provider, model) optional

$path = $image->store();            // or ->storePublicly() — returns the stored path
```

## Text-to-speech (audio)

```php
use Laravel\Ai\Audio;

$audio = Audio::of('Welcome to the show.')
    ->female()              // voice selection helpers
    ->voice('nova')
    ->instructions('Warm, slow, podcast tone.')
    ->generate();

$audio->store();
```

## Transcription (speech-to-text)

```php
use Laravel\Ai\Transcription;

$text = Transcription::fromStorage('recordings/call.mp3')   // ->fromPath / ->fromUpload($request->file('audio'))
    ->diarize()             // label speakers
    ->generate();
```

## Attachments — files/images into an agent

Send documents or images *to* an agent's prompt for analysis:

```php
use Laravel\Ai\Files;

$response = (new InvoiceReader)->prompt(
    'Extract the line items and total.',
    attachments: [
        Files\Document::fromStorage('invoices/2026-04.pdf'),
        Files\Image::fromUpload($request->file('photo')),
    ],
);
```

`Files\Document` / `Files\Image` support `fromPath` / `fromStorage` / `fromUrl` / `fromString` / `fromUpload` / `fromId`.

## Queueing

All of these run async the same way as agents:

```php
Image::of('...')->queue()->then(fn ($image) => $image->store());
```

## Key Points

- `Image::of()`, `Audio::of()`, `Transcription::from*()` — standalone entry points, not Agent classes.
- Generated media: `->store()` / `->storePublicly()` to persist.
- Send files **into** an agent via `prompt(..., attachments: [Files\Document/Image::from*()])`.
- All support `->queue()->then(...)` and `::fake()`.

## When to Use

✅ Generating images/audio, transcribing uploads, or having an agent read a PDF/image.
❌ Don't reach for these when a plain text prompt suffices — they cost more and add latency.

## Compliance

- ⚠️ **Uploaded media may contain PII/EXIF** — strip metadata and scope storage (private disk by default; `storePublicly()` only when intended).
- ⚠️ **Validate uploads** (type + size) before sending to a provider; never forward arbitrary user files unchecked.
