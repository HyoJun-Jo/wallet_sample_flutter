import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/web3_constants.dart';
import '../../../../core/enums/abc_network.dart';
import '../../../../core/utils/wei_utils.dart';
import '../../../../di/injection_container.dart';
import '../../../../shared/transaction/domain/entities/transaction_entities.dart';
import '../../../../shared/transaction/domain/repositories/transaction_repository.dart';
import '../../../../shared/signing/domain/entities/signing_entities.dart';
import '../../../../shared/signing/domain/usecases/sign_typed_data_usecase.dart';
import '../../../../shared/signing/domain/usecases/sign_usecase.dart' show PersonalSignUseCase;
import '../bloc/browser_bloc.dart';
import '../bloc/browser_event.dart';
import '../bloc/browser_state.dart';
import '../widgets/sign_request_sheet.dart';
import '../widgets/transaction_request_sheet.dart';

/// Web3 Browser Page
///
/// Integrated Web3 browser with Ethereum provider injection
/// Reference: talken-mfe-flutter Web3BrowserScreen
class Web3BrowserPage extends StatefulWidget {
  final String? initialUrl;
  final String walletAddress;

  const Web3BrowserPage({
    super.key,
    this.initialUrl,
    required this.walletAddress,
  });

  @override
  State<Web3BrowserPage> createState() => _Web3BrowserPageState();
}

class _Web3BrowserPageState extends State<Web3BrowserPage> {
  bool _isInitialized = false;
  AbcNetwork _currentNetwork = AbcNetwork.ethereum;
  InAppWebViewController? _webViewController;
  String _customUserAgent = '';

  final _urlController = TextEditingController();
  final _focusNode = FocusNode();

  // Signing UseCases (required for Web3 callbacks)
  final SignTypedDataUseCase _signTypedDataUseCase = sl<SignTypedDataUseCase>();
  final PersonalSignUseCase _personalSignUseCase = sl<PersonalSignUseCase>();

  // Transaction Repository (for nonce, gas, signTransaction, sendTransaction)
  final TransactionRepository _transactionRepository = sl<TransactionRepository>();

  @override
  void initState() {
    super.initState();
    _initWebView();
    _buildCustomUserAgent();
  }

  Future<void> _initWebView() async {
    try {
      await Web3Webview.initJs();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      log('Error initializing Web3Webview: $e', name: 'Web3Browser');
    }
  }

  /// Build custom user-agent string
  /// Format: " appName:%s appVersion:%s appTheme:%d appLang:%s appCurrency:%s osType:%s"
  Future<void> _buildCustomUserAgent() async {
    // Use fixed app name matching reference project
    const appName = 'Talken';
    String appVersion = '1.0.0';

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (e) {
      log('PackageInfo failed, using default version: $e', name: 'Web3Browser');
    }

    // Theme: 0 = dark, 1 = light (matching Android)
    const themeMode = 1; // Default to light

    // Language code
    const langCode = 'en'; // Default to English

    // Currency code
    const currencyCode = 'USD'; // Default to USD

    // OS type based on platform
    final osType = Platform.isIOS ? 'iOS' : 'AOS';

    _customUserAgent =
        ' appName:$appName appVersion:$appVersion appTheme:$themeMode appLang:$langCode appCurrency:$currencyCode osType:$osType';
  }

  /// Apply custom user-agent to the webview controller
  Future<void> _applyCustomUserAgent(InAppWebViewController controller) async {
    if (_customUserAgent.isEmpty) {
      await _buildCustomUserAgent();
    }

    if (_customUserAgent.isEmpty) return;

    try {
      final currentSettings = await controller.getSettings();
      if (currentSettings == null) return;

      final currentUserAgent = currentSettings.userAgent ?? '';
      currentSettings.userAgent = currentUserAgent + _customUserAgent;
      await controller.setSettings(settings: currentSettings);
    } catch (e) {
      log('Error applying user-agent: $e', name: 'Web3Browser');
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadUrl(String url) {
    String formattedUrl = url.trim();
    if (formattedUrl.isEmpty) return;

    if (!formattedUrl.startsWith('http://') &&
        !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    _urlController.text = formattedUrl;
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(formattedUrl)),
    );
  }

  String _getCurrentHost(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url;
    }
  }

