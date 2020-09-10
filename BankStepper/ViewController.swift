//
//  ViewController.swift
//  BankStepper
//
//  Created by Vlad on 9/3/20.
//  Copyright © 2020 Alexx. All rights reserved.
//

import UIKit
import PureLayout

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let stepper = BankStepper.StepperView()
        view.addSubview(stepper)
        stepper.autoCenterInSuperview()
    }


}

