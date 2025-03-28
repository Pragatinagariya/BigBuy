import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_return_requests.dart';
import 'globals.dart';
import 'dart:convert';
import 'cart_detail.dart'; // Import the new page
import 'dashboard.dart';
import 'globals.dart' as globals;
import 'shared_pref_helper.dart';
import 'company.dart';
import 'category.dart';
import 'mycart.dart';
import 'order.dart';
import 'myorders.dart';
class OrdersPage extends StatefulWidget {
  final String userid;
  const OrdersPage({required this.userid,super.key});

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List data = [];
 bool showCart = false;
  bool showOrder = false;
  int cartQty = 0;
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
    fetchData();
    fetchCartQty();
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
        }case 5: // ✅ Admin's "Return Requests" Page
      if (globals.usertype == 'A') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AdminReturnRequestsPage()),
        );
      }
      break;

    }
  }
  Future<double> fetchRate( String itemId, int qty) async {
  final Uri url = Uri.parse('https://tlr.amisys.in/android/PHP/v0/get_rate_by_ratelist_2.php');

  try {
    final response = await http.get(
      url.replace(queryParameters: {
        'custid': globals.userid!,
        'itemid': itemId,
        'qty': qty.toString(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success' && data['rate'] != null) {
        return double.parse(data['rate'].toString());
      } else {
        throw Exception('Failed to fetch rate: ${data["message"]}');
      }
    } else {
      throw Exception('Failed to load rate, status: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching rate: $e');
    return 0.0; // Return a default rate in case of error
  }
}
  Future<void> fetchData() async {
    String uri = "${uriname}orders.php"; // Correct URL with host
    try {
      var res = await http.get(Uri.parse(uri));
      if (res.statusCode == 200) {
        var response = jsonDecode(res.body);
        print('Response: $response'); // Print the response for debugging

        if (response is List) {
          setState(() {
            data = response;
          });
        } else if (response is Map<String, dynamic> && response.containsKey('data')) {
          setState(() {
            data = response['data']; // Extract the list from 'data' key
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid data format received')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: ${res.statusCode}')),
        );
      }
    } catch (e) {
      print('Error fetching data: $e'); // Print to console for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart Details'),
        backgroundColor: Colors.orangeAccent,
         leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Dashboard(userid: widget.userid)),
    );
  },
)
      ),
      body: data.isEmpty
          ? const  Center(
            child: Text(
              'Cart is empty  🛒🛒',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          )// Sho // Show loading spinner
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: GestureDetector( // Use GestureDetector for tap detection
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailPage(
                            customerId: data[index]['o_custid'].toString(), // Pass o_custid as customerId
                            customerName: data[index]['o_custname'] ?? 'N/A',
                            quantity: data[index]['o_orderqty'] ?? 'N/A',

                            userid:widget.userid,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${data[index]['o_custname'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              'Qty: ${data[index]['o_orderqty'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
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