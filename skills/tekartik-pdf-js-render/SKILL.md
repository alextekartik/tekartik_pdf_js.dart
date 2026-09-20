---
name: tekartik-pdf-js-render
description: >-
  Use when displaying a PDF in a Dart web page (dart2js / build_web_compilers)
  with tekartik_pdf_js, the thin dart:js wrapper over Mozilla PDF.js: the
  pdf_js.load({packageRoot, jsDir}) script loader, getDocument(url),
  getPdf(url:/data:), the Pdf / PdfPage / PdfPageViewport / RenderParameters
  wrappers, page.getViewport(scale), page.render(...), wiring canvasContext to
  a <canvas> 2d context, serving the bundled pdf.js and pdf.worker.js from
  packages/tekartik_pdf_js/js, and the dart:js (non-wasm) limitations.
---

# Rendering PDF pages in the browser (tekartik_pdf_js)

`tekartik_pdf_js` is a small, legacy `dart:js` wrapper around Mozilla's PDF.js.
It ships the PDF.js runtime (`lib/js/pdf.js`, `lib/js/pdf.worker.js`), loads it
into the page at runtime, and exposes just enough API to open a document, take
a page viewport and paint that page into an HTML `<canvas>`.

## Guidelines

* Dependency (git only, `publish_to: none`, the package lives at the repo
  root so there is no `path:`):
  ```yaml
  dependencies:
    tekartik_pdf_js:
      git:
        url: https://github.com/alextekartik/tekartik_pdf_js.dart
  ```
  It pulls `tekartik_browser_utils` (git, `ref: dart3a`) for the script loader
  and `package:path`. Build the app with `build_runner` +
  `build_web_compilers` (both are dev dependencies of the package itself).
* Imports: `package:tekartik_pdf_js/pdf_js.dart` (usually `as pdf_js`) for
  `load`, `getDocument`, `getPdf` and the `Promise` adapter;
  `package:tekartik_pdf_js/pdf.dart` for `Pdf`, `PdfPage`, `PdfPageViewport`
  and `RenderParameters`. `pdf_js.dart` already imports `pdf.dart`, but it
  does not re-export it: import both when you name the wrapper types.
* Always `await pdf_js.load()` once, before any `getDocument` / `getPdf`
  call. It injects `pdf.js` with `loadJavascriptScript` and then sets
  `PDFJS.workerSrc` to the sibling `pdf.worker.js`. Calling `getDocument`
  first throws (`js.context['PDFJS']` is null and is cached on first read).
* `load({String? packageRoot, String? jsDir})` resolves where those two JS
  files are served from:
  - nothing: `packages/tekartik_pdf_js/js` (relative to the page URL);
  - `packageRoot: 'foo'`: `foo/tekartik_pdf_js/js`;
  - `jsDir: '/packages/tekartik_pdf_js/js'`: used verbatim.
  Passing both `packageRoot` and `jsDir` throws a plain `String`. Use an
  absolute `jsDir` whenever the page is not served from the server root
  (`dart run build_runner serve example` serves `packages/` from `/` only),
  or point `jsDir` at your own copy of the two files.
* Documents: `getDocument(String url)` for a URL;
  `getPdf({String? url, Object? data})` for either, where `data` is raw bytes
  (a `Uint8List` crosses `dart:js` as a JS typed array). `getPdf` with
  neither argument calls PDF.js with `null` and fails at runtime.
* Pages are 1-based: `await pdf.getPage(1)`. `page.getViewport(scale)` returns
  a `PdfPageViewport` whose `width` / `height` are `num` (not `int`): call
  `.toInt()` before assigning them to `canvas.width` / `canvas.height`, and
  size the canvas *before* rendering.
* `RenderParameters` is a write-only builder over a jsified `{}`: set
  `canvasContext` and `viewport`, then `await page.render(params)`. There are
  no getters. `canvasContext` must be the *JS* 2d context, obtained with
  `js.JsObject.fromBrowserObject(canvas).callMethod('getContext', ['2d'])`;
  handing it the `dart:html` `CanvasRenderingContext2D` does not work (see the
  comment in `example/helloworld/hello.dart`).
* `Promise` wraps a then-able `JsObject` into a Dart `Future` and is exported
  for wrapping other PDF.js promises yourself; `page.render` and
  `Promise.future` are untyped `Future`s, so `await` them as `dynamic` or for
  their side effect only.
* Scope: this is the whole API. Page count (`numPages`), text content,
  annotations, outlines, `cleanup()` and PDF.js options are not wrapped, and
  the wrappers keep their `JsObject` private, so anything else means talking
  to `js.context['PDFJS']` directly or patching the package.
* Platform: `dart:js` + the legacy `PDFJS` global. Web only, JS output only —
  it does not compile to WebAssembly (`dart compile wasm`, Flutter web wasm)
  and `dart:js` / `dart:html` are deprecated, so treat this package as
  maintenance-only and prefer `package:web` + `dart:js_interop` for new code.
