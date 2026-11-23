//
//  KLSubscriptionJPPManager.swift
//  WQKuaiXXXProject
//
//  Created by MAC on 2026/11/23.
//


import Foundation
import StoreKit

public enum AppSDProductID: String, CaseIterable {
    case proSDWeek = "test_id1"   //
    case proSDMonth = "test_id2"   //
    case proSDYear = "test_id_jd"   //
}
public typealias PurchaseSDCompletion = (Bool, Error?, SKPaymentTransaction?) -> Void
public typealias RestoreSDCompletion = (Bool, Error?) -> Void
public typealias FetchSDCompletion = () -> ()
public typealias ReceiptSDCompletion = (Bool) -> ()


public final class KLSubscriptionJPPManager: NSObject {
    
    let SDcacheVIPKey = "SDcacheSFbvVIPKey"
    let kl_IsVIPKey = "kl_IsVIPKey"
    public var PageName = ""
    
    static let shared = KLSubscriptionJPPManager()
    
    public var fetchSDMax = 20
    public var productsSDRequest: SKProductsRequest?
    public var fetchSDNum = 0
    private var fetchSDCompletion: FetchSDCompletion?//获取商品列表
    private var refreshSDReceiptcompletion:ReceiptSDCompletion?// 刷新本地收据
    private var purchaseSDCompletion: PurchaseSDCompletion?//购买商品
    private var restoreSDCompletion: RestoreSDCompletion?//恢复已完成购买
    
