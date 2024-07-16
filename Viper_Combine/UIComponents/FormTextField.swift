//
//  FormTextField.swift
//  Viper_Combine
//
//  Created by Akel Barbosa on 5/07/24.
//

import Foundation
import UIKit
import Combine

enum TextFieldType {
    case email
    case normal
    case password
}

class FormTextField: UIView, UITextFieldDelegate {

    private let textField = CustomTextField()
    private let errorLabel = UILabel()
    private let togglePasswordButton = UIButton(type: .custom)
    private var heightConstraint: NSLayoutConstraint?
    
    private var cancellables = Set<AnyCancellable>()
    var textPublisher = PassthroughSubject<String?, Never>()
    var errorMessage = PassthroughSubject<String?, Never>()
    
    var text: String? {
        return textField.text
    }

    var padding: UIEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5) {
        didSet {
            textField.padding = padding
        }
    }

    var font: UIFont = UIFont.systemFont(ofSize: 16) {
        didSet {
            textField.font = font
        }
    }

    var textColor: UIColor = .label {
        didSet {
            textField.textColor = textColor
        }
    }

    var borderWidth: CGFloat = 1.0 {
        didSet {
            textField.layer.borderWidth = borderWidth
        }
    }

    var borderColor: UIColor = .black {
        didSet {
            textField.layer.borderColor = borderColor.cgColor
        }
    }
    

    var errorFont: UIFont = UIFont.preferredFont(forTextStyle: .caption1) {
        didSet {
            errorLabel.font = errorFont
        }
    }

    init(type: TextFieldType, placeholder: String, viewHeight: CGFloat = 50.0, errorFont: UIFont = UIFont.preferredFont(forTextStyle: .caption1)) {
        super.init(frame: .zero)
        setupUI(viewHeight: viewHeight, errorFont: errorFont)
        configure(type: type, placeholder: placeholder)
        setupBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(viewHeight: CGFloat, errorFont: UIFont) {
        // TextField
        textField.layer.borderWidth = borderWidth
        textField.layer.borderColor = borderColor.cgColor
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.layer.cornerRadius = 5.0 // Default corner radius
        textField.backgroundColor = .secondarySystemGroupedBackground
        textField.padding = padding
        textField.delegate = self
        textField.heightAnchor.constraint(equalToConstant: viewHeight).isActive = true
        
        // Error Label
        errorLabel.textColor = .red
        errorLabel.font = errorFont
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        
        // StackView
        let stackView = UIStackView(arrangedSubviews: [textField, errorLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

    }


    private func configure(type: TextFieldType, placeholder: String) {
        textField.placeholder = placeholder
        textField.font = font
        textField.textColor = textColor
        
        switch type {
        case .email:
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.rightView = nil
            textField.rightViewMode = .never
        case .normal:
            textField.autocapitalizationType = .words
            textField.autocorrectionType = .yes
            textField.rightView = nil
            textField.rightViewMode = .never
        case .password:
            textField.isSecureTextEntry = true
            configurePasswordField()
        }
    }

    private func configurePasswordField() {
        textField.rightView = togglePasswordButton
        textField.rightViewMode = .always
        togglePasswordButton.setImage(UIImage(systemName: "eye"), for: .normal)
        togglePasswordButton.setImage(UIImage(systemName: "eye.slash"), for: .selected)
        togglePasswordButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        togglePasswordButton.tintColor = .systemGray // Set default tint color
        togglePasswordButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30) // Set size of the button
    }

    @objc private func togglePasswordVisibility() {
        textField.isSecureTextEntry.toggle()
        togglePasswordButton.isSelected.toggle()
    }

    func showError(message: String = "Invalid input") {
        errorLabel.text = message
        errorLabel.isHidden = false
    }

    func hideError() {
        errorLabel.text = nil
        errorLabel.isHidden = true
    }
    
    private func setupBindings() {
        errorMessage
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                if let message = message, !message.isEmpty {
                    self?.errorLabel.text = message
                    self?.errorLabel.isHidden = false
                } else {
                    self?.errorLabel.isHidden = true
                }
            }
            .store(in: &cancellables)
        
        textPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                    self?.errorLabel.isHidden = true
            }
            .store(in: &cancellables)
    }
    
    // UITextFieldDelegate Methods
    func textFieldDidBeginEditing(_ textField: UITextField) {
        errorMessage.send(nil)
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        textPublisher.send(textField.text)
    }
}

private class CustomTextField: UITextField {
    var padding: UIEdgeInsets = .zero
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }
    
    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        guard let rightView = rightView else { return .zero }
        let width = rightView.frame.width
        let height = rightView.frame.height
        let x = bounds.width - width - padding.right
        let y = (bounds.height - height) / 2
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
