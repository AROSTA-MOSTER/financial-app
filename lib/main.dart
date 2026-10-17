import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LightGateRequisitionApp());
}

class LightGateRequisitionApp extends StatelessWidget {
  const LightGateRequisitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Light Gate Church Requisitions',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F2537),
          primary: const Color(0xFF0F2537), // Church Deep Navy
          secondary: const Color(0xFF2E6F40), // Liturgical Emerald
          tertiary: const Color(0xFFB45309), // Warm Amber
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF0F2537), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13),
        ),
      ),
      home: const RequisitionFormScreen(),
    );
  }
}

enum Persona {
  requester('Requester (Prepared By)', Icons.edit_document, Color(0xFF0284C7)),
  reviewer('Finance Dept (Reviewed By)', Icons.fact_check, Color(0xFFD97706)),
  approver('Management (Approved By)', Icons.verified_user, Color(0xFF059669));

  final String label;
  final IconData icon;
  final Color color;
  const Persona(this.label, this.icon, this.color);
}

class LineItem {
  int sn;
  String description;
  int amount;
  TextEditingController descController;
  TextEditingController amountController;

  LineItem({
    required this.sn,
    this.description = '',
    this.amount = 0,
  })  : descController = TextEditingController(text: description),
        amountController = TextEditingController(
          text: amount > 0 ? amount.toString() : '',
        );

  void dispose() {
    descController.dispose();
    amountController.dispose();
  }
}

class RequisitionFormScreen extends StatefulWidget {
  const RequisitionFormScreen({super.key});

  @override
  State<RequisitionFormScreen> createState() => _RequisitionFormScreenState();
}

class _RequisitionFormScreenState extends State<RequisitionFormScreen> {
  Persona _activePersona = Persona.requester;
  final _currencyFormat = NumberFormat('#,###', 'en_US');
  final _dateFormat = DateFormat('MMMM dd, yyyy');

  // Document Header Fields
  DateTime _date = DateTime.now();
  final _reqNoController = TextEditingController(text: 'REQ-2026-0001');
  String _selectedDepartment = 'Worship & Music';
  final _requestedByController = TextEditingController();
  final _purposeController = TextEditingController();

  final List<String> _departments = [
    'Worship & Music',
    'Media & Technical',
    'Youth & Teens Ministry',
    'Children Ministry',
    'Administration & Finance',
    'Hospitality & Ushering',
    'Pastoral & Counseling',
    'Evangelism & Outreach',
    'Facility & Maintenance',
  ];

  // Middle Items Table (default 5 rows like the docx)
  late List<LineItem> _items;

  // Sign-off section
  // 1. Prepared By
  final _preparedByNameController = TextEditingController();
  bool _isPreparedSigned = false;
  DateTime? _preparedDate;

  // 2. Reviewed By (Finance Dept)
  final _reviewedByNameController = TextEditingController();
  String _reviewerDecision = 'PENDING'; // 'PENDING', 'ENDORSED', 'REJECTED'
  String _reviewerNotes = '';
  DateTime? _reviewedDate;

  // 3. Approved By (Management)
  final _approvedByNameController = TextEditingController();
  String _approverDecision = 'PENDING'; // 'PENDING', 'APPROVED', 'REJECTED'
  String _approverNotes = '';
  DateTime? _approvedDate;

  @override
  void initState() {
    super.initState();
    _items = List.generate(
      5,
      (index) => LineItem(sn: index + 1),
    );
  }

