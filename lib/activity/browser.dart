import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:magtapp/activity/history.dart';
import 'package:magtapp/activity/summary.dart';
import 'package:magtapp/api/api_free.dart';
import 'package:magtapp/database/sql_database.dart';
import 'package:magtapp/support/constants.dart';

class BrowserPage extends StatefulWidget {
  const BrowserPage({super.key});

  @override
  State<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends State<BrowserPage> {
  // with SingleTickerProviderStateMixin {
  bool isLoading = true;
  late TextEditingController linkController;
  Color backBackgroundColor = Color.fromARGB(26, 158, 158, 158),
      frontBackgroundColor = Color.fromARGB(26, 158, 158, 158);

  SqlDatabase database = SqlDatabase(database: "database.db");

  bool forwardDisable = false,
      backDisable = false,
      saveSummary = false,
      showSummary = false;
  bool showTabs = false;

  String lastUrl = Constants.defaultUrl,
      summary = "No summary",
      prompt = "",
      title = "No title";

  int index = 0;

  void navigateNext() {}

  List<BrowserTab> tabs = [BrowserTab(url: WebUri(Constants.defaultUrl))];
  late ApiFreeAI apiFreeAI;

  @override
  void initState() {
    super.initState();
    linkController = TextEditingController();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
    database.getDatabasePath();
    apiFreeAI = ApiFreeAI(Constants.apiKey);
  }

  void sendRequest({String url = ""}) async {
    final response = await apiFreeAI.createCompletion(
      model: 'llama-3-8b-instruct',
      prompt:
          "Evaluate the page in 150 words $prompt also give title. Give evaluation and title as json",
      maxTokens: 100,
    );

    var json = jsonDecode("{${response?.split('{')[1].split('}')[0]}}");

    setState(() {
      title = json['title'];
      summary = json['evaluation'];
      isLoading = false;
      database.insertSummary(url, title, summary);
    });
  }

  @override
  void dispose() {
    linkController.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void validateController() async {
    var tab = tabs[index];

    backDisable = !await tab.controller!.canGoBack();
    forwardDisable = !await tab.controller!.canGoForward();
    var url = await tab.controller!.getUrl();

    lastUrl = url.toString();

    linkController.text = url.toString();

    if (saveSummary) {
      saveSummary = false;
      var controller = tabs[index].controller;
      var result = await controller?.evaluateJavascript(
        source: "document.body.innerText",
      );

      prompt = result.toString();
      sendRequest(url: lastUrl);
    }
    setState(() {});
  }

  void summarizePage() async {
    var url = await tabs[index].controller!.getUrl();
    var controller = tabs[index].controller;
    var result = await controller?.evaluateJavascript(
      source: "document.body.innerText",
    );

    prompt = result.toString();
    showSummary = true;
    sendRequest(url: url.toString());
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    // final showDialog =

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            isLoading = true;
          });
          summarizePage();
        },
        child: CircleAvatar(child: Icon(Icons.summarize)),
      ),
      appBar: AppBar(
        title: SizedBox(
          height: 38,
          child: TextField(
            style: TextStyle(fontSize: 14),
            controller: linkController,
            decoration: InputDecoration(
              prefixIcon: IconButton(
                iconSize: 15,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: lastUrl));
                  showSnackBar("Copied to dashboard", Colors.green);
                },
                icon: Icon(Icons.link),
              ),
              suffixIcon: IconButton(
                iconSize: 15,
                onPressed: () async {
                  saveSummary = true;
                  String url = Constants.getValidUrl(linkController.text);
                  if (!await Constants.isValidWebSite(url)) {
                    url = Constants.googleUrl(linkController.text);
                  }
                  tabs[index].controller?.loadUrl(
                    urlRequest: URLRequest(
                      url: WebUri(Constants.getValidUrl(url)),
                    ),
                  );
                },
                icon: Icon(Icons.search),
              ),
              filled: true,
              fillColor: const Color.fromARGB(58, 158, 158, 158),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              hintText: "Search...",
            ),
          ),
        ),
        actions: [
          CircleAvatar(
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: backDisable
                    ? Color.fromARGB(26, 158, 158, 158)
                    : Color.fromARGB(237, 174, 228, 255),
              ),
              onPressed: backDisable
                  ? null
                  : () {
                      tabs[index].controller?.goBack();
                    },
              icon: Icon(Icons.arrow_left),
            ),
          ),

          SizedBox(width: 5),

          CircleAvatar(
            backgroundColor: frontBackgroundColor,
            child: IconButton(
              style: IconButton.styleFrom(
                backgroundColor: forwardDisable
                    ? Color.fromARGB(26, 158, 158, 158)
                    : Color.fromARGB(237, 174, 228, 255),
              ),
              onPressed: forwardDisable
                  ? null
                  : () {
                      tabs[index].controller?.goForward();
                    },
              icon: Icon(Icons.arrow_right),
            ),
          ),

          SizedBox(width: 5),

          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case "page_summary":
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(builder: (context) => SummaryPage()),
                      )
                      .then((url) {
                        if (url != null) {
                          tabs[index].controller?.loadUrl(
                            urlRequest: URLRequest(url: WebUri(url)),
                          );
                        }
                      });
                  break;
                case "history":
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(builder: (context) => HistoryPage()),
                      )
                      .then((url) {
                        if (url != null) {
                          tabs[index].controller?.loadUrl(
                            urlRequest: URLRequest(url: WebUri(url)),
                          );
                        }
                      });
                  break;
                case "refresh":
                  tabs[index].controller?.reload();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "refresh",
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 5),
                    Text("Refresh"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "downloads",
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 5),
                    Text("Downloads"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "history",
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 5),
                    Text("History"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "page_summary",
                child: Row(
                  children: [
                    Icon(Icons.summarize),
                    SizedBox(width: 5),
                    Text("Page Summary"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                  ),
                  child: IndexedStack(
                    index: index,
                    children: tabs.map((tab) {
                      return InAppWebView(
                        initialUrlRequest: URLRequest(url: tab.url),
                        onWebViewCreated: (controller) {
                          tab.controller = controller;
                        },
                        onLoadStop: (controller, url) async {
                          isLoading = false;
                          var result = await controller.evaluateJavascript(
                            source: "document.body.innerText",
                          );

                          prompt = result.toString();

                          // print(result);
                          tab.currentUrl = url;

                          database.insertHistory(url.toString());

                          validateController();

                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          if (showTabs)
            Center(
              child: Stack(
                children: [
                  Container(
                    margin: EdgeInsets.all(10),
                    height: MediaQuery.of(context).size.height / 2,
                    width: double.infinity,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blue, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (int i = 0; i < (tabs.length ~/ 2); i++)
                            get2Tabs(i, size),

                          if (tabs.length % 2 != 0)
                            getTabs(tabs.length - 1, size),
                          if (tabs.length % 2 == 0 && tabs.length < 6)
                            Row(children: [addStack(size)]),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        backgroundColor: Constants.blue1,
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              showTabs = false;
                            });
                          },
                          icon: Icon(Icons.close, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          if (showSummary)
            Center(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.all(10),

                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(summary),
                      SizedBox(height: 5),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              showSummary = false;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white, // Text color
                            backgroundColor: Colors.blue, // Background color
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text("CLOSE"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (isLoading) LinearProgressIndicator(color: Colors.blue),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) {
          switch (i) {
            case 0:
              setState(() {
                tabs[index].controller?.loadUrl(
                  urlRequest: URLRequest(url: WebUri(Constants.defaultUrl)),
                );
              });
              break;
            case 1:
              pickDocument();
              break;
            case 2:
              setState(() {
                showTabs = !showTabs;
              });
              break;
            case 3:
              showDialog(
                context: context,
                barrierDismissible: false, // Prevent outside tap close
                builder: (context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Settings",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          TextButton(
                            onPressed: () async {
                              var url = await tabs[index].controller?.getUrl();

                              if (Constants.isDownloadableFile(
                                url.toString(),
                              )) {
                                var downloadFile = await Constants.downloadFile(url.toString());
                                
                                downloadFile != null ?
                                showSnackBar("File Downloaded", Colors.green) : showSnackBar("Permission Failed", Colors.red);
                                
                              } else {
                                Navigator.pop(context);
                                showSnackBar("Invalid File", Colors.red);
                              }
                              

                              setState(() {});
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white, // Text color
                              backgroundColor: Colors.blue, // Background color
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.download),
                                SizedBox(width: 10),
                                Text("DOWNLOAD FILE"),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white, // Text color
                              backgroundColor: Colors.blue, // Background color
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text("CLOSE"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
              break;
          }

          setState(() {
            _index = i;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),

          BottomNavigationBarItem(
            icon: Icon(Icons.file_present),
            label: "File",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.tab),
            label: "Tab (${index + 1}/${tabs.length})",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  int _index = 0;

  Future<void> pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'pptx', 'xlsx'],
    );

    if (result != null && tabs[index].controller != null) {
      String path = result.files.first.path!;

      tabs[index].controller!.loadFile(assetFilePath: path);
      print(result.files.first.path);
    }
  }

  void showSnackBar(String message, Color backBackgroundColor) {
    SnackBar snackBar = SnackBar(
      content: Text(message, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: backBackgroundColor,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Row get2Tabs(int index, Size size) {
    int index1 = index * 2;
    int index2 = index1 + 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [viewStack(size, index1), viewStack(size, index2)],
    );
  }

  void addTab() {
    if (tabs.length >= 6) {
      return;
    }
    setState(() {
      tabs.add(BrowserTab(url: WebUri(Constants.defaultUrl)));
      index = tabs.length - 1;
    });
  }

  void removeTab(int index) {
    setState(() {
      tabs.removeAt(index);

      if (tabs.isEmpty) {
        addTab();
      }

      if (index < this.index) {
        this.index = this.index - 1;
      } else if (index == this.index) {
        this.index = tabs.length - 1;
      }
    });
  }

  Row getTabs(int index, Size size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Stack(
          children: [
            Container(
              margin: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              width: size.width / 2 - 25 - 20,
              height: (size.width / 2 - 25 - 20) * 1.5,
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: tabs[index].url),
                onWebViewCreated: (controller) {
                  tabs[index].controller = controller;
                },
              ),
            ),

            removeCircleAvatar(index),
          ],
        ),

        addStack(size),
      ],
    );
  }

  CircleAvatar removeCircleAvatar(int index) {
    return CircleAvatar(
      backgroundColor: Constants.blue1,
      child: IconButton(
        onPressed: () {
          removeTab(index);
        },
        icon: Icon(Icons.close, color: Colors.red),
      ),
    );
  }

  Stack viewStack(Size size, int index) {
    return Stack(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              this.index = index;
              showTabs = false;
              validateController();
            });
          },
          child: Container(
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue, width: 1),
              borderRadius: BorderRadius.circular(10),
            ),
            width: size.width / 2 - 25 - 20,
            height: (size.width / 2 - 25 - 20) * 1.5,
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(
                      tabs[index].currentUrl != null
                          ? tabs[index].currentUrl.toString()
                          : Constants.defaultUrl,
                    ),
                  ),
                  onWebViewCreated: (controller) {
                    tabs[index].controller = controller;
                  },
                  gestureRecognizers: {},
                ),
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color.fromARGB(12, 189, 189, 189),
                  // color: Colors.amber,
                  // padding: EdgeInsets.all(90),
                ),
              ],
            ),
          ),
        ),

        removeCircleAvatar(index),
      ],
    );
  }

  Stack addStack(Size size) {
    return Stack(
      children: [
        Container(
          margin: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
          width: size.width / 2 - 25 - 20,
          height: (size.width / 2 - 25 - 20) * 1.5,
          child: IconButton(
            onPressed: () {
              addTab();
            },
            icon: Icon(Icons.add, weight: 3, size: 70),
          ),
        ),
      ],
    );
  }
}
