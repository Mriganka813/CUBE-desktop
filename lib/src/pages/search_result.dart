import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shopos/src/blocs/product/product_cubit.dart';
import 'package:shopos/src/blocs/report/report_cubit.dart';
import 'package:shopos/src/config/colors.dart';
import 'package:shopos/src/models/input/order.dart';
import 'package:shopos/src/pages/checkout.dart';
import 'package:shopos/src/pages/create_product.dart';
import 'package:shopos/src/services/global.dart';
import 'package:shopos/src/services/locator.dart';
import 'package:shopos/src/services/search_service.dart';
import 'package:shopos/src/services/set_or_change_pin.dart';
import 'package:shopos/src/widgets/custom_button.dart';
import 'package:shopos/src/widgets/custom_text_field.dart';
import 'package:shopos/src/widgets/custom_text_field2.dart';
import 'package:shopos/src/widgets/product_card_horizontal.dart';

import '../models/product.dart';

class ProductListPageArgs {
  bool isSelecting;
  final OrderType orderType;
  List<OrderItemInput> productlist = [];
  ProductListPageArgs(
      {this.isSelecting = true,
      required this.orderType,
      required this.productlist});
}

class SearchProductListScreen extends StatefulWidget {
  static const routeName = '/search-product-list-screen';

  SearchProductListScreen({required this.args});
  ProductListPageArgs args;

  @override
  State<SearchProductListScreen> createState() =>
      _SearchProductListScreenState();
}

class _SearchProductListScreenState extends State<SearchProductListScreen> {
  final scrollController = ScrollController();
  final SearchProductServices searchProductServices = SearchProductServices();
  List<Product> prodList = [];
  bool isLoadingMore = false;
  late final ProductCubit _productCubit;
  late List<Product> _products;
  bool itemCheckedFlag = false;
  TextEditingController searchController = TextEditingController();

  int page = 0;
  int _currentPage = 1;
  int _limit = 20;
  bool isAvailable = true;
  PinService _pinService = PinService();
  late final ReportCubit _reportCubit;
  final TextEditingController pinController = TextEditingController();

   int expiryDaysTOSearch = 7;
  String searchMode = "normalSearch";

  @override
  void initState() {
    super.initState();
    _products = [];
    _productCubit = ProductCubit()..getProducts(_currentPage, _limit);
    scrollController.addListener(_scrollListener);
    _reportCubit = ReportCubit();
    fetchSearchedProducts();
  }

  //goToProductDetails(BuildContext context, int idx) {
  // Navigator.of(context).pushNamed(SearchProductDetailsScreen.routeName,
  //    arguments: prodList[idx]);
  //}
  @override
  void dispose() {
    _reportCubit.close();
    super.dispose();
  }

  
  Future<void> fetchSearchedProducts() async {
    List newProducts = [];
    if (searchMode == "normalSearch") {
      newProducts =
          await searchProductServices.allproduct(_currentPage, _limit);
    } else if (searchMode == "expiry") {
      var list = await searchProductServices.searchByExpiry(expiryDaysTOSearch);
      if (list.isEmpty) {
        locator<GlobalServices>()
            .errorSnackBar(" No items expiring within the specified days.");
      } else {
        newProducts = list;
      }
    }

    for (var product in newProducts) {
      bool checkFlag=false;
      prodList.forEach((element) { if(element.id==product.id){
          checkFlag=true;
      }});
      if (!checkFlag) {
        prodList.add(product);
      }
    }

    // To show the same quantity selected in search page list also
    for (int i = 0; i < widget.args!.productlist.length; i++) {
      for (int j = 0; j < prodList.length; j++) {
        if (widget.args!.productlist[i].product!.id == prodList[j].id) {
          prodList[j].quantity = widget.args!.productlist[i].product!.quantity;
        }
      }
    }
    print("searched products: $prodList");
    setState(() {});
  }

