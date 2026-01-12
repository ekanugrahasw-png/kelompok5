import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../services/api_service.dart';
import 'add_draft_page.dart';

class DraftPage extends StatefulWidget {
  const DraftPage({Key? key}) : super(key: key);

  @override
  State<DraftPage> createState() => _DraftPageState();
}

class _DraftPageState extends State<DraftPage> with AutomaticKeepAliveClientMixin {
  late Future<List<Map<String, dynamic>>> _draftFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  void _loadDrafts() {
    setState(() {
      _draftFuture = DBHelper.getDrafts();
    });
  }

  String formatTanggal(dynamic t) {
    try {
      return DateFormat('dd MMM yyyy', 'id').format(DateTime.parse(t.toString()));
    } catch (_) {
      return '-';
    }
  }

  void showFotoCarousel(BuildContext context, List<String> fotos) {
    final PageController controller = PageController();
    int index = 0;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 500, maxWidth: 600),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Foto ${index + 1} dari ${fotos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: controller,
                      itemCount: fotos.length,
                      onPageChanged: (i) => setState(() => index = i),
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(fotos[i]), fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                  if (fotos.length > 1)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          fotos.length,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == index ? Colors.white : Colors.white38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> postToPesanan(Map<String, dynamic> draft) async {
    if (draft['kode_transaksi'] == null || 
        draft['tanggal'] == null || 
        draft['biaya'] == null ||
        draft['nama_teknisi'] == null ||
        draft['nama_pelanggan'] == null ||
        draft['nomor_telp'] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Data draft tidak lengkap')),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Padding(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 3),
                SizedBox(height: 20),
                Text(
                  'Posting dalam proses...',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final success = await ApiService.postPesanan(draft);
      
      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        await DBHelper.deleteDraft(draft['id']);
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Posting Laporan Berhasil!')),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        _loadDrafts();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Gagal Posting Laporan!')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Error: $e')),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> confirmDelete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 26),
            SizedBox(width: 12),
            Text('Hapus Draft', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Yakin ingin menghapus draft ini? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Batal', style: TextStyle(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await DBHelper.deleteDraft(id);
      _loadDrafts();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF546E7A),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Draft Pesanan', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            Text('Kelola draft servis Anda', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400)),
          ],
        ),
        toolbarHeight: 70,
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final res = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const AddDraftPage()),
            );
            if (res == true && mounted) {
              _loadDrafts();
            }
          },
          backgroundColor: const Color(0xFF546E7A),
          foregroundColor: Colors.white,
          elevation: 6,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text('Tambah Draft', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _draftFuture,
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 3),
                  SizedBox(height: 16),
                  Text('Memuat data...', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            );
          }
          
          final drafts = snap.data!;
          
          if (drafts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Belum ada draft',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tambahkan draft servis pertama Anda',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 20 : 12,
              isTablet ? 16 : 12,
              isTablet ? 20 : 12,
              140,
            ),
            itemCount: drafts.length,
            itemBuilder: (_, i) {
              final d = drafts[i];
              final fotos = [d['foto_1'], d['foto_2'], d['foto_3']]
                  .where((e) => e != null && e.toString().isNotEmpty)
                  .cast<String>()
                  .toList();
                  
              return Container(
                margin: EdgeInsets.only(bottom: isTablet ? 14 : 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.blue.shade100,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade50,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: InkWell(
                    onTap: fotos.isNotEmpty ? () => showFotoCarousel(context, fotos) : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header futuristik
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 14 : 12,
                            vertical: isTablet ? 10 : 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade600, Colors.blue.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(14),
                              topRight: Radius.circular(14),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  color: Colors.white,
                                  size: isTablet ? 18 : 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d['kode_transaksi'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isTablet ? 13 : 12,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade400,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.shade200,
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_note_rounded, size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'DRAFT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 9 : 8,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Content Body
                        Padding(
                          padding: EdgeInsets.all(isTablet ? 12 : 10),
                          child: Column(
                            children: [
                              // Foto thumbnail dengan gambar yang lebih kecil
                              if (fotos.isNotEmpty)
                                Row(
                                  children: [
                                    Container(
                                      height: isTablet ? 80 : 70,
                                      width: isTablet ? 80 : 70,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade100,
                                        border: Border.all(color: Colors.grey.shade300, width: 1),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(7),
                                        child: Image.file(
                                          File(fotos.first),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Icon(Icons.image_outlined, size: 28, color: Colors.grey.shade400),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isTablet ? 12 : 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildCompactInfo(
                                            Icons.calendar_today,
                                            formatTanggal(d['tanggal']),
                                            Colors.blue,
                                            isTablet,
                                          ),
                                          SizedBox(height: isTablet ? 6 : 5),
                                          _buildCompactInfo(
                                            Icons.engineering,
                                            d['nama_teknisi'],
                                            Colors.orange,
                                            isTablet,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              
                              if (fotos.isNotEmpty) SizedBox(height: isTablet ? 10 : 8),

                              // Info Grid - 2 Columns dengan padding lebih kecil
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      Icons.person_outline,
                                      'Pelanggan',
                                      d['nama_pelanggan'],
                                      Colors.purple,
                                      isTablet,
                                    ),
                                  ),
                                  SizedBox(width: isTablet ? 8 : 6),
                                  Expanded(
                                    child: _buildInfoCard(
                                      Icons.phone,
                                      'Telepon',
                                      d['nomor_telp'],
                                      Colors.teal,
                                      isTablet,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: isTablet ? 10 : 8),

                              // Total Biaya lebih compact
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 12 : 10,
                                  vertical: isTablet ? 10 : 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [const Color(0xFF546E7A), const Color(0xFF455A64)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.account_balance_wallet, size: isTablet ? 16 : 14, color: Colors.white),
                                        SizedBox(width: isTablet ? 8 : 6),
                                        Text(
                                          'Total Biaya',
                                          style: TextStyle(
                                            fontSize: isTablet ? 12 : 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Rp ${NumberFormat('#,###', 'id').format(d['biaya'])}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isTablet ? 14 : 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: isTablet ? 10 : 8),

                              // Action Buttons lebih compact
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => postToPesanan(d),
                                      icon: Icon(Icons.cloud_upload_outlined, size: isTablet ? 16 : 14),
                                      label: Text(
                                        'Posting',
                                        style: TextStyle(fontSize: isTablet ? 12 : 11, fontWeight: FontWeight.w600),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: isTablet ? 10 : 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: isTablet ? 8 : 6),
                                  ElevatedButton(
                                    onPressed: () => confirmDelete(d['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.all(isTablet ? 10 : 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 0,
                                      minimumSize: Size(isTablet ? 44 : 40, isTablet ? 44 : 40),
                                    ),
                                    child: Icon(Icons.delete_outline_rounded, size: isTablet ? 18 : 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Widget helper untuk info compact
  Widget _buildCompactInfo(IconData icon, String text, MaterialColor color, bool isTablet) {
    return Row(
      children: [
        Icon(icon, size: isTablet ? 14 : 12, color: color.shade600),
        SizedBox(width: isTablet ? 6 : 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isTablet ? 11 : 10,
              color: const Color(0xFF263238),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Widget helper untuk info card
  Widget _buildInfoCard(IconData icon, String label, String value, MaterialColor color, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 8 : 7),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: isTablet ? 14 : 12, color: color.shade700),
              SizedBox(width: isTablet ? 6 : 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 9 : 8,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 4 : 3),
          Text(
            value,
            style: TextStyle(
              fontSize: isTablet ? 11 : 10,
              color: const Color(0xFF263238),
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Widget untuk label:value format modern (jika masih diperlukan)
  Widget _buildLabelValue(String label, String value, IconData icon, MaterialColor color, bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: isTablet ? 14 : 12, color: color.shade700),
        ),
        SizedBox(width: isTablet ? 8 : 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label:',
                style: TextStyle(
                  fontSize: isTablet ? 9 : 8,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isTablet ? 11 : 10,
                  color: const Color(0xFF263238),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}