import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/web3_constants.dart';
import '../../../../core/enums/abc_network.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/wei_utils.dart';
import '../../../../di/injection_container.dart';
import '../../../signing/domain/entities/sign_request.dart';
import '../../../signing/domain/usecases/sign_eip1559_usecase.dart';
import '../../../signing/domain/usecases/sign_typed_data_usecase.dart';
import '../../../signing/domain/usecases/sign_usecase.dart';
import '../../../signing/domain/usecases/get_nonce_usecase.dart';
import '../../../signing/domain/usecases/estimate_gas_usecase.dart';
import '../../../signing/domain/usecases/get_suggested_gas_fees_usecase.dart';
import '../../../signing/domain/usecases/send_signed_transaction_usecase.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/usecases/add_bookmark_usecase.dart';
import '../../domain/usecases/get_bookmarks_usecase.dart';
import '../../domain/usecases/remove_bookmark_usecase.dart';
import '../../domain/usecases/is_bookmarked_usecase.dart';
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

  // UseCases
  final AddBookmarkUseCase _addBookmarkUseCase = sl<AddBookmarkUseCase>();
  final RemoveBookmarkUseCase _removeBookmarkUseCase = sl<RemoveBookmarkUseCase>();
  final IsBookmarkedUseCase _isBookmarkedUseCase = sl<IsBookmarkedUseCase>();
  final GetBookmarksUseCase _getBookmarksUseCase = sl<GetBookmarksUseCase>();
  final SignEip1559UseCase _signEip1559UseCase = sl<SignEip1559UseCase>();
  final SignTypedDataUseCase _signTypedDataUseCase = sl<SignTypedDataUseCase>();
  final SignUseCase _signUseCase = sl<SignUseCase>();
  final GetNonceUseCase _getNonceUseCase = sl<GetNonceUseCase>();
  final EstimateGasUseCase _estimateGasUseCase = sl<EstimateGasUseCase>();
  final GetSuggestedGasFeesUseCase _getSuggestedGasFeesUseCase = sl<GetSuggestedGasFeesUseCase>();
  final SendSignedTransactionUseCase _sendSignedTransactionUseCase = sl<SendSignedTransactionUseCase>();

  String _currentUrl = '';
  String? _pageTitle;
  bool _isLoading = false;
  int _loadingProgress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;

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

  String get _currentHost {
    try {
      final uri = Uri.parse(_currentUrl);
      return uri.host;
    } catch (_) {
      return _currentUrl;
    }
  }

  String get _dappName {
    return _pageTitle ?? _currentHost;
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

    final approved = await SignRequestSheet.show(
      context,
      dappName: _dappName,
      network: _currentNetwork,
      message: message,
    );

    if (approved != true) {
      throw Exception('User rejected sign request');
    }

    final result = await _signUseCase(
      SignParams(
        request: SignRequest(
          msgType: MessageType.message,
          accountId: widget.walletAddress,
          network: _currentNetwork.value,
          msg: message,
        ),
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

    final approved = await SignRequestSheet.show(
      context,
      dappName: _dappName,
      network: _currentNetwork,
      message: typedData,
    );

    if (approved != true) {
      throw Exception('User rejected sign request');
    }

    final result = await _signTypedDataUseCase(
      SignTypedDataParams(
        request: TypedDataSignRequest(
          accountId: widget.walletAddress,
          network: _currentNetwork.value,
          typeDataMsg: typedData,
        ),
      ),
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (signResult) => signResult.signature,
    );
  }

  Future<String> _ethSendTransaction(JsTransactionObject tx) async {
    if (!mounted) throw Exception('Widget not mounted');

    final approved = await TransactionRequestSheet.show(
      context,
      dappName: _dappName,
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
    final nonceResult = await _getNonceUseCase(
      GetNonceParams(address: from, network: network),
    );
    final nonce = nonceResult.fold(
      (failure) => '0',
      (n) => n,
    );

    // 2. Estimate gas or use provided gas limit
    String gasLimit = tx.gas ?? '21000';
    if (tx.gas == null || tx.gas!.isEmpty) {
      final gasResult = await _estimateGasUseCase(
        EstimateGasParams(
          network: network,
          from: from,
          to: to,
          value: value,
          data: data,
        ),
      );
      gasLimit = gasResult.fold(
        (failure) => data.length > 2 ? '100000' : '21000',
        (g) => g,
      );
    }

    // 3. Get suggested gas fees
    final gasFeeResult = await _getSuggestedGasFeesUseCase(
      GetSuggestedGasFeesParams(network: network),
    );
    final gasFees = gasFeeResult.fold(
      (failure) => const GasFeeInfo(
        gasPrice: '20000000000',
        maxFeePerGas: '20000000000',
        maxPriorityFeePerGas: '1000000000',
        estimatedGas: '21000',
      ),
      (g) => g,
    );

    // 4. Sign EIP-1559 transaction
    final maxPriorityFeeWei = WeiUtils.gweiToWeiHex(gasFees.maxPriorityFeePerGas ?? '1');
    final maxFeeWei = WeiUtils.gweiToWeiHex(gasFees.maxFeePerGas ?? gasFees.gasPrice);

    final signResult = await _signEip1559UseCase(
      SignEip1559Params(
        request: Eip1559SignRequest(
          accountId: from,
          network: network,
          from: from,
          to: to,
          value: value,
          data: data,
          nonce: nonce,
          gasLimit: gasLimit,
          maxPriorityFeePerGas: maxPriorityFeeWei,
          maxFeePerGas: maxFeeWei,
        ),
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
        final sendResult = await _sendSignedTransactionUseCase(
          SendSignedTransactionParams(
            network: network,
            signedTx: serializedTx,
          ),
        );

        return sendResult.fold(
          (failure) {
            log('Send failed: ${failure.message}', name: 'Web3Browser');
            throw Exception(failure.message);
          },
          (txHash) => txHash,
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
    final params = data.params;

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
    setState(() {
      _pageTitle = title;
    });
  }

  void _onLoadStart(InAppWebViewController controller, WebUri? url) {
    setState(() {
      _currentUrl = url?.toString() ?? '';
      _urlController.text = _currentUrl;
      _isLoading = true;
    });
  }

  void _onLoadStop(InAppWebViewController controller, WebUri? url) async {
    setState(() {
      _currentUrl = url?.toString() ?? '';
      _urlController.text = _currentUrl;
      _isLoading = false;
    });

    // Update navigation state
    final canGoBack = await controller.canGoBack();
    final canGoForward = await controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = canGoBack;
        _canGoForward = canGoForward;
      });
    }
  }

  void _onProgressChanged(InAppWebViewController controller, int progress) {
    setState(() {
      _loadingProgress = progress;
      _isLoading = progress < 100;
    });
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
    setState(() {
      _currentUrl = '';
      _pageTitle = null;
    });
    _webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri('about:blank')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            if (_isLoading)
              LinearProgressIndicator(
                value: _loadingProgress / 100,
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
      bottomNavigationBar: _buildBottomBar(),
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

  Widget _buildBottomBar() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _canGoBack ? _goBack : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _canGoForward ? _goForward : null,
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
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  _shareCurrentPage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border),
                title: const Text('Add Bookmark'),
                onTap: () {
                  Navigator.pop(context);
                  _addBookmark();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmarks),
                title: const Text('View Bookmarks'),
                onTap: () {
                  Navigator.pop(context);
                  _showBookmarks();
                },
              ),
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text('Open in External Browser'),
                onTap: () {
                  Navigator.pop(context);
                  _openInExternalBrowser();
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
  Future<void> _shareCurrentPage() async {
    if (_currentUrl.isEmpty) {
      _showSnackBar('No page to share');
      return;
    }

    try {
      final title = _pageTitle ?? _currentHost;
      await Share.share('$title\n$_currentUrl');
    } catch (e) {
      log('Share failed: $e', name: 'Web3Browser');
      _showSnackBar('Failed to share');
    }
  }

  /// Add current page to bookmarks
  Future<void> _addBookmark() async {
    if (_currentUrl.isEmpty) {
      _showSnackBar('No page to bookmark');
      return;
    }

    final title = _pageTitle ?? _currentHost;

    // Check if already bookmarked
    final isBookmarkedResult = await _isBookmarkedUseCase(
      IsBookmarkedParams(url: _currentUrl),
    );
    final alreadyBookmarked = isBookmarkedResult.fold(
      (_) => false,
      (isBookmarked) => isBookmarked,
    );

    if (alreadyBookmarked) {
      _showSnackBar('Already bookmarked');
      return;
    }

    final result = await _addBookmarkUseCase(
      AddBookmarkParams(title: title, url: _currentUrl),
    );

    result.fold(
      (failure) {
        log('Add bookmark failed: ${failure.message}', name: 'Web3Browser');
        _showSnackBar('Failed to add bookmark');
      },
      (_) => _showSnackBar('Bookmark added'),
    );
  }

  /// Show bookmarks list
  Future<void> _showBookmarks() async {
    final result = await _getBookmarksUseCase(NoParams());

    if (!mounted) return;

    result.fold(
      (failure) {
        log('Get bookmarks failed: ${failure.message}', name: 'Web3Browser');
        _showSnackBar('Failed to load bookmarks');
      },
      (bookmarks) {
        if (bookmarks.isEmpty) {
          _showSnackBar('No bookmarks yet');
          return;
        }
        _showBookmarksSheet(bookmarks);
      },
    );
  }

  /// Show bookmarks bottom sheet
  void _showBookmarksSheet(List<Bookmark> bookmarks) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final bookmark = bookmarks[index];

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
                          onPressed: () => _removeBookmark(bookmark.url),
                        ),
                        onTap: () {
                          Navigator.pop(context);
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
    );
  }

  /// Remove bookmark by URL
  Future<void> _removeBookmark(String url) async {
    final result = await _removeBookmarkUseCase(RemoveBookmarkParams(url: url));

    result.fold(
      (failure) {
        log('Remove bookmark failed: ${failure.message}', name: 'Web3Browser');
      },
      (_) {
        if (mounted) {
          Navigator.pop(context);
          _showBookmarks(); // Refresh list
        }
      },
    );
  }

  /// Open current URL in external browser
  Future<void> _openInExternalBrowser() async {
    if (_currentUrl.isEmpty) {
      _showSnackBar('No page to open');
      return;
    }

    try {
      final uri = Uri.parse(_currentUrl);
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