  String _getDappName(BrowserState state) {
    return state.pageTitle ?? _getCurrentHost(state.currentUrl);
  }

  Future<List<String>> _ethAccounts() async {
    if (widget.walletAddress.isEmpty) {
      return [];
    }
    return [widget.walletAddress];
  }

  Future<int> _ethChainId() async {
    return _currentNetwork.chainId;
  }

  Future<String> _ethPersonalSign(String message) async {
    if (!mounted) throw Exception('Widget not mounted');

    final state = context.read<BrowserBloc>().state;
    final approved = await SignRequestSheet.show(
      context,
      dappName: _getDappName(state),
      network: _currentNetwork,
      message: message,
    );

    if (approved != true) {
      throw Exception('User rejected sign request');
    }

    final result = await _personalSignUseCase(
      PersonalSignParams(
        msgType: MessageType.message,
        accountId: widget.walletAddress,
        network: _currentNetwork.value,
        message: message,
      ),
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (signResult) => signResult.signature,
    );
  }

  Future<String> _ethSign(String message) async {
    return _ethPersonalSign(message);
  }

  Future<String> _ethSignTypedData(String typedData) async {
    if (!mounted) throw Exception('Widget not mounted');

    final state = context.read<BrowserBloc>().state;
    final approved = await SignRequestSheet.show(
      context,
      dappName: _getDappName(state),
      network: _currentNetwork,
      message: typedData,
    );

    if (approved != true) {
      throw Exception('User rejected sign request');
    }

    final result = await _signTypedDataUseCase(
      SignTypedDataParams(
        accountId: widget.walletAddress,
        network: _currentNetwork.value,
        messageJson: typedData,
      ),
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (signResult) => signResult.signature,
    );
  }

  Future<String> _ethSendTransaction(JsTransactionObject tx) async {
    if (!mounted) throw Exception('Widget not mounted');

    final state = context.read<BrowserBloc>().state;
    final approved = await TransactionRequestSheet.show(
      context,
      dappName: _getDappName(state),
      network: _currentNetwork,
      from: tx.from ?? widget.walletAddress,
      to: tx.to ?? '',
      value: tx.value ?? '0',
      data: tx.data,
      gasLimit: tx.gas,
    );

    if (approved != true) {
      throw Exception('User rejected transaction');
    }

    final from = tx.from ?? widget.walletAddress;
    final to = tx.to ?? '';
    final rawValue = tx.value ?? '0';
    final data = tx.data ?? '0x';
    final network = _currentNetwork.value;

    // Convert value to wei hex using WeiUtils
    final value = WeiUtils.parseToWeiHex(rawValue);

    // 1. Get nonce
    final nonceResult = await _transactionRepository.getNonce(
      address: from,
      network: network,
    );
    final nonce = nonceResult.fold(
      (failure) => '0x0',
      (n) => n,
    );

    // 2. Estimate gas or use provided gas limit
    String gasLimit = tx.gas ?? '0x5208'; // 21000 in hex
    if (tx.gas == null || tx.gas!.isEmpty) {
      final gasResult = await _transactionRepository.estimateGas(
        params: EstimateGasParams(
          network: network,
          from: from,
          to: to,
          value: value,
          data: data,
        ),
      );
      gasLimit = gasResult.fold(
        (failure) => data.length > 2 ? '0x186a0' : '0x5208', // 100000 or 21000 in hex
        (g) => g.gasLimit,
      );
    }

    // 3. Get suggested gas fees
    final gasFeeResult = await _transactionRepository.getGasFees(
      network: network,
    );
    final gasFees = gasFeeResult.fold(
      (failure) => GasFees(
        low: const GasFeeDetail(
          maxFeePerGas: '0x4a817c800', // 20 gwei
          maxPriorityFeePerGas: '0x3b9aca00', // 1 gwei
        ),
        medium: const GasFeeDetail(
          maxFeePerGas: '0x4a817c800',
          maxPriorityFeePerGas: '0x3b9aca00',
        ),
        high: const GasFeeDetail(
          maxFeePerGas: '0x4a817c800',
          maxPriorityFeePerGas: '0x3b9aca00',
        ),
        baseFee: '0',
        network: network,
      ),
      (g) => g,
    );

    // 4. Sign EIP-1559 transaction
    // Use medium gas fees (already in hex wei format from repository)
    final maxPriorityFeeWei = gasFees.medium.maxPriorityFeePerGas;
    final maxFeeWei = gasFees.medium.maxFeePerGas;

    final signResult = await _transactionRepository.signTransaction(
      params: SignTransactionParams(
        network: network,
        from: from,
        to: to,
        value: value,
        data: data,
        nonce: nonce,
        gasLimit: gasLimit,
        maxPriorityFeePerGas: maxPriorityFeeWei,
        maxFeePerGas: maxFeeWei,
        type: SignType.eip1559,
      ),
    );

    return signResult.fold(
      (failure) {
        log('Sign failed: ${failure.message}', name: 'Web3Browser');
        throw Exception(failure.message);
      },
      (result) async {
        final serializedTx = result.serializedTx;
        if (serializedTx == null || serializedTx.isEmpty) {
          return result.txHash ?? result.signature;
        }

        // 5. Send signed transaction
        final sendResult = await _transactionRepository.sendTransaction(
          params: SendTransactionParams(
            network: network,
            signedTx: serializedTx,
          ),
        );

        return sendResult.fold(
          (failure) {
            log('Send failed: ${failure.message}', name: 'Web3Browser');
            throw Exception(failure.message);
          },
          (txResult) => txResult.txHash,
        );
      },
    );
  }

