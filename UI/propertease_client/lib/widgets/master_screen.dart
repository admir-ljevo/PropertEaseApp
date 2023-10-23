import 'package:flutter/material.dart';

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
          children: const [
            ListTile(
              title: Text("Properties"),
            ),
            ListTile(
              title: Text("News"),
            )
          ],
        ),
      ),
      body: widget.child!,
    );
  }
}
