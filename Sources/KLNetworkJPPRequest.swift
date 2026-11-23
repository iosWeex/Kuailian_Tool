
import Alamofire
import Foundation
import SVProgressHUD
import SAMKeychain
import AdSupport
import UIKit
import CommonCrypto

public enum NetworkStatus{
    case notReachable
    case unknown
    case ethernetOrWiFi
    case wwan
}


public class NetworkRequest: NSObject {
    
    public var baseURL = "jpp.cs2clean.top"
    public var appBundleName = Bundle.main.bundleIdentifier ?? "com.common.test.w"
    public var TokenKey = "kuailianTokenKey"
    public var SecretKey = "1e8f5d9284720f38effc97dfb8ba76a2"
    public var AppKey = "jppTest"
    
    
    public var isNetwork = false
    public let session: Session
    public static let shared = NetworkRequest()
    public let ceManager = NetworkReachabilityManager.init()
    
    
    public func initFirstKey(url:String,Bundle:String,secret:String,appk:String){
        self.baseURL = url
        self.appBundleName = Bundle
        self.SecretKey = secret
        self.AppKey = appk
    }
    
    let firstGetIdfaStringKey = "firstGetIdfaStringKey"
    let appVCode = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    
    public func NetWorkReachability(reaasStatus: @escaping(NetworkStatus)->Void){
        ceManager!.startListening { (stasdvds) in
            //蜂窝
            if stasdvds == NetworkReachabilityManager.NetworkReachabilityStatus.reachable(.cellular){
                reaasStatus(.wwan)
            }
            //不可用
            if stasdvds == NetworkReachabilityManager.NetworkReachabilityStatus.notReachable{
                reaasStatus(.notReachable)
            }
            //未知
            if stasdvds == NetworkReachabilityManager.NetworkReachabilityStatus.unknown{
                reaasStatus(.unknown)
            }
            //wifi
            if stasdvds == NetworkReachabilityManager.NetworkReachabilityStatus.reachable(.ethernetOrWiFi){
                reaasStatus(.ethernetOrWiFi)
            }
        }
    }
    //MARK: - POST请求  字典参数 ["id":"1","value":""]
    public func postDic(url:String,paramDic:[String:Any]?=[:],_ showHUD:Bool?=false,success: @escaping (Bool,Any) -> Void) {
        SVProgressHUD.setDefaultMaskType(.custom)
        SVProgressHUD.setMinimumDismissTimeInterval(2)
        SVProgressHUD.setHapticsEnabled(false)
        
        if showHUD! {
            SVProgressHUD.show()
        }
        print("url===:" + baseURL + url)
        print("\n 入参:")
        print(paramDic ?? [:])
        
        let ceheaders = HTTPHeaders(getNetHead())
        let urlcePath:URL = URL(string: baseURL + url)!
        
        var ceRequest = URLRequest(url: urlcePath)
        ceRequest.httpMethod = HTTPMethod.post.rawValue
        ceRequest.headers = ceheaders
        if let newcdfam = paramDic{
            do {
                let json = try JSONSerialization.data(withJSONObject: newcdfam)
                ceRequest.httpBody = json
            } catch {
                success(false,"数据序列化失败error==: \(error.localizedDescription)")
                if showHUD! {
                    SVProgressHUD.dismiss()
                }
                return
            }
        }
        AF.request(ceRequest)
            .validate(statusCode: 200..<300)
            .responseJSON { ceResponse in
                if showHUD! {
                    SVProgressHUD.dismiss()
                }
                switch ceResponse.result {
                case let .success(result):
                    do {
                        if let datadic = result as? [String: Any] {
                            if datadic["errno"] as! Int == 0 {
                                success(true, datadic)
                            }else{
                                success(false, datadic)
                            }
                        } else {
                            success(false, ["msg":"接口返回空"])
                        }
                    }
                    print("请求url=，====")
                    print(ceResponse.request?.url?.absoluteString ?? "")
                    print("返回数据=，====")
                    print(result)
                case let .failure(error):
                    print("接口报错sd，url=====\(String(describing: ceResponse.response?.url!.absoluteString))")
                    print(error)
                    success(false, ["msg":error.errorDescription])
                }
            }
    }
    
