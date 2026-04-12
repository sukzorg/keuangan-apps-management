import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class RecapReportPage extends StatefulWidget {
  final int recapId;
  final String title;

  const RecapReportPage({
    super.key,
    required this.recapId,
    required this.title,
  });

  @override
  State<RecapReportPage> createState() => _RecapReportPageState();
}

class _RecapReportPageState extends State<RecapReportPage> {
  late Future<Map<String, dynamic>> _report;

  @override
  void initState() {
    super.initState();
    // FIX: pakai named parameter
    _report = ApiService.getRecapReport(recapId: widget.recapId);
  }

  // ── Generate & Preview PDF ──────────────────────────────────────
  Future<void> _exportPdf(Map<String, dynamic> report) async {
    final pdf = pw.Document();

    final incomeEntries = (report['income_entries'] as List?) ?? [];
    final businessIncomes = (report['business_incomes'] as List?) ?? [];
    final budgets = (report['budget_allocations'] as List?) ?? [];
    final debts = (report['debts'] as List?) ?? [];

    final totalIncome = double.tryParse(report['total_income'].toString()) ?? 0;
    final totalExpense =
        double.tryParse(report['total_expense'].toString()) ?? 0;
    final totalDebt = double.tryParse(report['total_debt'].toString()) ?? 0;
    final totalBudget = double.tryParse(report['total_budget'].toString()) ?? 0;
    final balance = double.tryParse(report['ending_balance'].toString()) ?? 0;

    // Format tanggal manual (tanpa intl locale)
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/${now.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => [
          // ── HEADER ────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('1A237E'),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'LAPORAN KEUANGAN BULANAN',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                // FIX: PdfColors.white70 tidak ada → pakai PdfColors.white
                pw.Text(
                  'Periode: ${widget.title}',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 13,
                  ),
                ),
                pw.Text(
                  'Dicetak: $dateStr',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── RINGKASAN KEUANGAN ────────────────────────────────
          pw.Text(
            'RINGKASAN KEUANGAN',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),

          pw.Row(
            children: [
              _pdfSummaryBox(
                'Total Pemasukan',
                AppTheme.formatRupiahFull(totalIncome),
                PdfColors.green800,
              ),
              pw.SizedBox(width: 8),
              _pdfSummaryBox(
                'Total Pengeluaran',
                AppTheme.formatRupiahFull(totalExpense),
                PdfColors.red800,
              ),
              pw.SizedBox(width: 8),
              _pdfSummaryBox(
                'Saldo Akhir',
                AppTheme.formatRupiahFull(balance),
                balance >= 0 ? PdfColors.indigo800 : PdfColors.red800,
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          // ── PEMASUKAN ─────────────────────────────────────────
          if (incomeEntries.isNotEmpty || businessIncomes.isNotEmpty) ...[
            _pdfSectionHeader('PEMASUKAN', PdfColors.green800),
            pw.SizedBox(height: 8),

            if (incomeEntries.isNotEmpty) ...[
              pw.Text(
                'Pemasukan Umum',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              // FIX: cast eksplisit ke List<List<String>>
              _pdfTable(
                headers: ['Sumber', 'Tanggal', 'Jumlah'],
                rows: incomeEntries
                    .map<List<String>>(
                      (e) => [
                        e['income_source']?['name']?.toString() ?? '-',
                        e['received_date']?.toString() ?? '-',
                        AppTheme.formatRupiahFull(e['amount']),
                      ],
                    )
                    .toList(),
              ),
              pw.SizedBox(height: 8),
            ],

            if (businessIncomes.isNotEmpty) ...[
              pw.Text(
                'Income Bisnis',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              _pdfTable(
                headers: ['Bisnis', 'Deskripsi', 'Jumlah'],
                rows: businessIncomes
                    .map<List<String>>(
                      (e) => [
                        e['business']?['name']?.toString() ?? '-',
                        e['description']?.toString() ?? '-',
                        AppTheme.formatRupiahFull(e['amount']),
                      ],
                    )
                    .toList(),
              ),
              pw.SizedBox(height: 8),
            ],

            _pdfTotalRow(
              'Total Pemasukan',
              AppTheme.formatRupiahFull(totalIncome),
              PdfColors.green800,
            ),
            pw.SizedBox(height: 16),
          ],

          // ── HUTANG ────────────────────────────────────────────
          if (debts.isNotEmpty) ...[
            _pdfSectionHeader('HUTANG AKTIF', PdfColors.orange800),
            pw.SizedBox(height: 8),
            _pdfTable(
              headers: ['Pemberi Hutang', 'Cicilan/Bln', 'Sisa Bln', 'Total'],
              rows: debts
                  .map<List<String>>(
                    (d) => [
                      d['creditor_name']?.toString() ?? '-',
                      AppTheme.formatRupiahFull(d['monthly_installment']),
                      '${d['remaining_months']} bln',
                      AppTheme.formatRupiahFull(d['total_amount']),
                    ],
                  )
                  .toList(),
            ),
            pw.SizedBox(height: 4),
            _pdfTotalRow(
              'Total Hutang',
              AppTheme.formatRupiahFull(totalDebt),
              PdfColors.orange800,
            ),
            pw.SizedBox(height: 16),
          ],

          // ── BUDGET ────────────────────────────────────────────
          if (budgets.isNotEmpty) ...[
            _pdfSectionHeader('ALOKASI BUDGET', PdfColors.purple800),
            pw.SizedBox(height: 8),
            _pdfTable(
              headers: ['Kategori', 'Budget', 'Realisasi', 'Selisih'],
              rows: budgets.map<List<String>>((b) {
                final planned =
                    double.tryParse(b['planned_amount'].toString()) ?? 0;
                final actual =
                    double.tryParse(b['actual_amount']?.toString() ?? '0') ?? 0;
                final diff = planned - actual;
                return [
                  b['budget_category']?['name']?.toString() ?? '-',
                  AppTheme.formatRupiahFull(planned),
                  AppTheme.formatRupiahFull(actual),
                  AppTheme.formatRupiahFull(diff),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 4),
            _pdfTotalRow(
              'Total Budget',
              AppTheme.formatRupiahFull(totalBudget),
              PdfColors.purple800,
            ),
            pw.SizedBox(height: 16),
          ],

          // ── SALDO AKHIR ───────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('E8EAF6'),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColor.fromHex('1A237E')),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'SALDO AKHIR',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('1A237E'),
                  ),
                ),
                pw.Text(
                  AppTheme.formatRupiahFull(balance),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: balance >= 0 ? PdfColors.green800 : PdfColors.red800,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── FOOTER ────────────────────────────────────────────
          pw.Divider(),
          pw.Text(
            'Laporan ini dibuat secara otomatis oleh Aplikasi Keuangan.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_${widget.title.replaceAll(' ', '_')}.pdf',
    );
  }

  // ── PDF Helper Widgets ──────────────────────────────────────────
  pw.Widget _pdfSummaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfSectionHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _pdfTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        for (int i = 0; i < headers.length; i++) i: const pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    h,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ...rows.map(
          (row) => pw.TableRow(
            children: row
                .map(
                  (cell) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(
                      cell,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfTotalRow(String label, String value, PdfColor color) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── BUILD ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text("Laporan ${widget.title}"),
        actions: [
          FutureBuilder<Map<String, dynamic>>(
            future: _report,
            builder: (ctx, snap) {
              if (!snap.hasData) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: "Export PDF",
                onPressed: () => _exportPdf(snap.data!),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _report,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final report = snapshot.data!;
          final incomeEntries = (report['income_entries'] as List?) ?? [];
          final businessIncomes = (report['business_incomes'] as List?) ?? [];
          final budgets = (report['budget_allocations'] as List?) ?? [];
          final debts = (report['debts'] as List?) ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(report),
                const SizedBox(height: 20),

                // ── Pemasukan ────────────────────────────────────
                if (incomeEntries.isNotEmpty || businessIncomes.isNotEmpty) ...[
                  _sectionHeader(
                    "Pemasukan",
                    AppTheme.income,
                    Icons.arrow_downward,
                  ),
                  const SizedBox(height: 10),
                  if (incomeEntries.isNotEmpty) ...[
                    _subHeader("Pemasukan Umum"),
                    ...incomeEntries.map(
                      (e) => _transactionTile(
                        title: e['income_source']?['name']?.toString() ?? '-',
                        subtitle: e['received_date']?.toString() ?? '',
                        amount: e['amount'],
                        color: AppTheme.income,
                        icon: Icons.attach_money,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (businessIncomes.isNotEmpty) ...[
                    _subHeader("Income Bisnis"),
                    ...businessIncomes.map(
                      (e) => _transactionTile(
                        title: e['description']?.toString() ?? '-',
                        subtitle: e['business']?['name']?.toString() ?? '',
                        amount: e['amount'],
                        color: Colors.blue.shade700,
                        icon: Icons.business,
                      ),
                    ),
                  ],
                  _totalRow(
                    "Total Pemasukan",
                    report['total_income'],
                    AppTheme.income,
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Hutang ───────────────────────────────────────
                if (debts.isNotEmpty) ...[
                  _sectionHeader(
                    "Hutang Aktif",
                    AppTheme.debt,
                    Icons.credit_card,
                  ),
                  const SizedBox(height: 10),
                  ...debts.map((d) => _debtTile(d)),
                  _totalRow(
                    "Total Hutang",
                    report['total_debt'],
                    AppTheme.debt,
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Budget ───────────────────────────────────────
                if (budgets.isNotEmpty) ...[
                  _sectionHeader(
                    "Alokasi Budget",
                    AppTheme.budget,
                    Icons.pie_chart,
                  ),
                  const SizedBox(height: 10),
                  ...budgets.map((b) => _budgetTile(b)),
                  _totalRow(
                    "Total Budget",
                    report['total_budget'],
                    AppTheme.budget,
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Saldo Akhir ──────────────────────────────────
                _buildBalanceCard(report),
                const SizedBox(height: 24),

                // ── Tombol Export PDF ────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text(
                      "Export PDF",
                      style: TextStyle(fontSize: 16),
                    ),
                    onPressed: () => _exportPdf(report),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── UI Helper Widgets ───────────────────────────────────────────

  Widget _buildSummaryCards(Map<String, dynamic> report) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                label: "Pemasukan",
                value: report['total_income'],
                color: AppTheme.income,
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                label: "Pengeluaran",
                value: report['total_expense'],
                color: AppTheme.expense,
                icon: Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                label: "Hutang",
                value: report['total_debt'],
                color: AppTheme.debt,
                icon: Icons.credit_card,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                label: "Budget",
                value: report['total_budget'],
                color: AppTheme.budget,
                icon: Icons.pie_chart,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String label,
    required dynamic value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.caption),
                const SizedBox(height: 2),
                Text(
                  AppTheme.formatRupiah(value),
                  style: AppTheme.amount.copyWith(color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTheme.heading2.copyWith(color: color, fontSize: 15),
        ),
      ],
    );
  }

  Widget _subHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: AppTheme.heading3.copyWith(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _transactionTile({
    required String title,
    required String subtitle,
    required dynamic amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: AppTheme.caption),
              ],
            ),
          ),
          Text(
            AppTheme.formatRupiah(amount),
            style: AppTheme.amount.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _debtTile(Map<String, dynamic> debt) {
    final total = double.tryParse(debt['total_amount'].toString()) ?? 0;
    final monthly =
        double.tryParse(debt['monthly_installment'].toString()) ?? 0;
    final remaining = int.tryParse(debt['remaining_months'].toString()) ?? 0;
    final totalMonths = int.tryParse(debt['total_months'].toString()) ?? 1;
    final progress = totalMonths > 0
        ? (totalMonths - remaining) / totalMonths
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card, color: AppTheme.debt, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  debt['creditor_name']?.toString() ?? '-',
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                AppTheme.formatRupiah(total),
                style: AppTheme.amount.copyWith(color: AppTheme.debt),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.orange.shade100,
              valueColor: const AlwaysStoppedAnimation(AppTheme.debt),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${AppTheme.formatRupiah(monthly)}/bln — sisa $remaining bulan",
            style: AppTheme.caption,
          ),
        ],
      ),
    );
  }

  Widget _budgetTile(Map<String, dynamic> budget) {
    final planned = double.tryParse(budget['planned_amount'].toString()) ?? 0;
    final actual =
        double.tryParse(budget['actual_amount']?.toString() ?? '0') ?? 0;
    final diff = planned - actual;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.pie_chart, color: AppTheme.budget, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              budget['budget_category']?['name']?.toString() ?? '-',
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppTheme.formatRupiah(planned),
                style: AppTheme.amount.copyWith(
                  color: AppTheme.budget,
                  fontSize: 13,
                ),
              ),
              Text(
                diff >= 0
                    ? "Sisa ${AppTheme.formatRupiah(diff)}"
                    : "Lebih ${AppTheme.formatRupiah(diff.abs())}",
                style: AppTheme.caption.copyWith(
                  color: diff >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            AppTheme.formatRupiah(value),
            style: AppTheme.amount.copyWith(color: color, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(Map<String, dynamic> report) {
    final balance = double.tryParse(report['ending_balance'].toString()) ?? 0;
    final isPositive = balance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [AppTheme.primary, AppTheme.accent]
              : [AppTheme.expense, Colors.red.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? AppTheme.primary : AppTheme.expense)
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Saldo Akhir Bulan",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  AppTheme.formatRupiahFull(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isPositive ? Icons.trending_up : Icons.trending_down,
            color: Colors.white70,
            size: 28,
          ),
        ],
      ),
    );
  }
}
