import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_spacing.dart';
import '../../providers/groups_provider.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/primary_button.dart';

/// Form for creating a new travel group heading to [destinationName].
/// Reached from [GroupsForPlaceScreen]'s "Create Group" FAB.
class CreateGroupScreen extends ConsumerStatefulWidget {
  final String placeId;
  final String destinationName;
  final String coverImage;

  const CreateGroupScreen({
    super.key,
    required this.placeId,
    required this.destinationName,
    required this.coverImage,
  });

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _meetingPointController = TextEditingController(text: 'Dhaka');
  final _budgetController = TextEditingController();
  final _maxMembersController = TextEditingController(text: '6');
  final _descriptionController = TextEditingController();

  DateTime _tripDate = DateTime.now().add(const Duration(days: 14));
  bool _requireApproval = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _meetingPointController.dispose();
    _budgetController.dispose();
    _maxMembersController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tripDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _tripDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final group = await ref.read(groupsActionsProvider).createGroup(
          placeId: widget.placeId,
          destinationName: widget.destinationName,
          coverImage: widget.coverImage,
          title: _titleController.text.trim(),
          tripDate: _tripDate,
          meetingPoint: _meetingPointController.text.trim(),
          budgetBdt: double.tryParse(_budgetController.text.trim()) ?? 0,
          maxMembers: int.tryParse(_maxMembersController.text.trim()) ?? 6,
          description: _descriptionController.text.trim(),
          requireApproval: _requireApproval,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (group == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to create a group.')),
      );
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Group "${group.title}" created!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Group \u00b7 ${widget.destinationName}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: [
            AppTextField(
              label: 'Trip title',
              controller: _titleController,
              hint: 'e.g. Sunrise trip over the sea of clouds',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Give your trip a title' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Trip date', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(DateFormat('EEEE, d MMMM yyyy').format(_tripDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Meeting point',
              controller: _meetingPointController,
              hint: 'e.g. Dhaka (Saydabad bus stand)',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Where will the group meet?' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Budget per person (৳)',
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    hint: 'e.g. 5000',
                    validator: (v) => (double.tryParse(v ?? '') == null) ? 'Enter a number' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    label: 'Max members',
                    controller: _maxMembersController,
                    keyboardType: TextInputType.number,
                    hint: 'e.g. 6',
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 2) return 'At least 2';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Description (optional)',
              controller: _descriptionController,
              hint: 'Itinerary highlights, what\'s included, split of costs...',
            ),
            const SizedBox(height: AppSpacing.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _requireApproval,
              onChanged: (v) => setState(() => _requireApproval = v),
              title: const Text('Approve join requests manually'),
              subtitle: const Text('Off: anyone can join instantly while seats remain.'),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(label: 'Create Group', onPressed: _submit, isLoading: _isSubmitting, icon: Icons.groups_rounded),
          ],
        ),
      ),
    );
  }
}
