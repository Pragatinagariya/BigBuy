import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'globals.dart' as globals;

class ConfirmPage extends StatefulWidget {
  final List cartData; // Data from the cart
  final String userid; // User ID
  final int totalItems; // Total number of items
  final int totalQty; // Total quantity
  final double totalAmt; // Total amount

  const ConfirmPage({super.key, 
    required this.cartData,
    required this.userid,
    required this.totalItems,
    required this.totalQty,
    required this.totalAmt,
  });

  @override
  _ConfirmPageState createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  late TextEditingController quantityController;
  late TextEditingController itemRateController;
  late TextEditingController totalItemsController;

  String selectedOption = 'Pickup'; // Default selected option
  String? selectedValue; // For dropdown
  final List<String> dropdownItems = ['Option 1', 'Option 2', 'Option 3']; // Example dropdown items

  @override
  void initState() {
    super.initState();
    // Initialize controllers with data from the cart
    quantityController = TextEditingController(text: widget.totalQty.toString());
   itemRateController = TextEditingController(text: widget.totalAmt.toString()); // Use totalAmt directly itemRateController = TextEditingController(text: (widget.totalAmt.toString()); // Assuming average rate calculation
    totalItemsController = TextEditingController(text:widget.totalItems.toString());
  }

  @override
  void dispose() {
    // Dispose of the controllers when no longer needed
    quantityController.dispose();
    itemRateController.dispose();
    totalItemsController.dispose();
    super.dispose();
  }
//  int calculateTotalItems() {
//     // Use a Set to find unique items based on a unique identifier (e.g., itemId)
//     Set<String> uniqueItems = widget.cartData.map((item) => item['itemId'].toString()).toSet();
//     return uniqueItems.length;
//   }
  void confirmOrder() async {
    // Use the provided total quantities and amount
    String custId = widget.userid;
    int totalQty = int.parse(quantityController.text);
    int totalItems = widget.totalItems; // Total items from the cart
    double totalAmt = widget.totalAmt;

    String url = "${globals.uriname}order_insert.php";

    try {
      var response = await http.post(
        Uri.parse(url),
        body: {
          "om_custid": custId,
          "om_totalqty": totalQty.toString(),
          "om_noofitems": totalItems.toString(),
          "om_amt": totalAmt.toString(),
          
          "om_deliverytype": selectedOption, // Include delivery method
        },
      );



      print("Response Status: ${response.statusCode}"); // Debugging line
      print("Response Body: ${response.body}"); // Debugging line

      if (response.statusCode == 200) {
        var responseBody = jsonDecode(response.body);
        if (responseBody['success'] == 'true') {
          showSuccessDialog('Order confirmed successfully!');
        } else {
          showErrorSnackBar('Failed to confirm order: ${responseBody['message']}');
        }
      } else {
        showErrorSnackBar('Failed to confirm order. Status code: ${response.statusCode}');
      }
    } catch (e) {
      showErrorSnackBar('Error: $e');
    }
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to the previous page
              },
            ),
          ],
        );
      },
    );
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Order'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Text Field for Item Rate
              TextField(
                controller: itemRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Amount',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // Text Field for Quantity
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Display Total No of Items
              TextField(
                controller:totalItemsController,
                // enabled: false, // Read-only field
                decoration: const InputDecoration(
                  labelText: 'Total No of Items',
                  //  hintText: '${calculateTotalItems()}',  // Pass totalItems from constructor
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Radio Buttons for Pickup and Drop
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Pickup'),
                      leading: Radio<String>(
                        value: 'Pickup',
                        groupValue: selectedOption,
                        onChanged: (String? value) {
                          setState(() {
                            selectedOption = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Delivery'),
                      leading: Radio<String>(
                        value: 'Delivery',
                        groupValue: selectedOption,
                        onChanged: (String? value) {
                          setState(() {
                            selectedOption = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Dropdown Button
              // DropdownButton<String>(
              //   hint: Text('Select an Option'),
              //   value: selectedValue,
              //   isExpanded: true,
              //   items: dropdownItems.map((String item) {
              //     return DropdownMenuItem<String>(
              //       value: item,
              //       child: Text(item),
              //     );
              //   }).toList(),
              //   onChanged: (String? newValue) {
              //     setState(() {
              //       selectedValue = newValue;
              //     });
              //   },
              // ),
              // SizedBox(height: 16),

              // Confirm Button
              ElevatedButton(
                onPressed: () {
                  confirmOrder();
                },
                child: const Text('Confirm Order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
