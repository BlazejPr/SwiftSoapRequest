//
//  ExampleViewController.swift
//  gxh
//
//  Created by Błażej Kita on 14/04/2023.
//

import UIKit

class ExampleViewController: UIViewController {

    
    var dash:DashboardViewController? = nil
    
    @IBOutlet weak var contentView: UIView!
    var scrollView:UIScrollView = UIScrollView()
    var stackView:UIStackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

      
        self.contentView.addSubview(self.scrollView)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false;

        
        //Constrain scroll view
        self.scrollView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0).isActive = true;
        self.scrollView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0).isActive = true;
        self.scrollView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: 0).isActive = true;
        self.scrollView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: 0).isActive = true;

        //Add and setup stack view
        self.scrollView.addSubview(self.stackView)
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.axis = .vertical
        self.stackView.spacing = 0;

        //constrain stack view to scroll view
        self.stackView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor).isActive = true;
        self.stackView.topAnchor.constraint(equalTo: self.scrollView.topAnchor).isActive = true;
        self.stackView.trailingAnchor.constraint(equalTo: self.scrollView.trailingAnchor).isActive = true;
        self.stackView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor).isActive = true;
               
        //constrain width of stack view to width of self.view, NOT scroll view
        self.stackView.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true;
        
        self.getData()
    }
    
    public func setHandle(h:DashboardViewController)
    {
        self.dash = h
    }
    
    
    func getData()
    {
        do
        {
            
            // !!!! Before call add wsdl.xml to project
            // wsdl.xml is loading from your bundle
            // thanks for xml scheme SoapRequest knows how to build envelope
          
            // !!! comunication over socket 
            
            var soapReqeust:SoapRequest = SoapRequest()
            soapReqeust.prepare(url:  self.dash!.ip, port: self.dash!.port, urlParam: "/wsdl", method:"POST", scheme: "wsdl.xml")
            
            //params for method
            var param:Dictionary<String,Any> = [:]
            param["sid"] = self.dash!.ssid
            param["numZoneTop"] = 0
            param["numSectorTop"] = 0
            //param["any..."] = [:]
            
            var headers:Dictionary<String,String> = [:]
            headers["apiKey"] = self.dash!.apiKey
            
            
            soapReqeust.receive { response in
                
               
                
                if let res = response as? Dictionary<String,Any>
                {
                    if let status = res["status"] as? String
                     {
                         if(status == "OK")
                         {
                             if let resDictonary = res["response"] as? Dictionary<String,Any>
                             {
                                 print("Response: ", resDictonary)
                             }
                         }
                        
                        else
                        {
                            if let msg = res["msg"] as?String
                            {
                                ViewController.showMessage(vc: self, title: "Error!", msg: "GXH Server: " + msg)
                            }
                            else
                            {
                                ViewController.showMessage(vc: self, title: "Error!", msg: "Undefinded error")
                            }
                        }
                        
                     }
                }
                
            }
            
            
            try soapReqeust.callAction(actionName: "getAllLight", params: param, headers: headers);
          
            
        }catch
        {
            print("Error: \(error) ")
        }
        
    }
 

}
