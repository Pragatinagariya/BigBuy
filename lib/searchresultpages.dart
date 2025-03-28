import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'item_detail.dart';
import 'globals.dart' as globals; // Import your global variables
 // Assuming this is the page to add items to the cart

class SearchResultPages extends StatefulWidget {
  final String contextquery;
  final String userid;
  // final int contextig_id;
   final String contextig_id;

  const SearchResultPages({super.key, required this.contextquery, required this.userid,required this.contextig_id});

  @override
  _SearchResultPagesState createState() => _SearchResultPagesState();
}

class _SearchResultPagesState extends State<SearchResultPages> {
  List searchResults = [];

  @override
void initState() {
  super.initState();
  // Example of calling someFunction with dynamic values
  String dynamicQuery = widget.contextquery; // Assume this comes from a widget property or user input
  String dynamicGrpno = widget.contextig_id; // Same for grpno

  someFunction(dynamicQuery, dynamicGrpno);
}

void someFunction(String query, String grpno) {
  print('Before calling searchItems: Query: $query, Group No: $grpno');
  // Call searchItems with the specified query and group number
  searchItems(query, grpno);
}

Future<void> searchItems(String query, String grpno) async {
  print('Query: $query, Group No: $grpno');
  String uri = "${globals.uriname}Search.php?name=$query&flag=group&grpno=${grpno.trim()}"; // Construct URI
  print('API URI: $uri');
  
  try {
    var response = await http.get(Uri.parse(uri));
    print('Response Status Code: ${response.statusCode}'); // Log the response status

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      print('API Response: $jsonResponse'); // Log the API response
      
      if (jsonResponse is List) {
        setState(() {
          // Filter the results based on the group number
          searchResults = jsonResponse.where((item) => item['im_groupid'] == grpno.trim()).toList();
          print('Filtered Results: $searchResults'); 
        });
      }
    } else {
      print('Error fetching data: ${response.statusCode}'); // Log if not 200
    }
  } catch (e) {
    print('Error fetching search results: $e'); // Log errors
  }
}

  Future<void> addToCart(String itemId, String qty, String rate) async {
    String url = "${globals.uriname}addcart.php";
    try {
      var response = await http.post(
        Uri.parse(url),
        body: {
          'c_custid': widget.userid,
          'c_itemid': itemId,
          'c_qty': qty,
          'c_rate': rate,
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
             setState(() {
            searchResults.firstWhere(
                (item) => item['im_id'] == itemId)['im_cartqty'] = qty;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item added to cart successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add item to cart: ${jsonResponse['message']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed with status code: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
     // const String baseImageUrl = 'https://tlr.amisys.in/images/';
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Results"),
        backgroundColor: Colors.orange,
      ),
      body: searchResults.isEmpty
          ? const Center(child: Text('No results found'))
          : ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
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
                                      productData: searchResults[index],
                                      im_id: searchResults[index]["im_id"],
                                      userid: widget.userid,
                                      imageUrl: searchResults[index]["im_image"] != null &&
                                              searchResults[index]["im_image"].isNotEmpty
                                          ? '${globals.baseImageUrl}${searchResults[index]["im_image"]}'
                                          : '${globals.baseImageUrl}0000000.jpg',
                                      // imageUrl: itemData["im_image"] != null &&
                                      //     itemData["im_image"].isNotEmpty
                                      //     ? '${globals.baseImageUrl}${itemData["im_image"]}'
                                      //     : '${globals.baseImageUrl}0000000.jpg', // Use the specific item's image URL
                                      // productData: itemData,
                                    ),

                                  ),

                                );

                              },

                              child: SizedBox(
                                width: 98,
                                height: 100,
                                child: Image.network(
                                  searchResults[index]["im_image"] != null &&
                                          searchResults[index]["im_image"].isNotEmpty
                                      ? '${globals.baseImageUrl}${searchResults[index]["im_image"]}'
                                      : '${globals.baseImageUrl}0000000.jpg',
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
                                        Text('Packing: ${searchResults[index]["im_packing"] ?? "N/A"}', style: const TextStyle(fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Text('Pcs/Cartoon: ${searchResults[index]["im_pcspercarton"] ?? "N/A"}', style: const TextStyle(fontSize: 14)),
                                        const SizedBox(height: 5),
                                        Text('${searchResults[index]["im_company"] ?? "N/A"}', style: const TextStyle(fontSize: 14, color: Colors.red)),
                                        const SizedBox(height: 15),
                                        Text('MRP: ${searchResults[index]["im_mrp"] ?? "N/A"}', style: const TextStyle(fontSize: 14)),
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
                                            const Icon(Icons.currency_rupee, color: Colors.red, size: 16),
                                            Text('${searchResults[index]["im_rate"] ?? '0.00'}', style: const TextStyle(color: Colors.red, fontSize: 14)),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                                searchResults[index]["im_cartqty"] != null &&
                                                int.tryParse(searchResults[index]
                                                        ["im_cartqty"]) !=
                                                    null &&
                                                int.parse(searchResults[index]
                                                        ["im_cartqty"]) >  0
                                            ? Text(
                                                'Qty: ${searchResults[index]["im_cartqty"]}',
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                            color: Colors.teal))
                                            : const SizedBox.shrink(),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                          ),
                                          child: Text(
                                            searchResults[index]["im_cartqty"] !=
                                                        null &&
                                                    int.tryParse(searchResults[index]
                                                            ["im_cartqty"]) !=
                                                        null &&
                                                    int.parse(searchResults[index]
                                                            ["im_cartqty"]) >
                                                        0
                                                ? 'update Cart'
                                                : 'Add to Cart',
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 10),
                                          ),

                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                TextEditingController quantityController = TextEditingController(text:searchResults[index][
                                                                          "im_cartqty"] !=
                                                                      null &&
                                                                  int.tryParse(searchResults[
                                                                              index]
                                                                          [
                                                                          "im_cartqty"]) !=
                                                                      null
                                                              ? searchResults[index][
                                                                      "im_cartqty"]
                                                                  .toString() // Show existing quantity
                                                              : '', );
 FocusNode quantityFocusNode = FocusNode(); // Define FocusNode
                                        // Request focus after a small delay to ensure dialog renders first
                                         WidgetsBinding.instance.addPostFrameCallback((_) {
                                         quantityFocusNode.requestFocus();
                                         });
                                                return AlertDialog(
                                                  title: const Text("Enter Quantity"),
                                                  content: TextField(
                                                    controller: quantityController,
                                                    focusNode: quantityFocusNode,
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
                                                      onPressed: () {
                                                        String enteredQuantity = quantityController.text;
                                                        if (enteredQuantity.isNotEmpty) {
                                                          addToCart(
                                                            searchResults[index]["im_id"],
                                                            enteredQuantity,
                                                            searchResults[index]["im_rate"].toString(),
                                                          );
                                                          Navigator.of(context).pop(); // Close the dialog
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
                        Text(
                          searchResults[index]["im_name"] ?? "N/A",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