  void _scrollListener() async {
    if (isLoadingMore) return;
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      _currentPage++;
      setState(() {
        isLoadingMore = true;
      });
      await fetchSearchedProducts();
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  // void _selectProduct(Product product) {
  //   final canSelect = widget.args?.isSelecting ?? false;
  //   if (!canSelect) {
  //     return;
  //   }

  //   print("running");
  //   final isSale = widget.args?.orderType == OrderType.sale;
  //   if (isSale && (product.quantity ?? 0) < 1) {
  //     locator<GlobalServices>().infoSnackBar('Item not available');
  //     return;
  //   }

  //   setState(() {
  //     !_products.contains(product)
  //         ? _products.add(product)
  //         : _products.remove(product);
  //   });
  // }

  void _selectProduct(Product product) {
    print("helooooooooo");
    final isSale = widget.args?.orderType == OrderType.sale;
    if (isSale && (product.quantity ?? 0) < 1) {
      locator<GlobalServices>().infoSnackBar('Item not available');
      return;
    }

    setState(() {
      _products.add(product);
    });
  }

  void increaseTheQuantity(Product product) {
    _selectProduct(product);
  }

  void decreaseTheQuantity(Product product) {
    for (int j = 0; j < _products.length; j++) {
      if (_products[j].id == product.id) {
        _products.removeAt(j);
        break;
      }
    }
    setState(() {});
  }

  int countNoOfQuatityInArray(Product product) {
    int count = 0;
    _products.forEach((element) {
      if (element.id == product.id) count++;
    });

    return count;
  }

  FocusNode node = FocusNode();

  GlobalKey widgetKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    // final width = MediaQuery.of(context).size.width;

    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "Product List",
            style: TextStyle(
                color: Colors.black,
                fontSize: height / 45,
                fontFamily: 'GilroyBold'),
          ),
          centerTitle: true,
            actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                  onTap: () {
                    _showFilterDialog();
                  },
                  child: Icon(Icons.filter_alt)),
            )
          ],
        ),
        floatingActionButton: Container(
          margin: const EdgeInsets.only(
            right: 10,
            left: 30,
            bottom: 20,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.args!.isSelecting)
                Expanded(
                  child: CustomButton(
                      title: "Continue",
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      onTap: () {
                        if (_products.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(
                                "Please select products before continuing",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(
                          context,
                          _products,
                        );
                      }),
                ),
              if (widget.args?.isSelecting ?? false) const SizedBox(width: 20),
              FloatingActionButton(
                onPressed: () async {
                  _productCubit.getProducts(_currentPage, _limit);

                  await Navigator.pushNamed(context, '/create-product');
                  _productCubit.getProducts(_currentPage, _limit);
                },
                backgroundColor: Colors.green,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ],
          ),
        ),
        body: Stack(children: [
                Column(
                  children: [
                    SizedBox(
                      height: 60,
                    ),
                        prodList.length == 0
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 15),
                        child: Text('No products found!'),
                      ),
                    ):
                    Expanded(
                      child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, mainAxisExtent: 250),
                          padding: EdgeInsets.all(8),
                          itemCount: isLoadingMore
                              ? prodList.length + 1
                              : prodList.length,
                          controller: scrollController,
                          itemBuilder: (context, index) {
                            if (index < prodList.length) {
                              return Container(
                                height: 250,
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        ProductCardHorizontal(
                                          type: widget.args.orderType,
                                          key: ValueKey(prodList[index].id),
                                          noOfQuatityadded:
                                              countNoOfQuatityInArray(
                                                  prodList[index]),
                                          isSelecting: widget.args.isSelecting,
                                          onAdd: () {
                                            increaseTheQuantity(
                                                prodList[index]);
                                            if (widget.args!.orderType ==
                                                OrderType.sale) {
                                              prodList[index].quantity =
                                                  prodList[index].quantity! - 1;
                                            } else {
                                              prodList[index].quantity =
                                                  prodList[index].quantity! + 1;
                                            }
                                            setState(() {});
                                          },
                                          onRemove: () {
                                            decreaseTheQuantity(
                                                prodList[index]);
                                            itemCheckedFlag = false;
                                            if (widget.args!.orderType ==
                                                OrderType.sale) {
                                              prodList[index].quantity =
                                                  prodList[index].quantity! + 1;
                                            } else {
                                              prodList[index].quantity =
                                                  prodList[index].quantity! - 1;
                                            }
                                            setState(() {});
                                          },
                                          onTap: (q) {
                                            if (q == 1) {
                                              decreaseTheQuantity(
                                                  prodList[index]);
                                              itemCheckedFlag = false;
                                            } else if (q == 0) {
                                              _selectProduct(prodList[index]);
                                              itemCheckedFlag = true;
                                            }

                                            setState(() {});
                                          },
                                          product: prodList[index],
                                          onDelete: () async {
                                            var result = true;

                                            if (await _pinService.pinStatus() ==
                                                true) {
                                              result = await _showPinDialog()
                                                  as bool;
                                            }

                                            if (result!) {
                                              _productCubit.deleteProduct(
                                                  prodList[index],
                                                  _currentPage,
                                                  _limit);
                                              setState(() {
                                                prodList.removeAt(index);
                                              });
                                            }
                                          },
                                          onEdit: () async {
                                            var result = true;
                                            print("llllllll");
                                            if (await _pinService.pinStatus() ==
                                                true) {
                                              result = await _showPinDialog()
                                                  as bool;
                                            }
                                            if (result) {
                                              await Navigator.pushNamed(
                                                context,
                                                CreateProduct.routeName,
                                                arguments: prodList[index].id,
                                              );

                                              _productCubit.getProducts(
                                                  _currentPage, _limit);
                                              pinController.clear();
                                            }
                                          },
                                        ),
                                        if (countNoOfQuatityInArray(
                                                    prodList[index]) >
                                                0 &&
                                            widget.args.isSelecting)
                                          const Align(
                                            alignment: Alignment.topRight,
                                            child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: CircleAvatar(
                                                radius: 15,
                                                backgroundColor: Colors.green,
                                                child: Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              return Center(child: Text("loading"));
                            }
                          }),
                    ),
                  ],
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//               child: CustomTextField(
                  child: CustomTextField2(
                    key: widgetKey,
                    controller: searchController,

                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search',
                    onChanged: (String e) async {
                      if (e.isNotEmpty) {
                       
                        prodList = await searchProductServices.searchproduct(e);
                        for (int i = 0;
                            i < widget.args!.productlist.length;
                            i++) {
                          for (int j = 0; j < prodList.length; j++) {
                            if (widget.args!.productlist[i].product!.id ==
                                prodList[j].id) {
                              prodList[j].quantity =
                                  widget.args!.productlist[i].product!.quantity;
                            }
                          }
                        }
                        print(_products);

                        print("searchbar running");
                        setState(() {});
                      }
                    },
                    // onsubmitted: (value) {
                    //   Navigator.of(context).push(MaterialPageRoute(
                    //     builder: (context) =>
                    //         SearchProductListScreen(title: value!),
                    //   ));
                    // },
                  ),
                ),
              ]));
  }

  Future<bool?> _showPinDialog() {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
              content: PinCodeTextField(
                onChanged: (v) {},
                autoDisposeControllers: false,
                appContext: context,
                length: 6,
                obscureText: true,
                obscuringCharacter: '*',
                blinkWhenObscuring: true,
                animationType: AnimationType.fade,
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.underline,
                  borderRadius: BorderRadius.circular(5),
                  fieldHeight: 40,
                  fieldWidth: 30,
                  inactiveColor: Colors.black45,
                  inactiveFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  selectedColor: Colors.black45,
                  disabledColor: Colors.black,
                  activeFillColor: Colors.white,
                ),
                cursorColor: Colors.black,
                controller: pinController,
                animationDuration: const Duration(milliseconds: 300),
                enableActiveFill: true,
              ),
              title: Row(
                children: [
                  Expanded(child: Text('Enter your pin')),
                  GestureDetector(
                      onTap: () {
                        Navigator.of(ctx).pop();
                      },
                      child: Icon(Icons.close))
                ],
              ),
              actions: [
                Center(
                    child: Container(
                  width: 200,
                  height: 40,
                  child: CustomButton(
                      title: 'Verify',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                      onTap: () async {
                        bool status = await _pinService.verifyPin(
                            int.parse(pinController.text.toString()));
                        print(status);
                        if (status) {
                          pinController.clear();
                          Navigator.of(ctx).pop(true);
                        } else {
                          Navigator.of(ctx).pop(false);
                          pinController.clear();

                          return;
                        }
                      }),
                ))
              ],
            ));
  }
   Future<bool?> _showFilterDialog() {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
              content: Container(
                  height: 150,
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () {
                          _showExpiryFilterDialog();
                        },
                        leading: Text("Expiry"),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 15,
                        ),
                      ),
                    ],
                  )),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter'),
                  GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Icon(Icons.close))
                ],
              ),
            ));
  }

  Future<bool?> _showExpiryFilterDialog() {
    getData(int days) async {
      prodList.clear();
      expiryDaysTOSearch = days;
      searchMode = "expiry";
      setState(() {});
      fetchSearchedProducts();

      Navigator.of(context).pop();
      Navigator.of(context).pop();
    }

    ;

    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
              content:
                  Container(height: 350, child: ExpiryFilterContent(getData)),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Expiry days'),
                  GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Icon(Icons.close))
                ],
              ),
            ));
  }
}
class ExpiryFilterContent extends StatefulWidget {
  var ontap;
  ExpiryFilterContent(this.ontap);