    //MARK: - POST请求  数组参数
    public func postArray(url:String,paramArray:[Any]?,_ showHUD:Bool?=false,success: @escaping (Bool,Any) -> Void) {
        SVProgressHUD.setDefaultMaskType(.custom)
        SVProgressHUD.setMinimumDismissTimeInterval(2)
        SVProgressHUD.setHapticsEnabled(false)
        
        if showHUD! {
            SVProgressHUD.show()
        }
        
        print("url===:" + baseURL + url)
        print("\n 入参:")
        if paramArray != nil {
            print(paramArray! as [Any])
        }
        let ceHeaders = getNetHead()
        let urlcePath:URL = URL(string: baseURL + url)!
        
        var ceRequest = URLRequest(url: urlcePath)
        ceRequest.httpMethod = HTTPMethod.post.rawValue
        ceRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (keycex, valcefue) in ceHeaders {
            ceRequest.setValue(valcefue, forHTTPHeaderField: keycex)
        }
        do {
            let jsona = try JSONSerialization.data(withJSONObject: paramArray!)
            ceRequest.httpBody = jsona
        } catch {
            success(false,"数据序列化失败error==: \(error.localizedDescription)")
            if showHUD! {
                SVProgressHUD.show()
            }
            return
        }
        // 执行请求
        AF.request(ceRequest)
            .validate(statusCode: 200..<300)
            .responseJSON { ceResponse in
                
                if showHUD! {
                    SVProgressHUD.dismiss()
                }
                switch ceResponse.result {
                case let .success(ceResult):
                    do {
                        if let datyta = ceResult as? [String: Any] {
                            if datyta["errno"] as! Int == 0 {
                                success(true, datyta)
                            }else{
                                success(false, datyta)
                            }
                        } else {
                            success(false, ["msg":"接口返回空 xcxxc"])
                        }
                        print("请求url=，====")
                        print(ceResponse.request?.url?.absoluteString ?? "")
                        print("返回数据few，==")
                        print(ceResult)
                    }
                case let .failure(error):
                    success(false, ["msg":error.errorDescription])
                    print("接口报错vsv，url=====\(String(describing: ceResponse.response?.url!.absoluteString))")
                    print(error)
                }
            }
    }
    //MARK: - 上传
    public func upLoad(url:String,imageData:Data?,param:[String: String] = [:],_ showHUD:Bool=false,success: @escaping (Bool,Any) -> Void){
        SVProgressHUD.setDefaultMaskType(.custom)
        SVProgressHUD.setMinimumDismissTimeInterval(2)
        SVProgressHUD.setHapticsEnabled(false)
        
        
        if showHUD {
            SVProgressHUD.show()
        }
        print("url===:" + baseURL + url)
        print("\n 入参:")
        print(param)
        let ceHeaders = HTTPHeaders(getNetHead(isForm: true))
        let urlcePath:URL = URL(string: baseURL + url)!
        
        AF.upload(
            multipartFormData: { multipartFormData in
                if let daceta = imageData{
                    let typece = param["type"] ?? "image/png"
                    let filece = param["file"] ?? "imageName.png"
                    let namece = param["name"] ?? "imageName"
                    
                    multipartFormData.append(
                        daceta,
                        withName: namece,
                        fileName: filece,
                        mimeType: typece
                    )
                }
                
                // 2.2 添加额外的文本参数（如果有）
                for (keyce, valuece) in param {
                    if let datace = valuece.data(using: .utf8) {
                        multipartFormData.append(datace, withName: keyce)
                    }
                }
            },
            to: urlcePath,
            method: .post,
            headers: ceHeaders,  // 3. 设置自定义请求头
            requestModifier: { ceRequest in
                ceRequest.timeoutInterval = 60*10
            }
        )
        .validate()  // 可选：自动验证 HTTP 状态码 (200-299)
        .responseJSON { ceResponse in
            if showHUD {
                SVProgressHUD.dismiss()
            }
            switch ceResponse.result {
            case .success(let value):
                if let jsonCEdata = value as? [String: Any], let valueData = jsonCEdata["data"] as? [String: Any] {
                    //                        success(true,valueData)
                    if jsonCEdata["errno"] as! Int == 0 {
                        success(true, valueData)
                    }else{
                        success(false, jsonCEdata)
                    }
                } else {
                    success(false, ["msg":"数据错误"])
                }
            case .failure(let error):
                success(false, ["msg":error.errorDescription])
            }
        }
    }
    public func UPLOAD(url:String,PDFData:Data?,param:[String: String] = [:],_ showHUD:Bool?=false,success: @escaping (Bool,Any) -> Void){
        SVProgressHUD.setHapticsEnabled(false)
        SVProgressHUD.setDefaultMaskType(.custom)
        SVProgressHUD.setMinimumDismissTimeInterval(2)
        print("url===:" + baseURL + url)
        print("\n param:")
        print(param)
        if showHUD! {
            SVProgressHUD.show()
        }
        
        let headers = HTTPHeaders(getNetHead(isForm: true))
        let urkllPath:URL = URL(string: baseURL + url)!
        
        session.upload(
            multipartFormData: { multipartFormData in
                if let data = PDFData{
                    let name = param["name"] ?? "file"
                    let type = param["type"] ?? "pdf"
                    let file = param["file"] ?? "file.pdf"
                    multipartFormData.append(
                        data,
                        withName: name,           // 服务器接收的字段名
                        fileName: file,       // 文件名
                        mimeType: type       // MIME 类型
                    )
                }
                
                // 2.2 添加额外的文本参数（如果有）
                for (key, value) in param {
                    if let data = value.data(using: .utf8) {
                        multipartFormData.append(data, withName: key)
                    }
                }
            },
            to: urkllPath,
            method: .post,
            headers: headers,  // 3. 设置自定义请求头
            requestModifier: { request in
                request.timeoutInterval = 60*10
            }
        )
        .validate()  // 可选：自动验证 HTTP 状态码 (200-299)
        .response { response in
            SVProgressHUD.dismiss()
            switch response.result {
            case .success(let value):
                if let data = value {
                    success(true, data)
                } else {
                    success(false, ["msg":"数据错误"])
                }
            case .failure(let error):
                success(false, ["msg":error.errorDescription])
            }
        }
    }
    //MARK: - GET请求  字典参数 ["id":"1","value":""]
    public func GETDic(url:String,paramDic:[String:Any]?=[:],_ showHUD:Bool?=false,success: @escaping (Bool,Any) -> Void) {
        SVProgressHUD.setDefaultMaskType(.custom)
        SVProgressHUD.setMinimumDismissTimeInterval(2)
        SVProgressHUD.setHapticsEnabled(false)
        
        if showHUD! {
            SVProgressHUD.show()
        }
        print("url===:" + baseURL + url)
        print("\n 入参:")
        print(paramDic ?? [:])
        
        let ceheaders = HTTPHeaders(getNetHead())
        let urlceStr:String = baseURL + url
        AF.request(urlceStr, method: .get, parameters: paramDic, encoding: URLEncoding.default,headers: ceheaders)
            .validate()
            .responseJSON { res in
                if showHUD! {
                    SVProgressHUD.show()
                }
                switch res.result {
                case .success(let json):
                    print("JSON 返回：\(json)")
                    do {
                        if let datadic = json as? [String: Any] {
                            if datadic["errno"] as! Int == 0 {
                                success(true, datadic)
                            }else{
                                success(false, datadic)
                            }
                        } else {
                            success(false, ["msg":"接口返回空"])
                        }
                    }
                case .failure(let err):
                    print("接口报错sd，url=====\(String(describing: res.response?.url!.absoluteString))")
                    print(err)
                    success(false, ["msg":err.errorDescription])
                }
            }
    }
    
