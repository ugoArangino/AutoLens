import SwiftSyntax

extension VariableDeclSyntax {
    var readAccess: AccessLevel {
        return modifiers
            .filter {
                $0.detail == nil
            }
            .first
            .flatMap(AccessLevel.create)
            ?? .default
    }

    var writeAccess: AccessLevel {
        return modifiers
            .filter {
                $0.detail?.detail.description
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    == "set"
            }
            .first
            .flatMap(AccessLevel.create)
            ?? readAccess
    }

    var isStatic: Bool {
        return modifiers
            .contains {
                $0.name.text == "static"
            }
    }

    var isComputed: Bool {
        bindings.first?.accessorBlock != nil
    }

    var isStored: Bool {
        !isComputed && !isStatic
    }
}
