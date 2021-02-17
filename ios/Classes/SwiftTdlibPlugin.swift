//
//  TdlibPlugin.swift
//  Runner
//
//  Created by Hoang Duc on 27/01/2021.
//

import Flutter
import UIKit

typealias Runnable = (() -> ())

public class SwiftTdlibPlugin:  FlutterMethodCall, FlutterStreamHandler, FlutterPlugin {
    
    //Td client
    var client : UnsafeMutableRawPointer!
    static var methodChannel : FlutterMethodChannel!
    static var eventChannel : FlutterEventChannel!
    static var clients : Array<Client> = Array()
    static var newClient: Client?
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    methodChannel = FlutterMethodChannel(name: "channel/to/tdlib",
                                             binaryMessenger: registrar.messenger())
    eventChannel = FlutterEventChannel(name: "channel/to/tdlib/receive",
                                             binaryMessenger: registrar.messenger())

    let instance = SwiftTdlibPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
  }
    
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let lock = NSLock()
    DispatchQueue.global(qos: .utility).async {
        lock.lock()
        switch(call.method){
        case "clientReceive":
            let args = call.arguments as! [String : Any]
            if let res = td_json_client_receive(self.client, args["timeout"] as! Double) {
                let event = String(cString: res)
                result(event)
                print("\n\n\nMESSAGEE:\n\(event)\n\n\n")
            }else{
                result(nil)
            }
            print("Received successfully");
        case "clientSend":
            let args = call.arguments as! [String : Any]
            td_json_client_send(self.client, args["query"] as! String)
            result(nil)
            print("Sent successfully");
        case "clientExecute":
            let args = call.arguments as! [String : Any]
            if let res = td_json_client_execute(self.client, args["query"] as! String) {
                let event = String(cString: res)
                result(event)
            }
            print("Executed successfully");
        case "clientCreate":
            self.client = td_json_client_create();
            result(self.client.toInt())
            SwiftTdlibPlugin.eventChannel.setStreamHandler(self)
            print("Created successfully");
        case "clientDestroy":
            for entry in SwiftTdlibPlugin.clients {
                if (entry.clientId == self.client){
                        entry.close();
                        td_json_client_destroy(self.client)
                    if let index = SwiftTdlibPlugin.clients.firstIndex(where: { (temp) -> Bool in
                            return temp.clientId == entry.clientId
                        }) ?? nil {
                        SwiftTdlibPlugin.clients.remove(at: index)
                        }
                        break;
                      }
                    }
            
            result(nil)
            print("Destroyed successfully");
        default:
            result(FlutterMethodNotImplemented)
            return
        }
        lock.unlock();
    }
  }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        guard arguments != nil else { return nil }
        let clientId = self.client
        for entry in SwiftTdlibPlugin.clients {
            if entry.clientId == clientId {
                events(FlutterError.init(code: "UNAVAILABLE", message: "This Client Already is being listened to ", details: nil))
                return FlutterError.init(code: "UNAVAILABLE", message: "This Client Already is being listened to ", details: nil)
            }
        }
        
        SwiftTdlibPlugin.newClient = Client(clientId: self.client, events: events)
        SwiftTdlibPlugin.clients.append(SwiftTdlibPlugin.newClient!)
        
        DispatchQueue.global(qos: .default).async {
            SwiftTdlibPlugin.newClient?.run?()
        }
        
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        SwiftTdlibPlugin.newClient?.close()
        if let index = SwiftTdlibPlugin.clients.firstIndex(where: { (temp) -> Bool in
            return temp.clientId == SwiftTdlibPlugin.newClient?.clientId
        }) ?? nil {
            SwiftTdlibPlugin.clients.remove(at: index)
        }
        return nil
    }
    
    
    
    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        teardownEventChannels()
    }
    
    func teardownEventChannels() {
        SwiftTdlibPlugin.methodChannel.setMethodCallHandler(nil)
        SwiftTdlibPlugin.methodChannel = nil
        SwiftTdlibPlugin.eventChannel.setStreamHandler(nil)
        SwiftTdlibPlugin.eventChannel = nil
        for entry in SwiftTdlibPlugin.clients {
          if (!entry.stopFlag){
            entry.close()
            td_json_client_destroy(entry.clientId)
          }
        }
        SwiftTdlibPlugin.clients.removeAll()
      }
}

class Client {
    var stopFlag : Bool = false
    var events : FlutterEventSink
    var clientId: UnsafeMutableRawPointer?
    var run: Runnable?
    
    
    init(clientId: UnsafeMutableRawPointer, events: @escaping FlutterEventSink) {
        self.clientId = clientId
        self.events = events
        self.run  = { () -> Void in
                while !self.stopFlag {
                    if let cString = td_json_client_receive(
                        clientId,
                        30.0
                    ) {
                        let res = String(
                            cString: cString
                        )
                        DispatchQueue.global(qos: .utility).async {
                            events(res)
                        }
                    }
                }
        }
    }
    
    func close() {
        self.stopFlag = true
    }
}

extension UnsafeMutableRawPointer{
    func toInt() -> UInt64 {
        return UInt64(bitPattern:Int64(Int(bitPattern: self)))
    }
}
