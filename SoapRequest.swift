//
//  SoapRequest.swift
//  gxh
//
//  Created by Błażej Kita on 04/04/2023.
//

import Foundation


//--------------------

struct XMLComplexType
{
    var name:String = ""
    var namespace:String = ""
    var complexType = ""
    var childern:Array<XMLComplexType> = []
    var type:String  = ""
}


//--------------------

struct XMLPart
{
    var name:String = ""
    var type:String = ""
}

struct XMLMessage
{
    var name:String = ""
    var parts:Array<XMLPart> = []
}
 

//--------------------

struct XMLPortType
{
    var name:String = ""
    var inputMessage:XMLMessage?
    var outputMessage:XMLMessage?
}


struct XMLElementStackInfo
{
    var element_name:String = ""
    var param: String = ""
  
}

struct XMLBinding
{
    var actionName: String = ""
    var soapAction:String = ""
    
}

 


enum SoapError: Error
{
    case NoFoundAction(String)
    case NoFoundBind(String)
    case NoFoundParam(String)
    case BadInputData(String)
    case BadDataType(String)
    
    case ConnectionProblem(String)
}


class ParseDelagate: NSObject, XMLParserDelegate
{
     
     
     public var  complexType:Array<XMLComplexType> = []
     private var complexTypeCurrent          = -1
    
     public var messages:Array<XMLMessage> = []
     private var messageCurrent = -1
    
     public var portTypes:Array<XMLPortType> = []
     private var portTypesCurrent = -1
    
    public var soapActions:Array<XMLBinding> = []
    
    
    private var elementNameStack:Array<XMLElementStackInfo> = []
    private var tmpAssoc:Dictionary<String,Any> = [:]
    private var tmpAssocCount:Dictionary<String,Any> = [:]
    private var tmpAssocLastKey:String = ""
    private var resultAssoc:Dictionary<String,Any> = [:]

    
    public var soapAction:String = ""
    public var lastErrorCode: String = ""
    public var lastErrorString: String = ""
   
    
     func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
       
         
             var b_last:XMLElementStackInfo = XMLElementStackInfo(element_name:"", param: "")
             var last:XMLElementStackInfo   = XMLElementStackInfo(element_name:"", param: "")
         
             if(self.elementNameStack.count > 0 )
             {
                 last = self.elementNameStack[  self.elementNameStack.count-1 ]
             }
         
             if(self.elementNameStack.count > 1 )  {b_last = self.elementNameStack[  self.elementNameStack.count-2 ]}
           
         
         
            if( (b_last.element_name == "types" && last.element_name == "xsd:schema" && elementName == "xsd:complexType" ) || ( last.element_name == "types" && elementName == "xsd:complexType" ) ) {
                 if let dt_name = attributeDict["name"] ?? nil
                 {
                        complexTypeCurrent += 1
                         
                        let dataType:XMLComplexType = XMLComplexType(name: dt_name,  namespace:"", childern: [], type: elementName )
                        self.complexType.append(dataType)
                 }
             }
         
             else
             if( last.element_name == "xsd:complexType" && ( elementName == "xsd:all" || elementName == "xsd:sequence" ) ) {
                    self.complexType[complexTypeCurrent].complexType = elementName
              }
           
             else
             if( ( last.element_name == "xsd:all"  ||  last.element_name == "xsd:sequence"   ) && elementName == "xsd:element" ) {
                  if let dt_name = attributeDict["name"] ?? nil
                  {
                         let elementType:String = attributeDict["type"] ?? "none"
                      
                         let elementOf:XMLComplexType = XMLComplexType(name: dt_name,  namespace:"", childern: [], type: elementType )
                         self.complexType[complexTypeCurrent].childern.append(elementOf)
                  }
              }
         
             else
             if( last.element_name == "definitions" && elementName == "message" ) {
                   
                 if let dt_name = attributeDict["name"] ?? nil
                 {
                     let xmlMessage:XMLMessage = XMLMessage(name: dt_name, parts: [] )
                     messages.append(xmlMessage)
                     messageCurrent += 1
                 }
              }
         
