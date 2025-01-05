# LibreOTP

LibreOTP is a cross-platform desktop OTP code generator. Currently it works exclusively with an exported JSON file from [2FAS](https://2fas.com/). It supports Windows, Mac and Linux and 2FAS features like grouping. Currently only TOTP keys are supported.

This project was borne from necessity. I needed a modern desktop application that would support 2FAS exports including grouping and search on Linux. It's rough, it's ready, but it does exactly what I needed it to do and might be what you need to!

Flutter means this app works on Windows, Mac and Linux.

Contributions and improvements are welcome, open an `RFC: ` issue if you'd like to discuss a plan before getting started.

## Preview
[Demo Video](https://github.com/user-attachments/assets/7fb41579-4e8b-41b5-8915-f7de742037fe)

## Getting Started

1. Generate an unencrypted export from your 2FAS app and download it to your desktop machine, call it `data.json`. 
   - :bulb: Improvement opportunity: Support encrypted exports
2. Put this file in a folder called 'LibreOTP' in your system documents directory. This is the hard coded location where the app will search for it e.g. on my linux system that's `/home/henri/Documents/LibreOTP/data.json`. On other platforms the document directory is:
   - Windows: `C:\Users\<Username>\Documents\LibreOTP\data.json`
   - MacOS: `/Users/<Username>/Library/Containers/com.henricook.libreotp/Data/Documents/LibreOTP/data.json` (sorry, MacOS Sandboxing requirements make this ugly)
   - Linux: `/home/<Username>/Documents`
3. Download the appropriate binary for your OS from the [Releases page](https://github.com/henricook/libreotp/releases)
4. Unpack the zip, it's rough and ready right now but there'll be a folder called 'bundle' in there that you can switch to. On Linux to run the app you'd now do:
   - `chmod +x ./LibreOTP`
   - `./LibreOTP`
5. Enjoy! And don't forget to :star: Star the repository to encourage further updates. 

## Limitations
- If `data.json` isn't in the right place, or its malformed, the crash will be quick and unhandled.
- There's not really much error handling at all.

## Credit

### [OTPClient](https://github.com/paolostivanin/OTPClient)

Core layout of the app is heavily inspired by `otpclient` which I liked but I found lacked grouping. Being written in C, I didn't find it particularly easy to contribute to either. 

### [Flutter](https://github.com/flutter/flutter) + [GPT4o](https://chat.openai.com)

The Flutter docs are great and along with IntelliJ's starter project meant I got up and running really fast. Coupled with copious amounts of GPTing I went from concept to version 0.1 in just 3 hours with no prior knowledge of Flutter or Dart.

## Roadmap / ideas

1. Supported encrypted dumps so that I don't need to leave my secrets unencrypted on disk
2. (Big one) Sync with Google Drive
3. Better installers
4. Automated release pipeline with tagging and asset generation
