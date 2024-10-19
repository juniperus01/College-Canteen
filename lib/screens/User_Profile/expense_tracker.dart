import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExpenseTrackerPage extends StatefulWidget {
  final String email;

  ExpenseTrackerPage({required this.email});

  @override
  _ExpenseTrackerPageState createState() => _ExpenseTrackerPageState();
}

class _ExpenseTrackerPageState extends State<ExpenseTrackerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<Map<String, dynamic>>> groupedExpenses = {};
  bool _isLoading = true;
  double _totalMonthlyExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('user_email', isEqualTo: widget.email)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        for (var doc in snapshot.docs) {
          Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
          String formattedDate = _formatDate(orderData['timestamp']);

          if (!groupedExpenses.containsKey(formattedDate)) {
            groupedExpenses[formattedDate] = [];
          }
          groupedExpenses[formattedDate]!.add(orderData);

          // Calculate total monthly expenses
          _totalMonthlyExpenses += (orderData['totalPrice'] as double? ?? 0.0);
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching expenses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('d MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Your Expenses', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          // Display total expenses of the month
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total Expenses: ₹${_totalMonthlyExpenses.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : groupedExpenses.isEmpty
                    ? Center(child: Text('No expenses available'))
                    : ListView.builder(
                        padding: EdgeInsets.all(16.0),
                        itemCount: groupedExpenses.keys.length,
                        itemBuilder: (context, index) {
                          final dateKey = groupedExpenses.keys.elementAt(index);
                          final expensesForDate = groupedExpenses[dateKey]!;

                          // Calculate total price for this date
                          double totalPriceForDate = expensesForDate.fold(
                              0.0, (sum, order) => sum + (order['totalPrice'] as double? ?? 0.0));

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Date heading
                                Container(
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(15),
                                    ),
                                  ),
                                  child: Text(
                                    dateKey,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListTile(
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Display all expenses for this date
                                        ...expensesForDate.map((order) {
                                          // Ensure 'items' is a List of Maps
                                          final items = (order['items'] as List<dynamic>? ?? []);

                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Display each item with its quantity and price
                                              ...items.map((item) {
                                                final quantity = item['quantity'] ?? 1; // Default to 1 if not provided
                                                final name = item['name'] ?? 'Unknown Item'; // Default name if not provided
                                                final price = item['price'] ?? 0.0; // Default price if not provided

                                                return Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.fastfood, color: Colors.grey),
                                                        SizedBox(width: 8),
                                                        Text(name),
                                                      ],
                                                    ),
                                                    Text('x$quantity'), // Display quantity as x2
                                                  ],
                                                );
                                              }).toList(),
                                              SizedBox(height: 4),
                                            ],
                                          );
                                        }).toList(),
                                        SizedBox(height: 4),
                                      ],
                                    ),
                                  ),
                                ),
                                // Total Price for the date
                                Container(
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.only(
                                      bottomLeft: Radius.circular(15),
                                      bottomRight: Radius.circular(15),
                                    ),
                                  ),
                                  child: Text(
                                    'Total: ₹${totalPriceForDate.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
