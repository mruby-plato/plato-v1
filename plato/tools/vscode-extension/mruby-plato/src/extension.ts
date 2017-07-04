'use strict';
// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import * as cp from 'child_process';

const isWin = process.platform === 'win32';
var output = null;

// Execute shell command
// params:
//  action: shell command
//  conTitle: Title of output window.
// return:
//  none.
function executeCommand(action: string, conTitle: string): void {
    var curprc : cp.ChildProcess;
    var cwd = vscode.workspace.rootPath;
    if (!output) {
        output = vscode.window.createOutputChannel(conTitle);
    }
    output.show(vscode.ViewColumn.Two);

    var sh, args;
    var opts = {cwd: cwd, datached: false};
    if (isWin) {    // Windows
        sh = 'cmd';
        args = ['/s', '/c', action];
        opts['windowsVerbatimArguments'] = true;
    } else {        // Mac, Linux
        sh = '/bin/bash';
        args = ['-c', action];
    }
    var child = cp.spawn(sh, args, opts);
    curprc = child;

    child.stderr.on('data', (data) => {
        output.append(data.toString());
    });
    child.stdout.on('data', (data) => {
        output.append(data.toString());
    });
    child.on('close', (code, signal) => {
        if (signal)     output.appendLine('Exited with signal ' + signal);
        else if (code)  output.appendLine('Exited with status ' + code);
        curprc = null;
    });
    child.stdin.end();
}

// Get application path
// params:
//  none.
// return:
//  application path
function getAppPath(): string {
    // Get active file's path
    let editor = vscode.window.activeTextEditor;
    if (!editor) {
        vscode.window.showWarningMessage('No active source code.');
        return null;
    }
    let path = editor.document.fileName;

    // Get application directory
    let idx;
    if ((idx = path.lastIndexOf('/')) < 0) {
        if ((idx = path.lastIndexOf('\\')) < 0) {
            vscode.window.showErrorMessage('Cannot get application path.');
            return null;
        }
    }
    return path.substr(0, idx);
}

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {

    // Use the console to output diagnostic information (console.log) and errors (console.error)
    // This line of code will only be executed once when your extension is activated
    console.log('Congratulations, your extension "mruby-plato" is now active!');

    // The command has been defined in the package.json file
    // Now provide the implementation of the command with  registerCommand
    // The commandId parameter must match the command field in package.json
    // let disposable = vscode.commands.registerCommand('extension.sayHello', () => {
    //     // The code you place here will be executed every time your command is executed

    //     // Display a message box to the user
    //     vscode.window.showInformationMessage('Hello World!');
    // });
    // context.subscriptions.push(disposable);

    let buildApp = vscode.commands.registerCommand('extension.buildApp', () => {
        let base = getAppPath();
        var action = 'rake -f ' + base + '/Rakefile'
        // vscode.window.showInformationMessage(action);
        executeCommand(action, 'Plato');
    });
    context.subscriptions.push(buildApp);

    let writeApp = vscode.commands.registerCommand('extension.writeApp', () => {
        let base = getAppPath();
        var action = 'ruby ' + base + '/../.plato/tools/mrbwriter.rb ' + base
        // vscode.window.showInformationMessage(action);
        executeCommand(action, 'Plato');
    });
    context.subscriptions.push(writeApp);
}

// this method is called when your extension is deactivated
export function deactivate() {
}