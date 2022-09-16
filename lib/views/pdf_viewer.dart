
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;

import '../modal/modal.dart';
import '../services/ad_state.dart';
import '../services/sqlite_helper.dart';

class PDFViewerPage extends StatefulWidget {
  final PDFItems pdfItems;

  const PDFViewerPage({required this.pdfItems, Key? key}) : super(key: key);

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  PDFViewController? controller;
  int pages = 0;
  int indexPage = 0;
  String name ='';
  late File file ;

  BannerAd? banner;
  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    final adState = Provider.of<AdState>(context);
    adState.initialization.then((status) {
      setState(() {
        banner = BannerAd(
          size: AdSize.banner,
          adUnitId: adState.bannerAdUnitId,
          request: const AdRequest(),
          listener: adState.adListener,
        )..load();
      });
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    file = File(widget.pdfItems.location!);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    name = path.basename(file.path);
    final text = '${indexPage + 1} of $pages';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.blue[900],
        actions: [
          Center(child: Text(text),),
          PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
              value: 0,
              onTap: ()=> share(),
              child: const Text('Share'),
                ),
                // PopupMenuItem(
                //   onTap: ()=> rename(context),
                //   value: 0,
                //   child: const Text('Rename'),
                // ),
                PopupMenuItem(
                  onTap: ()=> delete(context),
                  value: 0,
                  child: const Text('Delete'),
                )
              ];
            },
          ),
          const SizedBox(width: 14,)
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PDFView(
              filePath: file.path,
              autoSpacing: false,
              pageSnap: false,
              pageFling: false,
              onRender: (pages) => setState(() => this.pages = pages!),
              onViewCreated: (controller) {
                setState(() => this.controller = controller);},
              onPageChanged: (indexPage, _) => setState(() => this.indexPage = indexPage!),
            ),
          ),
          if (banner == null)
            const SizedBox(height: 50,)
          else
            SizedBox(
              height: 50,
              child: AdWidget(ad: banner!,),
            )
        ],
      ),
    );
  }

  share() async {
    await Share.shareFiles(
      [widget.pdfItems.location!],);
  }
  ///To Name The PDF
  rename(BuildContext context) {
    PDFItems pdf = widget.pdfItems;
    int len = pdf.title!.length - 4;
    int length = pdf.title!.length;
    TextEditingController nameController = TextEditingController();
    nameController.text = widget.pdfItems.title!.replaceRange(len, length,'');
    String filename = '';
    setState(() {});
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Rename',style: TextStyle(color: Colors.grey[600] ),),
            content: Container(
              decoration:  BoxDecoration(
                  border: Border(bottom: BorderSide(width: 1,
                      color: Colors.blue[900]!))
              ),
              child: TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                    border:  InputBorder.none,
                    hintText: 'Name',
                    suffix: GestureDetector(
                      onTap: (){
                        nameController.clear();
                        // setState(() {});
                      },
                      child: const Icon(Icons.close),
                    )
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: ()async{
                  filename = nameController.text +'.pdf';
                  File file = File(pdf.location!);
                  String dir = path.dirname(file.path);
                  String newPath = path.join(dir, filename);
                  print(dir);
                  await file.rename(newPath).then((value) {
                    name = filename;
                    PDFItems p = PDFItems(
                        id: pdf.id,
                        title: filename,
                        location: file.path,
                        timeCreated: pdf.timeCreated
                    );
                    DBHelper.instance.update(p).then((value) {
                      setState(() {});
                      Navigator.pop(context);
                    });
                  });

                },
                child: const Text('Ok'),
                style: TextButton.styleFrom(
                    primary: Colors.blue[900]
                ),
              )
            ],
          );
        }
    );
  }
  delete(BuildContext context) async{
      File(widget.pdfItems.location!).delete().then((value) {
        DBHelper.instance.delete(widget.pdfItems.id!).then((value) {
          Navigator.pop(context);
        });
      });

  }
}