    // 是否为会员
    public var isSDPremium: Bool = false
    // MARK: - 去重缓存（已处理订单ID）
    private var handledSDProductIds = Set<String>()
    // 所有商品信息
    public var SD_products: [SKProduct] = []
    
    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        loadHandledSDCache()
    }
    //MARK:  恢复已完成购买（通常用于用户在新设备上恢复订阅）
    /// - Parameter completion: 恢复完成回调（success, error）
    public func restoreSDPurchases(compcletion: @escaping RestoreSDCompletion) {
        guard restoreSDCompletion == nil else {
            compcletion(false, NSError(domain: "KLSubscriptionJPPManager",
                                       code: -2,
                                       userInfo: [NSLocalizedDescriptionKey: "Restoresdf already in progress"]))
            return
        }
        restoreSDCompletion = compcletion
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    // MARK: - 缓存读写（持久化去重记录）
    private func loadHandledSDCache() {
        if let array = UserDefaults.standard.array(forKey: SDcacheVIPKey) as? [String] {
            handledSDProductIds = Set(array)
        }
    }
    
    private func saveHandledTxCache() {
        UserDefaults.standard.set(Array(handledSDProductIds), forKey: SDcacheVIPKey)
    }
    /// 购买商品(商品没有预加载)
    public func SD_BuyPurchase(productId: String,
                        completion: @escaping PurchaseSDCompletion) {
        // 确保没有正在进行中的购买回调（避免覆盖）
        guard purchaseSDCompletion == nil else {
            completion(false, NSError(domain: "KLSubscriptionJPPManager",
                                      code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "Previous purchase not finished"]),
                       nil)
            return
        }
        purchaseSDCompletion = completion
        
        let payssdment = SKMutablePayment()
        payssdment.productIdentifier = productId
        payssdment.quantity = 1
        SKPaymentQueue.default().add(payssdment)
    }
    //检测是否是会员
    public func checkSDUserStatus(compceletion: ((Bool) -> Void)?=nil) {
        let isSDvip = UserDefaults.standard.integer(forKey: kl_IsVIPKey)
        if isSDvip == 1 {
            isSDPremium = true
        }else{
            isSDPremium = false
        }
        guard let receiptceBase64 = getSDReceipaasBase64() else {
            // 没有收据，尝试刷新
            refreshSDReceipt { Suecc in
                if Suecc, let newdSDReceipt = self.getSDReceipaasBase64() {
                    self.appleSDBuy(verifySDInfo: newdSDReceipt, pathSD: self.PageName) {[weak self] success, dic in
                        guard let `self` = self else { return }
                        if success {
                            if let insDic = dic, let daavc = insDic["data"] as? Dictionary<String,Any> {
                                if let vipvag = daavc["vipflag"] as? Int,vipvag == 1 {
                                    self.isSDPremium = true
                                    UserDefaults.standard.setValue(1, forKey: self.kl_IsVIPKey)
                                    compceletion?(true)
                                }else{
                                    self.isSDPremium = false
                                    UserDefaults.standard.setValue(0, forKey: self.kl_IsVIPKey)
                                    compceletion?(false)
                                }
                            }else{
                                self.isSDPremium = false
                                UserDefaults.standard.setValue(0, forKey: self.kl_IsVIPKey)
                                compceletion?(false)
                            }
                            
                        }else{
                            self.isSDPremium = false
                            UserDefaults.standard.setValue(0, forKey: self.kl_IsVIPKey)
                            compceletion?(false)
                        }
                    }
                }else{
                    self.isSDPremium = false
                    UserDefaults.standard.setValue(0, forKey: self.kl_IsVIPKey)
                    compceletion?(false)
                }
            }
            return
        }
        appleSDBuy(verifySDInfo: receiptceBase64, pathSD: self.PageName) {[weak self] success, dic in
            guard let `self` = self else { return }
            if success {
                if let inDic = dic, let SData = inDic["data"] as? Dictionary<String,Any> {
                    if let vilag = SData["vipflag"] as? Int,vilag == 1 {
                        self.isSDPremium = true
                        UserDefaults.standard.setValue(1, forKey: self.kl_IsVIPKey)
                        compceletion?(true)
                    }else{
                        self.isSDPremium = false
                        UserDefaults.standard.setValue(0, forKey: self.kl_IsVIPKey)
                        compceletion?(false)
                    }
                }else{
                    self.isSDPremium = false
                    UserDefaults.standard.setValue(0, forKey: self.kl_IsVIPKey)
                    compceletion?(false)
                }
                
            }else{
                self.isSDPremium = false
                UserDefaults.standard.setValue(0, forKey: self.kl_IsVIPKey)
                compceletion?(false)
            }
        }
    }
    //MARK:  购买商品
    public func SD_BuyPurchase(productSD: SKProduct,
                        comcepletion: @escaping PurchaseSDCompletion) {
        
        guard purchaseSDCompletion == nil else {
            comcepletion(false, NSError(domain: "KLSubscriptionJPPManager",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Previous purchase not finished"]),
                         nil)
            return
        }
        purchaseSDCompletion = comcepletion
        
        let payceSDment = SKPayment(product: productSD)
        SKPaymentQueue.default().add(payceSDment)
    }
    // MARK: 从 App Store 获取商品列表
    public func getAllSDProducts(productSDIdents: Set<String> = Set(AppSDProductID.allCases.map { $0.rawValue }),compcletion: @escaping FetchSDCompletion) {
        fetchSDCompletion = compcletion
        // 取消已有的请求
        productsSDRequest?.cancel()
        productsSDRequest = SKProductsRequest(productIdentifiers: productSDIdents)
        productsSDRequest?.delegate = self
        productsSDRequest?.start()
        fetchSDNum = 1
    }
    
    /// 将收据发送给后台服务器验证并处理业务逻辑
    private func sendReceiptToBackend(transcaction: SKPaymentTransaction,
                                      isvRestore: Bool = false) {
        guard let recedfdBase64 = getSDReceipaasBase64() else {
            // 没有收据，尝试刷新
            refreshSDReceipt { success in
                if success, let newSDeceipt = self.getSDReceipaasBase64() {
                    self.verifySDReceiptOnServer(receipt: newSDeceipt,
                                                 transacdtion: transcaction,
                                                 isRestore: isvRestore)
                } else {
                    self.finishSDTransaction(transcaction, success: false, errorString: "No receipt found")
                }
            }
            return
        }
        verifySDReceiptOnServer(receipt: recedfdBase64, transacdtion: transcaction, isRestore: isvRestore)
    }
   
    /// 从本地获取收据的 Base64 字符串（若无收据则尝试刷新）
    private func getSDReceipaasBase64() -> String? {
        guard let recatURL = Bundle.main.appStoreReceiptURL else { return nil }
        do {
            let rectaData = try Data(contentsOf: recatURL)
            return rectaData.base64EncodedString()
        } catch {
            print("读取收据失败aa: \(error.localizedDescription)")
            return nil
        }
    }
    /// 刷新本地收据（当收据不存在时调用）
    private func refreshSDReceipt(completion: @escaping (Bool) -> Void) {
        let redqest = SKReceiptRefreshRequest()
        redqest.delegate = self
        redqest.start()
        refreshSDReceiptcompletion = completion
    }
    private func finishSDTransaction(_ transaction: SKPaymentTransaction,
                                     success: Bool,
                                     errorString: String?) {
        //
        let errraaora = errorString.map { NSError(domain: "KLSubscriptionJPPManager", code: -3, userInfo: [NSLocalizedDescriptionKey: $0]) }
        if success {
            // 购买/恢复成功 -> 回调并 finish 交易
            if transaction.transactionState == .purchased {
                purchaseSDCompletion?(true, nil, transaction)
                purchaseSDCompletion = nil
            } else if transaction.transactionState == .restored {
                restoreSDCompletion?(true, nil)
                restoreSDCompletion = nil
            }
        } else {
            // 失败回调
            if transaction.transactionState == .purchased {
                purchaseSDCompletion?(false, errraaora, transaction)
                purchaseSDCompletion = nil
            } else if transaction.transactionState == .restored {
                restoreSDCompletion?(false, errraaora)
                restoreSDCompletion = nil
            }
        }
        // 无论成功失败，必须 finish 该交易，移除支付队列
        print("finishTransaction")
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    private func verifySDReceiptOnServer(receipt: String,
                                         transacdtion: SKPaymentTransaction,
                                         isRestore: Bool) {
        
        appleSDBuy(verifySDInfo: receipt, pathSD: self.PageName) {[weak self] success, dic in
            guard let `self` = self else { return }
            if success {
                if let inDic = dic, let dae = inDic["data"] as? Dictionary<String,Any>,let plisot = dae["plist"] as? Array<Dictionary<String,Any>> ,plisot.count > 0 {
                    if let vipfflag = dae["vipflag"] as? Int,vipfflag == 1 {
                        self.isSDPremium = true
                        UserDefaults.standard.setValue(1, forKey: self.kl_IsVIPKey)
                    }else{
                        self.isSDPremium = false
                        UserDefaults.standard.setValue(0, forKey: self.kl_IsVIPKey)
                    }
                    self.finishSDTransaction(transacdtion, success: true, errorString: nil)
                }
                else{
                    self.finishSDTransaction(transacdtion, success: false, errorString: "数据格式错误")
                }
            }else{
                self.finishSDTransaction(transacdtion, success: false, errorString: "")
            }
        }
    }
    
    // MARK: 工具方法：根据产品ID获取对应Product
    func getSDProduct(id: AppSDProductID) -> SKProduct? {
        SD_products.first { $0.productIdentifier == id.rawValue }
    }
    func appleSDBuy(
        verifySDInfo:String,//票据数据
        pathSD:String,//来源页面
        completion: @escaping (Bool, [String: Any]?)-> Void
    ) {
        var params: [String: Any] = [:]
        params["verifyInfo"] = verifySDInfo
        params["path"] = pathSD
        NetworkRequest.shared.postDic(url: "/apple/buy", paramDic: params,false) { success, dic in
            if success {
                if let bkcexDic = dic as? Dictionary<String, Any>{
                    completion(true, bkcexDic)
                }else{
                    completion(true, nil)
                }
            }else{
                if let bkcexDic = dic as? Dictionary<String, Any>{
                    completion(false,bkcexDic)
                }else{
                    completion(false, nil)
                }
            }
        }
    }
    
}


// SKRequestDelegate
extension KLSubscriptionJPPManager: SKRequestDelegate {
    public func requestDidFinish(_ request: SKRequest) {
        // 刷新收据完成，重新检测订阅
        refreshSDReceiptcompletion?(true)
        refreshSDReceiptcompletion = nil
    }
    
}
// MARK: - SKProductsRequestDelegate
extension KLSubscriptionJPPManager: SKProductsRequestDelegate {
    
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.SD_products = response.products
        self.SD_products = self.SD_products.sorted(by: { Double(truncating: $0.kl_priceValue) < Double(truncating: $1.kl_priceValue)
        })
        fetchSDCompletion?()
        fetchSDCompletion = nil
        self.productsSDRequest = nil
        // 打印无效的商品ID（调试用）
        if !response.invalidProductIdentifiers.isEmpty {
            print("Invfdsalid product IDs: \(response.invalidProductIdentifiers)")
        }
    }
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        refreshSDReceiptcompletion?(false)
        refreshSDReceiptcompletion = nil
        if fetchSDNum <= fetchSDMax {
            productsSDRequest?.start()
            fetchSDNum += 1
            return
        }
        self.productsSDRequest = nil
        self.SD_products.removeAll()
    }
    
}
// MARK: - SKPaymentTransactionObserver
extension KLSubscriptionJPPManager: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for trancetion in transactions {
            handleSingleTransaction(queue: queue, trancetion: trancetion)
        }
    }
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        restoreSDCompletion?(false, error)
        restoreSDCompletion = nil
    }
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        restoreSDCompletion?(true, nil)
        restoreSDCompletion = nil
    }
    
    
    func handleSingleTransaction(queue: SKPaymentQueue, trancetion: SKPaymentTransaction) {
        // 去重：已处理过直接finish跳过
        if let txzId = trancetion.transactionIdentifier {
            if handledSDProductIds.contains(txzId) {
                queue.finishTransaction(trancetion)
                return
            }
        }
        
        switch trancetion.transactionState {
            
            
        case .purchased:
            // 购买成功 -> 发送收据到服务器验证
            let txxoId = trancetion.transactionIdentifier ?? ""
            handledSDProductIds.insert(txxoId)
            saveHandledTxCache()
            sendReceiptToBackend(transcaction: trancetion, isvRestore: false)
            
        case .restored:
            // 恢复成功 -> 同样需要服务器验证
            let txxoId = trancetion.transactionIdentifier ?? ""
            handledSDProductIds.insert(txxoId)
            saveHandledTxCache()
            sendReceiptToBackend(transcaction: trancetion, isvRestore: true)
        case .purchasing:
            // 正在购买，无需操作
            break
        case .failed:
            // 购买失败
            let eroror = trancetion.error as? NSError
            // 若用户取消则不视为错误
            if let error = eroror, error.code != SKError.paymentCancelled.rawValue {
                purchaseSDCompletion?(false, error, trancetion)
            } else {
                purchaseSDCompletion?(false, nil, trancetion)
            }
            purchaseSDCompletion = nil
            queue.finishTransaction(trancetion)
            
        case .deferred:
            // 等待家长同意或外部审核，不做处理
            print("Transacktion defaearred: \(trancetion)")
            purchaseSDCompletion?(false, nil, trancetion)
        @unknown default:
            queue.finishTransaction(trancetion)
            purchaseSDCompletion?(false, nil, trancetion)
            break
        }
    }
}



