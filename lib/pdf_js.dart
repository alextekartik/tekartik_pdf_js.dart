library pdf_js;

import 'package:tekartik_utils/js_utils.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:js' as js;
import 'pdf.dart';

final String _defaultPackageRoot = "packages";
final String _defaultJsPath = "tekartik_pdf_js/js";
final String _pdfJsFile = "pdf.js";
final String _pdfJsWorkerFile = "pdf.worker.js";

///
/// Either specify packageRoot (default packages) or jsDir (default packages/tekartik_pdf_js/js)
/// or nothing
Future load({String packageRoot, String jsDir}) async {
  if (jsDir != null) {
    if (packageRoot != null) {
      throw "you cannot specify both packageRoot and jsDir";
    }
  } else {
    if (packageRoot == null) {
      packageRoot = _defaultPackageRoot;
    }
    jsDir = posix.join(packageRoot, _defaultJsPath);
  }

  await loadJavascriptScript(join(jsDir, _pdfJsFile));
  _pdfJsContext['workerSrc'] = join(jsDir, _pdfJsWorkerFile);
}

js.JsObject _cachedPdfJsContext;

js.JsObject get _pdfJsContext {
  if (_cachedPdfJsContext == null) {
    _cachedPdfJsContext = js.context['PDFJS'];
  }
  return _cachedPdfJsContext;
}

class Promise {
  js.JsObject jsObject;
  Completer completer = new Completer();
  Promise(this.jsObject) {
    //print(jsObjectOrAnyToDebugString(jsObject));
    var then = (result) {
      completer.complete(result);
    };
    var onError = (e) {
      try {
        throw e;
      } catch (e, st) {
        completer.completeError(e, st);
      }
    };
    jsObject.callMethod('then', [then, onError]);
  }
  Future get future => completer.future;
}

Future getDocument(String url) async {
  Promise promise = new Promise(js.context['PDFJS'].callMethod('getDocument', [url]));
  Pdf pdf = new Pdf(await promise.future);
  return pdf;
}

Future<Pdf> getPdf({String url, var data}) async {
  Promise promise;
  if (data != null) {
    promise = new Promise(js.context['PDFJS'].callMethod('getDocument', [data]));
  } else {
    promise = new Promise(js.context['PDFJS'].callMethod('getDocument', [url]));
  }
  Pdf pdf = new Pdf(await promise.future);
  return pdf;
}
