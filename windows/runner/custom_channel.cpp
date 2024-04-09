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
               auto a_it = (argsList->find(flutter::EncodableValue("a")))->second;    
               // Just converting it to int
               int a = static_cast<int>(std::get<int>((a_it)));
               
               flutter::EncodableValue res ; // final result variable
               if(a){
                 // convert to string since we send back the result as string
                 std::string c = std::to_string(a);
                     LPCWSTR subKey = L"SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment";
                      LPCWSTR valueName = L"PATH";

                      // Obtener el valor actual del registro
                      std::wstring currentValue = GetRegistryStringValue(HKEY_LOCAL_MACHINE, subKey, valueName);

                      // Agregar más datos al valor actual
                      std::wstring newData = std::wstring(c.begin(), c.end());;
                      std::wstring newData1 = L"\\flutter-master\\bin";
                      std::wstring updatedValue = currentValue + L";" + newData + newData1; // Aquí se está concatenando el valor actual con los nuevos datos

                      // Establecer el nuevo valor en el registro
                      if (SetRegistryStringValue(HKEY_LOCAL_MACHINE, subKey, valueName, updatedValue)) {
                          res = flutter::EncodableValue("Valor actualizado correctamente: " + c);
                          (*resPointer)->Success(res);

                      }
                      else {
                 (*resPointer)->Error("Error occured");

                      }
                // send positive result
                 (*resPointer)->Success(res);
               }else{
                // if not send error
                 (*resPointer)->Error("Error occured");
               }
        }
    };

}