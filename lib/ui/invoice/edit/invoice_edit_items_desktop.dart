import 'package:flutter/material.dart';
import 'package:invoiceninja_flutter/constants.dart';
import 'package:invoiceninja_flutter/data/models/entities.dart';
import 'package:invoiceninja_flutter/data/models/invoice_model.dart';
import 'package:invoiceninja_flutter/redux/product/product_selectors.dart';
import 'package:invoiceninja_flutter/ui/app/form_card.dart';
import 'package:invoiceninja_flutter/ui/app/forms/custom_field.dart';
import 'package:invoiceninja_flutter/ui/invoice/edit/invoice_edit_items_vm.dart';
import 'package:invoiceninja_flutter/ui/settings/custom_fields.dart';
import 'package:invoiceninja_flutter/utils/formatting.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class InvoiceEditItemsDesktop extends StatefulWidget {
  const InvoiceEditItemsDesktop({
    this.viewModel,
  });

  final EntityEditItemsVM viewModel;

  @override
  _InvoiceEditItemsDesktopState createState() =>
      _InvoiceEditItemsDesktopState();
}

class _InvoiceEditItemsDesktopState extends State<InvoiceEditItemsDesktop> {
  int _updatedAt;

  /*
  final Map<int, FocusNode> _focusNodes = {};

  @override
  void didChangeDependencies() {
    _focusNodes.values.forEach((node) => node.dispose());

    final lineItems = widget.viewModel.invoice.lineItems;
    for (var index = 0; index < lineItems.length; index++) {
      _focusNodes[index] = FocusNode()
        ..addListener(() => _onFocusChange(index));
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _focusNodes.values.forEach((node) => node.dispose());
    super.dispose();
  }

  void _onFocusChange(int index) {
    setState(() {});
  }
  */

  void _updateTable() {
    setState(() {
      _updatedAt = DateTime.now().millisecondsSinceEpoch;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);
    final viewModel = widget.viewModel;
    final state = viewModel.state;
    final company = state.company;
    final invoice = viewModel.invoice;
    final lineItems = invoice.lineItems.toList();
    final productState = state.productState;
    final productIds =
        memoizedDropdownProductList(productState.map, productState.list);

    if (lineItems.where((item) => item.isEmpty).isEmpty) {
      lineItems.add(InvoiceItemEntity());
    }

    return FormCard(
      padding: const EdgeInsets.symmetric(horizontal: kMobileDialogPadding),
      child: Table(
        defaultColumnWidth: FixedColumnWidth(150),
        columnWidths: {
          0: FixedColumnWidth(200),
          1: FlexColumnWidth(),
          5: FixedColumnWidth(kMinInteractiveDimension),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        key: ValueKey('__datatable_${_updatedAt}__'),
        children: [
          TableRow(children: [
            TableHeader(localization.item),
            TableHeader(localization.description),
            if (company.hasCustomField(CustomFieldType.product1))
              TableHeader(
                  company.getCustomFieldLabel(CustomFieldType.product1)),
            if (company.hasCustomField(CustomFieldType.product2))
              TableHeader(
                  company.getCustomFieldLabel(CustomFieldType.product2)),
            if (company.hasCustomField(CustomFieldType.product3))
              TableHeader(
                  company.getCustomFieldLabel(CustomFieldType.product3)),
            if (company.hasCustomField(CustomFieldType.product4))
              TableHeader(
                  company.getCustomFieldLabel(CustomFieldType.product4)),
            TableHeader(localization.unitCost, isNumeric: true),
            TableHeader(localization.quantity, isNumeric: true),
            TableHeader(localization.lineTotal, isNumeric: true),
            TableHeader(''),
          ]),
          for (var index = 0; index < lineItems.length; index++)
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.only(right: kTableColumnGap),
                child: TypeAheadFormField<String>(
                  initialValue: lineItems[index].productKey,
                  noItemsFoundBuilder: (context) => SizedBox(),
                  suggestionsCallback: (pattern) {
                    return productIds
                        .where((productId) =>
                            productState.map[productId].matchesFilter(pattern))
                        .toList();
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      title: Text(productState.map[suggestion].productKey),
                    );
                  },
                  onSuggestionSelected: (suggestion) {
                    final item = lineItems[index];
                    final product = productState.map[suggestion];
                    final updatedItem = item.rebuild((b) => b
                      ..productKey = product.productKey
                      ..notes = product.notes
                      ..cost = product.price
                      ..quantity = item.quantity == 0 &&
                              viewModel.state.company.defaultQuantity
                          ? 1
                          : item.quantity);
                    viewModel.onChangedInvoiceItem(updatedItem, index);
                    viewModel.addLineItem();
                    _updateTable();
                  },
                  textFieldConfiguration:
                      TextFieldConfiguration<String>(onChanged: (value) {
                    viewModel.onChangedInvoiceItem(
                        lineItems[index].rebuild((b) => b..productKey = value),
                        index);
                  }),
                  autoFlipDirection: true,
                  //direction: AxisDirection.up,
                  animationStart: 1,
                  debounceDuration: Duration(seconds: 0),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: kTableColumnGap),
                child: TextFormField(
                  initialValue: lineItems[index].notes,
                  onChanged: (value) => viewModel.onChangedInvoiceItem(
                      lineItems[index].rebuild((b) => b..notes = value), index),
                  minLines: 1,
                  maxLines: 6,
                  //maxLines: _focusNodes[index].hasFocus ? 6 : 1,
                  //focusNode: _focusNodes[index],
                ),
              ),
              if (company.hasCustomField(CustomFieldType.product1))
                Padding(
                  padding: const EdgeInsets.only(right: kTableColumnGap),
                  child: CustomField(
                    field: CustomFieldType.product1,
                    value: lineItems[index].customValue1,
                    hideFieldLabel: true,
                    onChanged: (value) => viewModel.onChangedInvoiceItem(
                        lineItems[index]
                            .rebuild((b) => b..customValue1 = value),
                        index),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: kTableColumnGap),
                child: TextFormField(
                  textAlign: TextAlign.right,
                  initialValue: formatNumber(lineItems[index].cost, context,
                      formatNumberType: FormatNumberType.input),
                  onChanged: (value) => viewModel.onChangedInvoiceItem(
                      lineItems[index]
                          .rebuild((b) => b..cost = parseDouble(value)),
                      index),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: kTableColumnGap),
                child: TextFormField(
                  textAlign: TextAlign.right,
                  initialValue: formatNumber(lineItems[index].quantity, context,
                      formatNumberType: FormatNumberType.input),
                  onChanged: (value) => viewModel.onChangedInvoiceItem(
                      lineItems[index]
                          .rebuild((b) => b..quantity = parseDouble(value)),
                      index),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: kTableColumnGap),
                child: TextFormField(
                  key: ValueKey('__total_${index}_${lineItems[index].total}__'),
                  readOnly: true,
                  enabled: false,
                  initialValue: formatNumber(lineItems[index].total, context),
                  textAlign: TextAlign.right,
                ),
              ),
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: lineItems[index].isEmpty
                    ? null
                    : () {
                        viewModel.onRemoveInvoiceItemPressed(index);
                        _updateTable();
                      },
              ),
            ])
        ],
      ),
    );
  }
}

class TableHeader extends StatelessWidget {
  const TableHeader(this.label, {this.isNumeric = false});

  final String label;
  final bool isNumeric;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: 8, right: isNumeric ? kTableColumnGap : 0),
      child: Text(
        label,
        textAlign: isNumeric ? TextAlign.right : TextAlign.left,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}
