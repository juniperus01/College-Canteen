import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  final String email;

  AdminPage({required this.email});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addFoodItem(String category) async {
    TextEditingController nameController = TextEditingController();
    TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Food Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: 'Item Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _firestore.collection(category).add({
                'name': nameController.text,
                'price': double.parse(priceController.text),
              });
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _modifyFoodItem(String category, DocumentSnapshot foodItem) async {
    TextEditingController nameController = TextEditingController(text: foodItem['name']);
    TextEditingController priceController = TextEditingController(text: foodItem['price'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modify Food Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Item Name'),
            ),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: 'Item Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _firestore.collection(category).doc(foodItem.id).update({
                'name': nameController.text,
                'price': double.parse(priceController.text),
              });
              Navigator.pop(context);
            },
            child: Text('Modify'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFoodItem(String category, DocumentSnapshot foodItem) async {
    await _firestore.collection(category).doc(foodItem.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - Manage Menu'),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((categoryDoc) {
              String category = categoryDoc.id;
              return ExpansionTile(
                title: Text(categoryDoc['title']),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection(category).snapshots(),
                    builder: (context, itemSnapshot) {
                      if (!itemSnapshot.hasData) {
                        return Center(child: CircularProgressIndicator());
                      }

                      return Column(
                        children: itemSnapshot.data!.docs.map((foodItem) {
                          return ListTile(
                            title: Text(foodItem['name']),
                            subtitle: Text('Price: ₹${foodItem['price']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _modifyFoodItem(category, foodItem);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _removeFoodItem(category, foodItem);
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () => _addFoodItem(category),
                    child: Text('Add Food Item', style: TextStyle(color: Colors.green)),
                  ),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
