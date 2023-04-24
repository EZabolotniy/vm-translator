//
//  Parser.swift
//  
//
//  Created by Evgeniy Zabolotniy on 05.04.2023.
//

import RemoveComments

enum ParsingError: Error {
  case invalidCommand(String)
  case invalidNumberOfArguments(String)
  case invalidArgumentType(String)
  case invalidMemorySegment(String)
  case invalidIndex(String)
}

func parse(line: String) throws -> VMCommand? {
  let noComments = line.removeComments()
  guard !noComments.isEmpty else {
    return nil
  }
  return try VMCommand(string: noComments)
}

extension VMCommand {
  fileprivate init(string: String) throws {
    if let stackCommand = try VMCommand.Stack(string: string) {
      self = .stack(stackCommand)
    } else if let arithmeticCommand = VMCommand.Arithmetic(rawValue: string) {
      self = .arithmetic(arithmeticCommand)
    } else if let controlFlowCommand = try VMCommand.ControlFlow(string: string) {
      self = .controlFlow(controlFlowCommand)
    } else if let functionCommand = try VMCommand.Function(string: string) {
      self = .function(functionCommand)
    } else {
      throw ParsingError.invalidCommand(string)
    }
  }
}

extension VMCommand.Stack {
  fileprivate init?(string: String) throws {
    let commandParts = string.split(separator: " ")
    guard let command = commandParts.first, VMCommand.Stack.CommandName.all.contains(String(command)) else {
      return nil
    }
    guard commandParts.count == 3 else {
      throw ParsingError.invalidNumberOfArguments(string)
    }
    guard let memorySegment = MemorySegment(rawValue: String(commandParts[1])) else {
      throw ParsingError.invalidMemorySegment(string)
    }
    guard let index = Int(String(commandParts[2])) else {
      throw ParsingError.invalidIndex(string)
    }
    switch command {
    case VMCommand.Stack.CommandName.push:
      self = .push(fromSegment: memorySegment, index: index)
    case VMCommand.Stack.CommandName.pop:
      self = .pop(toSegment: memorySegment, index: index)
    default:
      return nil
    }
  }
}

extension VMCommand.ControlFlow {
  fileprivate init?(string: String) throws {
    let commandParts = string.split(separator: " ")
    guard let command = commandParts.first, VMCommand.ControlFlow.CommandName.all.contains(String(command)) else {
      return nil
    }
    guard commandParts.count == 2 else {
      throw ParsingError.invalidNumberOfArguments(string)
    }
    switch command {
    case VMCommand.ControlFlow.CommandName.label:
      self = .label(String(commandParts[1]))
    case VMCommand.ControlFlow.CommandName.goTo:
      self = .goTo(String(commandParts[1]))
    case VMCommand.ControlFlow.CommandName.ifGoTo:
      self = .ifGoTo(String(commandParts[1]))
    default:
      return nil
    }
  }
}

extension VMCommand.Function {
  fileprivate init?(string: String) throws {
    let commandParts = string.split(separator: " ")
    guard let command = commandParts.first, VMCommand.Function.CommandName.all.contains(String(command)) else {
      return nil
    }
    switch command {
    case VMCommand.Function.CommandName.function:
      guard commandParts.count == 3 else {
        throw ParsingError.invalidNumberOfArguments(string)
      }
      guard let numberOfLocalVariables = Int(commandParts[2]) else {
        throw ParsingError.invalidArgumentType("\(string): \(commandParts[2])")
      }
      self = .declaration(name: String(commandParts[1]), numberOfLocalVariables: numberOfLocalVariables)
    case VMCommand.Function.CommandName.call:
      guard commandParts.count == 3 else {
        throw ParsingError.invalidNumberOfArguments(string)
      }
      guard let numberOfArguments = Int(commandParts[2]) else {
        throw ParsingError.invalidArgumentType("\(string): \(commandParts[2])")
      }
      self = .call(name: String(commandParts[1]), numberOfArguments: numberOfArguments)
    case VMCommand.Function.CommandName.return:
      self = .return
    default:
      return nil
    }
  }
}

extension VMCommand.Stack {
  fileprivate enum CommandName {
    static let push = "push"
    static let pop = "pop"
    static var all = [push, pop]
  }
}

extension VMCommand.ControlFlow {
  fileprivate enum CommandName {
    static let label = "label"
    static let goTo = "goto"
    static let ifGoTo = "if-goto"
    static var all = [label, goTo, ifGoTo]
  }
}

extension VMCommand.Function {
  fileprivate enum CommandName {
    static let function = "function"
    static let call = "call"
    static let `return` = "return"
    static var all = [function, call, `return`]
  }
}
