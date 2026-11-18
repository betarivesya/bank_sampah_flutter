import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'google_sign_in_button_stub.dart'
    if (dart.library.js_interop) 'google_sign_in_button_web.dart'
    as implementation;

Widget buildGoogleSignInButton() {
  return implementation.buildGoogleSignInButton();
}
