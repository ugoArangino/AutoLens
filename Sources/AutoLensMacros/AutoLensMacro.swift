import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct AutoLens: MemberMacro {
    private enum Constant {
        static let lensIdentifier = "Lens"
        static let orginalIdentifier = "orginal"
    }

    private static func createSetterArgument(
        forVariable arugmentVariable: VariableDeclSyntax,
        inLensVariable lensVariable: VariableDeclSyntax,
        lensVariableName _: TokenSyntax,
        withVariables allVariables: [VariableDeclSyntax]
    ) -> LabeledExprSyntax? {
        guard
            let binding = arugmentVariable.bindings.first,
            let argumentName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
        else {
            return nil
        }

        let isLastVariable = allVariables.last == arugmentVariable
        let trailingComma: TokenSyntax? = isLastVariable ? nil : .commaToken()

        return if arugmentVariable == lensVariable {
            .init(
                label: argumentName,
                colon: .colonToken(),
                expression: DeclReferenceExprSyntax(baseName: argumentName),
                trailingComma: trailingComma
            )
        } else {
            .init(
                label: argumentName,
                colon: .colonToken(),
                expression: DeclReferenceExprSyntax(baseName: "\(raw: Constant.orginalIdentifier).\(argumentName)"),
                trailingComma: trailingComma
            )
        }
    }

    private static func createLens(
        for lensVariable: VariableDeclSyntax,
        struct structName: String,
        withVariables allVariables: [VariableDeclSyntax]
    ) -> DeclSyntax? {
        guard
            let binding = lensVariable.bindings.first,
            let variableName = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier,
            let baseType = binding.typeAnnotation?.type
        else {
            return nil
        }

        let name = variableName.text + Constant.lensIdentifier

        let variable = VariableDeclSyntax(
            modifiers: [
                lensVariable.writeAccess.declModifierSyntax,
                DeclModifierSyntax(name: .keyword(SwiftSyntax.Keyword.static)),
            ],
            SwiftSyntax.Keyword.let,
            name: PatternSyntax(IdentifierPatternSyntax(identifier: .identifier(name))),
            initializer: .init(
                value: FunctionCallExprSyntax(
                    calledExpression: GenericSpecializationExprSyntax(
                        expression: DeclReferenceExprSyntax(baseName: .identifier(Constant.lensIdentifier)),
                        genericArgumentClause: GenericArgumentClauseSyntax(
                            leftAngle: .leftAngleToken(),
                            arguments: [
                                GenericArgumentSyntax(
                                    argument: IdentifierTypeSyntax(name: .identifier(structName)),
                                    trailingComma: .commaToken()
                                ),
                                GenericArgumentSyntax(
                                    argument: baseType
                                ),
                            ],
                            rightAngle: .rightAngleToken()
                        )
                    ),
                    leftParen: .leftParenToken(),
                    arguments: LabeledExprListSyntax([
                        LabeledExprSyntax(
                            leadingTrivia: .newline,
                            label: .identifier("get"),
                            colon: .colonToken(),
                            expression: ClosureExprSyntax(
                                statements: CodeBlockItemListSyntax([
                                    CodeBlockItemSyntax(
                                        item: .init(
                                            MemberAccessExprSyntax(
                                                base: DeclReferenceExprSyntax(baseName: .dollarIdentifier("$0")),
                                                name: variableName
                                            )
                                        )
                                    ),
                                ])
                            ),
                            trailingComma: .commaToken()
                        ),
                        LabeledExprSyntax(
                            leadingTrivia: .newline,
                            label: .identifier("set"),
                            colon: .colonToken(),
                            expression: ClosureExprSyntax(
                                signature: ClosureSignatureSyntax(
                                    parameterClause: .init(ClosureShorthandParameterListSyntax([
                                        ClosureShorthandParameterSyntax(
                                            name: variableName,
                                            trailingComma: .commaToken()
                                        ),
                                        .init(name: .identifier(Constant.orginalIdentifier)),
                                    ])),
                                    inKeyword: .keyword(.in)
                                ),
                                statements: CodeBlockItemListSyntax([
                                    CodeBlockItemSyntax(
                                        item: .init(
                                            FunctionCallExprSyntax(
                                                calledExpression: DeclReferenceExprSyntax(baseName: .identifier(structName)),
                                                leftParen: .leftParenToken(),
                                                arguments: .init(
                                                    allVariables
                                                        .compactMap { arugmentExpr in
                                                            createSetterArgument(forVariable: arugmentExpr, inLensVariable: lensVariable, lensVariableName: variableName, withVariables: allVariables)
                                                        }
                                                ),
                                                rightParen: .rightParenToken()
                                            )
                                        )
                                    ),
                                ])
                            ),
                            trailingTrivia: .newline
                        ),
                    ]),
                    rightParen: .rightParenToken()
                )
            )
        )

        return DeclSyntax(variable)
    }

    public static func expansion(
        of _: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            return .init()
        }

        let structName = structDecl.name.text
        let members = structDecl.memberBlock.members
        let variableDecls = members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter(\.isStored)

        return variableDecls
            .compactMap { variableDecl in
                createLens(for: variableDecl, struct: structName, withVariables: variableDecls)
            }
    }
}

@main
struct InventoryMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AutoLens.self,
    ]
}
