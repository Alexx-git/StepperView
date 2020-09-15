//
//  ViewController.swift
//  BankStepper
//
//  Created by Vlad on 9/3/20.
//  Copyright © 2020 Alexx. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let stepper = BankStepper.StepperView()
        view.addSubview(stepper)
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        stepper.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        stepper.plusImage = UIImage(named: "plus_circle")
        stepper.minusImage = UIImage(named: "minus_circle")
        stepper.buttonSize = CGSize(width: 40, height: 40)
        stepper.textFieldWidth = 100.0
        stepper.limits = (0, 200)
        stepper.step = 10
        stepper.validator = Validator(with: stepper)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        print("self: \(self)")
    }

}

