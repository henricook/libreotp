# Libre OTP

This project was borne from necessity. I needed a modern desktop application that would support 2FAS exports including grouping and search on Linux. It's rough, it's ready, but it does exactly what I needed it to do and might be what you need to!

Flutter means this app works on Windows, Mac and Linux.

Contributions and improvements are welcome, open an `RFC: ` issue if you'd like to discuss a plan before getting started.

## Getting Started

1. Generate an unencrypted export from your 2FAS app and download it to your desktop machine, call it `data.json`. 
   - :bulb: Improvement opportunity: Support encrypted exports
2. Put this file in a folder called 'LibreOTP' in your system documents directory. This is the hard coded location where the app will search for it e.g. on my linux system that's `/home/henri/Documents/LibreOTP/data.json`. On other platforms the document directory is:
   - Windows: `C:\Users\<Username>\Documents\LibreOTP\data.json`
   - MacOS: `/Users/<Username>/Documents/LibreOTP/data.json`
   - Linux: `/home/<Username>/Documents`
3. Download the appropriate binary for your OS from the [Releases page]()

## Credit

### [OTPClient](https://github.com/paolostivanin/OTPClient)

Core layout of the app is heavily inspired by `otpclient` which I liked but I found lacked grouping. Being written in C, I didn't find it particularly easy to contribute to either. 

### [Flutter](https://github.com/flutter/flutter) + [GPT4o](https://chat.openai.com)

The Flutter docs are great and along with IntelliJ's starter project meant I got up and running really fast. Coupled with copious amounts of GPTing I went from concept to version 0.1 in just 3 hours with no prior knowledge of Flutter or Dart.

## Roadmap / ideas

1. Supported encrypted dumps so that I don't need to leave my secrets unencrypted on disk
2. (Big one) Sync with Google Drive
