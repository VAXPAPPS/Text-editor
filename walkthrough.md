# Flutter IDE Walkthrough

This document outlines the features of the custom Flutter IDE built with Flutter.

## Features

### 1. Project Management
- **Open Project**: Click the "Open Project" button or folder icon to select a Flutter project directory.
- **File Explorer**: View the project structure in the left sidebar. Click files to open them.

### 2. Code Editor
- **Syntax Highlighting**: Supports Dart syntax highlighting using `flutter_highlight`.
- **Editing**: Basic text editing with line numbers.
- **Save**: Click the Save icon (floppy disk) in the toolbar to save changes to the current file.

### 3. Integrated Terminal & Runner
- **Terminal**: A built-in terminal panel at the bottom displays output.
- **Run**: Click the Green Play button to run `flutter run -d linux`.
- **Hot Reload**: Click the Yellow Lightning button to trigger Hot Reload (`r`).
- **Hot Restart**: Click the Orange Refresh button to trigger Hot Restart (`R`).
- **Stop**: Click the Red Stop button to terminate the app (`q`).

## Architecture
- **State Management**: Uses `flutter_riverpod` for global state (project path, active file, process output).
- **Layout**: Uses `multi_split_view` for resizable panes.
- **Process Management**: Uses `dart:io` `Process` to spawn and control the Flutter tool.
