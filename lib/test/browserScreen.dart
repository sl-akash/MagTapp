import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BrowserTab {
  InAppWebViewController? controller;
  WebUri url;

  BrowserTab({required this.url});
}

class BrowserScreen extends StatefulWidget {
  @override
  _BrowserScreenState createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  List<BrowserTab> tabs = [
    BrowserTab(url: WebUri("https://google.com")),
  ];

  int currentIndex = 0;

  void addNewTab(String url) {
    setState(() {
      tabs.add(BrowserTab(url: WebUri(url)));
      currentIndex = tabs.length - 1;
    });
  }

  void closeTab(int index) {
    if (tabs.length == 1) return;
    setState(() {
      tabs.removeAt(index);
      currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mini Browser"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => addNewTab("https://google.com"),
          ),
        ],
      ),
      body: IndexedStack(
        index: currentIndex,
        children: tabs.map((tab) {
          return InAppWebView(
            initialUrlRequest: URLRequest(url: tab.url),
            onWebViewCreated: (controller) {
              tab.controller = controller;
            },
          );
        }).toList(),
      ),
      bottomNavigationBar: Container(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  currentIndex = index;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15),
                alignment: Alignment.center,
                color: currentIndex == index
                    ? Colors.blue
                    : Colors.grey.shade300,
                child: Row(
                  children: [
                    Text("Tab ${index + 1}"),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => closeTab(index),
                      child: Icon(Icons.close, size: 16),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}