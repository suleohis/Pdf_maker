import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../modal/modal.dart';
import '../services/ad_state.dart';
import '../services/sqlite_helper.dart';

class CreatePdfPage extends StatefulWidget {
  final List<File> image;

  const CreatePdfPage({required this.image, Key? key}) : super(key: key);
  @override
  _CreatePdfPageState createState() => _CreatePdfPageState();
}

class _CreatePdfPageState extends State<CreatePdfPage> {
  final picker = ImagePicker();
  final pdf = pw.Document();
  List<File> _image = [];
  int chosenImage = 0;
  bool cropping = false;
  final controller = CropController();
   String filename = '';

  final isDialOpen = ValueNotifier(false);
  TextEditingController nameController = TextEditingController();

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
    _image = widget.image;
    nameController.text = 'pdf ' +  DateFormat('yyyy-MM-dd ss  kk.mm.ss').format(DateTime.now());
    filename = nameController.text;
    super.initState();
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
          if(cropping == true){
          setState(() {
            cropping = false;
          });
          return false;
        }else{
          disCard(context);
          return true;
        }
        }

      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          title: TextButton(
            child: Text(filename,style: const TextStyle(color: Colors.white),),
            onPressed: () => name(context),
          ),
          backgroundColor: Colors.blue[900],
          automaticallyImplyLeading: false,
          leading: cropping == true ?
              IconButton(onPressed: (){
                setState(() {
                  cropping = false;
                });
              }, icon: const Icon(Icons.arrow_back,color: Colors.white,))
              :
          IconButton(onPressed: () => disCard(context),
              icon: const Icon(Icons.arrow_back,color: Colors.white,)),

            actions: [
            if(cropping == false)
            IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () {
                  createPDF();
                  savePDF(context);
                }),
            if(cropping == false)
            IconButton(
                icon: const Icon(Icons.crop),
                onPressed: () {

                    setState(() {
                      cropping = true;
                    });


                })
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 14.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          controller.crop();
                          cropping = false;
                        });
                      },
                      child: const Center(child: Text("DONE"))
                    ),
                  )
    ,

          ],
        ),
        body: _image.isNotEmpty
            ? Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 2 / 3,
                              child: cropping ? Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Crop(
                                  image: _image[chosenImage].readAsBytesSync(),
                                  controller: controller,
                                  onCropped: (image) async{
                                    Uint8List img = image;
                                    final tempDir = await getTemporaryDirectory();
                                    final file = await  File
                                      ('${tempDir.path}/image.jpg').create();
                                    file.writeAsBytesSync(img);
                                    _image[chosenImage] =  file;
                                    setState(() {});
                                  },
                                  baseColor: Colors.transparent,
                                  maskColor: Colors.black.withOpacity(0.4),
                                  onMoved: (newRect) {
                                    // do something with current cropping area.
                                  },
                                  onStatusChanged: (status) {
                                    // do something with current CropStatus
                                  },
                                  cornerDotBuilder: (size, edgeAlignment) =>
                                      const DotControl(color: Colors.blue),
                                  // interactive: true,
                                ),
                              )
                                  :
                              Container(
                                  margin: const EdgeInsets.all(8),
                                  child: Image.file(
                                    _image[chosenImage],
                                  )),

                          ) ,


                          SizedBox(
                            height: MediaQuery.of(context).size.height * 1 / 6,
                            child: Container(
                              color: Colors.black,
                              child: ListView.builder(
                                itemCount: _image.length,
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (BuildContext context, int index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          chosenImage = index;
                                        });
                                      },
                                      child: Container(
                                          margin: const EdgeInsets.all(8),
                                          child: Image.file(
                                            _image[index],
                                            fit: BoxFit.fill,
                                          )),
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                  ),
                ),
                if (banner == null)
                  const SizedBox(height:  0,)
                else
                  SizedBox(
                    height: 50,
                    child: AdWidget(ad: banner!,),
                  )

              ],
            )
            : Container(),

        floatingActionButton: Padding(
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
                  onTap: () => getImageFromGallery(false,context)
              ),
              SpeedDialChild(
                  label: 'Camera',
                  child: const Icon(Icons.camera_alt),
                  backgroundColor: Colors.green,
                  onTap: () => getImageFromGallery(true,context)
              )
            ],
          ),
        ),
      ),
    );
  }



  /// Get Images
  getImageFromGallery(bool camera, BuildContext context) async {

    if(camera) {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
      // final file = await ImageCropper().cropImage(sourcePath: pickedFile!.path,
      //   uiSettings: [androidUiSettingsLocked()],
      // );
      setState(() {
        if (pickedFile != null) {
          _image.add(File(pickedFile.path));

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

        } else {
          if (kDebugMode) {
            print('No image selected');
          }
        }
      });
    }
  }

  ///Create PDF
  createPDF() async {
    for (var img in _image) {
      final image = pw.MemoryImage(img.readAsBytesSync());

      pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(image));
          }));

    }
  }

  ///Save PDF
  savePDF(BuildContext context) async {
    DateTime dateTime = DateTime.now();
    try {
      var status = await Permission.storage.status;
      if(status.isGranted){
        final dir =  Directory( "storage/emulated/0/Documents");
        final file = File('${dir.path}/$filename.pdf');
        await file.writeAsBytes(await pdf.save());
        PDFItems pdfItems = PDFItems(
            title: path.basename(file.path),
            location: file.path,
            timeCreated: dateTime
        );
        DBHelper.instance.create(pdfItems);
        Navigator.pop(context);
        showPrintedMessage('success', 'saved to documents',context);
      } else {
        Permission.storage.request().then((value) {
          if(value.isGranted){
            savePDF(context);
          }else {
            Navigator.pop(context);
          }
        });
      }

    } catch (e) {
      showPrintedMessage('error', e.toString(),context);
    }
  }

  showPrintedMessage(String title, String msg,BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 3),
    ));
    // Flushbar(
    //   title: title,
    //   message: msg,
    //   duration: const Duration(seconds: 3),
    //   icon: const Icon(
    //     Icons.info,
    //     color: Colors.blue,
    //   ),
    // ).show(context);
  }
  ///To Name The PDF
  name(BuildContext context) {
    nameController.text = filename;
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
                        setState(() {});
                      },
                      child: const Icon(Icons.close),
                    )
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: (){
                  filename = nameController.text;
                  Navigator.pop(context);
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
  
  ///To Let the Page
  disCard(BuildContext context) {
    nameController.text = filename;
    setState(() {});
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Confirm?'
              ,style: TextStyle(color: Colors.grey[600] ),),
            content: const Text('Are You Sure You Want To Discard The Pictures ?'
               ),
            actions: [
              TextButton(
                onPressed: (){
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
                style: TextButton.styleFrom(
                    primary: Colors.blue[900]
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              TextButton(
                onPressed: (){
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Discard'),
                style: TextButton.styleFrom(
                    primary: Colors.blue[900]
                ),
              ),
            ],
          );
        }
    );
  }
}