extension SKProduct {
    // MARK: - 判断订阅类型：周、月、季、年
    enum kl_SubscriptionType {
        case year   // 年
        case unknown
        case day   // 天
        case month  // 月
        case quarter// 季（3个月）
        case week   // 周
    }
    // 示给用户：例如 ¥18.00／月
    var kl_localPrice: String {
        let sd_formatater = NumberFormatter()
        sd_formatater.numberStyle = .currency
        sd_formatater.locale = priceLocale
        return sd_formatater.string(from: price) ?? "\(price)"
    }
   
    
    // 核心：判断是周/月/季/年
    var kl_subscriptionType: kl_SubscriptionType {
        guard let perwifod = subscriptionPeriod else {
            return .unknown
        }
        
        let unfit = perwifod.unit
        let cosaunt = perwifod.numberOfUnits
        
        switch unfit {
        case .day where cosaunt == 7:
            return .week
        case .day :
            return .day
        case .month where cosaunt == 3:
            return .quarter // 季度 = 3个月
        case .year where cosaunt == 1:
            return .year
        case .week where cosaunt == 1:
            return .week
        case .month where cosaunt == 1:
            return .month
        default:
            return .unknown
        }
    }
    // 商品名称（你在后台填的标题）
    var kl_name: String { localizedTitle }
    