* There is no `test/` directory and no automated test: verify in a browser.
  A quick loop is `dart run build_runner serve example` from the package
  checkout, then open the `helloworld/` page.

## Examples

### Hello world: first page into a canvas

```dart
import 'dart:html';
import 'dart:js' as js;

import 'package:tekartik_pdf_js/pdf.dart';
import 'package:tekartik_pdf_js/pdf_js.dart' as pdf_js;

Future<void> main() async {
  // Serves lib/js/pdf.js and lib/js/pdf.worker.js from the build output.
  await pdf_js.load(jsDir: '/packages/tekartik_pdf_js/js');

  var pdf = await pdf_js.getDocument('/assets/helloworld.pdf');
  var page = await pdf.getPage(1);
  var viewport = page.getViewport(1.5);

  var canvas = document.getElementById('the-canvas') as CanvasElement;
  canvas.width = viewport.width.toInt();
  canvas.height = viewport.height.toInt();
  var context = js.JsObject.fromBrowserObject(canvas)
      .callMethod('getContext', ['2d']) as js.JsObject;

  await page.render(RenderParameters()
    ..canvasContext = context
    ..viewport = viewport);
}
```

### Open a document from bytes

```dart
import 'dart:html';
import 'dart:typed_data';

import 'package:tekartik_pdf_js/pdf.dart';
import 'package:tekartik_pdf_js/pdf_js.dart' as pdf_js;

/// Downloads [url] as bytes and hands them to PDF.js (no second fetch).
Future<Pdf> openPdfBytes(String url) async {
  await pdf_js.load(jsDir: '/packages/tekartik_pdf_js/js');
  var request = await HttpRequest.request(url, responseType: 'arraybuffer');
  var bytes = Uint8List.view(request.response as ByteBuffer);
  return pdf_js.getPdf(data: bytes);
}
```

### Render one page to a PNG data url

```dart
import 'dart:html';
import 'dart:js' as js;

import 'package:tekartik_pdf_js/pdf.dart';

/// Renders [pageNumber] (1-based) of [pdf] off-screen and returns a data url.
Future<String> renderPageToDataUrl(
  Pdf pdf,
  int pageNumber, {
  num scale = 1.5,
}) async {
  var page = await pdf.getPage(pageNumber);
  var viewport = page.getViewport(scale);
  var canvas = CanvasElement(
    width: viewport.width.toInt(),
    height: viewport.height.toInt(),
  );
  var context = js.JsObject.fromBrowserObject(canvas)
      .callMethod('getContext', ['2d']) as js.JsObject;
  await page.render(RenderParameters()
    ..canvasContext = context
    ..viewport = viewport);
  return canvas.toDataUrl();
}
```

### Render pages until PDF.js refuses (no numPages getter)

```dart
import 'dart:html';
import 'dart:js' as js;

import 'package:tekartik_pdf_js/pdf.dart';
import 'package:tekartik_pdf_js/pdf_js.dart' as pdf_js;

/// The wrapper exposes no page count: render 1, 2, 3... until getPage fails.
Future<void> renderAllPages(String url, Element container) async {
  await pdf_js.load(jsDir: '/packages/tekartik_pdf_js/js');
  var pdf = await pdf_js.getPdf(url: url);
  for (var pageNumber = 1;; pageNumber++) {
    PdfPage page;
    try {
      page = await pdf.getPage(pageNumber);
    } catch (_) {
      break; // past the last page
    }
    var viewport = page.getViewport(1);
    var canvas = CanvasElement(
      width: viewport.width.toInt(),
      height: viewport.height.toInt(),
    );
    container.append(canvas);
    var context = js.JsObject.fromBrowserObject(canvas)
        .callMethod('getContext', ['2d']) as js.JsObject;
    await page.render(RenderParameters()
      ..canvasContext = context
      ..viewport = viewport);
  }
}
```

## Common mistakes

* Calling `getDocument` / `getPdf` before `await pdf_js.load()`, or calling
  `load` with both `packageRoot` and `jsDir`.
* Leaving the default `jsDir` while serving the page from a sub-directory:
  `packages/tekartik_pdf_js/js/pdf.js` then resolves under that directory and
  the script (or the worker) 404s.
* Passing a `dart:html` `CanvasRenderingContext2D` as `canvasContext` instead
  of the `JsObject` from `JsObject.fromBrowserObject(canvas)`.
* Assigning `viewport.width` / `viewport.height` (a `num`) directly to
  `canvas.width` / `canvas.height`, or resizing the canvas after `render`
  (resizing clears it).
* Swapping `lib/js/pdf.js` for a modern PDF.js build: this wrapper reads the
  legacy `PDFJS` global, not `pdfjsLib`.
* Expecting it to work in a wasm build or under Flutter web's wasm target.