  @override
  void dispose() {
    _reqNoController.dispose();
    _requestedByController.dispose();
    _purposeController.dispose();
    _preparedByNameController.dispose();
    _reviewedByNameController.dispose();
    _approvedByNameController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  int get _grandTotal {
    return _items.fold(0, (sum, item) => sum + item.amount);
  }

  void _addItemRow() {
    setState(() {
      _items.add(LineItem(sn: _items.length + 1));
    });
  }

  void _removeItemRow(int index) {
    if (_items.length <= 1) return;
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
      for (int i = 0; i < _items.length; i++) {
        _items[i].sn = i + 1;
      }
    });
  }

  void _resetForm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Form?'),
        content: const Text('This will clear all entered items and signatures.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _date = DateTime.now();
                _requestedByController.clear();
                _purposeController.clear();
                _preparedByNameController.clear();
                _reviewedByNameController.clear();
                _approvedByNameController.clear();
                _isPreparedSigned = false;
                _preparedDate = null;
                _reviewerDecision = 'PENDING';
                _reviewerNotes = '';
                _reviewedDate = null;
                _approverDecision = 'PENDING';
                _approverNotes = '';
                _approvedDate = null;
                for (var item in _items) {
                  item.dispose();
                }
                _items = List.generate(5, (index) => LineItem(sn: index + 1));
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2537),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.church, color: Colors.white),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LIGHT GATE CHURCH',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'DAILY REQUISITION FORM',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reset Form',
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _resetForm,
          ),
          IconButton(
            tooltip: 'View Document Summary',
            icon: const Icon(Icons.preview_outlined, color: Colors.white),
            onPressed: _showDocumentSummaryDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Container(
            color: const Color(0xFF1E3A52),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'ROLE: ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: Persona.values.map((persona) {
                        final isSelected = _activePersona == persona;
                        final shortName = persona == Persona.requester
                            ? 'Requester'
                            : persona == Persona.reviewer
                                ? 'Finance Dept'
                                : 'Management';
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => setState(() => _activePersona = persona),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? persona.color : Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? Colors.white.withOpacity(0.4) : Colors.white24,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_circle : persona.icon,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    shortName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Church Document Header Box
                _buildDocumentHeaderCard(),
                const SizedBox(height: 16),

                // Middle Particulars / Items Table
                _buildParticularsTableCard(),
                const SizedBox(height: 16),

                // Bottom Tripartite Sign-off Section
                _buildSignoffSectionCard(),
                const SizedBox(height: 24),

                // Official Action Buttons
                _buildPersonaActionControls(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1. Top Document Header Box
  Widget _buildDocumentHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 42,
                      height: 42,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.church, color: Color(0xFF0F2537), size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LIGHT GATE CHURCH',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F2537),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'DAILY REQUISITION FORM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusBadgeColor().withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusBadgeColor().withOpacity(0.4)),
                  ),
                  child: Text(
                    _getCurrentStatusText(),
                    style: TextStyle(
                      color: _getStatusBadgeColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),

            // Date & Requisition No
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 450;
                final dateWidget = InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today, size: 18),
                    ),
                    child: Text(
                      _dateFormat.format(_date),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                );

                final reqNoWidget = TextFormField(
                  controller: _reqNoController,
                  decoration: const InputDecoration(
                    labelText: 'Requisition No',
                    prefixIcon: Icon(Icons.tag, size: 18),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      dateWidget,
                      const SizedBox(height: 12),
                      reqNoWidget,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: dateWidget),
                    const SizedBox(width: 12),
                    Expanded(child: reqNoWidget),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            // Department & Requested By
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 450;
                final deptWidget = DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedDepartment,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    prefixIcon: Icon(Icons.account_tree_outlined, size: 18),
                  ),
                  items: _departments.map((dept) {
                    return DropdownMenuItem(
                      value: dept,
                      child: Text(
                        dept,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDepartment = val);
                  },
                );

                final reqByWidget = TextFormField(
                  controller: _requestedByController,
                  decoration: const InputDecoration(
                    labelText: 'Requested By',
                    prefixIcon: Icon(Icons.person_outline, size: 18),
                  ),
                  onChanged: (val) {
                    if (!_isPreparedSigned) {
                      _preparedByNameController.text = val;
                    }
                  },
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      deptWidget,
                      const SizedBox(height: 12),
                      reqByWidget,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: deptWidget),
                    const SizedBox(width: 12),
                    Expanded(child: reqByWidget),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            // Purpose of Request
            TextFormField(
              controller: _purposeController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Purpose of Request',
                alignLabelWithHint: true,
                hintText: 'State the specific purpose and ministry objective...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Middle Items / Particulars Table
  Widget _buildParticularsTableCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PARTICULARS & EXPENSE ITEMS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F2537),
                    letterSpacing: 0.6,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addItemRow,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Row'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0F2537),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Table Header Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      'S/N',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Item Description / Particulars',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total Amount (RWF)',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 36),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Table Rows
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (ctx, i) => const Divider(height: 12),
              itemBuilder: (ctx, index) {
                final item = _items[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // S/N
                    SizedBox(
                      width: 32,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.sn}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Description
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: item.descController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Description of item...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) {
                          item.description = val;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Amount (RWF)
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: item.amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          hintText: '0',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onChanged: (val) {
                          setState(() {
                            item.amount = int.tryParse(val) ?? 0;
                          });
                        },
                      ),
                    ),

                    // Delete Row Button
                    SizedBox(
                      width: 36,
                      child: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.black38, size: 18),
                        onPressed: () => _removeItemRow(index),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Grand Total Footer Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2537),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'GRAND TOTAL (RWF):',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    '${_currencyFormat.format(_grandTotal)} RWF',
                    style: const TextStyle(
                      color: Color(0xFF6EE7B7),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Bottom Tripartite Sign-off Section (Prepared By / Reviewed By / Approved By)
  Widget _buildSignoffSectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AUTHORIZATION & SIGN-OFF BLOCKS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2537),
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),

            // 1. Prepared By (Requestor)
            _buildSignatureBlock(
              title: 'Prepared By (Requestor)',
              borderColor: const Color(0xFF0284C7),
              badgeText: _isPreparedSigned ? 'SIGNED & SUBMITTED' : 'DRAFT',
              badgeColor: _isPreparedSigned ? Colors.green : Colors.grey,
              nameController: _preparedByNameController,
              isSigned: _isPreparedSigned,
              signedDate: _preparedDate,
              rolePersona: Persona.requester,
              onSignTap: () {
                if (_preparedByNameController.text.trim().isEmpty) {
                  _showSnack('Please enter Requestor Name before signing.');
                  return;
                }
                setState(() {
                  _isPreparedSigned = true;
                  _preparedDate = DateTime.now();
                });
                _showSnack('Requisition digitally signed by Requestor!');
              },
            ),
            const SizedBox(height: 14),

            // 2. Reviewed By (Finance Dept)
            _buildSignatureBlock(
              title: 'Reviewed By (Finance Dept)',
              borderColor: const Color(0xFFD97706),
              badgeText: _reviewerDecision,
              badgeColor: _reviewerDecision == 'ENDORSED'
                  ? Colors.green
                  : _reviewerDecision == 'REJECTED'
                      ? Colors.red
                      : Colors.orange,
              nameController: _reviewedByNameController,
              isSigned: _reviewerDecision != 'PENDING',
              signedDate: _reviewedDate,
              rolePersona: Persona.reviewer,
              notes: _reviewerNotes,
              onSignTap: () => _promptReviewerAction(),
            ),
            const SizedBox(height: 14),

            // 3. Approved By (Management)
            _buildSignatureBlock(
              title: 'Approved By (Management)',
              borderColor: const Color(0xFF059669),
              badgeText: _approverDecision,
              badgeColor: _approverDecision == 'APPROVED'
                  ? Colors.green
                  : _approverDecision == 'REJECTED'
                      ? Colors.red
                      : Colors.orange,
              nameController: _approvedByNameController,
              isSigned: _approverDecision != 'PENDING',
              signedDate: _approvedDate,
              rolePersona: Persona.approver,
              notes: _approverNotes,
              onSignTap: () => _promptApproverAction(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureBlock({
    required String title,
    required Color borderColor,
    required String badgeText,
    required Color badgeColor,
    required TextEditingController nameController,
    required bool isSigned,
    required DateTime? signedDate,
    required Persona rolePersona,
    required VoidCallback onSignTap,
    String? notes,
  }) {
    final isCurrentPersona = _activePersona == rolePersona;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrentPersona ? borderColor.withOpacity(0.04) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentPersona ? borderColor : const Color(0xFFE2E8F0),
          width: isCurrentPersona ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isCurrentPersona ? borderColor : const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withOpacity(0.4)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Name and Signature block with responsive layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final nameWidget = TextFormField(
                controller: nameController,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Name / Signature',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              );

              final actionButton = isSigned
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            signedDate != null ? DateFormat('MMM dd, yyyy').format(signedDate) : 'Signed',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: onSignTap,
                      icon: Icon(
                        isCurrentPersona ? Icons.edit : rolePersona.icon,
                        size: 14,
                      ),
                      label: Text(
                        isCurrentPersona
                            ? (rolePersona == Persona.requester
                                ? 'Sign Form'
                                : rolePersona == Persona.reviewer
                                    ? 'Endorse'
                                    : 'Authorize')
                            : (rolePersona == Persona.requester
                                ? 'Sign / Act'
                                : rolePersona == Persona.reviewer
                                    ? 'Review & Sign'
                                    : 'Approve & Sign'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: borderColor,
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                    );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    nameWidget,
                    const SizedBox(height: 8),
                    actionButton,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(flex: 3, child: nameWidget),
                  const SizedBox(width: 10),
                  Expanded(flex: 2, child: actionButton),
                ],
              );
            },
          ),

          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment_outlined, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Remarks: $notes',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 4. Role Action Buttons
  Widget _buildPersonaActionControls() {
    return Card(
      color: const Color(0xFF0F2537),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(_activePersona.icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Actions for ${_activePersona.label}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                final primaryBtn = ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  onPressed: () {
                    if (_activePersona == Persona.requester) {
                      _preparedByNameController.text = _requestedByController.text;
                      setState(() {
                        _isPreparedSigned = true;
                        _preparedDate = DateTime.now();
                      });
                      _showSnack('Requisition prepared and submitted for review!');
                    } else if (_activePersona == Persona.reviewer) {
                      _promptReviewerAction();
                    } else {
                      _promptApproverAction();
                    }
                  },
                  label: Text(
                    _activePersona == Persona.requester
                        ? 'Submit as Requestor'
                        : _activePersona == Persona.reviewer
                            ? 'Endorse (Finance)'
                            : 'Approve (Management)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                );

                final summaryBtn = OutlinedButton.icon(
                  icon: const Icon(Icons.description_outlined, size: 16),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  onPressed: _showDocumentSummaryDialog,
                  label: const Text('View Summary', style: TextStyle(fontSize: 13)),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      primaryBtn,
                      const SizedBox(height: 10),
                      summaryBtn,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: primaryBtn),
                    const SizedBox(width: 10),
                    summaryBtn,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _promptReviewerAction() {
    final nameCtrl = TextEditingController(text: _reviewedByNameController.text);
    final noteCtrl = TextEditingController(text: _reviewerNotes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finance Dept Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Reviewer Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Review Notes / Remarks'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _reviewedByNameController.text = nameCtrl.text;
                _reviewerDecision = 'REJECTED';
                _reviewerNotes = noteCtrl.text;
                _reviewedDate = DateTime.now();
              });
              _showSnack('Requisition rejected at Finance Review stage.');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _reviewedByNameController.text = nameCtrl.text;
                _reviewerDecision = 'ENDORSED';
                _reviewerNotes = noteCtrl.text;
                _reviewedDate = DateTime.now();
              });
              _showSnack('Requisition endorsed by Finance Dept!');
            },
            child: const Text('Endorse & Sign'),
          ),
        ],
      ),
    );
  }

  void _promptApproverAction() {
    final nameCtrl = TextEditingController(text: _approvedByNameController.text);
    final noteCtrl = TextEditingController(text: _approverNotes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Management Approval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Approver Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Management Decision Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _approvedByNameController.text = nameCtrl.text;
                _approverDecision = 'REJECTED';
                _approverNotes = noteCtrl.text;
                _approvedDate = DateTime.now();
              });
              _showSnack('Requisition rejected by Management.');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _approvedByNameController.text = nameCtrl.text;
                _approverDecision = 'APPROVED';
                _approverNotes = noteCtrl.text;
                _approvedDate = DateTime.now();
              });
              _showSnack('Requisition APPROVED by Management! Ready for archive.');
            },
            child: const Text('Authorize & Approve'),
          ),
        ],
      ),
    );
  }

  void _showDocumentSummaryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.church, color: Color(0xFF0F2537)),
            const SizedBox(width: 8),
            const Text('Official Requisition Record', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryLine('Requisition No', _reqNoController.text),
                _buildSummaryLine('Date', _dateFormat.format(_date)),
                _buildSummaryLine('Department', _selectedDepartment),
                _buildSummaryLine('Requested By', _requestedByController.text),
                _buildSummaryLine('Purpose', _purposeController.text),
                const Divider(height: 20),
                const Text('Items Particulars:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                ..._items.where((i) => i.description.isNotEmpty || i.amount > 0).map((i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${i.sn}. ${i.description.isEmpty ? "(Item)" : i.description}'),
                        Text('${_currencyFormat.format(i.amount)} RWF', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('GRAND TOTAL:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${_currencyFormat.format(_grandTotal)} RWF',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                _buildSummaryLine(
                  'Prepared By',
                  '${_preparedByNameController.text} (${_isPreparedSigned ? "Signed" : "Draft"})',
                ),
                _buildSummaryLine(
                  'Reviewed By',
                  '${_reviewedByNameController.text} ($_reviewerDecision)',
                ),
                _buildSummaryLine(
                  'Approved By',
                  '${_approvedByNameController.text} ($_approverDecision)',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentStatusText() {
    if (_approverDecision == 'APPROVED') return 'APPROVED';
    if (_approverDecision == 'REJECTED') return 'REJECTED BY MANAGEMENT';
    if (_reviewerDecision == 'REJECTED') return 'REJECTED BY FINANCE';
    if (_reviewerDecision == 'ENDORSED') return 'PENDING APPROVAL';
    if (_isPreparedSigned) return 'PENDING REVIEW';
    return 'DRAFT';
  }

  Color _getStatusBadgeColor() {
    if (_approverDecision == 'APPROVED') return const Color(0xFF059669);
    if (_approverDecision == 'REJECTED' || _reviewerDecision == 'REJECTED') return const Color(0xFFDC2626);
    if (_reviewerDecision == 'ENDORSED') return const Color(0xFF0284C7);
    if (_isPreparedSigned) return const Color(0xFFD97706);
    return Colors.grey;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
