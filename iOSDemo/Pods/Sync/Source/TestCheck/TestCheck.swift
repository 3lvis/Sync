/*
 https://github.com/3lvis/TestCheck

 Licensed under the **MIT** license

 > Copyright (c) 2015 Elvis Nuñez
 > Copyright (c) 2016 3lvis
 >
 > Permission is hereby granted, free of charge, to any person obtaining
 > a copy of this software and associated documentation files (the
 > "Software"), to deal in the Software without restriction, including
 > without limitation the rights to use, copy, modify, merge, publish,
 > distribute, sublicense, and/or sell copies of the Software, and to
 > permit persons to whom the Software is furnished to do so, subject to
 > the following conditions:
 >
 > The above copyright notice and this permission notice shall be
 > included in all copies or substantial portions of the Software.
 >
 > THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 > EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 > MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 > IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 > CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 > TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 > SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

@objc public class TestCheck: NSObject {
    /**
     Method to check wheter your on testing mode or not.
     - returns: A Bool, `true` if you're on testing mode, `false` if you're not.
     */
    static public let isTesting: Bool = {
        let enviroment = ProcessInfo().environment
        let serviceName = enviroment["XPC_SERVICE_NAME"]
        let injectBundle = enviroment["XCInjectBundle"]
        var isRunning = (enviroment["TRAVIS"] != nil || enviroment["XCTestConfigurationFilePath"] != nil)

        if !isRunning {
            if let serviceName = serviceName {
                isRunning = (serviceName as NSString).pathExtension == "xctest"
            }
        }

        if !isRunning {
            if let injectBundle = injectBundle {
                isRunning = (injectBundle as NSString).pathExtension == "xctest"
            }
        }

        return isRunning
    }()
}
