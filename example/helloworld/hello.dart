// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_print

import 'dart:html';
import 'dart:js' as js;

import 'package:tekartik_pdf_js/pdf.dart';
import 'package:tekartik_pdf_js/pdf_js.dart' as pdf_js;

void _msg(String msg) {
  querySelector('#output')!.text = msg;
}

Future<void> main() async {
  _msg('Loading pdf.js');
  await pdf_js.load();

  // Fetch the PDF document from the URL
  _msg('Loading pdf file');
  var pdf = await pdf_js.getDocument('../js/helloworld/helloworld.pdf');
  var page = await pdf.getPage(1);
  num scale = 1.5;
  var viewport = page.getViewport(scale);

  //
  // Prepare canvas using PDF page dimensions
  //
  var canvas = document.getElementById('the-canvas') as CanvasElement;
  // This is not working!
  // var context = new js.JsObject.fromBrowserObject(canvas.getContext('2d'));
  var context = js.JsObject.fromBrowserObject(canvas)
      .callMethod('getContext', ['2d']) as js.JsObject;
  canvas.height = viewport.height.toInt();
  canvas.width = viewport.width.toInt();

  //
  // Render PDF page into canvas context
  //
  var renderContext = RenderParameters()
    ..canvasContext = context
    ..viewport = viewport;
  _msg('rendering');
  await page.render(renderContext);
  querySelector('#output')!.text = 'rendering done...';
  print(canvas.toDataUrl());

  var pom = document.createElement('a');
  pom.setAttribute('href', canvas.toDataUrl());
  pom.setAttribute('download', 'image.png');
  pom.innerHtml = 'Download';

  //pom.style.display = 'none';
  document.body!.append(pom);
}