  Future<bool> _walletSwitchEthereumChain(JsAddEthereumChain chain) async {
    final chainIdHex = chain.chainId;
    if (chainIdHex == null) return false;

    final chainId = int.tryParse(
      chainIdHex.startsWith('0x') ? chainIdHex.substring(2) : chainIdHex,
      radix: 16,
    );

    if (chainId == null) return false;
    if (chainId == _currentNetwork.chainId) return true;

    final targetNetwork = AbcNetwork.chainOf(chainId);
    if (targetNetwork == null) {
      throw Exception('Unsupported chain ID: $chainId');
    }

    setState(() {
      _currentNetwork = targetNetwork;
    });

    return true;
  }

  /// Handle unsupported RPC methods
  Future<dynamic> _onDefaultCallback(JsCallBackData data) async {
    final method = data.method;
    // params available via data.params if needed for specific methods

    // Handle common unsupported methods gracefully
    switch (method) {
      case 'eth_blockNumber':
        // Return a mock block number (DApps usually just want to check connectivity)
        return '0x1234567';

      case 'eth_getBlockByNumber':
        // Return minimal block data
        return {
          'number': '0x1234567',
          'timestamp': '0x${(DateTime.now().millisecondsSinceEpoch ~/ 1000).toRadixString(16)}',
        };

      case 'eth_gasPrice':
        // Return a reasonable gas price (30 gwei)
        return '0x6fc23ac00';

      case 'eth_estimateGas':
        // Return default gas estimate
        return '0x5208'; // 21000

      case 'eth_getBalance':
        // Return 0 balance (or could implement actual balance check)
        return '0x0';

      case 'eth_call':
        // This is tricky - would need actual RPC call
        // For now, throw an error
        throw Exception('eth_call not supported in this wallet');

      case 'eth_getTransactionCount':
        // Return 0 nonce
        return '0x0';

      case 'eth_getCode':
        // Return empty code (EOA)
        return '0x';

      case 'net_version':
        // Return current network ID
        return _currentNetwork.chainId.toString();

      case 'web3_clientVersion':
        return 'TalkenWallet/1.0.0';

      default:
        log('RPC method not implemented: $method', name: 'Web3Browser');
        throw Exception('Method not supported: $method');
    }
  }

  void _onTitleChanged(InAppWebViewController controller, String? title) {
    // Title is updated via onLoadStop with full page info
  }

