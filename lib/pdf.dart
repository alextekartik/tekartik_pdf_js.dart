library;

import 'dart:async';
import 'dart:js' as js;

import 'pdf_js.dart' as pdf_js;

class PdfPageViewport {
  final js.JsObject _jsObject;
  PdfPageViewport(this._jsObject);
  // might not be int
  num get width => _jsObject['width'] as num;
  num get height => _jsObject['height'] as num;
}

class PdfPage {
  final js.JsObject _jsObject;
  PdfPage(this._jsObject);
  PdfPageViewport getViewport(num scale) {
    var viewPort = PdfPageViewport(
        _jsObject.callMethod('getViewport', [scale]) as js.JsObject);
    return viewPort;
  }

  Future render(RenderParameters params) {
    var promise = pdf_js.Promise(
        _jsObject.callMethod('render', [params._jsObject]) as js.JsObject);
    return promise.future;
  }
}

class RenderParameters {
  final js.JsObject _jsObject = js.JsObject.jsify({});
  set viewport(PdfPageViewport viewport) =>
      _jsObject['viewport'] = viewport._jsObject;
  set canvasContext(Object canvasContext) =>
      _jsObject['canvasContext'] = canvasContext;
}

class Pdf {
  final js.JsObject _jsObject;
  Pdf(this._jsObject);
  Future<PdfPage> getPage(int pageNum) async {
    var promise = pdf_js.Promise(
        _jsObject.callMethod('getPage', [pageNum]) as js.JsObject);
    var page = PdfPage((await promise.future) as js.JsObject);
    return page;
  }
}
