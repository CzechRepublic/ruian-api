import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:js' as js;

Future<Null> main() async {
  await window.onLoad.first;

  querySelector('#generateOk')?.onClick?.listen(closeModal);

  js.context['dartRecaptchaHandler'] = recaptchaHandler;
}

Future recaptchaHandler(String code) async {
  InputElement email = querySelector('#generateEmail');

  String emailValue = email.value;
  emailValue = emailValue.replaceAll(new RegExp(r"\+"), '%2B');

  if (new RegExp(
          r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$")
      .hasMatch(emailValue)) {
    String url = 'api/v1/ruian/apikey?email=$emailValue&recaptcha=$code';

    HttpRequest request = await HttpRequest.request(url);

    Map map = JSON.decode(request.response);

    if (map['data'] == 'old') {
      querySelector('#generateNew').style.display = 'none';
      querySelector('#generateOld').style.display = 'block';
      querySelector('#generateWrong').style.display = 'none';
    } else if (map['data'] == 'new') {
      querySelector('#generateNew').style.display = 'block';
      querySelector('#generateOld').style.display = 'none';
      querySelector('#generateWrong').style.display = 'none';
    } else {
      querySelector('#generateNew').style.display = 'none';
      querySelector('#generateOld').style.display = 'none';
      querySelector('#generateWrong').style.display = 'block';
    }

    email.value = '';

    querySelector('#generateModal').style.display = 'block';
  } else {
    querySelector('#generateNew').style.display = 'none';
    querySelector('#generateOld').style.display = 'none';
    querySelector('#generateWrong').style.display = 'block';

    querySelector('#generateModal').style.display = 'block';
  }
}

void closeModal(MouseEvent event) {
  querySelector('#generateModal').style.display = 'none';
  querySelector('#generateNew').style.display = 'none';
  querySelector('#generateOld').style.display = 'none';
  querySelector('#generateWrong').style.display = 'none';
}
