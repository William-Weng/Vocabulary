//
//  PaletteViewController.swift
//  Vocabulary
//
//  Created by William.Weng on 2023/9/8.
//

import UIKit

// MARK: - 調色盤
final class PaletteViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        palettePicker()
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension PaletteViewController: UIColorPickerViewControllerDelegate {
    
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        
        let selectedCGColor = viewController.selectedColor.cgColor
        
        myPrint(selectedCGColor.colorSpace)
        myPrint(selectedCGColor._hexString())
    }
}

// MARK: - 小工具
private extension PaletteViewController {
    
    func palettePicker() {
        
        let colorPicker = UIColorPickerViewController._build(delegate: self)
        colorPicker.supportsAlpha = false
        
        present(colorPicker, animated: true)
    }
}