  void _onLoadStart(InAppWebViewController controller, WebUri? url) {
    final urlString = url?.toString() ?? '';
    _urlController.text = urlString;

    if (mounted) {
      context.read<BrowserBloc>().add(BrowserUrlLoaded(url: urlString));
      context.read<BrowserBloc>().add(const BrowserLoadingStarted());
    }
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? url) async {
    final urlString = url?.toString() ?? '';
    _urlController.text = urlString;

    final title = await controller.getTitle();
    final canGoBack = await controller.canGoBack();
    final canGoForward = await controller.canGoForward();

    if (mounted) {
      context.read<BrowserBloc>().add(BrowserPageLoaded(
        url: urlString,
        title: title,
        canGoBack: canGoBack,
        canGoForward: canGoForward,
      ));
    }
  }

  void _onProgressChanged(InAppWebViewController controller, int progress) {
    if (mounted) {
      context.read<BrowserBloc>().add(BrowserProgressChanged(progress: progress));
    }
  }

  Future<NavigationActionPolicy?> _shouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final url = action.request.url;
    if (url == null) return NavigationActionPolicy.CANCEL;

    final urlString = url.toString();

    // Allow normal http/https navigation
    if (urlString.startsWith('http://') || urlString.startsWith('https://')) {
      return NavigationActionPolicy.ALLOW;
    }

