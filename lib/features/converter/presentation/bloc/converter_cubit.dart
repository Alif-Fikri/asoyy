import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/converter_rates_repository.dart';
import 'converter_state.dart';

class ConverterCubit extends Cubit<ConverterRatesState> {
  final ConverterRatesRepository _repo;

  ConverterCubit(this._repo) : super(ConverterRatesInitial()) {
    _init();
  }

  Future<void> _init() async {
    final cached = _repo.getCached();
    if (cached != null) {
      emit(ConverterRatesLoaded(cached));
      if (cached.isStaleAt(DateTime.now(), ConverterRatesRepository.ttl)) {
        _refresh();
      }
      return;
    }
    await _refresh();
  }

  Future<void> _refresh() async {
    final current = state;
    if (current is ConverterRatesLoaded) {
      emit(current.copyWith(refreshing: true, refreshFailed: false));
    }
    try {
      final fresh = await _repo.fetchAndCache();
      emit(ConverterRatesLoaded(fresh));
    } catch (_) {
      final latest = state;
      if (latest is ConverterRatesLoaded) {
        emit(latest.copyWith(refreshing: false, refreshFailed: true));
      } else {
        emit(ConverterRatesError('offline'));
      }
    }
  }

  Future<void> retry() => _refresh();
}
