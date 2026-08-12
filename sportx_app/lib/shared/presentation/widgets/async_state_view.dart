import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class AsyncDetailBuilder<T> extends StatelessWidget {
  final AsyncValue<T> async;
  final String title;
  final Widget Function(T data) dataBuilder;
  final VoidCallback? onRetry;

  const AsyncDetailBuilder({
    super.key,
    required this.async,
    required this.title,
    required this.dataBuilder,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => _Scaffold(
        title: title,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => _Scaffold(
        title: title,
        body: _ErrorView(
          message: e is ApiException ? e.message : 'Failed to load. Pull to retry.',
          onRetry: onRetry,
        ),
      ),
      data: dataBuilder,
    );
  }
}

class DirectoryStateView<T> extends StatelessWidget {
  final DirectoryState<T> state;
  final String title;
  final Widget Function(List<T> items) dataBuilder;
  final VoidCallback? onRetry;

  const DirectoryStateView({
    super.key,
    required this.state,
    required this.title,
    required this.dataBuilder,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.items.isEmpty) {
      return _Scaffold(
        title: title,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (state.error != null && state.items.isEmpty) {
      return _Scaffold(
        title: title,
        body: _ErrorView(message: state.error!, onRetry: onRetry),
      );
    }
    if (state.items.isEmpty) {
      return _Scaffold(
        title: title,
        body: const _EmptyView(),
      );
    }
    return dataBuilder(state.items);
  }
}

class _Scaffold extends StatelessWidget {
  final String title;
  final Widget body;
  const _Scaffold({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: body,
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.cloudOff, size: 40, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.searchX, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text('Nothing here yet',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