    // 商品描述
    var kl_desc: String { localizedDescription }
    // 商品ID
    var kl_productId: String { productIdentifier }
    
    // 快捷判断
    var kl_isDaySubscription: Bool { kl_subscriptionType == .day }
    var kl_isQuarterSubscription: Bool { kl_subscriptionType == .quarter }
    var kl_isYearSubscription: Bool { kl_subscriptionType == .year }
    var kl_isWeekSubscription: Bool { kl_subscriptionType == .week }
    var kl_isMonthSubscription: Bool { kl_subscriptionType == .month }
    
    // 原始价格（NSDecimalNumber，用于计算）
    var kl_priceValue: NSDecimalNumber { price }
    
    // 货币符号：¥、$、€
    var kl_currencySymbol: String { priceLocale.currencySymbol ?? "" }
    
    // 货币代码：CNY、USD、EUR
    var kl_currencyCode: String { priceLocale.currencyCode ?? "" }
    
    
    // 订阅类型：按月/按年/按周
    var kl_subscriptionPeriodText: String {
        guard let peariod = subscriptionPeriod else { return "永久" }
        
        let unait = peariod.unit
        let cousnt = peariod.numberOfUnits
        
        switch unait {
        case .month: return "\(cousnt)月"
        case .year: return "\(cousnt)年"
        case .day: return "\(cousnt)天"
        case .week: return "\(cousnt)周"
        @unknown default: return ""
        }
    }
    // 是否有免费试用
    var kl_hasFreeTrial: Bool {
        guard let intnro = introductoryPrice else { return false }
        return intnro.paymentMode == .freeTrial
    }
    
    // 展示用文字：周订阅 / 月订阅 / 季订阅 / 年订阅
    var kl_SubscriptionTypeName: String {
        switch kl_subscriptionType {
        case .day: return "天"
        case .week: return "周"
        case .month: return "月"
        case .quarter: return "季"
        case .year: return "年"
        case .unknown: return "未知"
        }
    }
    // 最终展示给用户的完整名称：例如 连续包月 ¥18.00
    var kl_fullDisplayText: String {
        return "\(kl_name) \(kl_localPrice)"
    }
    // 免费试用天数（无试用返回 0）
    var kl_freeTrialDays: Int {
        guard let intrdso = introductoryPrice,
              intrdso.paymentMode == .freeTrial else { return 0 }
        
        let peritsod = intrdso.subscriptionPeriod
        let coahunt = peritsod.numberOfUnits
        switch peritsod.unit {
        case .day:    return coahunt
        case .week:   return coahunt * 7
        case .month:  return coahunt * 30 // 近似
        case .year:   return coahunt * 365
        @unknown default: return 0
        }
    }
    
   
}
