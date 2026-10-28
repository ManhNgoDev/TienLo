import 'package:flutter/material.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../auth/data/auth_repository.dart';

Future<void> showBugReportDialog(
  BuildContext context, {
  String screenName = 'UNKNOWN_SCREEN',
  String? initialCategory,
  String? initialTitle,
  String? initialError,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _BugReportBottomSheet(
      screenName: screenName,
      initialCategory: initialCategory,
      initialTitle: initialTitle,
      initialError: initialError,
    ),
  );
}

class _BugReportBottomSheet extends StatefulWidget {
  final String screenName;
  final String? initialCategory;
  final String? initialTitle;
  final String? initialError;

  const _BugReportBottomSheet({
    required this.screenName,
    this.initialCategory,
    this.initialTitle,
    this.initialError,
  });

  @override
  State<_BugReportBottomSheet> createState() => _BugReportBottomSheetState();
}

class _BugReportBottomSheetState extends State<_BugReportBottomSheet> {
  final _feedbackService = FeedbackService();
  final _authRepository = AuthRepository();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _emailController = TextEditingController();

  late String _selectedCategory;
  bool _isSubmitting = false;
  bool _includeStackTrace = true;
  String? _statusMessage;
  bool _isSuccess = false;

  final List<Map<String, String>> _categories = [
    {'code': 'LOGIN', 'label': 'Đăng nhập'},
    {'code': 'CAMPAIGN', 'label': 'Nhiệm vụ'},
    {'code': 'STREAK', 'label': 'Chuỗi ngày'},
    {'code': 'UPDATE', 'label': 'Cập nhật'},
    {'code': 'OTHER', 'label': 'Khác'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? (widget.screenName.contains('Đăng nhập') ? 'LOGIN' : 'OTHER');

    if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
      _titleController.text = widget.initialTitle!;
    } else if (widget.initialError != null && widget.initialError!.isNotEmpty) {
      _titleController.text = 'Sự cố: ${widget.initialError!.split('\n').first.takeChars(50)}';
    }

    if (widget.initialError != null && widget.initialError!.isNotEmpty) {
      _descController.text = 'Gặp lỗi trong quá trình sử dụng:\n${widget.initialError}';
    }

    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    try {
      final user = await _authRepository.getSavedUser();
      if (user != null && user.email.isNotEmpty && mounted) {
        setState(() {
          if (_emailController.text.isEmpty) {
            _emailController.text = user.email;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _statusMessage = 'Vui lòng nhập tiêu đề sự cố ngắn gọn!';
        _isSuccess = false;
      });
      return;
    }

    if (desc.isEmpty) {
      setState(() {
        _statusMessage = 'Vui lòng mô tả chi tiết lỗi bạn gặp phải!';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });

    final res = await _feedbackService.sendBugReport(
      title: title,
      description: desc,
      category: _selectedCategory,
      screen: widget.screenName,
      userEmail: _emailController.text.trim(),
      stackTrace: _includeStackTrace ? widget.initialError : null,
    );

    if (!mounted) return;

    final isOk = res['success'] == true;
    setState(() {
      _isSubmitting = false;
      _isSuccess = isOk;
      _statusMessage = res['message']?.toString() ??
          (isOk ? 'Báo cáo sự cố đã được gửi tới Gmail Admin!' : 'Gửi báo cáo thất bại');
    });

    if (isOk) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 30,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh gạt modal
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(
                    Icons.bug_report_rounded,
                    color: Color(0xFFEF4444),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Báo Cáo Sự Cố & Lỗi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Chuyển thẳng tới Gmail Quản Trị Viên • ${widget.screenName}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  tooltip: 'Đóng',
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Danh mục lỗi (Chips)
            const Text(
              'DANH MỤC LỖI',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['code'];
                return ChoiceChip(
                  label: Text(cat['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = cat['code']!);
                    }
                  },
                  backgroundColor: const Color(0xFF1E293B),
                  selectedColor: const Color(0xFFEF4444),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFEF4444) : Colors.white12,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Email liên hệ
            const Text(
              'EMAIL CỦA BẠN (ĐỂ ADMIN PHẢN HỒI)',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Nhập email của bạn (ví dụ: ban@gmail.com)',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38, size: 18),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Tiêu đề lỗi
            const Text(
              'TIÊU ĐỀ SỰ CỐ *',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ví dụ: Bị lỗi đăng nhập Google, không load được bảng xếp hạng...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                prefixIcon: const Icon(Icons.title_rounded, color: Colors.white38, size: 18),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Mô tả chi tiết
            const Text(
              'MÔ TẢ CHI TIẾT SỰ CỐ *',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Hãy mô tả cụ thể các bước bạn đã làm trước khi xảy ra lỗi để Admin fix nhanh nhất...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                ),
              ),
            ),

            if (widget.initialError != null && widget.initialError!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: _includeStackTrace,
                    onChanged: (val) => setState(() => _includeStackTrace = val ?? true),
                    activeColor: const Color(0xFFEF4444),
                  ),
                  const Expanded(
                    child: Text(
                      'Đính kèm mã lỗi kỹ thuật hệ thống vừa xảy ra',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],

            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? const Color(0xFF065F46).withValues(alpha: 0.4)
                      : const Color(0xFF991B1B).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                      color: _isSuccess ? const Color(0xFF34D399) : const Color(0xFFFCA5A5),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _isSuccess ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Nút bấm Gửi
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Đang gửi báo cáo tới Gmail Admin...',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Gửi Báo Cáo Sự Cố Tới Admin',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _StringExt on String {
  String takeChars(int n) {
    if (length <= n) return this;
    return substring(0, n);
  }
}
