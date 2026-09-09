import 'package:equatable/equatable.dart';
import '../../domain/entities/exchange_rates.dart';

abstract class ConverterRatesState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ConverterRatesInitial extends ConverterRatesState {}

class ConverterRatesLoaded extends ConverterRatesState {
  final ExchangeRates rates;
  final bool refreshing;
  final bool refreshFailed;

  ConverterRatesLoaded(
    this.rates, {
    this.refreshing = false,
    this.refreshFailed = false,
  });

  ConverterRatesLoaded copyWith({
    ExchangeRates? rates,
    bool? refreshing,
    bool? refreshFailed,
  }) =>
      ConverterRatesLoaded(
        rates ?? this.rates,
        refreshing: refreshing ?? this.refreshing,
        refreshFailed: refreshFailed ?? this.refreshFailed,
      );

  @override
  List<Object?> get props => [rates.fetchedAt, refreshing, refreshFailed];
}

class ConverterRatesError extends ConverterRatesState {
  final String message;
  ConverterRatesError(this.message);

  @override
  List<Object?> get props => [message];
}
