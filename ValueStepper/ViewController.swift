//
//  ViewController.swift
//  ValueStepper
//
//  Created by Alexx on 9/3/20.
//  Copyright © 2020 Alexx. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let stepper = ValueStepper.StepperView()
        view.addSubview(stepper)
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        stepper.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stepper.plusImage = UIImage(named: "plus_circle")
        stepper.minusImage = UIImage(named: "minus_circle")
        stepper.buttonsSize = CGSize(width: 40, height: 40)
        stepper.font = UIFont.init(name: stepper.font.fontName, size: 20.0)!
        stepper.textColor = .red
        stepper.limits = (0, nil)
        stepper.step = 0.01
        stepper.value = -20.0
        stepper.spacing = 50.0
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("self: \(self)")
    }

}

