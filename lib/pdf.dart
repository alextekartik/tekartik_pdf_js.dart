library pdf_js.pdf;

import 'dart:js' as js;
import 'pdf_js.dart' as pdf_js;
import 'dart:async';

class PdfPageViewport {
  js.JsObject _jsObject;
  PdfPageViewport(this._jsObject);
  // might not be int
  num get width => _jsObject['width'];
  num get height => _jsObject['height'];
}

class PdfPage {
  js.JsObject _jsObject;
  PdfPage(this._jsObject);
  PdfPageViewport getViewport(num scale) {
    PdfPageViewport viewPort = new PdfPageViewport(_jsObject.callMethod('getViewport', [scale]));
    return viewPort;
  }
  Future render(RenderParameters params) {
    pdf_js.Promise promise = new pdf_js.Promise(_jsObject.callMethod('render', [params._jsObject]));
    return promise.future;
  }
}

class RenderParameters {
  js.JsObject _jsObject = new js.JsObject.jsify({});
  set viewport(PdfPageViewport viewport) => _jsObject['viewport'] = viewport._jsObject;
  set canvasContext(var canvasContext) => _jsObject['canvasContext'] = canvasContext;
}
class Pdf {
  js.JsObject _jsObject;
  Pdf(this._jsObject);
  Future getPage(int pageNum) async {
    pdf_js.Promise promise = new pdf_js.Promise(_jsObject.callMethod('getPage', [pageNum]));
    PdfPage page = new PdfPage(await promise.future);
    return page;
  }

}