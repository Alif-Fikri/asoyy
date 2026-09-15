import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_color_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/delete_confirm_dialog.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/ios_section.dart';
import '../../../../core/widgets/nexus_app_bar.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/utils/note_status.dart';
import '../bloc/note_bloc.dart';
import '../bloc/note_event.dart';
import '../bloc/note_state.dart';
import '../widgets/note_card.dart';
import 'note_form_page.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  void _openForm(BuildContext context, {NoteEntity? existing}) {
    final bloc = context.read<NoteBloc>();
    final s = context.strings;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NoteFormPage(
        existing: existing,
        onSave: (note) {
          bloc.add(SaveNoteRequested(note));
          AppToast.show(context, s.notes_saved);
        },
      ),
    ));
  }

  Future<void> _delete(BuildContext context, NoteEntity note) async {
    final bloc = context.read<NoteBloc>();
    final s = context.strings;
    final confirmed = await showDeleteConfirm(context);
    if (!confirmed || !context.mounted) return;
    bloc.add(DeleteNoteRequested(note.id));
    AppToast.show(context, s.notes_deleted);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;

    return Scaffold(
      backgroundColor: c.background,
      appBar: NexusAppBar(
        title: s.notes_title,
        extraActions: [
          IconButton(
            icon: const Icon(CupertinoIcons.plus_circle),
            onPressed: () => _openForm(context),
            tooltip: s.notes_add,
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<NoteBloc, NoteState>(
          builder: (context, state) {
            if (state is NoteLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is NoteError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: AppColors.alarmColor),
                ),
              );
            }
            if (state is! NoteLoaded) return const SizedBox();

            if (state.notes.isEmpty) {
              return EmptyStateWidget(
                icon: CupertinoIcons.doc_text,
                title: s.notes_empty_title,
                subtitle: s.notes_empty_subtitle,
              );
            }

            final now = DateTime.now();
            final sorted = sortNotes(state.notes, now);
            final active = sorted.where((n) => !n.isCompleted).toList();
            final done = sorted.where((n) => n.isCompleted).toList();

            Widget buildCard(NoteEntity note) => GestureDetector(
                  onLongPress: () => _delete(context, note),
                  child: NoteCard(
                    note: note,
                    now: now,
                    onTap: () => _openForm(context, existing: note),
                    onToggleDone: () => context
                        .read<NoteBloc>()
                        .add(ToggleNoteDoneRequested(note.id)),
                    onToggleItem: (itemId) =>
                        context.read<NoteBloc>().add(
                              ToggleChecklistItemRequested(
                                noteId: note.id,
                                itemId: itemId,
                              ),
                            ),
                  ),
                );

            return ListView(
              padding: EdgeInsets.fromLTRB(
                0,
                8,
                0,
                MediaQuery.of(context).padding.bottom + 40,
              ),
              children: [
                if (active.isNotEmpty)
                  IosSection(
                    header: s.notes_group_active,
                    children: active.map(buildCard).toList(),
                  ),
                if (done.isNotEmpty)
                  IosSection(
                    header: s.notes_group_done,
                    children: done.map(buildCard).toList(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