    //MARK: - 工具方法
    func getNetHead(isForm:Bool=false)-> [String: String]{
        
        let appceceV = appVCode
        let timeceInterval: TimeInterval = Date().timeIntervalSince1970
        let timeceStamp = Int(timeceInterval)
        let nowceInt = "\(timeceStamp)"
        
        let ceTypeid = getCEIphoneDvtype()
        let langCE = Locale.preferredLanguages.first ?? "zh"
        let ceDeviceid = makeDeviceIdFirst()
        let cesignkey = SecretKey + ceDeviceid + nowceInt
        let cesign = cesignkey.md5()
        let cemodel = UIDevice.current.model
        let ceosver = UIDevice.current.systemVersion
        let cepackage = appBundleName
        let ceencrypt = "0"
        let array = [
            appceceV,nowceInt,ceTypeid,langCE,cesign,cemodel,ceosver,cepackage,ceDeviceid,ceencrypt
        ]
        let cevalue = array.joined(separator: ";")
        
        var ceheaders: [String: String] = [:]
        if isForm {
            ceheaders = [
                "aejcuketbhj": AppKey + ";" + cevalue,
                "Content-Type": "multipart/form-data",
            ]
        }else{
            ceheaders = [
                "aejcuketbhj": AppKey + ";" + cevalue,
                "Content-Type": "application/json",
            ]
        }
        if let CEToken = UserDefaults.standard.string(forKey: TokenKey), !CEToken.isEmpty {
            ceheaders["authorization"] = CEToken
        }else{
            ceheaders["authorization"] = ""
        }
        return ceheaders
        
    }
    func makeDeviceIdFirst() -> String {
        let makeCEzero = "00000000-0000-0000-0000-000000000000"
        var myCEServer = ""
        if let IdentifierCEKey = Bundle.main.object(forInfoDictionaryKey: String(kCFBundleIdentifierKey)) as? String {
            myCEServer = IdentifierCEKey
        }else{
            myCEServer = makeCEzero
        }
        let creatceStr = "_user_deviceId_Cache_key"
        let makeCEAcct = myCEServer + creatceStr
        
        var keyCEChainID = SAMKeychain.password(forService: myCEServer, account: makeCEAcct) ?? ""
        if keyCEChainID.count > 0 {
            return keyCEChainID
        } else {
            if let ididid = UserDefaults.standard.string(forKey: firstGetIdfaStringKey),ididid.count > 0 {
                return ididid
            }
            
            let idfaCEStr = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            if idfaCEStr.count > 0 {
                keyCEChainID = idfaCEStr
            }
            if keyCEChainID == makeCEzero || idfaCEStr.count == 0 {
                let uuidCEStr = NSUUID.init().uuidString as NSString
                keyCEChainID = String(format: "UUID%@", uuidCEStr.substring(from: 4))
            }
            
            SAMKeychain.setAccessibilityType(kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
            
            let ceQuery = SAMKeychainQuery()
            ceQuery.synchronizationMode = .no
            ceQuery.password = keyCEChainID
            ceQuery.service = myCEServer
            ceQuery.account = makeCEAcct
            do {
                try ceQuery.save()
            } catch {}
            UserDefaults.standard.setValue(keyCEChainID, forKey: firstGetIdfaStringKey)
            return keyCEChainID
        }
    }
    func getCEIphoneDvtype()->String {
        var systemaCEInfo = utsname()
        uname(&systemaCEInfo)
        let machineaCEMirror = Mirror(reflecting: systemaCEInfo.machine)
        return machineaCEMirror.children.reduce("") { result, element in
            guard let charCEValue = element.value as? Int8, charCEValue != 0 else { return result }
            return result + String(UnicodeScalar(UInt8(charCEValue)))
        }
    }
    
    private override init() {
        let concefig = URLSessionConfiguration.default
        concefig.timeoutIntervalForRequest = 30
        concefig.timeoutIntervalForResource = 60 * 10
        session = Session(configuration: concefig)
    }
}

extension String{
    func md5() -> String {
        let mesdfgsageData = self.data(using: .utf8)!
        var ffsdvgest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        mesdfgsageData.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            _ = CC_MD5(bytes.baseAddress, CC_LONG(mesdfgsageData.count), &ffsdvgest)
        }
        return ffsdvgest.map { String(format: "%02x", $0) }.joined()
    }
    
}
