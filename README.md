# FilesTree
iOS Engineering Internship Assignment (PDF Expert)

Built using Xcode Version 12.5 (12E262)

### Use CocoaPods to install dependencies

1. Run `pod install` in terminal
1. Open `FilesTree.xcworkspace` and run the project on selected device or simulator

### Update Credentials to use Google Sheets Service API

Add a URL scheme to project

Google Sign-in requires a custom URL Scheme to be added to project. To add the custom scheme:

Open project configuration: double-click the project name (`FilesTree`) in the left tree view. Select app from the TARGETS section, then select the Info tab, and expand the URL Types section.
Click the + button, and add your reversed client ID as a URL scheme.

Add your Client ID from [Google Cloud Console](https://console.cloud.google.com/apis/credentials/oauthclient/) in `AppDelegate.swift`:

```
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let rootViewController = EntriesCollectionViewController(collectionViewLayout: UICollectionViewLayout())
        
        window = UIWindow()
        window?.rootViewController = UINavigationController(rootViewController: rootViewController)
        window?.makeKeyAndVisible()
        
        // Initialize sign-in with Google.
        GIDSignIn.sharedInstance().clientID = "913111204097-6oa0ga437ujrv30jnogs0hbqk60k8rsa.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().delegate = self
        
        return true
    }
```

Add your `API key` and `spreadsheetId` and specify correct `range` in `GoogleSheetsService.swift`

```
private let sheetID = "1e8gLI6Ft1qlawb7DWHUGPUQlkpDaV5wxkuJvNkWGGHE"
private let range = "Sheet1"
private let apiKey = "AIzaSyBPybXkT_7v-Fjzg9xDnCpEglBRM1QtiV4"
```

### Also you can contact me via email and I'll add your Google Account to test members and you will be able to use Google Sheets Service API without changing the code.

