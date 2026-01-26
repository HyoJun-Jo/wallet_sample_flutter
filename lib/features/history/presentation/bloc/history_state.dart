import 'package:equatable/equatable.dart';

import '../../domain/entities/history_entry.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  final List<HistoryEntry> entries;
  final String walletAddress;

  const HistoryLoaded({
    required this.entries,
    required this.walletAddress,
  });

  @override
  List<Object?> get props => [entries, walletAddress];

  HistoryLoaded copyWith({
    List<HistoryEntry>? entries,
    String? walletAddress,
  }) {
    return HistoryLoaded(
      entries: entries ?? this.entries,
      walletAddress: walletAddress ?? this.walletAddress,
    );
  }
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
