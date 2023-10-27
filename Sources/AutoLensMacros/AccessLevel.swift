import SwiftSyntax

enum AccessLevel: String {
    case `internal`
    case `private`
    case `fileprivate`
    case `public`
    case open
}

extension AccessLevel {
    static func create(withModifier modifier: DeclModifierSyntax) -> AccessLevel {
        switch modifier.name.text {
        case AccessLevel.public.rawValue:
            .public
        case AccessLevel.private.rawValue:
            .private
        case AccessLevel.fileprivate.rawValue:
            .fileprivate
        case AccessLevel.internal.rawValue:
            .internal
        case AccessLevel.open.rawValue:
            .open
        default:
            .internal
        }
    }

    static var `default` = AccessLevel.internal

    var declModifierSyntax: DeclModifierSyntax {
        switch self {
        case .public:
            DeclModifierSyntax(name: .keyword(.public))
        case .private:
            DeclModifierSyntax(name: .keyword(.private))
        case .fileprivate:
            DeclModifierSyntax(name: .keyword(.fileprivate))
        case .internal:
            DeclModifierSyntax(name: .keyword(.internal))
        case .open:
            DeclModifierSyntax(name: .keyword(.open))
        }
    }
}
