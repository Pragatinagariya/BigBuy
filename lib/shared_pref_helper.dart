

import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {
  static const _keyUsername = 'username';
  static const _keyUserid = 'userid';
  static const _keyUsertype = 'usertype';
  static const _keyLoggedIn = 'isLoggedIn';

  // Save login state
  static Future<void> saveLoginState(String username, String userid,String usertype, bool keepLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyUserid, userid);
    await prefs.setString(_keyUsertype,usertype);
    await prefs.setBool(_keyLoggedIn, keepLoggedIn);
  }

  // Clear login state
 static Future<void> clearLoginState({bool retainUsertype = false}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keyUsername);
  await prefs.remove(_keyUserid);
  await prefs.remove(_keyLoggedIn);

  // Retain usertype if needed

}

  // Check if logged in
  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  // Get the saved username
  static Future<String?> getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername);
  }
    static Future<String?> getUsertype() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsertype);
  }


  // Get the saved userid
  static Future<String?> getUserid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserid);
  }
}
