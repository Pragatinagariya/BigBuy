import 'package:flutter/material.dart';
import 'package:TALREJA/category.dart';
import 'package:TALREJA/company.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Contact_us.dart';
import 'Login.dart';
import 'UserListPage.dart';
import 'UserProfilePage.dart';
import 'admin_return_requests.dart';
import 'globals.dart' as globals; // Import your global variables
import 'category_items.dart';
import 'shared_pref_helper.dart';
import 'order.dart';
import 'cart.dart';
import 'dart:async';
import 'company_item.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'mycart.dart';
import 'item_detail_page.dart';
import 'searchresultpage.dart';
import 'myorders.dart';


class Dashboard extends StatefulWidget {
  final String userid;

  const Dashboard({super.key, required this.userid});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List userData = [];
  List searchResults = [];
  String searchQuery = '';
  List companyData = [];
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isListening = false;
  Timer? _debounce;
  final String _text = '';
  int cartQty = 0;

  @override
  void initState() {
    super.initState();
    print("User Type: ${globals.usertype}");
    // fetchUserTypeAndSetVisibilitysetCartAndOrderVisibility();
    fetchUserTypeAndSetVisibility();

    _requestMicrophonePermission().then((_) {
      _initSpeech();
      fetchCartQty();
      getUserData();
      // searchItems();
      getCompanyData();
    }); // Fetch company categories separately
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (val) => print('Error: $val'),
      onStatus: (val) => print('Status: $val'),
    );
    print('Speech Enabled: $_speechEnabled');
    setState(() {});
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  void _startListening() async {
    if (_speechEnabled && !_speechToText.isListening) {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        onSoundLevelChange: (level) {
          // Handle sound level change if needed
        },
        cancelOnError: true,
        listenFor: Duration(seconds: 30), // Extend listening duration
      );
      setState(() {
        _isListening = true;
      });
    }
  }

  void _stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

// Handle speech result and restart listening if needed
  void _onSpeechResult(SpeechRecognitionResult result) {
    print('Recognized Words: ${result.recognizedWords}');
    setState(() {
      _lastWords = result.recognizedWords;
      _searchController.text =
          _lastWords; // Set search bar text to speech result
    });

    // If still listening, restart after a delay for continuous search
    if (_isListening) {
      Future.delayed(Duration(seconds: 1), () {
        if (!_speechToText.isListening) {
          _startListening(); // Restart listening
        }
      });
    }
  }
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  fetchCartQty(); // Fetch cart quantity when dependencies change
}
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
     
 
    if (state == AppLifecycleState.resumed) {
      // Reinitialize speech to text when the app resumes
       fetchCartQty();
      _initSpeech();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Stop listening if the app is paused or inactive
      _stopListening();
    }
  }
  // Fetch user categories or search result based on query

  Future<void> searchItems(String query) async {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          searchResults = [];
        });
        return;
      }

      String uri = "${globals.uriname}Search.php?name=$query";
      try {
        var response = await http.get(Uri.parse(uri));
        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          if (jsonResponse is List) {
            setState(() {
              searchResults = jsonResponse;
            });
          }
        }
      } catch (e) {
        print('Error during search: $e');
      }
    });
  }

  // Fetch user categories
  Future<void> getUserData() async {
    String uri = "${globals.uriname}itemgroup.php";

    try {
      var response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse is List) {
          setState(() {
            userData = jsonResponse;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  // Fetch company categories
  Future<void> getCompanyData() async {
    String uri = "${globals.uriname}itemcmp.php";

    try {
      var response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse is List) {
          setState(() {
            companyData = jsonResponse;
          });
        }
      }
    } catch (e) {
      print('Error fetching company data: $e');
    }
  }

  int _selectedIndex = 0; // Track the selected index

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the corresponding page based on the index
    switch (index) {
      case 0:
        // Navigate to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => Dashboard(userid: widget.userid)),
        );
        break;
      case 1:
        // Navigate to Categories
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MyHomePage(userid: widget.userid)),
        );
        break;
      case 2:
        // Navigate to Cart
        if (showCart) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CartPagedetail(userid: globals.userid!)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => OrdersPage(userid: widget.userid)),
          );
        }
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CompanyPage(userid: widget.userid)),
        );
        break;
