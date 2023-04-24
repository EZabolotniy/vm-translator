//
//  VMTranslator.swift
//
//
//  Created by Evgeniy Zabolotniy on 05.04.2023.
//

import Files

struct VMTranslator {
  private init() {}
}

extension VMTranslator {
  static func translateFile(at path: String, into fileWriter: FileLineWriter) throws {
    guard let fileName = path.split(separator: "/").last?.split(separator: ".").first,
          let lines = FileLineReader.readLines(path: path) else {
      throw Error.failedToOpenFile(path)
    }
    var linesCount = 0
    for line in lines {
      if let command = try parse(line: line) {
        let assemblyCode = command.toAssemblyCode(fileName: String(fileName), lineNumber: linesCount)
        fileWriter.writeLine(assemblyCode)
        linesCount += 1
      }
    }
  }
}

extension VMTranslator {
  enum Error: Swift.Error {
    case failedToOpenFile(_ path: String)
  }
}
