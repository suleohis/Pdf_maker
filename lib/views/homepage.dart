import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:pdf_maker/views/pdf_viewer.dart';
import 'package:pdf_render/pdf_render_widgets.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../modal/modal.dart';
import '../services/ad_state.dart';
import '../services/sqlite_helper.dart';
import 'create_pdf_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final isDialOpen = ValueNotifier(false);
  BannerAd? banner;
  List<PDFItems> pdfs = [];
  bool isLoading = false;
  List<int> selectedPDF = [];
  bool selected = false;
  List<bool> selectedList = [];

  Future getPdf() async{
    setState(() => isLoading =true);
    pdfs = await DBHelper.instance.readAllPDFs();

    setState(() => isLoading =false);
    pdfs.map((e) => selectedList.add(false)).toList();
  }
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
    super.initState();
    getPdf();
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
     onWillPop: () async{
       if(isDialOpen.value){
         ///close speed dial
         isDialOpen.value = false;
         return false;
       } else {
         if(selected == true){
           setState(() {
             selected = false;
           });
           return false;
         } else {
           return true;
         }
       }
     },
      child: Scaffold(
        appBar: AppBar(
          title:const Text('Image To PDF'),
          elevation: 0,
          backgroundColor: Colors.blue[900],
        ),
        body: Column(
          children: [
            isLoading ?
                const Expanded(child: Center(child: CircularProgressIndicator())): pdfs.isEmpty ?
            const Expanded(
              child: Center(
                child: Text('No PDF', style:
                TextStyle(color: Colors.black, fontSize: 24),),
              ),
            ) : Expanded(child: buildPdf()),
            if (banner == null)
            const SizedBox(height: 50,)
            else
              SizedBox(
                height: 50,
                  child: AdWidget(ad: banner!,),
              )
          ],
        ),
        floatingActionButton: selected == false ? Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: SpeedDial(
            icon: Icons.add,
            activeIcon: Icons.close,
            backgroundColor: Colors.blue[900],
            overlayColor: Colors.black,
            spacing:  12,
            spaceBetweenChildren: 12,
            overlayOpacity: 0.4,
            openCloseDial: isDialOpen,
            children: [
              SpeedDialChild(
                label: 'Gallery',
                child: const Icon(Icons.photo),
                backgroundColor: Colors.red,
                onTap: () => getImageFromGallery(false)
              ),
              SpeedDialChild(
                  label: 'Camera',
                  child: const Icon(Icons.camera_alt),
                backgroundColor: Colors.green,
                  onTap: () => getImageFromGallery(true)
              )
            ],
          ),
        ) :null,
        bottomNavigationBar: selected == true ?BottomNavigationBar(
          selectedItemColor: Colors.grey,
            unselectedItemColor: Colors.grey,
          onTap: (int index){
            _onItemTapped(index);
          },
          items:   const [
            BottomNavigationBarItem(
              icon: Icon(Icons.share),
              label: 'Share',
            ),
            // if(selectedPDF.length < 2 && selectedPDF.isNotEmpty )
            // const BottomNavigationBarItem(
            //   icon: Icon(Icons.edit),
            //   label: 'Rename',
            // ),
            BottomNavigationBarItem(
              icon:  Icon(Icons.delete),
              label: 'Delete',
            ),
          ],
        ) : null,
      ),
    );
  }

  _onItemTapped(int index) {
    bool second =  (selectedPDF.length < 2 && selectedPDF.isNotEmpty );
    if(index == 0) {
      share();
    }
    if(index == 1) {
      delete();
    }
    // if(index == 1 && second ) {
    //   rename(context);
    // } else if(index == 1 && !second){
    //   delete();
    // }
    // if(index == 2 && second) {
    //  delete();
    // }
  }
  buildPdf(){
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: pdfs.length,
      itemBuilder: (context, index) {
        final pdf = pdfs[index];
        int len = pdf.title!.length - 4;
        int length = pdf.title!.length;
        String time = DateFormat('yyyy-MM-dd').format(DateTime.now());
       if(File(pdf.location!).existsSync()){
         if(selected == true) {
           return Padding(
             padding: const EdgeInsets.only(bottom: 8.0),
             child: GestureDetector(
               onLongPress: () => setState(() {
                 selectedPDF.clear();
                 selected = false;
               }),
               child: CheckboxListTile(
                 title: Text(pdf.title!.replaceRange(len, length,'')),
                 secondary: SizedBox(
                   width: 100, height: 150,
                   child: Container(
                     padding: const EdgeInsets.all(3.0),
                     decoration: BoxDecoration(
                         border: Border.all(color: Colors.grey[200]!),
                         borderRadius: BorderRadius.circular(10)
                     ),
                     child: PdfDocumentLoader.openFile(
                         pdf.location!,
                         pageNumber: 1,
                         pageBuilder: (context, textureBuilder, pageSize) => textureBuilder()
                     ),
                   ),
                 ),
                 // controlAffinity: ListTileControlAffinity.leading,
                 subtitle: Column(
                   mainAxisAlignment: MainAxisAlignment.end,
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(time ,style: TextStyle(color: Colors.grey[6600]),)
                   ],
                 ), onChanged: (bool? value) {
                   if(selectedList[index] == true){
                     setState(() {
                       selectedPDF.remove(index);
                       selectedList[index] = false;
                     });
                   } else {
                     setState(() {
                       selectedPDF.add(index);
                       selectedList[index] = true;
                     });
                   }
               },
                 value: selectedList[index],
               ),
             ),
           );
         }
         else {
           return GestureDetector(
             onTap: (){
               Navigator.push(context, MaterialPageRoute(builder:
                   (context) => PDFViewerPage(pdfItems: pdf,)))
                   .then((value) => getPdf());
             },
             onLongPress: () {
               selectedPDF.clear();
               setState(() => selected =  true);
             },
             child: Padding(
               padding: const EdgeInsets.only(bottom: 8.0),
               child: ListTile(
                 title: Text(pdf.title!.replaceRange(len, length,'')),
                 leading: SizedBox(
                   width: 100, height: 150,
                   child: Container(
                     padding: const EdgeInsets.all(3.0),
                     decoration: BoxDecoration(
                         border: Border.all(color: Colors.grey[200]!),
                         borderRadius: BorderRadius.circular(10)
                     ),
                     child: PdfDocumentLoader.openFile(
                         pdf.location!,
                         pageNumber: 1,
                         pageBuilder: (context, textureBuilder, pageSize) => textureBuilder()
                     ),
                   ),
                 ),
                 subtitle: Column(
                   mainAxisAlignment: MainAxisAlignment.end,
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(time ,style: TextStyle(color: Colors.grey[6600]),)
                   ],
                 ),
               ),
             ),
           );
         }
       } else{
         // DBHelper.instance.delete(pdf.id!);
         return const SizedBox();
       }
      },
    );
  }
  share() async {
    await Share.shareFiles(
      selectedPDF.map((e) => pdfs[e].location!).toList(),

    ).then((value) {
      selectedPDF = [];
      selected = false;
      getPdf();
    });
  }
  ///To Name The PDF
  rename(BuildContext context) {
    PDFItems pdf = pdfs[selectedPDF.first];
    int len = pdf.title!.length - 4;
    int length = pdf.title!.length;
    TextEditingController nameController = TextEditingController();
    nameController.text = pdfs[selectedPDF.first].title!.replaceRange(len, length,'');
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
                    PDFItems p = PDFItems(
                        id: pdf.id,
                        title: filename,
                        location: file.path,
                        timeCreated: pdf.timeCreated
                    );
                    DBHelper.instance.update(p).then((value) {
                      Navigator.pop(context);
                      selectedPDF.clear();
                      selected = false;
                      getPdf();
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
  delete() async{
    for (var e in selectedPDF) {
      File(pdfs[e].location!).delete().then((value) {
        DBHelper.instance.delete(pdfs[e].id!);
      });
    }
    selectedPDF.clear();
    selected = false;
    getPdf();
  }
  getImageFromGallery(bool camera) async {
    List<File> _image = [];
    if(camera) {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      // final file = await ImageCropper().cropImage(sourcePath: pickedFile!.path,
      //   uiSettings: [androidUiSettingsLocked()],
      // );
      setState(() {
        if (pickedFile != null) {
          _image.add(File(pickedFile.path));
          Navigator.of(context).push(MaterialPageRoute(builder:
              (context)=>CreatePdfPage(image: _image))).then((value) => getPdf());
        } else {
          if (kDebugMode) {
            print('No image selected');
          }
        }
      });
    } else {
      final pickedFile = await ImagePicker().pickMultiImage();
      setState(() {
        if (pickedFile != null) {
          for (var element in pickedFile) {
            _image.add(File(element.path));
          }
          Navigator.of(context).push(MaterialPageRoute(builder:
              (context)=>CreatePdfPage(image: _image))).then((value) => getPdf());
        } else {
          if (kDebugMode) {
            print('No image selected');
          }
        }
      });
    }
  }


}