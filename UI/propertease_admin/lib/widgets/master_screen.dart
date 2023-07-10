import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:propertease_admin/main.dart';
import 'package:propertease_admin/screens/property_list_screen.dart';

class MasterScreenWidget extends StatefulWidget {
  Widget? child;
  String? title;
  Widget? title_widget;
  MasterScreenWidget({this.child, this.title, this.title_widget, super.key});
  @override
  State<MasterScreenWidget> createState() => _MasterScreenWidgetState();
}

class _MasterScreenWidgetState extends State<MasterScreenWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.title_widget ?? Text(widget.title ?? ""),
      ),
      drawer: Drawer(
        child: ListView(children: [
          ListTile(
            title: Text("Login"),
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (context) => LoginWidget()));
            },
          ),
          ListTile(
            title: Text("Nekretnine"),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const PropertyListWidget()));
            },
          ),
        ]),
      ),
      body: widget.child!,
    );
  }
}
