//
//  main.swift
//  
//
//  Created by Evgeniy Zabolotniy on 06.04.2023.
//

import Foundation
import Files

guard let fileWriter = FileLineWriter.createFile(atPath: outputFilePath) else {
  writeToStdErr("Can not write to file at path: \(outputFilePath)!\n")
  exit(EXIT_FAILURE)
}

do {
  fileWriter.writeLine(
    // Bootstrap code
    """
    // SP=261
    @261
    D=A
    @SP
    M=D
    // call Sys.init
    @Sys.init
    0;JMP

    """
  )
  try inputFilePaths().forEach {
    try VMTranslator.translateFile(at: $0, into: fileWriter)
  }
} catch {
  writeToStdErr("Error: \(error)!\n")
  exit(EXIT_FAILURE)
}


// MARK: - Utils

private var inputFileOrDir: String {
  guard let fileName = CommandLine.arguments.dropFirst().first else {
    writeToStdErr("No arguments: \(CommandLine.arguments)!\n")
    exit(EXIT_FAILURE)
  }
  return fileName
}

private func inputFilePaths() throws -> [String] {
  if inputFileOrDir.isVMFile {
    return [FileManager.default.currentDirectoryPath + "/" + inputFileOrDir]
  } else {
    let dirPath = FileManager.default.currentDirectoryPath + "/" + inputFileOrDir
    return try FileManager.default
      .contentsOfDirectory(atPath: dirPath)
      .filter(\.isVMFile)
      .map { dirPath + "/" + $0 }
  }
}

extension String {
  var isVMFile: Bool {
    hasSuffix(".vm")
  }
}

private var outputFilePath: String {
  guard let inputFileName = inputFileOrDir.split(separator: ".").first else {
    writeToStdErr("Invalid file name: \(inputFileOrDir)!\n")
    exit(EXIT_FAILURE)
  }
  let currentDirectory = FileManager.default.currentDirectoryPath
  return currentDirectory + "/" + inputFileName + ".asm"
}

private func writeToStdErr(_ str: String) {
  let handle = FileHandle.standardError
  if let data = str.data(using: .utf8) {
    handle.write(data)
  }
}
