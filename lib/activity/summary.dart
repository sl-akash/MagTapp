import 'package:flutter/material.dart';
import 'package:magtapp/database/sql_database.dart';
import 'package:magtapp/support/constants.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  SqlDatabase database = SqlDatabase(database: "database.db");

  List<Map> summaryList = [];

  @override
  void initState() {
    super.initState();
    database.getDatabasePath();

    getAllSummary();
  }

  Future<void> getAllSummary() async {
    Future.delayed(Duration(seconds: 1), () async {
      var list = await database.getAllSummary();

      // historyList = list;

      summaryList.clear();
      summaryList.addAll(list);

      setState(() {});
    });
  }

  // void getAllSummary() async {
  //   var list = await database.getAllSummary();

  //   summaryList = list;
  // }

  void deleteData(int index) {
    database.deleteSummary(summaryList[index]['id']);
    summaryList.removeAt(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Summary")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (int i = 0; i < summaryList.length; i++) summaryContainer(i),
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
          Navigator.pop(context, summaryList[index]['url']);
        },
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summaryList[index]['title'],
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  maxLines: 2,
                  summaryList[index]['url'],
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
                Text(
                  summaryList[index]['summary'],
                  style: TextStyle(fontSize: 15),
                  softWrap: true,
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
