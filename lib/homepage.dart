import 'package:asset_management/api_helper.dart';
import 'package:asset_management/loginpage.dart';
import 'package:asset_management/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

////////////////////////////////////////////////////////////
/// ASSET HOME PAGE
////////////////////////////////////////////////////////////
class AssetHome extends StatefulWidget {
  const AssetHome({super.key});

  @override
  State<AssetHome> createState() => _AssetHomeState();
}

class _AssetHomeState extends State<AssetHome> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> assets = [];

  ////////////////////////////////////////////////////////////
  /// CONTROLLERS
  ////////////////////////////////////////////////////////////

  final idCtrl = TextEditingController();
  final barcodeCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final sellingCtrl = TextEditingController();
  final purchaseCtrl = TextEditingController();
  final uomCtrl = TextEditingController();
  final opStockCtrl = TextEditingController();
  final currentStockCtrl = TextEditingController();
  final taxCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final f2 = FocusNode();
  final f3 = FocusNode();
  final f4 = FocusNode();
  final f5 = FocusNode();
  final f6 = FocusNode();
  final f7 = FocusNode();
  final f8 = FocusNode();
  final f9 = FocusNode();
  final f10 = FocusNode();
  final saveFocus = FocusNode();

  int? editingId;

  bool loading = true;

  List<Map<String, dynamic>> filteredAssets = [];

  final barcodeSearchCtrl = TextEditingController();
  final nameSearchCtrl = TextEditingController();
  final categorySearchCtrl = TextEditingController();
  final taxSearchCtrl = TextEditingController();
  int currentPage = 0;
  final int rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    load();
  }

  List<Map<String, dynamic>> get pagedAssets {
    final start = currentPage * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, filteredAssets.length);
    return filteredAssets.sublist(start, end);
  }

  int get totalPages => (filteredAssets.length / rowsPerPage).ceil();

  Future load() async {
    setState(() => loading = true);
    try {
      assets = await ApiHelper.getItems();
      filteredAssets = List.from(assets);
      currentPage = 0;
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load items: $e")));
    }
    setState(() => loading = false);
  }

  Future logout() async {
    await TokenStorage.delete();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  ////////////////////////////////////////////////////////////
  /// FORM HELPERS
  ////////////////////////////////////////////////////////////

  void clearForm() {
    editingId = null;

    idCtrl.clear();
    barcodeCtrl.clear();
    nameCtrl.clear();
    categoryCtrl.clear();
    sellingCtrl.clear();
    purchaseCtrl.clear();
    uomCtrl.clear();
    opStockCtrl.clear();
    currentStockCtrl.clear();
    taxCtrl.clear();
  }

  void openAdd() {
    clearForm();
    _scaffoldKey.currentState!.openEndDrawer();
  }

  void openEdit(Map<String, dynamic> item) {
    editingId = item["id"];
    barcodeCtrl.text = item["barcode"] ?? "";
    nameCtrl.text = item["name"] ?? "";
    categoryCtrl.text = item["category"] ?? "";
    sellingCtrl.text = item["selling_price"]?.toString() ?? "";
    purchaseCtrl.text = item["purchase_price"]?.toString() ?? "";
    uomCtrl.text = item["uom"] ?? "";
    opStockCtrl.text = item["op_stock"]?.toString() ?? "";
    currentStockCtrl.text = item["current_stock"]?.toString() ?? "";
    taxCtrl.text = item["tax"] ?? "";
    _scaffoldKey.currentState!.openEndDrawer();
  }

  Future save() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      "barcode": barcodeCtrl.text.trim(),
      "name": nameCtrl.text.trim(),
      "category": categoryCtrl.text.trim(),
      "selling_price": double.tryParse(sellingCtrl.text) ?? 0,
      "purchase_price": double.tryParse(purchaseCtrl.text) ?? 0,
      "uom": uomCtrl.text.trim(),
      "op_stock": int.tryParse(opStockCtrl.text) ?? 0,
      "current_stock": int.tryParse(currentStockCtrl.text) ?? 0,
      "tax": taxCtrl.text.trim(),
    };

    if (editingId == null) {
      // Add new item
      final created = await ApiHelper.addItem(data);
      if (created != null) {
        Navigator.pop(context);
        setState(() {
          assets.add(created); // add locally
        });
        applyFilter(); // refresh filtered list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item added successfully")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to save item")));
      }
    } else {
      // Update existing item
      final success = await ApiHelper.updateItem(editingId!, data);
      if (success) {
        Navigator.pop(context);
        setState(() {
          final index = assets.indexWhere((e) => e["id"] == editingId);
          if (index != -1) {
            assets[index] = {...assets[index], ...data};
          }
        });
        applyFilter(); // refresh filtered list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item updated successfully")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to update item")));
      }
    }
  }

  Future deleteItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiHelper.deleteItem(id);
      if (success) {
        setState(() {
          assets.removeWhere((e) => e["id"] == id); // remove locally
        });
        applyFilter(); // refresh filtered list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item deleted successfully")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to delete item")));
      }
    }
  }

  void applyFilter() {
    final b = barcodeSearchCtrl.text.toLowerCase();
    final n = nameSearchCtrl.text.toLowerCase();
    final c = categorySearchCtrl.text.toLowerCase();
    final t = taxSearchCtrl.text.toLowerCase();

    setState(() {
      filteredAssets = assets.where((item) {
        final barcode = (item["barcode"] ?? "").toString().toLowerCase();
        final name = (item["name"] ?? "").toString().toLowerCase();
        final category = (item["category"] ?? "").toString().toLowerCase();
        final tax = (item["tax"] ?? "").toString().toLowerCase();

        return barcode.contains(b) &&
            name.contains(n) &&
            category.contains(c) &&
            tax.contains(t);
      }).toList();
    });
    currentPage = 0;
  }

  ////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      ////////////////////////////////////////////////////////////
      /// RIGHT SLIDER FORM
      ////////////////////////////////////////////////////////////
      endDrawer: Drawer(
        width: 420,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Form(
                autovalidateMode: AutovalidateMode.onUnfocus,
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      editingId == null ? "Add Item" : "Edit Item",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    buildField(
                      barcodeCtrl,
                      "Barcode",
                      focus: f2,
                      nextFocus: f3,
                    ),
                    buildField(nameCtrl, "Item Name", focus: f3, nextFocus: f4),
                    buildField(
                      categoryCtrl,
                      "Category",
                      focus: f4,
                      nextFocus: f5,
                    ),
                    buildField(
                      sellingCtrl,
                      "Selling Price",
                      number: true,
                      focus: f5,
                      nextFocus: f6,
                    ),
                    buildField(
                      purchaseCtrl,
                      "Purchase Price",
                      number: true,
                      focus: f6,
                      nextFocus: f7,
                    ),
                    buildField(uomCtrl, "UOM", focus: f7, nextFocus: f8),
                    buildField(
                      opStockCtrl,
                      "OP Stock",
                      number: true,
                      focus: f8,
                      nextFocus: f9,
                    ),
                    buildField(
                      currentStockCtrl,
                      "Current Stock",
                      number: true,
                      focus: f9,
                      nextFocus: f10,
                    ),
                    buildField(
                      taxCtrl,
                      "Tax Type",
                      focus: f10,
                      nextFocus: saveFocus,
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Focus(
                        focusNode: saveFocus,
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.enter) {
                            save();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: Builder(
                          builder: (context) {
                            final focused = Focus.of(context).hasFocus;
                            return Container(
                              decoration: BoxDecoration(
                                border: focused
                                    ? Border.all(
                                        color: AppColors.button,
                                        width: 2,
                                      )
                                    : null, // highlight when focused
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 200,
                                    child: ElevatedButton(
                                      onPressed: save,
                                      child: Text(
                                        editingId == null
                                            ? "Save Item"
                                            : "Update Item",
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      ////////////////////////////////////////////////////////////
      /// MAIN PAGE
      ////////////////////////////////////////////////////////////
      appBar: AppBar(
        title: const Text("POS", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF455A64),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: openAdd,
        child: const Icon(Icons.add),
      ),

      ////////////////////////////////////////////////////////////
      /// TABLE (auto width by content)
      ////////////////////////////////////////////////////////////
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : assets.isEmpty
          ? const Center(child: Text("No items"))
          : LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 1000;

                Widget tableWidget = Container(
                  color: Colors.grey.shade100, // page background
                  child: Column(
                    children: [
                      ////////////////////////////////////////////////////////////
                      /// SEARCH SECTION (professional card)
                      ////////////////////////////////////////////////////////////
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Search Filters",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),

                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  buildSearchField(
                                    controller: barcodeSearchCtrl,
                                    label: "Barcode",
                                    width: 170,
                                  ),
                                  const SizedBox(width: 12),
                                  buildSearchField(
                                    controller: nameSearchCtrl,
                                    label: "Name",
                                    width: 200,
                                  ),
                                  const SizedBox(width: 12),
                                  buildSearchField(
                                    controller: categorySearchCtrl,
                                    label: "Category",
                                    width: 200,
                                  ),
                                  const SizedBox(width: 12),
                                  buildSearchField(
                                    controller: taxSearchCtrl,
                                    label: "Tax",
                                    width: 150,
                                  ),
                                  const SizedBox(width: 16),

                                  OutlinedButton.icon(
                                    onPressed: () {
                                      barcodeSearchCtrl.clear();
                                      nameSearchCtrl.clear();
                                      categorySearchCtrl.clear();
                                      taxSearchCtrl.clear();
                                      setState(() {
                                        filteredAssets = List.from(assets);
                                        currentPage = 0;
                                      });
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text("Reset"),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      ////////////////////////////////////////////////////////////
                      /// TABLE SECTION (main professional container)
                      ////////////////////////////////////////////////////////////
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              //////////////////////////////////////////////////////
                              /// small header bar
                              //////////////////////////////////////////////////////
                              /// PAGINATION HEADER
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Items List",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  Wrap(
                                    spacing: 6,
                                    children: List.generate(totalPages, (
                                      index,
                                    ) {
                                      final selected = index == currentPage;

                                      return InkWell(
                                        onTap: () {
                                          setState(() => currentPage = index);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? Colors.grey.shade300
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Text("${index + 1}"),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),

                              const Divider(height: 18, thickness: .8),

                              //////////////////////////////////////////////////////
                              /// TABLE
                              //////////////////////////////////////////////////////
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.blueGrey.shade100,
                                      ),
                                    ),
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: isSmallScreen
                                              ? 1350
                                              : constraints.maxWidth - 70,
                                        ),
                                        child: Table(
                                          key: ValueKey(filteredAssets.length),
                                          border: TableBorder(
                                            horizontalInside: BorderSide(
                                              color: Colors.blueGrey.shade50,
                                            ),
                                            verticalInside: BorderSide(
                                              color: Colors.blueGrey.shade50,
                                            ),
                                          ),
                                          defaultVerticalAlignment:
                                              TableCellVerticalAlignment
                                                  .middle,
                                          columnWidths: const {
                                            0: FixedColumnWidth(80),
                                            1: FixedColumnWidth(200),
                                            2: FixedColumnWidth(200),
                                            3: FixedColumnWidth(200),
                                            4: FixedColumnWidth(130),
                                            5: FixedColumnWidth(130),
                                            6: FixedColumnWidth(130),
                                            7: FixedColumnWidth(90),
                                            8: FixedColumnWidth(110),
                                            9: FixedColumnWidth(110),
                                            10: FixedColumnWidth(70),
                                            11: FixedColumnWidth(80),
                                          },
                                          children: [
                                            headerRow(),
                                            ...pagedAssets.asMap().entries.map((
                                              entry,
                                            ) {
                                              final a = entry.value;
                                              return row(
                                                [
                                                  a["id"],
                                                  a["barcode"],
                                                  a["name"],
                                                  a["category"],
                                                  a["selling_price"] ?? 0,
                                                  a["purchase_price"] ?? 0,
                                                  a["uom"],
                                                  a["op_stock"] ?? 0,
                                                  a["current_stock"] ?? 0,
                                                  a["tax"],
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      size: 20,
                                                    ),
                                                    onPressed: () => openEdit(a),
                                                  ),
                                                  IconButton(
                                                    padding: EdgeInsets.zero,
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      size: 20,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () =>
                                                        deleteItem(a["id"]),
                                                  ),
                                                ],
                                                index: entry.key,
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// FOOTER INFO
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Showing ${filteredAssets.isEmpty ? 0 : currentPage * rowsPerPage + 1}"
                            "–${(currentPage * rowsPerPage + pagedAssets.length)} "
                            "of ${filteredAssets.length} entries",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                return tableWidget;
              },
            ),
    );
  }

  // Helper function to create rectangular search field
  Widget buildSearchField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    double? width,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: TextField(
          controller: controller,
          onChanged: (_) => applyFilter(),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: icon != null ? Icon(icon) : null,
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    );
  }
  ////////////////////////////////////////////////////////////
  /// SMALL HELPERS
  ////////////////////////////////////////////////////////////

  Widget buildField(
    TextEditingController c,
    String label, {
    bool number = false,
    FocusNode? focus,
    FocusNode? nextFocus,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        focusNode: focus,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        textInputAction: nextFocus != null
            ? TextInputAction.next
            : TextInputAction.done,

        inputFormatters: number
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : null,

        onFieldSubmitted: (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          } else {
            FocusScope.of(context).unfocus();
          }
        },

        decoration: InputDecoration(labelText: label),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return "Required";
          if (number && double.tryParse(v.trim()) == null)
            return "Numbers only";
          return null;
        },
      ),
    );
  }

  TableRow headerRow() {
    return row([
      "ID",
      "Barcode",
      "Item Name",
      "Category",
      "Selling price",
      "Purchase price",
      "UOM (unit of measurement)",
      "OP Stock",
      "Current stock",
      "Tax type",
      "Edit",
      "Delete",
    ], header: true);
  }

  TableRow row(List<dynamic> cells, {bool header = false, int? index}) {
    return TableRow(
      decoration: BoxDecoration(
        color: header
            ? const Color(0xFFE3F2FD)
            : (index != null && index.isEven
                  ? Colors.white
                  : const Color(0xFFFAFBFC)),
      ),
      children: cells
          .map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: e is Widget
                  ? e
                  : SelectableText(
                      "$e",
                      style: header
                          ? const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            )
                          : null,
                    ),
            ),
          )
          .toList(),
    );
  }
}