// case 4:
//       // Open the barcode scanner page and await result
//       var res = await Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => const SimpleBarcodeScannerPage()),
//       );
      case 4:
        if (showOrder) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => OrderMasterPage(userid: widget.userid)),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    OrderMasterByCustId(userid: widget.userid)),
          );
        }
      case 5: // ✅ Admin's "Return Requests" Page
        if (globals.usertype == 'A') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminReturnRequestsPage()),
          );
        }
        break;
      // Handle the barcode scan result
      //    if (res is String) {
      //       await fetchAndNavigateToItemDetails(res); // Call the function to fetch item details
      //     }
      //     break;
      // }
    }
  }

  Future<void> fetchAndNavigateToItemDetails(String barcode) async {
    // const String baseImageUrl = 'https://spk.amisys.in/images/';
    final response = await http.get(Uri.parse(
        "${globals.uriname}item_by_barcode.php?ig_barcode=$barcode&ig_custid=${globals.userid!}"));

    if (response.statusCode == 200) {
      List<dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing response: $e')),
        );
        return;
      }

      // Debugging statement
      print('Scanned Barcode: $barcode');
      print('Response Data: $data');

      // Find the item based on the scanned barcode
      final itemData = data.firstWhere(
        (item) =>
            item['im_barcode']?.trim() ==
            barcode.trim(), // Compare trimmed strings
        orElse: () => null, // Return null if no item matches the barcode
      );

      if (itemData != null) {
        // Debugging statement
        print('Item Data: $itemData');

        // Navigate to ItemDetailPages and pass the specific item's data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailPages(
              im_id: itemData["im_id"] ??
                  "unknown_id", // Use the specific item's ID
              userid: widget.userid, // Pass the current user's ID
              // imageUrl: itemData['im_image'] ?? '',
              imageUrl: itemData["im_image"] != null &&
                      itemData["im_image"].isNotEmpty
                  ? '${globals.baseImageUrl}${itemData["im_image"]}'
                  : '${globals.baseImageUrl}0000000.jpg', // Use the specific item's image URL
                      productData: itemData, // Pass the specific item's data
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No item found for this barcode.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch item data.')),
      );
    }
  }

  bool showCart = false;
  bool showOrder = false;
  Future<void> fetchUserTypeAndSetVisibility() async {
    try {
      globals.usertype = await SharedPrefHelper.getUsertype() ??
          'default'; // Set a default if null
      setCartAndOrderVisibility();
    } catch (e) {
      print("Error fetching user type: $e"); // Log the error
    }
  }

  void setCartAndOrderVisibility() {
    if (globals.usertype == 'C') {
      setState(() {
        showCart = true;
        showOrder = true;
      });
    } else if (globals.usertype == 'A') {
      setState(() {
        showCart = false;
        showOrder = false;
      });
    }
  }
  Future<void> fetchCartQty() async {
  String url = '${globals.uriname}cart_qty.php?c_custid=${widget.userid}';  // Use widget.userid dynamically
  print('API URL: $url');  // Debug print to check the URL

  try {
    final response = await http.post(Uri.parse(url), body: {
      'c_custid': widget.userid,  // Pass the logged-in user's ID
    });

    print('Response: ${response.body}');  // Debug print to check the response

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      if (responseBody.isNotEmpty && responseBody[0]['TotalQty'] != null) {
        setState(() {
          cartQty = int.parse(responseBody[0]['TotalQty'].toString());  // Convert string to int
        });
      } else {
        print('Failed to fetch cart quantity or TotalQty is null');
      }
    } else {
      print('Failed to load cart quantity. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching cart quantity: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    // const String baseImageUrl = 'https://spk.amisys.in/images/';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Row(
          children: [
            Expanded(
              // Expands the search bar to take the remaining space in the AppBar
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  // padding: const EdgeInsets.only(left: 10),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 10), // Aligns text vertically
                  labelText: "Search",
                  fillColor: Colors.white,
                  filled: true, // Fill the search bar background
                  isDense: true, // Reduces height for the TextField in AppBar
                  suffixIcon: Padding(
                    // mainAxisSize: MainAxisSize.min,
                    padding: const EdgeInsets.only(left: 10),
                    child: Wrap(
                      spacing: 0,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isListening
                                ? Icons.mic
                                : Icons
                                    .mic_off, // Change icon based on listening state
                          ),
                          onPressed: () {
                            if (!_isListening) {
                              _startListening();
                            } else {
                              _stopListening();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_rounded),
                          onPressed: () async {
                            // Navigate to the barcode scanner page
                            var res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SimpleBarcodeScannerPage()),
                            );

                            // If a result (barcode) is returned, call the fetch function
                            if (res is String) {
                              await fetchAndNavigateToItemDetails(
                                  res); // Call the function to fetch item details
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchResultPage(
                                  contextquery: _searchController.text,
                                  userid: widget.userid,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width *
            0.55, // Set the width of the Drawer
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  // ✅ Navigate to Profile Page when clicked
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(userid: widget.userid),
                    ),
                  );
                },
                child: Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 20),
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 40, color: Colors.orange),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        globals.username ?? 'C',
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Dashboard(
                            userid: widget.userid)), // Your home page route
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Category'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyHomePage(
                            userid: widget.userid)), // Your category page route
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Company'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            CompanyPage(userid: widget.userid)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: Text(globals.usertype == 'A' ? 'Cart' : 'My Cart'), // Dynamic Text
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartPagedetail(userid: globals.userid!)),
                  );
                },
              ),

              // ✅ Show "Order" for Admin & "My Orders" for Users
              ListTile(
                leading: const Icon(Icons.assignment),
                title: Text(globals.usertype == 'A' ? 'Orders' : 'My Orders'), // Dynamic Text
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderMasterPage(userid: widget.userid)),
                  );
                },
              ),

              if (globals.usertype == 'A') // Show return option only for admin
                ListTile(
                  leading: const Icon(Icons.assignment_return),
                  title: const Text('Returns'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              AdminReturnRequestsPage()),
                    );
                  },
                ),
              if (globals.usertype == 'A')
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('View Customers'), // ✅ Navigate to Customer List
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserListPage()),
                  );
                },
              ),

              if (globals.usertype == 'C')
              ListTile(
                leading: const Icon(Icons.contact_page),
                title: const Text("Contact Us"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ContactUsPage()), // ✅ Open Contact Us Page
                  );
                },
              ),

              // ListTile(
              //   leading: const Icon(Icons.assignment_return, color: Colors.red), // More relevant return icon
              //   title: const Text('Return Requests', style: TextStyle(fontWeight: FontWeight.bold)),
              //   onTap: () {
              //     Navigator.pop(context);
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => AdminReturnRequestsPage()), // Open return requests page
              //     );
              //   },
              // ),

              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log Out'),
                onTap: () async {
                  // Clear the saved login state
                  await SharedPrefHelper.clearLoginState();

                  // Navigate to the login page and clear the previous stack
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) =>
                            const LoginPage()), // Ensure LoginPage is imported and exists
                    (Route<dynamic> route) =>
                        false, // This ensures all previous routes are removed
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: userData.isEmpty && companyData.isEmpty
            ? const Center(child: Text('No data available'))
            : SingleChildScrollView(
                // Add this for scrolling
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Shop by Category',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                    LimitedBox(
                      maxHeight: MediaQuery.of(context).size.height *
                          0.3, // Responsive height
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(5.0),
                        itemCount: userData.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 600
                                  ? 4 // More columns on wider screens
                                  : 3, // Default for smaller screens
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio:
                              MediaQuery.of(context).size.width > 600
                                  ? 1.2
                                  : 0.99,
                        ),
                        itemBuilder: (context, index) {
                          var item = userData[index];
                          String imageUrl =
                              '${globals.baseImageUrl}${item['ig_image']}';
                          return categoryCard(
                            item['ig_name'],
                            imageUrl,
                            item['ig_id'] ?? '',
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MyHomePage(userid: widget.userid),
                          ),
                        );
                      },
                      child: const Text(
                        // Icons.expand_more,
                        // color: Colors.orange,
                        ' Click here for more.....',
                        // color: Colors.orange,
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Shop by Company',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                    LimitedBox(
                      maxHeight: MediaQuery.of(context).size.height *
                          0.3, // Responsive height
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(5.0),
                        itemCount: userData.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 600
                                  ? 4 // More columns on wider screens
                                  : 3, // Default for smaller screens
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio:
                              MediaQuery.of(context).size.width > 600
                                  ? 1.2
                                  : 0.99,
                        ),
                        itemBuilder: (context, index) {
                          var item = companyData[index];
                          String imageUrl =
                              '${globals.baseImageUrl}${item['ic_image']}';



                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CompanyItem(
                                        ig_id: item['ic_id'] ?? '',
                                        ig_custid: globals.userid!,
                                        userid: globals.userid!,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Container(
                                        height: 70,
                                        width: 70,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          image: DecorationImage(
                                            image: imageUrl.startsWith('http')
                                                ? NetworkImage(imageUrl)
                                                : AssetImage(imageUrl)
                                                    as ImageProvider,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                  height:
                                      3), // Adjust the height here if needed
                              SizedBox(
                                width:
                                    75, // Limit the width of the text to the size of the image
                                child: Text(
                                  item['ic_name'],
                                  style: const TextStyle(
                                    fontSize:
                                        12, // Adjust the font size if necessary
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow
                                      .ellipsis, // Handle long text by ellipsizing
                                  maxLines: 1, // Ensure single-line text
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CompanyPage(userid: widget.userid),
                          ),
                        );
                      },
                      child: const Text(
                        // Icons.expand_more,
                        // color: Colors.orange,
                        ' Click here for more.....',
                        // color: Colors.orange,
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
         type: BottomNavigationBarType.fixed, 
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Category',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.shopping_cart),
                if (cartQty > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$cartQty',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: showCart ? 'myCart' : 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Company',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment),
            label: showOrder ? 'myOrder' : 'Order',
          ),
          if (globals.usertype == 'A') // 🔹 Check if the logged-in user is Admin
            const BottomNavigationBarItem(
              icon: Icon(Icons.assignment_return), // Return Icon
              label: 'Returns',
            ),

        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.grey,
        unselectedItemColor: Colors.grey, // Color for unselected items
        showUnselectedLabels: true, // Show labels for unselected items
        onTap: _onItemTapped,
      ),
    );
  }

  Widget categoryCard(String name, String imagePath, String igId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailScreen(
              ig_id: igId ?? '',
              ig_custid: globals.userid!,
              userid: globals.userid!,
               ig_name: name,
               
            ),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              height: 75,
              width: 75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: imagePath.startsWith('http')
                      ? NetworkImage(imagePath)
                      : AssetImage(imagePath) as ImageProvider,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3), // Adjust the height here if needed
          SizedBox(
            width: 75, // Limit the width of the text to the size of the image
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 12, // Adjust the font size if necessary
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
              overflow:
                  TextOverflow.ellipsis, // Handle long text by ellipsizing
              maxLines: 1, // Ensure single-line text
            ),
          ),
        ],
      ),
    );
  }
}
