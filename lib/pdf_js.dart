library pdf_js;

import 'dart:async';
import 'dart:js' as js;

import 'package:path/path.dart';
import 'package:tekartik_browser_utils/js_loader_utils.dart';

import 'pdf.dart';

final String _defaultPackageRoot = 'packages';
final String _defaultJsPath = 'tekartik_pdf_js/js';
final String _pdfJsFile = 'pdf.js';
final String _pdfJsWorkerFile = 'pdf.worker.js';

///
/// Either specify packageRoot (default packages) or jsDir (default packages/tekartik_pdf_js/js)
/// or nothing
Future load({String? packageRoot, String? jsDir}) async {
  if (jsDir != null) {
    if (packageRoot != null) {
      throw 'you cannot specify both packageRoot and jsDir';
    }
  } else {
    packageRoot ??= _defaultPackageRoot;
    jsDir = posix.join(packageRoot, _defaultJsPath);
  }

  await loadJavascriptScript(join(jsDir, _pdfJsFile));
  _pdfJsContext['workerSrc'] = join(jsDir, _pdfJsWorkerFile);
}

js.JsObject? _cachedPdfJsContext;

js.JsObject get _pdfJsContext {
  _cachedPdfJsContext ??= js.context['PDFJS'] as js.JsObject;
  return _cachedPdfJsContext!;
}

class Promise {
  js.JsObject jsObject;
  Completer completer = Completer();
  Promise(this.jsObject) {
    //print(jsObjectOrAnyToDebugString(jsObject));
    void then(Object? result) {
      completer.complete(result);
    }

    void onError(Object e) {
      try {
        throw e;
      } catch (e, st) {
        completer.completeError(e, st);
      }
    }

    jsObject.callMethod('then', [then, onError]);
  }
  Future get future => completer.future;
}

Future<Pdf> getDocument(String url) async {
  var promise =
      Promise(_pdfJsContext.callMethod('getDocument', [url]) as js.JsObject);
  var pdf = Pdf((await promise.future) as js.JsObject);
  return pdf;
}

Future<Pdf> getPdf({String? url, Object? data}) async {
  Promise promise;
  if (data != null) {
    promise =
        Promise(_pdfJsContext.callMethod('getDocument', [data]) as js.JsObject);
  } else {
    promise =
        Promise(_pdfJsContext.callMethod('getDocument', [url]) as js.JsObject);
  }
  var pdf = Pdf((await promise.future) as js.JsObject);
  return pdf;
}