             else
             if( last.element_name == "message" && elementName == "part" ) {
                   
                 if let dt_name = attributeDict["name"] ?? nil
                 {
                     let elementType:String = attributeDict["type"] ?? "none"
                     let part:XMLPart = XMLPart(name: dt_name,type: elementType)
                     
                     messages[messageCurrent].parts.append(part)
                 }
              }
         
             else
             if( last.element_name == "portType" && elementName == "operation" ) {
                   
                 if let dt_name = attributeDict["name"] ?? nil
                 {
                     
                     let portType:XMLPortType = XMLPortType( name: dt_name ,inputMessage: nil, outputMessage: nil)
                     portTypes.append(portType)
                     portTypesCurrent += 1
                 }
              }
             else
             if( last.element_name == "operation" && elementName == "input" ) {
                   
                 if let msg_name = attributeDict["message"] ?? nil
                 {
                     portTypes[portTypesCurrent].inputMessage = getMessageByName(msg_name:msg_name)
                 }
              }
             else
             if( last.element_name == "operation" && elementName == "output" ) {
                   
                 if let msg_name = attributeDict["message"] ?? nil
                 {
                     portTypes[portTypesCurrent].outputMessage = getMessageByName(msg_name:msg_name)
                 }
              }
             else
             if( b_last.element_name == "binding" && last.element_name == "operation" && elementName == "soap:operation" ) {
                   
                 if let dt_name = attributeDict["soapAction"] ?? nil
                 {
                     let xmlSoapAction:XMLBinding = XMLBinding(actionName: last.param, soapAction: dt_name)
                     soapActions.append(xmlSoapAction)
                 }
              }
         
         
         
         
             var topP = ""
             if let dt_name = attributeDict["name"] ?? nil
             {
                 topP = dt_name
             }
         
             let newItem: XMLElementStackInfo = XMLElementStackInfo(element_name: elementName, param: topP)
             self.elementNameStack.append(newItem)
         
          
         