    // Block other schemes
    return NavigationActionPolicy.CANCEL;
  }

  void _goBack() {
    _webViewController?.goBack();
  }

  void _goForward() {
    _webViewController?.goForward();
  }

  void _refresh() {
    _webViewController?.reload();
  }

  void _goHome() {
    _urlController.clear();
    if (mounted) {
      context.read<BrowserBloc>().add(const BrowserUrlLoaded(url: ''));
    }
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri('about:blank')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BrowserBloc>()..add(const BookmarksLoadRequested()),
      child: BlocBuilder<BrowserBloc, BrowserState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Web3 Browser'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: _buildUrlBar(),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Loading progress
                  if (state.isLoading)
                    LinearProgressIndicator(
                      value: state.loadingProgress / 100,
                      minHeight: 2,
                    ),

                  // WebView
                  Expanded(
                    child: _isInitialized ? _buildWebView() : _buildLoadingState(),
                  ),

                  // Connected wallet info
                  _buildWalletInfo(),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomBar(context, state),
          );
        },
      ),
    );
  }

  Widget _buildUrlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _urlController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'Enter URL or search',
          prefixIcon: const Icon(Icons.language, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward, size: 20),
            onPressed: () {
              _focusNode.unfocus();
              _loadUrl(_urlController.text);
            },
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
        onSubmitted: (value) {
          _loadUrl(value);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing Web3...'),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return Web3Webview(
      initialUrlRequest: URLRequest(
        url: WebUri(widget.initialUrl ?? Web3Constants.defaultHomeUrl),
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptCanOpenWindowsAutomatically: false,
        supportMultipleWindows: false,
        allowsInlineMediaPlayback: true,
        javaScriptEnabled: true,
        domStorageEnabled: true,
        useShouldOverrideUrlLoading: true,
      ),
      settings: Web3Settings(
        name: Web3Constants.walletName,
        eth: Web3EthSettings(
          chainId: _currentNetwork.chainId,
          rdns: Web3Constants.rdns,
          icon: Web3Constants.eip6963Icon,
        ),
      ),
      onWebViewCreated: (controller) async {
        _webViewController = controller;
        await _applyCustomUserAgent(controller);
      },
      shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
      onTitleChanged: _onTitleChanged,
      onLoadStart: _onLoadStart,
      onLoadStop: _onLoadStop,
      onProgressChanged: _onProgressChanged,
      ethAccounts: _ethAccounts,
      ethChainId: _ethChainId,
      ethSendTransaction: _ethSendTransaction,
      ethSign: _ethSign,
      ethPersonalSign: _ethPersonalSign,
      ethSignTypedData: _ethSignTypedData,
      walletSwitchEthereumChain: _walletSwitchEthereumChain,
      onDefaultCallback: _onDefaultCallback,
    );
  }

  Widget _buildWalletInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.green.shade50,
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Connected: ${_shortenAddress(widget.walletAddress)}',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _currentNetwork.displayName,
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, BrowserState state) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: state.canGoBack ? _goBack : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: state.canGoForward ? _goForward : null,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: _goHome,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showOptionsMenu(context),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu(BuildContext blocContext) {
    final state = blocContext.read<BrowserBloc>().state;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareCurrentPage(state);
                },
              ),
              ListTile(
                leading: Icon(
                  state.isCurrentPageBookmarked
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
                title: Text(
                  state.isCurrentPageBookmarked
                      ? 'Remove Bookmark'
                      : 'Add Bookmark',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (state.isCurrentPageBookmarked) {
                    _removeBookmark(blocContext, state.currentUrl);
                  } else {
                    _addBookmark(blocContext, state);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmarks),
                title: const Text('View Bookmarks'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showBookmarks(blocContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text('Open in External Browser'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openInExternalBrowser(state);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _shortenAddress(String address) {
    if (address.length <= 16) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
  }

  /// Share current page URL
  Future<void> _shareCurrentPage(BrowserState state) async {
    if (state.currentUrl.isEmpty) {
      _showSnackBar('No page to share');
      return;
    }

    try {
      final title = state.pageTitle ?? _getCurrentHost(state.currentUrl);
      await Share.share('$title\n${state.currentUrl}');
    } catch (e) {
      log('Share failed: $e', name: 'Web3Browser');
      _showSnackBar('Failed to share');
    }
  }

  /// Add current page to bookmarks
  void _addBookmark(BuildContext blocContext, BrowserState state) {
    if (state.currentUrl.isEmpty) {
      _showSnackBar('No page to bookmark');
      return;
    }

    if (state.isCurrentPageBookmarked) {
      _showSnackBar('Already bookmarked');
      return;
    }

    final title = state.pageTitle ?? _getCurrentHost(state.currentUrl);
    blocContext.read<BrowserBloc>().add(BookmarkAddRequested(
      title: title,
      url: state.currentUrl,
    ));
    _showSnackBar('Bookmark added');
  }

  /// Show bookmarks list
  void _showBookmarks(BuildContext blocContext) {
    final state = blocContext.read<BrowserBloc>().state;
    final bookmarks = state.bookmarks;

    if (bookmarks.isEmpty) {
      _showSnackBar('No bookmarks yet');
      return;
    }

    _showBookmarksSheet(blocContext, bookmarks);
  }

  /// Show bookmarks bottom sheet
  void _showBookmarksSheet(BuildContext blocContext, List<dynamic> bookmarks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: blocContext.read<BrowserBloc>(),
          child: BlocBuilder<BrowserBloc, BrowserState>(
            builder: (innerContext, state) {
              return DraggableScrollableSheet(
                initialChildSize: 0.5,
                minChildSize: 0.3,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Text(
                              'Bookmarks',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: state.bookmarks.length,
                          itemBuilder: (context, index) {
                            final bookmark = state.bookmarks[index];

                            return ListTile(
                              leading: const Icon(Icons.bookmark),
                              title: Text(
                                bookmark.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                bookmark.url,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () {
                                  _removeBookmark(innerContext, bookmark.url);
                                },
                              ),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                _loadUrl(bookmark.url);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Remove bookmark by URL
  void _removeBookmark(BuildContext blocContext, String url) {
    blocContext.read<BrowserBloc>().add(BookmarkRemoveRequested(url: url));
  }

  /// Open current URL in external browser
  Future<void> _openInExternalBrowser(BrowserState state) async {
    if (state.currentUrl.isEmpty) {
      _showSnackBar('No page to open');
      return;
    }

    try {
      final uri = Uri.parse(state.currentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Cannot open URL');
      }
    } catch (e) {
      log('Open external browser failed: $e', name: 'Web3Browser');
      _showSnackBar('Failed to open external browser');
    }
  }

  /// Show snackbar message
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
