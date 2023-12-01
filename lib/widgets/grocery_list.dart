import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
   List<GroceryItem> _groceryItem = [];
   var _isLoading = true;
   String? _error; // או שיציג null או שיציג סטרינג במקרה של שגיאה

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
      'flutter-prep-aa023-default-rtdb.firebaseio.com',
      'shooping-List.json',
    );
    final response = await http.get(url);
    if(response.statusCode >= 400) {
      setState(() {
      _error = 'Faild to fetch data. please try again later.';
      });
    }
    
    if(response.body == 'null') {
      setState(() {
      _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> listData =
        json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
            (catItem) => catItem.value.title == item.value['category'],
          )
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: Category(
            category.title,
            category.color,
          ),
        ),
      );
    }
    setState(() {
      _groceryItem = loadedItems;
      _isLoading = false;
    });
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if(newItem == null) {
      return;
    }

    setState(() {
    _groceryItem.add(newItem);
    });
   
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItem.indexOf(item);

    setState(() {
        _groceryItem.remove(item);
      });

    final url = Uri.https(
      'flutter-prep-aa023-default-rtdb.firebaseio.com',
      'shooping-List/${item.id}.json',
    );
    
    final response = await http.delete(url);
      if(response.statusCode >= 400) {
      setState(() {
        _groceryItem.insert(index , item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('no items are chosen'),
    );

    if(_isLoading) {
      content = const Center(child: CircularProgressIndicator(),);
    }

    if (_groceryItem.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItem.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItem[index]);
          },
          key: ValueKey(_groceryItem[index].id),
          child: ListTile(
            title: Text(_groceryItem[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItem[index].category.color,
            ),
            trailing: Text(_groceryItem[index].quantity.toString()),
          ),
        ),
      );
    }

    if(_error != null) {
      content = Center(child: Text(_error!),);
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Grocery'),
          actions: [
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: content);
  }
}
