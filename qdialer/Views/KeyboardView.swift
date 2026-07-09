import SwiftUI
import UIKit

// MARK: - SwiftUI wrapper — pass searchText via Binding, UIKit handles the rest

struct KeyboardView: UIViewRepresentable {
    @Binding var searchText: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let kb = KeyboardUIView()
        kb.searchTextBinding = _searchText
        kb.setContentHuggingPriority(.required, for: .vertical)
        kb.setContentCompressionResistancePriority(.required, for: .vertical)
        return kb
    }

    func updateUIView(_ view: UIView, context: Context) {}
}

// MARK: - Coordinator

extension KeyboardView {
    @MainActor
    final class Coordinator {}
}

// MARK: - UIKit keyboard — created once, never recreated

@MainActor
final class KeyboardUIView: UIStackView {
    var searchTextBinding: Binding<String>?

    init() {
        super.init(frame: .zero)
        build()
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Explicit size so SwiftUI doesn't squeeze the UIKit view to zero.
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric,
               height: 8 + 38 + 4 + 1 + 4 + 44 + 4 + 44 + 4 + 44 + 4 + 40 + 8)
    }

    private func build() {
        axis = .vertical
        spacing = 4
        alignment = .fill
        backgroundColor = UIColor(white: 0.10, alpha: 1)
        layoutMargins = UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6)
        isLayoutMarginsRelativeArrangement = true

        addRow(keys: ["1","2","3","4","5","6","7","8","9","0"], isNumber: true)

        let sep = UIView()
        sep.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
        addArrangedSubview(sep)

        addRow(keys: ["Q","W","E","R","T","Y","U","I","O","P"])
        addRow(keys: ["A","S","D","F","G","H","J","K","L"])
        addLastRow()
        addBottomRow()
    }

    private func addRow(keys: [String], isNumber: Bool = false) {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 4
        row.distribution = .fillEqually

        for key in keys {
            let btn = UIButton(type: .system)
            let letter = isNumber ? key : key.lowercased()
            btn.setTitle(key, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: isNumber ? 16 : 17, weight: isNumber ? .regular : .medium)
            btn.setTitleColor(isNumber ? .white.withAlphaComponent(0.85) : .white, for: .normal)
            btn.backgroundColor = isNumber ? UIColor(white: 0.21, alpha: 1) : UIColor(white: 0.26, alpha: 1)
            btn.layer.cornerRadius = isNumber ? 6 : 7
            btn.heightAnchor.constraint(equalToConstant: isNumber ? 38 : 44).isActive = true

            btn.addAction(UIAction { [weak self] _ in
                self?.searchTextBinding?.wrappedValue.append(letter)
            }, for: .touchUpInside)

            row.addArrangedSubview(btn)
        }
        addArrangedSubview(row)
    }

    private func addLastRow() {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 4
        row.distribution = .fillProportionally

        // Empty space where dial button would appear
        let dialSpacer = UIView()
        dialSpacer.widthAnchor.constraint(equalToConstant: 48).isActive = true
        row.addArrangedSubview(dialSpacer)

        for key in ["Z","X","C","V","B","N","M"] {
            let btn = UIButton(type: .system)
            btn.setTitle(key, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
            btn.setTitleColor(.white, for: .normal)
            btn.backgroundColor = UIColor(white: 0.26, alpha: 1)
            btn.layer.cornerRadius = 7
            btn.heightAnchor.constraint(equalToConstant: 44).isActive = true

            btn.addAction(UIAction { [weak self] _ in
                self?.searchTextBinding?.wrappedValue.append(key.lowercased())
            }, for: .touchUpInside)

            row.addArrangedSubview(btn)
        }

        // Backspace
        let bs = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 17)
        bs.setImage(UIImage(systemName: "delete.left.fill", withConfiguration: cfg), for: .normal)
        bs.tintColor = .white.withAlphaComponent(0.8)
        bs.backgroundColor = UIColor(white: 0.18, alpha: 1)
        bs.layer.cornerRadius = 8
        bs.widthAnchor.constraint(equalToConstant: 48).isActive = true
        bs.heightAnchor.constraint(equalToConstant: 44).isActive = true
        bs.addAction(UIAction { [weak self] _ in
            guard let s = self?.searchTextBinding else { return }
            if !s.wrappedValue.isEmpty { s.wrappedValue.removeLast() }
        }, for: .touchUpInside)
        row.addArrangedSubview(bs)

        addArrangedSubview(row)
    }

    private func addBottomRow() {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 4
        row.distribution = .fillProportionally

        // Clear button
        let clear = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        clear.setImage(UIImage(systemName: "xmark", withConfiguration: cfg), for: .normal)
        clear.tintColor = .white.withAlphaComponent(0.7)
        clear.backgroundColor = UIColor(white: 0.18, alpha: 1)
        clear.layer.cornerRadius = 7
        clear.widthAnchor.constraint(equalToConstant: 48).isActive = true
        clear.heightAnchor.constraint(equalToConstant: 40).isActive = true
        clear.addAction(UIAction { [weak self] _ in
            self?.searchTextBinding?.wrappedValue = ""
        }, for: .touchUpInside)
        row.addArrangedSubview(clear)

        // Space
        let space = UIButton(type: .system)
        space.setTitle("SPACE", for: .normal)
        space.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        space.setTitleColor(.white.withAlphaComponent(0.6), for: .normal)
        space.backgroundColor = UIColor(white: 0.15, alpha: 1)
        space.layer.cornerRadius = 7
        space.layer.borderWidth = 0.5
        space.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        space.heightAnchor.constraint(equalToConstant: 40).isActive = true
        space.setContentHuggingPriority(.defaultLow, for: .horizontal)
        space.addAction(UIAction { [weak self] _ in
            self?.searchTextBinding?.wrappedValue.append(" ")
        }, for: .touchUpInside)
        row.addArrangedSubview(space)

        // Trailing spacer matching clear button width
        let endSpacer = UIView()
        endSpacer.widthAnchor.constraint(equalToConstant: 48).isActive = true
        row.addArrangedSubview(endSpacer)

        addArrangedSubview(row)
    }
}
