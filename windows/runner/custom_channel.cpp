#include "flutter_window.h"
#include "flutter/generated_plugin_registrant.h"
#include <string>

#include <flutter/binary_messenger.h>
#include <flutter/standard_method_codec.h>
#include <flutter/method_channel.h>
#include <flutter/method_result_functions.h>
#include <flutter/encodable_value.h>
#include <../standard_codec.cc>
#include <Windows.h>
#include <iostream>

namespace custom_channels {
    class createChannelCalc {
        public:
        createChannelCalc(flutter::FlutterEngine *engine){initialize(engine);}
        // Takes care of the initial channel creation and registering the callback function
        void initialize(flutter::FlutterEngine *FlEngine){
            const static std::string channel_name("calc_channel");
            // We need to create codec, binary messenger and channel
            flutter::BinaryMessenger *messenger = FlEngine->messenger();
            const flutter::StandardMethodCodec *codec = &flutter::StandardMethodCodec::GetInstance();
            auto channel = std::make_unique<flutter::MethodChannel<>>(messenger ,channel_name ,codec);
            // Set a method handler this will be executed whenever we invoke MethodChannel from dart
            channel->SetMethodCallHandler(
            [&](const flutter::MethodCall<>& call, std::unique_ptr<flutter::MethodResult<>> result) {
                AddMethodHandlers(call,&result);
             }); 
        }

std::wstring GetRegistryStringValue(HKEY hKey, LPCWSTR subKey, LPCWSTR valueName) {
    HKEY hSubKey;
    if (RegOpenKeyEx(hKey, subKey, 0, KEY_READ, &hSubKey) == ERROR_SUCCESS) {
        DWORD bufferSize = static_cast<DWORD>(0);;
        if (RegQueryValueEx(hSubKey, valueName, NULL, NULL, NULL, &bufferSize) == ERROR_SUCCESS) {
            wchar_t* buffer = new wchar_t[bufferSize / sizeof(wchar_t)];
            if (RegQueryValueEx(hSubKey, valueName, NULL, NULL, reinterpret_cast<LPBYTE>(buffer), &bufferSize) == ERROR_SUCCESS) {
                std::wstring value(buffer);
                delete[] buffer;
                RegCloseKey(hSubKey);
                return value;
            }
            delete[] buffer;
        }
        RegCloseKey(hSubKey);
    }
    return L"";
}

// Función para establecer el valor de una cadena en el registro
bool SetRegistryStringValue(HKEY hKey, LPCWSTR subKey, LPCWSTR valueName, const std::wstring& newValue) {
    HKEY hSubKey;
    if (RegOpenKeyEx(hKey, subKey, 0, KEY_SET_VALUE, &hSubKey) == ERROR_SUCCESS) {
        if (RegSetValueEx(hSubKey, valueName, 0, REG_SZ, reinterpret_cast<const BYTE*>(newValue.c_str()), (newValue.length() + 1) * sizeof(wchar_t)) == ERROR_SUCCESS) {
            RegCloseKey(hSubKey);
            return true;
        }
        RegCloseKey(hSubKey);
    }
    return false;
}

        // Handle the call
        void AddMethodHandlers(const flutter::MethodCall<>& call, std::unique_ptr<flutter::MethodResult<>> *result){
            // When a method has been invoked
            // Just identify the method requested & handover control to the function that handles it
            //
            // check the name of the method requested
            if (call.method_name().compare("add") == 0) {
               try {
                 // The add method has been called 
                 handleAdd(call,result);
               }catch (...) {
                 (*result)->Error("An error was caught");
               } 
            }
            // handle other else if conditions
            else {
                //If unknown method send NotImplemented() result
                (*result)->NotImplemented();
            }
       
        }

        // ADD FUNCTIONS THAT ACTUALLY HANDLE THE REQUESTED METHODS
        // Function to handle add method
        void handleAdd(const flutter::MethodCall<>& call, std::unique_ptr<flutter::MethodResult<>> *resPointer){
               // convert arguments passed to EncodableMap ;)
               const flutter::EncodableMap *argsList = std::get_if<flutter::EncodableMap>(call.arguments()); 
               //we will get values in pairs ie., first::"a" second::10.
               //we get the second part
               auto a_it = argsList->find(flutter::EncodableValue("a"));

                if (a_it != argsList->end()) {
               flutter::EncodableValue res;
                std::string a = std::get<std::string>(a_it->second);
                std::wstring c(a.begin(), a.end());

                     LPCWSTR subKey = L"Environment";
                    //  LPCWSTR subKey = L"SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment";
                      LPCWSTR valueName = L"PATH";
                      std::wstring currentValue = GetRegistryStringValue(HKEY_CURRENT_USER, subKey, valueName);
                    std::wstring newData = std::wstring(c.begin(), c.end());
                      std::wstring newData1 = L"\\flutter-master\\bin";
                      std::wstring updatedValue = currentValue + L";" + newData + newData1; // Aquí se está concatenando el valor actual con los nuevos datos
               res = flutter::EncodableValue(a_it->second);
                                     if (SetRegistryStringValue(HKEY_CURRENT_USER, subKey, valueName, updatedValue)) {
                          res = flutter::EncodableValue(a_it->second);
                          (*resPointer)->Success(res);

                      }
                      else {
                 (*resPointer)->Error("The regisrty is not updated");

                      }
                  }
                     else {
        (*resPointer)->Error("El valor 'a' no se encontró");
    }
        }
    };

}