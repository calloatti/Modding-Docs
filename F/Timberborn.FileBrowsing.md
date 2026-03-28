# Timberborn.FileBrowsing

## Overview
The `Timberborn.FileBrowsing` module provides an in-game file explorer UI. It is primarily utilized in the Map Editor to allow players to browse their local file system, select directories, and open specific files (such as images for custom map backgrounds). The system wraps standard C# `System.IO` operations into a Unity UI Toolkit interface.

---

## Key Components

### 1. `FileBrowser`
The main controller and entry point for the file browsing interface.
* **Dialog Management**: It implements `IPanelController`, allowing it to be pushed onto the game's `PanelStack` as a modal dialog.
* **State Persistence**: It remembers the `LastOpenedPath` using Unity `PlayerPrefs` to restore the user's previous location across sessions.
* **Manual Navigation**: It manages a path text field that allows users to manually type a path to navigate.

### 2. `DirectoryListView`
Handles the logic for populating and displaying folder contents.
* **Data Sourcing**: It retrieves files and directories using `DirectoryInfo.GetFileSystemInfos()`.
* **System Filtering**: It automatically hides files flagged as `Hidden` or `System`.
* **Drive Detection**: If the provided path is empty, it populates the view with a list of ready system drives using `DriveInfo.GetDrives()`.
* **Error Handling**: It catches `UnauthorizedAccessException` and displays a "No Permission" dialog if the user attempts to enter restricted folders.

### 3. `FileFilter` and `FileFilterProvider`
* **`FileFilter`**: Defines valid file extensions (e.g., `.png`, `.jpg`) and an associated `Sprite` icon to display next to those files in the list.
* **`FileFilterProvider`**: A singleton that pre-loads common filters, specifically providing an `Images` filter restricted to `.png` and `.jpg` files.

### 4. `DiskSystemEntry`
A lightweight `readonly struct` that represents a single item on the disk. It caches vital metadata including the item's name, full path, parent directory, and whether it is a directory or currently exists.

---

## Technical UI Details

### `DiskSystemEntryElementFactory`
This factory handles the visual creation and data binding of rows within the explorer's `ListView`.
* **Icon Logic**: It loads the standard directory icon from `UI/Images/Core/directory-icon` during initialization.
* **Row Binding**: When binding a row, it sets the label text to the entry's name and assigns either the directory icon or the extension-specific icon provided by the active `FileFilter`.

---

## How to Use This in a Mod

### Opening the File Browser
To use the file browser in a mod, you must inject the `FileBrowser` and `FileFilterProvider` and call the `Open` method with a callback.

    public class MyModPathSelector {
        private readonly FileBrowser _fileBrowser;
        private readonly FileFilterProvider _filterProvider;

        public MyModPathSelector(FileBrowser fileBrowser, FileFilterProvider filterProvider) {
            _fileBrowser = fileBrowser;
            _filterProvider = filterProvider;
        }

        public void PromptUserForImage() {
            // Open the browser with a callback to handle the selected path
            _fileBrowser.Open(
                openFileCallback: (path) => Debug.Log($"User selected: {path}"),
                fileFilter: _filterProvider.Images,
                tipLocKey: "MyMod.SelectMapTextureTip"
            );
        }
    }

---

## Modding Insights & Limitations

* **Context Restriction**: The `FileBrowsingConfigurator` is currently hardcoded only to the `MapEditor` context.
* **Layout Requirements**: The system expects UXML files at `Common/FileBrowser` and `Common/DiskSystemEntryElement` to define the visual layout.
* **Performance**: The list utilizes `CollectionVirtualizationMethod.DynamicHeight`, making it efficient for folders containing a large number of files.

---

## Related DLLs
* **Timberborn.CoreUI**: Supplies the `PanelStack`, `VisualElementLoader`, and `DialogBoxShower`.
* **Timberborn.PlatformUtilities**: Provides the `UserDataFolder` reference used as the default fallback directory.
* **Timberborn.AssetSystem**: Used by factories to load standard UI icons and sprites.