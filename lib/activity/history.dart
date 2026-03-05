import 'package:flutter/material.dart';
import 'package:magtapp/database/sql_database.dart';
import 'package:magtapp/support/constants.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  SqlDatabase database = SqlDatabase(database: "database.db");

  List<Map> historyList = [];

  @override
  void initState() {
    super.initState();
    database.getDatabasePath();

    getAllHistory();
  }

  Future<void> getAllHistory() async {
    Future.delayed(Duration(seconds: 1), () async {
      var list = await database.getAllHistory();

      // historyList = list;

      historyList.clear();
      historyList.addAll(list);

      setState(() {});
    });
  }

  // void getAllSummary() async {
  //   var list = await database.getAllSummary();

  //   summaryList = list;
  // }

  void deleteData(int index) {
    database.deleteHistory(historyList[index]['id']);
    historyList.removeAt(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("History")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (int i = 0; i < historyList.length; i++) summaryContainer(i),
          ],
        ),
      ),
    );
  }

  Container summaryContainer(int index) {
    Color backBackgroundColor = Constants.blue1;

    if (index % 2 != 0) {
      backBackgroundColor = Constants.grey1;
    }

    return Container(
      decoration: BoxDecoration(color: backBackgroundColor),
      padding: EdgeInsets.all(10),
      margin: EdgeInsets.all(10),
      child: InkWell(
        onTap: () {
          Navigator.pop(context, historyList[index]['url']);
        },
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateTime.fromMillisecondsSinceEpoch(historyList[index]['timestamp']).toString(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  maxLines: 2,
                  historyList[index]['url'],
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
                
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: () {
                      deleteData(index);
                    },
                    icon: Icon(Icons.delete, color: Colors.red),
                    // color: Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