  @override
  State<ExpiryFilterContent> createState() => _RadioButtonGroupState();
}

class _RadioButtonGroupState extends State<ExpiryFilterContent> {
  int groupedValue = 7;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioMenuButton(
            value: 7,
            groupValue: groupedValue,
            onChanged: (v) {
              groupedValue = 7;
              setState(() {});
            },
            child: Text("7")),
        RadioMenuButton(
            value: 15,
            groupValue: groupedValue,
            onChanged: (v) {
              groupedValue = 15;
              setState(() {});
            },
            child: Text("15")),
        RadioMenuButton(
            value: 30,
            groupValue: groupedValue,
            onChanged: (v) {
              groupedValue = 30;
              setState(() {});
            },
            child: Text("30")),
        RadioMenuButton(
            value: 90,
            groupValue: groupedValue,
            onChanged: (v) {
              groupedValue = 90;
              setState(() {});
            },
            child: Text("90")),
        RadioMenuButton(
            value: 180,
            groupValue: groupedValue,
            onChanged: (v) {
              groupedValue = 180;
              setState(() {});
            },
            child: Text("180")),
            SizedBox(height: 20,),
        CustomTextField(
          inputType: TextInputType.number,
          hintText: "Custom Expiry",
          onChanged: (e) {
            groupedValue = int.parse(e);
          },
        ),
                   SizedBox(height: 20,),
        CustomButton(
            title: 'Submit',
            onTap: () async {
              widget.ontap(groupedValue);
            }),
      ],
    );
  }
}
