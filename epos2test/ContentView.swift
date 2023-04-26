//
//  ContentView.swift
//  epos2test
//
//  Created by 城川一理 on 2023/02/07.
//

import SwiftUI

struct ContentView: View {
    var epos2PtrReceiveDelegate: Epos2PtrReceiveDelegate?
    @State var printer: Epos2Printer?
    
    var valuePrinterSeries: Epos2PrinterSeries = EPOS2_TM_M30
    var valuePrinterModel: Epos2ModelLang = EPOS2_MODEL_JAPANESE
    @State var target: String?

    private var Printername = "TM-m30_008053"
    @State var BDAddress:String = "BT:00:01:90:77:A6:65"
    
    private let printerDescovery = EposPrinterDescovery()
    
    var body: some View {
        VStack {
            TextField("ブルートゥースアドレス", text: $BDAddress)
            
            Button("印刷"){
                SimplePrint()
            }
            .font(Font.largeTitle)
            
            Button("Bluetoothデバイス検索開始"){
                printerDescovery.start()
            }
            .font(Font.largeTitle)
            
            Button("Bluetoothデバイス検索停止"){
                printerDescovery.stop()
            }
            .font(Font.largeTitle)
        }
        .padding()
    }
    
    func SimplePrint(){
        //
        if initializePrinterObject()==false{
            return
        }
        target = BDAddress

        //let queue = OperationQueue()
        //queue.addOperation({ [self] in
            if !runPrinterReceiptSequence() {
                //hideIndicator();
            }
        //})

        finalizePrinterObject()
        
    }
    
    @discardableResult
    func initializePrinterObject() -> Bool {
        printer = Epos2Printer(printerSeries: valuePrinterSeries.rawValue, lang: valuePrinterModel.rawValue)
        
        if printer == nil {
            return false
        }
        //printer!.setReceiveEventDelegate(self)
        printer!.setReceiveEventDelegate(epos2PtrReceiveDelegate)

        return true
    }
    func finalizePrinterObject() {
        if printer == nil {
            return
        }

        printer!.setReceiveEventDelegate(nil)
        printer = nil
    }

    func runPrinterReceiptSequence() -> Bool {
        if !createReceiptData() {
            return false
        }
        
        if !printData() {
            return false
        }
        
        return true
    }
    func createReceiptData() -> Bool {
        
        var result = EPOS2_SUCCESS.rawValue
        
        let textData: NSMutableString = NSMutableString()

        //result = printer!.addTextAlign(EPOS2_ALIGN_CENTER.rawValue)
        result = printer!.addTextAlign(EPOS2_ALIGN_LEFT.rawValue)
        if result != EPOS2_SUCCESS.rawValue {
            //MessageView.showErrorEpos(result, method:"addTextAlign")
            return false;
        }
        
        // Section 1 : Store information
        result = printer!.addFeedLine(1)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            //MessageView.showErrorEpos(result, method:"addFeedLine")
            return false
        }
        
        result = printer!.addTextLang(EPOS2_LANG_JA.rawValue)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            return false;
        }

        textData.append("123456789022345678903234567890423456789052345678\n")
        textData.append("株式会社ティエスアイ１２３４５６７８９０１２３４\n")
        textData.append("THE STORE 123 (555) 555 – 5555\n")
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            //MessageView.showErrorEpos(result, method:"addText")
            return false;
        }
        textData.setString("")
        
        // Section 2 : Purchaced items
        textData.append("400 OHEIDA 3PK SPRINGF  9.99 R\n")
        result = printer!.addText(textData as String)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            //MessageView.showErrorEpos(result, method:"addText")
            return false;
        }
        textData.setString("")

        result = printer!.addCut(EPOS2_CUT_FEED.rawValue)
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            //MessageView.showErrorEpos(result, method:"addCut")
            return false
        }
        
        return true
    }
    func printData() -> Bool {
        if printer == nil {
            return false
        }
        
        if !connectPrinter() {
            printer!.clearCommandBuffer()
            return false
        }
        
        let result = printer!.sendData(Int(EPOS2_PARAM_DEFAULT))
        if result != EPOS2_SUCCESS.rawValue {
            printer!.clearCommandBuffer()
            //MessageView.showErrorEpos(result, method:"sendData")
            printer!.disconnect()
            return false
        }
        
        return true
    }
    func connectPrinter() -> Bool {
        var result: Int32 = EPOS2_SUCCESS.rawValue
        
        if printer == nil {
            return false
        }
        
        //Note: This API must be used from background thread only
        result = printer!.connect(target, timeout:Int(EPOS2_PARAM_DEFAULT))
        if result != EPOS2_SUCCESS.rawValue {
            //MessageView.showErrorEpos(result, method:"connect")
            return false
        }
        
        return true
    }
}

extension ContentView {
    class EposPrinterDescovery: NSObject, Epos2DiscoveryDelegate {
        func start() {
            let filterOpt = Epos2FilterOption()
            filterOpt.portType = EPOS2_PORTTYPE_BLUETOOTH.rawValue
            filterOpt.deviceModel = EPOS2_MODEL_ALL.rawValue
            filterOpt.deviceType = EPOS2_TYPE_ALL.rawValue
            let result = Epos2Discovery.start(filterOpt, delegate: self)
            if result != EPOS2_SUCCESS.rawValue {
                print("Epos2Discovery start error. result=\(result)")
            }
        }
        
        func stop() {
            Epos2Discovery.stop()
        }
        
        internal func onDiscovery(_ deviceInfo: Epos2DeviceInfo!) {
            print("Device found: -------------------------")
            print("Target: \(String(describing: deviceInfo.target))")
            print("Device name: \(String(describing: deviceInfo.deviceName))")
            print("MAC address: \(String(describing: deviceInfo.macAddress))")
            print("IP address: \(String(describing: deviceInfo.ipAddress))")
            print("BD address: \(String(describing: deviceInfo.bdAddress))")
            print("BD LE address: \(String(describing: deviceInfo.leBdAddress))")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
