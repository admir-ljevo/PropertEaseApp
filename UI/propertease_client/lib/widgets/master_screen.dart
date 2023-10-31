import 'package:flutter/material.dart';

import '../screens/notifications/notification_list.dart';
import '../screens/property/property_list.dart';

class MasterScreenWidget extends StatefulWidget {
  Widget? child;
  String? title;
  Widget? title_widget;

  MasterScreenWidget({this.child, this.title, this.title_widget, super.key});

  @override
  State<StatefulWidget> createState() => MasterScreenWidgetState();
}

class MasterScreenWidgetState extends State<MasterScreenWidget> {
  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: widget.title_widget ?? Text(widget.title ?? ""),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text("Properties"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const PropertyListWidget()));
              },
            ),
            ListTile(
              title: const Text("News"),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const NewsListWidget()));
              },
            ),
          ],
        ),
      ),
      body: widget.child!,
    );
  }
}
