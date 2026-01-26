/// ABC WaaS API Endpoints
class ApiEndpoints {
  ApiEndpoints._();

  static const String secureChannelCreate = '/secure/channel/create';

  /// Get user info
  static String users(String email) =>
      '/member/user-management/users/${Uri.encodeComponent(email)}';

  /// Change password
  static const String changePassword = '/member/user-management/users/changepassword';

  /// Initialize password
  static const String initPassword = '/member/user-management/users/initpassword';

  /// Send verification code
  static String sendCode(String email) =>
      '/member/mail-service/${Uri.encodeComponent(email)}/sendcode';

  /// Verify code
  static String verifyCode(String email) =>
      '/member/mail-service/${Uri.encodeComponent(email)}/verifycode';

  /// Email login
  static const String login = '/auth/auth-service/v2/login';

  /// SNS token login (SNS access token → ABC WaaS JWT)
  static const String snsTokenLogin = '/auth/auth-service/v2/token/login';

  /// Refresh token
  static const String refreshToken = '/auth/auth-service/v2/refresh';

  /// SNS registration (code 618 - user not found)
  static const String snsJoin = '/member/user-management/v2/join';

  /// Email registration (with code)
  static const String emailAddUser = '/member/user-management/users/v2/adduser';

  /// Create/Recover wallet
  static const String wallets = '/wapi/v2/mpc/wallets';

  /// Wallet info
  static const String walletsInfo = '/wapi/v2/mpc/wallets/info';

  /// Sign
  static const String sign = '/wapi/v2/sign';

  /// Sign hash
  static const String signHash = '/wapi/v2/sign/hash';

  /// Sign typed data
  static const String signTypedData = '/wapi/v2/sign/typed-data';

  /// Create token transfer data
  static const String tokenTransferData = '/wapi/v2/token/transfer-data';

  /// Get token allowance

  /// Get token list
  static const String tokens = '/wapi/v2/walletscan/tokens';

  /// Get native tokens
  static const String natives = '/wapi/v2/walletscan/natives';

  /// Get specific token
  static String token(String contractAddress) =>
      '/wapi/v2/walletscan/token/$contractAddress';

  /// Get NFT list
  static const String nfts = '/wapi/v2/walletscan/nfts';

  /// Get NFTs by contract
  static String contractNfts(String contractAddress) =>
      '/wapi/v2/walletscan/nfts/$contractAddress';

  /// Get transaction list
  static const String transactions = '/wapi/v2/walletscan/transactions';

  /// Get gas price
  static const String gasPrice = '/wapi/v2/gas/price';

  /// Get suggested gas fees
  static const String suggestGasFees = '/wapi/v2/gas/suggestedGasFees';

  /// Estimate legacy gas
  static const String estimateLegacy = '/wapi/v2/gas/estimate/legacy';

  /// Estimate EIP-1559 gas
  static const String estimateEip1559 = '/wapi/v2/gas/estimate/eip1559';

  /// Send transaction
  static const String sendTransaction = '/wapi/v2/transactions/raw-tx/send';

  /// Get transaction receipt
  static const String transactionReceipt = '/wapi/v2/transactions/receipt';

  /// Get nonce
  static const String nonce = '/wapi/v2/address/nonce';

  /// Solana RPC call
  static const String solRpcCall = '/wapi/v2/solana/rpc/call';

  /// Get Solana address
  static const String solAddress = '/wapi/v2/solana/wallet/getAddress';

  /// Generate SOL transfer transaction
  static const String solGenerateTransferSolTransaction =
      '/wapi/v2/solana/tx/generateTransferSOLTransaction';

  /// Generate FT transfer transaction
  static const String solGenerateTransferFtTransaction =
      '/wapi/v2/solana/tx/generateTransferFTTransaction';

  /// Send Solana transaction
  static const String solSendTransaction = '/wapi/v2/solana/tx/sendTransaction';

  /// V3 wallet
  static const String walletV3 = '/v3/wallet';

  /// Generate V3 wallet
  static const String walletGenerateV3 = '/v3/wallet/generate';

  /// Recover V3 wallet
  static const String walletRecoverV3 = '/v3/wallet/recover';

  /// V3 sign
  static const String signV3 = '/v3/wallet/sign';

  /// BTC address lookup
  static const String btcAddress = '/wapi/v2/btc/address';
}
