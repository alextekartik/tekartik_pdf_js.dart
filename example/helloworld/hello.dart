// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:js' as js;
import 'package:tekartik_pdf_js/pdf_js.dart' as pdf_js;
import 'package:tekartik_pdf_js/pdf.dart';

_msg(String msg) {
  querySelector('#output').text = msg;
}
main() async {
  _msg("Loading pdf.js");
  await pdf_js.load();

  // Fetch the PDF document from the URL
  _msg("Loading pdf file");
  Pdf pdf = await pdf_js.getDocument('../js/helloworld/helloworld.pdf');
  PdfPage page = await pdf.getPage(1);
  num scale = 1.5;
  PdfPageViewport viewport = page.getViewport(scale);

  //
  // Prepare canvas using PDF page dimensions
  //
  CanvasElement canvas = document.getElementById('the-canvas');
  // This is not working!
  // var context = new js.JsObject.fromBrowserObject(canvas.getContext('2d'));
  var context = new js.JsObject.fromBrowserObject(canvas).callMethod('getContext', ['2d']);
  canvas.height = viewport.height;
  canvas.width = viewport.width;

  //
  // Render PDF page into canvas context
  //
  RenderParameters renderContext = new RenderParameters()
    ..canvasContext = context
    ..viewport = viewport;
  _msg("rendering");
  await page.render(renderContext);
  querySelector('#output').text = 'rendering done...';
}
