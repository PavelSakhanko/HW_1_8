//
//  CameraView.swift
//  HW_1_8
//
//  Created by Pavel Sakhanko on 18.04.21.
//

import SwiftUI

struct CameraView: View {

    @StateObject var model = CameraViewModel()

    var body: some View {
        GeometryReader { reader in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                VStack {
                    CameraPreview(session: model.session)
                    .onAppear {
                        model.configure()
                    }
                }
            }
        }
    }
}
