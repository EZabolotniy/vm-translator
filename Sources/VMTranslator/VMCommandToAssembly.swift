//
//  VMCommandToAssembly.swift
//  
//
//  Created by Evgeniy Zabolotniy on 09.04.2023.
//

extension VMCommand {
  func toAssemblyCode(fileName: String, lineNumber: Int) -> String {
    switch self {
    case let .stack(command):
      switch command {
      case let .push(fromSegment: memorySegment, index: index):
        let comment = "// push \(memorySegment) \(index)\n"
        let setupDRegister: String
        switch memorySegment {
        case .constant:
          setupDRegister = """
            @\(index)
            D=A

            """
        case .static:
          setupDRegister = """
          @\(fileName).\(index)
          D=M

          """
        case .pointer, .temp:
          setupDRegister = """
            @\(memorySegment.RAMAddress + index)
            D=M

            """
        case .argument, .local, .this, .that:
          setupDRegister = """
            @\(index)
            D=A
            @\(memorySegment.RAMAddress)
            A=D+M
            D=M

            """
        }
        return comment + setupDRegister + pushDRegisterToStack
      case let .pop(toSegment: memorySegment, index: index):
        let comment = "// pop \(memorySegment) \(index)\n"
        let command: String
        switch memorySegment {
        case .constant:
          fatalError("pop \(memorySegment) \(index) – Pop to constant memory segment is impossible")
        case .static:
          command = """
            @SP
            A=M-1
            D=M
            @\(fileName).\(index)
            M=D
            @SP
            M=M-1

            """
        case .pointer, .temp:
          command = """
            @\(memorySegment.RAMAddress + index)
            D=A
            @address
            M=D
            @SP
            A=M-1
            D=M
            @address
            A=M
            M=D
            @SP
            M=M-1

            """
        case .argument, .local, .this, .that:
          command = """
            @SP
            A=M-1
            D=M
            @top
            M=D
            @\(index)
            D=A
            @\(memorySegment.RAMAddress)
            D=D+M
            @address
            M=D
            @top
            D=M
            @address
            A=M
            M=D
            @SP
            M=M-1

            """
        }
        return comment + command
      }

    case let .arithmetic(command):
      switch command {
      case .add:
        return "// add\n" + popToDRegister + """
        @SP
        A=M-1
        M=D+M

        """
      case .sub:
        return "// sub\n" + popToDRegister + """
        @SP
        A=M-1
        M=M-D

        """
      case .eq:
        return "// eq\n" + popToDRegister + """
        @SP
        A=M-1
        D=M-D
        @EQ_EQUAL\(lineNumber)
        D;JEQ
        @SP
        A=M-1
        M=0
        @EQ_END\(lineNumber)
        0;JMP
        (EQ_EQUAL\(lineNumber))
        @SP
        A=M-1
        M=-1
        (EQ_END\(lineNumber))

        """
      case .gt:
        return "// gt\n" + popToDRegister + """
        @SP
        A=M-1
        D=M-D
        @GT_GREATER\(lineNumber)
        D;JGT
        @SP
        A=M-1
        M=0
        @GT_END\(lineNumber)
        0;JMP
        (GT_GREATER\(lineNumber))
        @SP
        A=M-1
        M=-1
        (GT_END\(lineNumber))

        """
      case .lt:
        return "// lt\n" + popToDRegister + """
        @SP
        A=M-1
        D=M-D
        @LT_LOWER\(lineNumber)
        D;JLT
        @SP
        A=M-1
        M=0
        @LT_END\(lineNumber)
        0;JMP
        (LT_LOWER\(lineNumber))
        @SP
        A=M-1
        M=-1
        (LT_END\(lineNumber))

        """
      case .and:
        return "// and\n" + popToDRegister + """
        @SP
        A=M-1
        M=D&M

        """
      case .or:
        return "// or\n" + popToDRegister + """
        @SP
        A=M-1
        M=D|M

        """
      case .neg:
        return "// neg\n" + """
        @SP
        A=M-1
        M=-M

        """
      case .not:
        return "// not\n" + """
        @SP
        A=M-1
        M=!M

        """
      }

    case let .controlFlow(command):
      switch command {
      case let .label(label):
        return "(\(label.uppercased()))"
      case let .goTo(label):
        return "// goto \(label)\n" + """
        @\(label)
        0;JMP

        """
      case let .ifGoTo(label):
        // if stack’s topmost element not zero, jump to the specified destination;
        return "// if-goto \(label)\n" + popToDRegister + """
        @\(label)
        D;JNE

        """
      }

    case let .function(command):
      switch command {
      case let .declaration(name, numberOfLocalVariables):
        return "// function \(name) \(numberOfLocalVariables)\n" +
          "(\(name))\n" +
          [VMCommand](
            repeating: VMCommand.stack(VMCommand.Stack.push(fromSegment: .constant, index: 0)),
            count: numberOfLocalVariables
          ).lazy.map { $0.toAssemblyCode(fileName: fileName, lineNumber: lineNumber) }.joined()
      case let .call(name, numberOfArguments):
        let returnLabel = "return-\(name)$\(lineNumber)"
        return "// call \(name) \(numberOfArguments)\n" +
          """
          // push \(returnLabel)
          @\(returnLabel)
          D=A
          \(pushDRegisterToStack)
          """ +
          pushLabelValueToStack("LCL") +
          pushLabelValueToStack("ARG") +
          pushLabelValueToStack("THIS") +
          pushLabelValueToStack("THAT") +
          """
          // ARG = SP - numberOfArguments - 5
          @SP
          D=M
          @\(numberOfArguments)
          D=D-A
          @5
          D=D-A
          @ARG
          M=D
          // LCL = SP
          @SP
          D=M
          @LCL
          M=D
          // goto \(name)
          @\(name)
          0;JMP
          (\(returnLabel))

          """
      case .return:
        return """
          // FRAME = LCL // FRAME is a tmp variable (R13)
          @LCL
          D=M
          @R13
          M=D
          // RET = *(FRAME - 5) // RET is a tmp variable (R14)
          @R13
          D=M
          @5
          D=D-A
          A=D
          D=M
          @R14
          M=D
          // *ARG = pop() // Reposition the return value for the caller
          @SP
          A=M-1
          D=M
          @ARG
          A=M
          M=D
          // SP = ARG + 1
          @ARG
          D=M+1
          @SP
          M=D
          // THAT = *(FRAME - 1)
          @R13
          D=M-1
          A=D
          D=M
          @THAT
          M=D
          // THIS = *(FRAME - 2)
          @R13
          D=M
          @2
          D=D-A
          A=D
          D=M
          @THIS
          M=D
          // ARG = *(FRAME - 3)
          @R13
          D=M
          @3
          D=D-A
          A=D
          D=M
          @ARG
          M=D
          // LCL = *(FRAME - 4)
          @R13
          D=M
          @4
          D=D-A
          A=D
          D=M
          @LCL
          M=D
          // goto RET
          @R14
          A=M
          0;JMP

          """
      }
    }
  }
}

let pushDRegisterToStack = """
  @SP
  A=M
  M=D
  @SP
  M=M+1

  """

private var popToDRegister = """
  @SP
  A=M-1
  D=M
  @SP
  M=M-1

  """

private func pushLabelValueToStack(_ label: String) -> String {
  """
  // push \(label)
  @\(label)
  D=M
  \(pushDRegisterToStack)
  """
}
