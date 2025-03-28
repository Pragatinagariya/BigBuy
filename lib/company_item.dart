import 'package:flutter/material.dart';
import 'package:TALREJA/searchresultcomp.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'UserListPage.dart';
import 'globals.dart' as globals;
import 'item_detail.dart';
import 'mycart.dart';
import 'Login.dart';
import 'myorders.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'shared_pref_helper.dart';
import 'company.dart';
import 'Dashboard.dart';
import 'item_detail_page.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'category.dart';
import 'order.dart';
import 'cart.dart';
import 'admin_return_requests.dart';
class CompanyItem extends StatefulWidget {
  final String ig_id;
  final String ig_custid;
  final String userid;

  const CompanyItem({
    super.key,
    required this.ig_id,
    required this.ig_custid,
    required this.userid,
  });

  @override
  State<CompanyItem> createState() => _CompanyItemState();
}

class _CompanyItemState extends State<CompanyItem> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> userData = []; // Original data
  List<dynamic> filteredData = [];
  // String searchQuery = '';
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  String cmpname = '';
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isListening = false;
  List searchResults = [];
  List<dynamic> currentItem = [];
  String selectedRange = 'A-Z';
bool showCart = false;
  bool showOrder = false;
   int cartQty = 0;
  List<Map<String, dynamic>> cartItems = [];
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

  @override
  void initState() {
    super.initState();
    fetchUserTypeAndSetVisibility();
    fetchCartQty();
     getRecord().then((_) {

    // After fetching data, apply default filter
    if (userData.isNotEmpty) {
      filterByRange('A-Z'); // Apply the 'A-Z' filter automatically
    }
     });
    _initSpeech();
    _searchController.addListener(() {
      if (_searchController.text.isNotEmpty) {
        searchItems(_searchController.text, cmpname);
      } else {
        // If the search bar is empty, reset the filtered data
        setState(() {
          filteredData = userData;
        });
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reinitialize speech to text when the app resumes
      _initSpeech();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Stop listening if the app is paused or inactive
      _stopListening();
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

// Initialize speech recognition
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (val) => print('Error: $val'),
      onStatus: (val) => print('Status: $val'),
    );
    setState(() {
      _isListening = false; // Ensure initial state is not listening
    });
  }

// Start listening to speech
  void _startListening() async {
    if (_speechEnabled && !_speechToText.isListening) {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        cancelOnError: true,
        listenFor: Duration(seconds: 90),
      );
      setState(() {
        _isListening = true;
      });
    }
  }

// Stop listening to speech
  void _stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

// Handle speech result and restart if necessary
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _searchController.text =
          _lastWords; // Set search bar text to speech result
    });

    // Restart listening after delay for continuous search
    Future.delayed(Duration(seconds: 1), () {
      if (!_speechToText.isListening) {
        _startListening(); // Restart listening if not already
      }
    });
  }
  // Initialize speech recognition

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> searchItems(String query, String cmpname) async {
  print('Query: $query, cmpname: $cmpname');
  
  // Constructing the URI with company name, but filtering by item name only
  String uri = "${globals.uriname}Search.php?name=$query&flag=cmp&cmpname=${cmpname.trim()}"; 
  print('API URI: $uri');
  
  try {
    var response = await http.get(Uri.parse(uri));
    print('Response Status Code: ${response.statusCode}'); // Log the response status
    
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      print('API Response: $jsonResponse'); // Log the API response

      if (jsonResponse is List) {
        setState(() {
          // Filter results by item name only (no longer considering cmpname for filtering)
          searchResults = jsonResponse.where((item) {
            String itemName = item['im_name'] ?? '';
            // Check if the item name contains the query (case insensitive)
            return itemName.toLowerCase().contains(query.toLowerCase());
          }).toList();
          
          print('Filtered Results by item name: $searchResults');
        });
      }
    } else {
      print('Error fetching data: ${response.statusCode}'); // Log if not 200
    }
  } catch (e) {
    print('Error fetching search results: $e'); // Log errors
  }
}

  @override
  void dispose() {
    _searchController.dispose();
    _stopListening();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

 

   Future<void> addToCart(String itemId, String qty, String rate) async {
  String url = "${globals.uriname}addcart.php";
  try {
    print('Sending data to add to cart:');
    print('c_custid: ${widget.userid}');
    print('c_itemid: $itemId');
    print('c_qty: $qty');
    print('c_rate: $rate');

    var response = await http.post(
      Uri.parse(url),
      body: {
        'c_custid': widget.userid,
        'c_itemid': itemId,
        'c_qty': qty,
        'c_rate': rate,
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      print('Response from server: $jsonResponse');

      if (jsonResponse['status'] == 'success') {
        // Update local data
        setState(() {
          userData.firstWhere(
                  (item) => item['im_id'] == itemId)['im_cartqty'] = qty;
        });

        // Fetch updated cart quantity
        await fetchCartQty();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added to cart successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed to add item to cart: ${jsonResponse['message']}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed with status code: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
    );
  }
}

  Future<void> getRecord() async {
    String uri =
        "${globals.uriname}item_by_cmp.php?ig_id=${widget.ig_id}&ig_custid=${globals.userid!}"; // Include clientcode in the URL
    try {
      var response = await http.get(Uri.parse(uri));
      print('Raw response body: ${response.body}');
      if (response.statusCode == 200) {
        var jsonResponse;
        try {
          jsonResponse = jsonDecode(response.body);
          print('Parsed JSON Response: $jsonResponse');
        } catch (e) {
          print('JSON decoding error: $e');
          return;
        }
        if (jsonResponse is List) {
          setState(() {
            userData = jsonResponse;
            print("State updated with ${userData.length} items");
          });
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Request error: $e');
    }
  }
Future<double> fetchRate(String itemId, int qty) async {
  // Check if userid is set
  if (globals.userid == null) {
    print('Error: userid is not set. Please login first.');
    return 0.0;
  }

  // Debugging: Log input parameters
  print('Fetching rate with parameters:');
  print('Customer ID: ${globals.userid}');
  print('Item ID: $itemId');
  print('Quantity: $qty');

  final Uri url = Uri.parse('${globals.uriname}get_rate_by_ratelist_2.php');

  try {
    final Map<String, String> queryParams = {
      'custid': globals.userid!,
      'itemid': itemId,
      'qty': qty.toString(),
    };

    final response = await http.get(
      url.replace(queryParameters: queryParams),
    ).timeout(Duration(seconds: 10));

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['status'] == 'success' && data['rate'] != null) {
        double rate = double.parse(data['rate'].toString());
        print('Rate fetched successfully: $rate');
        return rate;
      } else {
        print('Error in response: ${data['message']}');
        throw Exception('Failed to fetch rate: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load rate, HTTP status: ${response.statusCode}');
    }
  } catch (e) {
    print('Exception occurred: $e');
    return 0.0;
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
  void filterByRange(String range) {
  setState(() {
    if (range == 'A-Z') {
      // Show all data for 'A-Z'
      filteredData = userData;
    } else {
      List<String> selectedRangeList;
      switch (range) {
        case 'A-E':
          selectedRangeList = ['A', 'B', 'C', 'D', 'E'];
          break;
        case 'F-J':
          selectedRangeList = ['F','G', 'H', 'I', 'J'];
          break;
        case 'K-O':
          selectedRangeList = ['K','L', 'M', 'N', 'O'];
          break;
        case 'P-T':
          selectedRangeList = ['P','Q', 'R', 'S', 'T'];
          break;
        case 'U-Z':
          selectedRangeList = ['U','V', 'W', 'X', 'Y', 'Z'];
          break;
        default:
          selectedRangeList = [];
          break;
      }

      filteredData = userData.where((item) {
        final name = item["im_name"];
        if (name == null || name.isEmpty) {
          return false;
        }

        final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '';
        if (firstLetter.isEmpty) {
          return false;
        }

        return selectedRangeList.contains(firstLetter);
      }).toList();
    }
  });

  // Debugging Log
  print("Filtered Data: $filteredData");
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
                //  controller: _searchController,
  onChanged: (query) {
    searchItems(query, widget.ig_id); // Call the search function whenever the text changes
  },
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
                            String query = _searchController
                                .text; // Get the query from the controller
                            //  String cmpname = "Godrej";  // Hardcoded company name
                            String cmpname = widget.ig_id;

                            print(
                                'Navigating to SearchResultComp with Query: $query, Company Name: $cmpname');

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchResultComp(
                                  contextquery: query, // Pass the search query
                                  contextic_id:
                                      cmpname, // Pass the hardcoded company name
                                  userid: widget
                                      .userid, // Keep passing the userid as before
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
              Container(
                height: 87.5,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                ),
                child: Center(
                  // Center widget to align content vertically and horizontally
                  child: Text(
                    globals.username ??
                        '', // Fallback to an empty string if username is null
                    style: const TextStyle(color: Colors.white, fontSize: 24),
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
                title: const Text('My Cart'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            CartPagedetail(userid: globals.userid!)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment),
                title: const Text('My Orders'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            OrderMasterPage(userid: widget.userid)),
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
      
      body: Column(
        children: [
          // Heading for the company name
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              "${userData.isNotEmpty ? userData[0]["im_company"] ?? "N/A" : "N/A"}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
          Padding(
  padding: const EdgeInsets.all(8.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: ['A-E', 'F-J', 'K-O', 'P-T', 'U-Z' ,'A-Z'].map((range) {
      bool isSelected = selectedRange == range; // Check if the range is selected

      return SizedBox(
        width: 50,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              selectedRange = range; // Update selected range
              filterByRange(range);   // Trigger filtering
              itemBuilder: (context);
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.orange : Colors.teal, // Highlight selected button
            padding: EdgeInsets.zero,
          ),
          child: Text(
            range,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      );
    }).toList(),
  ),
),

          const SizedBox(height: 1),
          
         Expanded(
  child: (filteredData.isEmpty && searchResults.isEmpty)
      ? Center(
          child: Text('No data found 😑😑', style: TextStyle(fontSize: 16, color: Colors.black)),
        )
      : ListView.builder(
          itemCount: _searchController.text.isEmpty
              ? (filteredData.isNotEmpty ? filteredData.length : userData.length)
              : searchResults.isNotEmpty ? searchResults.length : filteredData.length,
          itemBuilder: (context, index) {
            final currentItem = _searchController.text.isEmpty
                ? (filteredData.isNotEmpty ? filteredData[index] : userData[index])
                : searchResults.isNotEmpty
                    ? searchResults[index]
                    : filteredData[index];
   print(currentItem);
            // Check if currentItem is null to avoid the NoSuchMethodError
            if (currentItem == null) {
              return SizedBox.shrink(); // Return an empty widget if currentItem is null
            }

            // Safely access the im_image property
            final imageUrl = currentItem["im_image"] != null && currentItem["im_image"].isNotEmpty
                ? '${globals.baseImageUrl}${currentItem["im_image"]}'
                : '${globals.baseImageUrl}0000000.jpg';

            return Card(
              margin: const EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                     
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CartPage(
                                  productData: currentItem,
                                  im_id: currentItem["im_id"],
                                  userid: globals.userid ?? '',
                                  imageUrl: imageUrl,
                                ),
                              ),
                            );
                          },
                          child: SizedBox(
                            width: 98,
                            height: 100,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Packing: ${currentItem["im_packing"] ?? "N/A"}',
                                        style: const TextStyle(fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(
                                        'Pcs/Cartoon: ${currentItem["im_pcspercarton"] ?? "N/A"}',
                                        style: const TextStyle(fontSize: 14)),
                                    const SizedBox(height: 5),
                                    Text(
                                        '${currentItem["im_company"] ?? "N/A"}',
                                        style: const TextStyle(fontSize: 14, color: Colors.red)),
                                    const SizedBox(height: 15),
                                    Text(
                                        'MRP: ${currentItem["im_mrp"] ?? "N/A"}',
                                        style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Icon(Icons.currency_rupee,
                                            color: Colors.red, size: 16),
                                        Text(
                                          '${currentItem["im_rate"] ?? '0.00'}',
                                          style: const TextStyle(color: Colors.red, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    currentItem["im_cartqty"] != null &&
                                            int.tryParse(currentItem["im_cartqty"]) != null &&
                                            int.parse(currentItem["im_cartqty"]) > 0
                                        ? Text(
                                            'Qty: ${currentItem["im_cartqty"]}',
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal))
                                        : const SizedBox.shrink(),
                                    const SizedBox(height: 8),
                                    if (globals.usertype == 'C')
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                      child: Text(
                                        currentItem["im_cartqty"] != null &&
                                                int.tryParse(currentItem["im_cartqty"]) != null &&
                                                int.parse(currentItem["im_cartqty"]) > 0
                                            ? 'Update Cart'
                                            : 'Add to Cart',
                                        style: const TextStyle(color: Colors.black, fontSize: 10),
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            TextEditingController quantityController = TextEditingController(
                                              text: currentItem["im_cartqty"] != null &&
                                                      int.tryParse(currentItem["im_cartqty"]) != null
                                                  ? currentItem["im_cartqty"].toString()
                                                  : '',
                                            );
                                            FocusNode quantityFocusNode = FocusNode(); // Define FocusNode
                                        // Request focus after a small delay to ensure dialog renders first
                                         WidgetsBinding.instance.addPostFrameCallback((_) {
                                         quantityFocusNode.requestFocus();
                                         });
                                            return AlertDialog(
                                              title: const Text("Enter Quantity"),
                                              content: TextField(
                                                controller: quantityController,
                                                focusNode:quantityFocusNode,
                                                keyboardType: TextInputType.number,
                                                decoration: const InputDecoration(hintText: "Quantity"),
                                              ),
                                              actions: [
                                                TextButton(
                                                  child: const Text("Cancel"),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                                TextButton(
                                                  child: const Text("OK"),
                                                    onPressed: () async {
  String enteredQuantity = quantityController.text;
  if (enteredQuantity.isNotEmpty) {
    int qty = int.tryParse(enteredQuantity) ?? 0;
    if (qty > 0) {
      // Fetch the rate before adding to cart
      // String custId = 'custId';  // Use dynamic custid if available
      String itemId = currentItem["im_id"].toString();

      double rate = await fetchRate( itemId, qty);  // Fetch rate using API
      if (rate > 0) {
        currentItem["im_rate"] = rate.toStringAsFixed(2);  // Update rate in currentItem
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch rate')),
        );
      }

      // Add to cart with updated rate
      addToCart(itemId, enteredQuantity, currentItem["im_rate"].toString());
      Navigator.of(context).pop(); // Close the dialog
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than 0')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a quantity')),
    );
  }
},
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Second row: Name
                    Text(
                      currentItem["im_name"] ?? "N/A",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
)

        ],
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
}
