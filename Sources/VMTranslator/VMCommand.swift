//
//  VMCommand.swift
//  
//
//  Created by Evgeniy Zabolotniy on 07.04.2023.
//

enum VMCommand {
  case stack(Stack)
  case arithmetic(Arithmetic)
  case controlFlow(ControlFlow)
  case function(Function)
}

extension VMCommand {
  enum Stack {
    case push(fromSegment: MemorySegment, index: Int)
    case pop(toSegment: MemorySegment, index: Int)
  }

  enum Arithmetic: String {
    case add
    case sub
    case neg
    case eq
    case gt
    case lt
    case and
    case or
    case not
  }

  enum ControlFlow {
    case label(String)
    case goTo(String)
    case ifGoTo(String)
  }

  enum Function {
    case declaration(name: String, numberOfLocalVariables: Int)
    case call(name: String, numberOfArguments: Int)
    case `return`
  }
}