         if(soapAction.count > 0)
         {
             var keyStackStr:String = ""
             for stack in self.elementNameStack
             {
                 keyStackStr += self.removeSeparator(val: stack.element_name) + "@";
             }
             
             if var countNow = self.tmpAssocCount[keyStackStr] as? Int
             {
                 // print("\nExist", keyStackStr, countNow);
                 
                  var exp = keyStackStr.components(separatedBy: "@")
                  var lastElement  = exp[ exp.count - 2 ]
                 
                  lastElement = lastElement  + String(countNow)
                  let newItem: XMLElementStackInfo = XMLElementStackInfo(element_name: lastElement, param: "")
                
                  var newStackArr = ""
                  var inx = 0
                 
                  for stack in self.elementNameStack
                  {
                      if(inx > self.elementNameStack.count - 2) { break; }
                      newStackArr += self.removeSeparator(val: stack.element_name) + "@";
                      inx += 1
                  }
                  
                  newStackArr += lastElement + "@"
                  print("\nNew stack ", newStackArr)
                  self.tmpAssocLastKey = newStackArr
                 
                  self.elementNameStack.removeLast()
                  self.elementNameStack.append(newItem)
                  
                 
                  countNow += 1
                  self.tmpAssocCount[keyStackStr] = countNow
             }
             else
             {
                  self.tmpAssocCount[keyStackStr] = 1
                  self.tmpAssocLastKey = keyStackStr
             }
             
           
            
             
             
         }
            
        }
    
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
             if(self.elementNameStack.count > 0 )
             {
                self.elementNameStack.removeLast();
            }
      }
    
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
              
        
                var b_last:XMLElementStackInfo = XMLElementStackInfo(element_name:"", param: "")
                var last:XMLElementStackInfo   = XMLElementStackInfo(element_name:"", param: "")
            
                if(self.elementNameStack.count > 0 )
                {
                    last = self.elementNameStack[  self.elementNameStack.count-1 ]
                }
            
                if(self.elementNameStack.count > 1 )
                {
                    b_last = self.elementNameStack[  self.elementNameStack.count-2 ]
                }
        
                if( (b_last.element_name == "SOAP-ENV:Fault" || b_last.element_name == "Fault") && last.element_name == "faultcode")
                {
                    self.lastErrorCode = string
                }

                if( (b_last.element_name == "SOAP-ENV:Fault" || b_last.element_name == "Fault") && last.element_name == "faultstring")
                {
                    self.lastErrorString = string
                }
        
             
            if(self.tmpAssocLastKey.count > 0)
            {
                print("Save into", self.tmpAssocLastKey, "val: ", string)
                self.tmpAssoc[ self.tmpAssocLastKey ] = string
                
            }
         
    }
    
    
 
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
       }
    
    
    func removeSeparator(val:String) -> String
    {
        var tmpElementName = val
        let arrCheck = val.components(separatedBy: ":")
        if(arrCheck.count == 2) { tmpElementName = arrCheck[1] }
        return tmpElementName
    }
    
    func getMessageByName(msg_name:String) -> XMLMessage?
    {
        var clearMsgName = self.removeSeparator(val: msg_name)
        
    
        for item in self.messages
        {
            if(item.name == clearMsgName)
            {
                return item
            }
        }
        
        return nil
    }
    
    func getVarType(stack: Array<XMLElementStackInfo>, element_name:String) -> String
    {
            if(stack.count == 0) { return "??" }
        
        
            var el = stack.last!
            let structName =  self.removeSeparator(val: el.element_name)
            
            //search dataStructure in mesages by elementName
            for msg in self.messages
            {
                if(msg.name == structName)
                {
                    for p in msg.parts
                    {
                        if(p.name == element_name)
                        {
                            return  self.removeSeparator(val: p.type)
                        }
                    }
                    break;
                }
            }
        
        
        return "?"
    }
   

   
    
    private func tmpToAssoc()
    {
       
        //sort by deep..
        let sorted = self.tmpAssoc.sorted(by: {el1,el2 in
            
            let e1 = el1.key.components(separatedBy: "@")
            let e2 = el2.key.components(separatedBy: "@")
            if(e1.count < e2.count)  {
                return false;
            }
            
          //  if(e1.count == e2.count)  {
            //    var arrKey:Array<String> = [ el1.key, el2.key ]
             //   let sortedStudents = arrKey.sorted()
             //   if( sortedStudents[0] == el1) { return false; }
           // }
            
            
            return true;
            
        }  )
        
        
     
        for actualDeep in 0...5
        {
            sorted.forEach { (key: String, value: Any) in
                
              //  print("\n\n-- ", key,  " = " , value  )
                
                let exp = key.components(separatedBy: "@")
                
                if(exp.count-1 > actualDeep)
                {
                    var deepVal:Any = [:]
                    if( exp.count-2 == actualDeep ) { deepVal = value; }
                    
                    
                    if(actualDeep == 0)
                    {
                        self.resultAssoc[ exp[actualDeep] ] = deepVal
                    }
                    
                    if(actualDeep == 1)
                    {
                        if var a0 = self.resultAssoc[ exp[actualDeep - 1 ] ] as? Dictionary<String,Any>
                        {
                            a0[ exp[actualDeep] ] = deepVal
                            self.resultAssoc[ exp[actualDeep - 1 ] ]  = a0
                        }
                    }
                    
                    if(actualDeep == 2)
                    {
                        if var a0 = self.resultAssoc[ exp[actualDeep - 2 ] ] as? Dictionary<String,Any>
                        {
                            if var a1 = a0[ exp[actualDeep - 1 ] ] as? Dictionary<String,Any>
                            {
                                  a1[ exp[actualDeep] ] = deepVal
                                  a0[ exp[actualDeep - 1 ] ] = a1
                                  self.resultAssoc[ exp[actualDeep - 2 ] ]  = a0
                            }
                        }
                    }
                    
                    if(actualDeep == 3)
                    {
                        if var a0 = self.resultAssoc[ exp[actualDeep - 3 ] ] as? Dictionary<String,Any>
                        {
                            if var a1 = a0[ exp[actualDeep - 2 ] ] as? Dictionary<String,Any>
                            {
                                if var a2 = a1[ exp[actualDeep - 1 ] ] as? Dictionary<String,Any>
                                {
                                    a2[ exp[actualDeep] ] = deepVal
                                    a1[ exp[actualDeep - 1 ] ] = a2
                                    a0[ exp[actualDeep - 2 ] ] = a1
                                    self.resultAssoc[ exp[actualDeep - 3 ] ]  = a0
                                }
                            }
                        }
                    }
                    
                    if(actualDeep == 4)
                    {
                        if var a0 = self.resultAssoc[ exp[actualDeep - 4 ] ] as? Dictionary<String,Any>
                        {
                            if var a1 = a0[ exp[actualDeep - 3 ] ] as? Dictionary<String,Any>
                            {
                                if var a2 = a1[ exp[actualDeep - 2 ] ] as? Dictionary<String,Any>
                                {
                                    if var a3 = a2[ exp[actualDeep - 1 ] ] as? Dictionary<String,Any>
                                    {
                                        a3[ exp[actualDeep] ] = deepVal
                                        a2[ exp[actualDeep - 1 ] ] = a3
                                        a1[ exp[actualDeep - 2 ] ] = a2
                                        a0[ exp[actualDeep - 3 ] ] = a1
                                        self.resultAssoc[ exp[actualDeep - 4 ] ]  = a0
                                    }
                                }
                            }
                        }
                    }
                    
                    if(actualDeep == 5)
                    {
                        if var a0 = self.resultAssoc[ exp[actualDeep - 5 ] ] as? Dictionary<String,Any>
                        {
                            if var a1 = a0[ exp[actualDeep - 4 ] ] as? Dictionary<String,Any>
                            {
                                if var a2 = a1[ exp[actualDeep - 3 ] ] as? Dictionary<String,Any>
                                {
                                    if var a3 = a2[ exp[actualDeep - 2 ] ] as? Dictionary<String,Any>
                                    {
                                        if var a4 = a3[ exp[actualDeep - 1 ] ] as? Dictionary<String,Any>
                                        {
                                            a4[ exp[actualDeep] ] = deepVal
                                            a3[ exp[actualDeep - 1 ] ] = a4
                                            a2[ exp[actualDeep - 2 ] ] = a3
                                            a1[ exp[actualDeep - 3 ] ] = a2
                                            a0[ exp[actualDeep - 4 ] ] = a1
                                            self.resultAssoc[ exp[actualDeep - 5 ] ]  = a0
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    
                }
                
                print(self.resultAssoc)
                
            }
        }
        
        
    }
    
    
    
    public func getAssoc() -> Dictionary<String,Any>
    {
        
        self.tmpToAssoc();
        let soapResElement = self.removeSeparator(val: self.soapAction) + "Response"
     //   print("\n\ngetAssoc" , soapResElement, self.resultAssoc)
        
        if let envelope = self.resultAssoc["Envelope"] as? Dictionary<String,Any>
        {
            if let body = envelope["Body"] as? Dictionary<String,Any>
            {
                if let res = body[soapResElement] as? Dictionary<String,Any>
                {
                    return res;
                }
            }
        }
        return [:]
    }
}



 

class SoapRequest: NSObject, StreamDelegate
{
    
  
    private var webServiceScheme = "wsdl.xml"
    private var wsdlContent      = ""
    private var url              = "https://localhost"
    private var port             = 80
    private var urlParam         = "/wsdl"
    private var urlMethod        = "POST"
    
    
    private var rawXMLToSend         = ""
    
    private var soapAction           = ""
    private var soapActionBind       = ""
    private var soapActionParamIn:Array<Any> = []
    
    
    private var xmlParserDelegate = ParseDelagate()
    
    private var headers:Dictionary<String,String> = [:]
    private var envelopeXMLRequest = ""
 
    
    private var useSocket = true   //if you don't connect over http'S'
    private var inputStream: InputStream!
    private var outputStream: OutputStream!
    private var responseStr = ""
    private var isOpen = false
    private var isResponse = false
    
    
 
    var recv: ((Dictionary<String,Any>) -> Void)? = nil
  
   /**
        If you use https
    */
    public func  setOverHTTPS() { self.useSocket = false;  }
    public func  disableHTTPS() { self.useSocket = true;  }
    
    
    func prepare(url:String, port:Int, urlParam:String, method:String, scheme: String)
    {
       
        self.url   = url
        self.port  = port
        self.urlParam = urlParam
        self.urlMethod = method
        self.webServiceScheme = scheme
        
        //fetch ComplexTypes, Message, Action, ... from XML and  put them in arrays
        self.loadWSDL()
    }
    
    
    
    func receive( _ function: @escaping (Dictionary<String,Any>) -> Void )
    {
        self.recv = function
    }
 
    func callAction(actionName:String, params:Dictionary<String,Any>, headers:Dictionary<String,String> ) throws -> Bool
    {
        //search action
        var find = -1
        
        for  (ix, port) in self.xmlParserDelegate.portTypes.enumerated()
        {
            if(port.name == actionName)
            {
                find = ix
                break
            }
        }
        
        if(find == -1)
        {
            throw SoapError.NoFoundAction(actionName);
        }
        
        
        self.isResponse = false
        self.soapAction = actionName
        self.headers = headers
        
        self.xmlParserDelegate.soapActions.forEach { b in
            if(b.actionName == actionName)
            {
                self.soapActionBind = b.soapAction
            }
        }
        
        if(self.soapActionBind.count == 0)
        {
            throw SoapError.NoFoundBind(actionName);
        }
        
        
        let inputMessage = self.xmlParserDelegate.portTypes[find].inputMessage
        
        var strXMLRequest:String = try self.mapElements(deep: 0, inAny: inputMessage!.parts, inName: inputMessage!.name ,inType: "Array<XMLPart>", inData: params)
    
        var envelope  = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>"
            envelope += "<SOAP-ENV:Envelope>"
             envelope += "<SOAP-ENV:Body>"
        
               envelope += "<" + actionName + "Request>"
                 envelope += strXMLRequest
               envelope += "</" + actionName + "Request>"
        
            envelope += "</SOAP-ENV:Body>"
           envelope += "</SOAP-ENV:Envelope>"
      
        self.envelopeXMLRequest = envelope

       
        if(self.useSocket)
        {
            self.sendRequestOverSocket()
        }
        else
        {
            self.sendRequestOverHttps()
        }
    
    
        
        return true;
    }
   
    
    private func sendRequestOverHttps()
    {
          let url = URL(string: self.url)!
      
          let session = URLSession.shared
          var request = URLRequest(url: url)
        
          request.httpMethod = self.urlMethod
          
          request.setValue(self.soapActionBind, forHTTPHeaderField: "SOAPAction")
          request.setValue("application/soap+xml", forHTTPHeaderField: "Content-Type")
        
          self.headers.forEach({ (h_name, h_value) in
              request.setValue(h_value, forHTTPHeaderField: h_name)
          })
        
        request.httpBody =  self.envelopeXMLRequest.data(using: .utf8)
        
          let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                   
              guard error == nil else {
                  return
              }
                   
              guard let data = data else {
                  return
              }
                   
             do {
                 
                 self.parseResponse(envelope: String(data: data, encoding: .utf8)! )
                 
             } catch let error {
               print(error.localizedDescription)
             }
          })

          task.resume()
    }
    
   
    
    private func sendRequestOverSocket()
    {
        
        //Another thread..
        DispatchQueue.global(qos: .utility).async(){
          
           
         
            Stream.getStreamsToHost(withName: self.url, port: Int(exactly: self.port)!, inputStream: &self.inputStream, outputStream: &self.outputStream)

        
            self.inputStream.delegate = self
            self.outputStream.delegate = self

            self.inputStream!.schedule(in: .main, forMode:RunLoop.Mode.default)
            self.outputStream!.schedule(in: .main, forMode: RunLoop.Mode.default)

            self.inputStream.open()
            self.outputStream.open()
            
            
            //HTTP header
            var http:String = ""
            if(self.urlMethod.lowercased() == "post") {
                http += "POST " + self.urlParam + " HTTP/1.1\r\n";
            }
            
            if(self.urlMethod.lowercased() == "get") {
                http += "GET " + self.urlParam  + " HTTP/1.1\r\n";
            }

            http += "SOAPAction: " + self.soapActionBind + "\r\n"
            http += "User-Agent: blazej-kita-soap-ios\r\n"
            http += "Content-Type: application/soap+xml\r\n"
            
            self.headers.forEach({ (h_name, h_value) in
                http += h_name + ": " + h_value + "\r\n"
            })
            
            let length = self.envelopeXMLRequest.count
            http += "Content-Length: " + String(length) + "\r\n"
          
            http += "\r\n\r\n"
          
            
           //HTTP content...
            http += self.envelopeXMLRequest
            
            
           // print("Wait for open, max 2sec")
            for _ in 1...200
            {
                if(self.isOpen) { break; }
                usleep(10000)   //0.01 sec
            }
            
            if(!self.isOpen )
            {
                print("Cannot connect " + self.url)
                return;
            }
            
            
            var data = http.data(using: .utf8)!
            data.withUnsafeBytes {
                 guard let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self)
                 else {
                     print("Error 0x0002")
                     return
                 }
                self.outputStream.write(pointer, maxLength: data.count)
             }
            
            
          //  print("Wait for response, max 10sec")
            for _ in 1...1000
            {
                if(self.isResponse) { break; }
                usleep(10000)   //0.01 sec
            }
            
            self.inputStream.close()
            self.outputStream.close()
            
            
            print(self.responseStr)
            
            let headers_content = self.responseStr.components(separatedBy: "\r\n\r\n")
            if(headers_content.count > 1 )
            {
                self.parseResponse( envelope: headers_content[1] )
            }
            
         
        }
        
            
        
    }
    
    private func sendRequestOverHttp()
    {
         
    }
    
    
    
    private func readResponse()
    {
           
               var buffer = [UInt8](repeating: 0, count: 10240)
               while (self.inputStream!.hasBytesAvailable) {
                   let bytesRead: Int = inputStream!.read(&buffer, maxLength: buffer.count)
                   if bytesRead >= 0 {
                       self.responseStr += NSString(bytes: UnsafePointer(buffer), length: bytesRead, encoding: String.Encoding.ascii.rawValue)! as String
                   }
               }
    }

    
    
    //Delegate method override
     func stream(_ aStream: Stream, handle eventCode: Stream.Event){
         switch eventCode{
         case .hasBytesAvailable:
            // print("something to pass")
             self.readResponse()
         case .endEncountered:
            // print("end of inputStream")
             isResponse = true
        // case .errorOccurred:
            // print("error occured")
       //  case .hasSpaceAvailable:
            // print("has space available")
         case .openCompleted:
              isOpen = true
           //  print("open completed")
         default:
                 print("StreamDelegate event")
             
            
         }
     }
    
     
    
    
    private func mapElements(deep:Int, inAny:Any, inName:String , inType:String, inData:Any) throws -> String
    {
        var ret:String = ""
        
        
        if(inType == "Array<XMLPart>")
        {
            let arr:Array<XMLPart> = inAny as! Array<XMLPart>
            
            for part in arr
            {
               // print("Deep: ", deep,  "Name: " ,  part.name, "type: ", part.type);
                
                if let dic:Dictionary<String,Any> = inData as? Dictionary<String,Any>
                {
                    if let inDataDown:Any = dic[part.name] as? Any
                    {
                         ret += try self.mapElements(deep: deep + 1, inAny: part, inName: part.name, inType: part.type, inData: inDataDown)
                    }else
                    {
                        throw SoapError.NoFoundParam(part.name)
                    }
                }else
                {
                    throw SoapError.BadInputData("Data input should be dictonary inData<Dictonary,Any>")
                }
            }
        }
        
        
        if(inType == "xsd:string" || inType == "xs:string"  || inType == "string")
        {
            //print("Deep: ", deep,  "Name: " , inName  , "type: ", inType);
            
            if let inDataDown:String = inData as? String
            {
                ret += "<" + inName + ">" + inDataDown + "</" + inName + ">"
            }else
            {
                throw SoapError.BadDataType("Bad data type, needed: String for " + inName )
            }
            
        }
        
        if(inType == "xsd:date" || inType == "xs:date"  || inType == "date")
        {
            print("Deep: ", deep,  "Name: " , inName  , "type: ", inType);
            
            if let inDataDown:String = inData as? String
            {
                ret += "<" + inName + ">" + inDataDown + "</" + inName + ">"
            }else
            {
                throw SoapError.BadDataType("Bad data type, needed: Date for " + inName )
            }
        }
        
        
        if(inType == "xsd:decimal" || inType == "xs:decimal"  || inType == "decimal")
        {
            print("Deep: ", deep,  "Name: " , inName  , "type: ", inType);
            
            if let inDataDown:String = inData as? String
            {
                if let _:Decimal = Decimal(string: inDataDown)
                {
                    ret += "<" + inName + ">" + inDataDown + "</" + inName + ">"
                }else
                {
                    throw SoapError.BadDataType("Bad data type, needed: Decimal for " + inName )
                }
                
            }else
            {
                throw SoapError.BadDataType("Bad data type, needed: Decimal for " + inName )
            }
        }
        
        
        if(inType == "xsd:integer" || inType == "xs:integer"  || inType == "integer")
        {
            print("Deep: ", deep,  "Name: " , inName  , "type: ", inType);
            
          
                if let val = inData as? Int
                {
                    ret += "<" + inName + ">" + String(val) + "</" + inName + ">"
                }else
                {
                    throw SoapError.BadDataType("Bad data type, needed: Integer for " + inName )
                }
        
        }
        
        
        return ret;
    }
    
    private func getRawEnvelope() -> String
    {
        return self.envelopeXMLRequest
    }
    
    private func loadWSDL()
    {
                do{
                            var filePath = Bundle.main.url(forResource: "wsdl", withExtension: "xml")
                   
                            let fm = FileManager.default;
                            let suppurl = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                            var defPath:String = "?"
                            
                            if let regPrivateFile:URL = filePath
                            {
                                defPath = regPrivateFile.path
                                
                                if(fm.fileExists(atPath: defPath))
                                {
                                    let wsdlData:Data   = try Data(contentsOf: regPrivateFile)
                                    self.wsdlContent =  String(decoding: wsdlData, as: UTF8.self)
                                    
                                    let xmlParser = XMLParser(data: wsdlData)
                                    xmlParser.delegate = self.xmlParserDelegate
                                    
                                    if(xmlParser.parse())
                                    {
                                    }
                                    
                                }else
                                {
                                    print("Scheme WSDL not found!")
                                }
                            }
                
            }catch{
                print("Fault");
            }
        
        
    }
    

    private func parseResponse(envelope:String)
    {
        print("EnvelopeResponse ", envelope)
        
        let xmlParser = XMLParser(  data: envelope.data(using: .utf8)! )
        
        
        self.xmlParserDelegate.soapAction = self.soapAction
        xmlParser.delegate = self.xmlParserDelegate
        
        if(xmlParser.parse())
        {
        }
        
        if(!self.xmlParserDelegate.lastErrorCode.isEmpty)
        {
            var  response:Dictionary<String,Any> = [:]
            response["code"] = self.xmlParserDelegate.lastErrorCode
            response["msg"] = self.xmlParserDelegate.lastErrorString
            response["status"] = "ERROR"
            
            if(self.recv != nil)
            {
                self.recv!( response );
            }
        }
        
       
        var  response:Dictionary<String,Any> = [:]
        response["response"] = self.xmlParserDelegate.getAssoc()
        response["status"] = "OK"
        
        if(self.recv != nil)
        {
            self.recv!( response );
        }
        
        
        
    }
  
}

