# Relish - Compact Swift Command Line Tool for Your Xcode Project

Welcome to Relish, a compact and powerful Swift command-line tool designed to enhance your Xcode project workflow. Relish provides a suite of helpful commands to streamline technical services, automate pre-commit hooks in Git, and verify code changes efficiently. By working directly with Git, Relish analyzes your code to identify common issues, manage linting, and optimize your Xcode project file, thereby minimizing conflicts and formatting your code consistently.

## Features

- **Pre-Commit Hooks**: Easily set up pre-commit hooks in Git to ensure code quality before every commit.
- **Code Verification**: Automatically verify code changes to catch common issues early.
- **Project Sorting**: Sort your Xcode project files to reduce merge conflicts.
- **Code Formatting**: Format your source code to maintain a consistent style.
- **Dependency Management**: Install and configure necessary dependencies like SwiftFormat and SwiftLint.

## Installation

To install Relish, follow these steps:

1. Clone the repository:
   ```sh
   git clone https://github.com/yourusername/relish.git
   ```

2. Navigate to the Relish directory:
   ```sh
   cd relish
   ```

3. Run the setup script:
   ```sh
   ./setup.sh
   ```

## Usage

After installation, you can access Relish directly from your terminal. To complete the setup process and install dependencies, run:
```sh
relish environment setup
```

This command will install dependencies using Homebrew, including SwiftFormat and SwiftLint. Configuration files for these tools will be placed in your home directory under the `relish` folder. You can customize the SwiftFormat and SwiftLint configuration files according to your project's code style and add new checks as needed.

### Commands

Relish comes with several built-in commands to help manage your project:

- **Sort**: Sorts your Xcode project file to minimize conflicts.
  ```sh
  relish sort
  ```

- **Verify**: Verifies the code in the Git staging area, ensuring all checks are passed before committing.
  ```sh
  relish verify pre-commit
  ```

- **Environment**: Sets up the necessary environment for Relish to function.
  ```sh
  relish environment setup
  ```

- **Help**: Displays detailed information about available commands.
  ```sh
  relish help
  ```

### Verification Checks

The `relish verify pre-commit` command performs several checks on staged files:

- **Formatting**: Ensures code is formatted correctly; prevents commits if issues are found.
- **Sorting**: Checks if the project file is sorted; recommends sorting before committing.
- **Dead Links**: Identifies broken file references in the project; prevents commits if found.
- **Large Files**: Prevents the upload of large files; configurations can be adjusted in the `relish` folder.
- **Linting**: Checks code health according to the configured lint rules.

## CI/CD Integration

Relish is designed to work seamlessly with GitHub Actions and other CI/CD processes. All checks can be run locally, and the server can re-verify your PR and code to ensure no blocking or dead code reaches the main or development branches.

## Customization

Feel free to modify the source code to add custom checks tailored to your project's needs. Relish is flexible and allows for extensive customization. Ensure you run Relish from the root of your project to avoid issues with relative paths in Git history.

## Optimize Your Workflow

Use Relish to optimize your development workflow, enhance code quality, and reduce merge conflicts. Happy coding!

