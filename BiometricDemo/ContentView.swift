import SwiftUI

struct ContentView: View {
    private let standardPadding: CGFloat = 8.0

    @ObservedObject private var viewModel = BiometricsViewModel()
    @State private var shouldGoToLoggedInView = false

    private var securedContentBorderColor: Color {
        return viewModel.isBiometricLoginEnabled ? .blue : .gray
    }

    private var headerText: AnyView {
        AnyView (
            Text("BioMetricDemo App")
                .font(.headline)
                .fontWeight(.bold)
                .padding(.top, 4 * standardPadding)
        )
    }

    private var infoText: AnyView {
        AnyView (
            Text(viewModel.informationText)
                .padding(
                    .all,
                    standardPadding
                )
        )
    }

    private var noBioAuthButton: AnyView {
        AnyView (
            Button(action: moveToNewScreen) {
                Text("Go without BioMetric Auth")
                    .padding(.all, standardPadding)
                    .border(/*@START_MENU_TOKEN@*/Color.blue/*@END_MENU_TOKEN@*/, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
            .opacity(
                viewModel.isBiometricLoginEnabled ? 0 : 1
            )
        )
    }

    private var goToSettingsButton: AnyView {
        AnyView (
            Button(action: goTosettings) {
                Text("Go to Settings")
                    .padding(.all, standardPadding)
                    .border(/*@START_MENU_TOKEN@*/Color.blue/*@END_MENU_TOKEN@*/, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }
            .opacity(
                viewModel.isSettingsButtonHidden ? 0 : 1
            )
        )
    }

    @State private var showingAlert = false

    private var accessSecureContentButton: AnyView {
        AnyView (
            Button(action: {
                self.showingAlert = true
            }) {
                Text("Access Secured Content")
                    .padding(.all, standardPadding)
                    .border(
                        securedContentBorderColor,
                        width: 1
                    )
                    .disabled(!viewModel.isBiometricLoginEnabled)
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Face ID Prompt"),
                    message: Text("Press contimue to use Face ID"),
                    primaryButton: .default(Text("Continue"), action: performBiometricLogin),
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
            .onAppear { print("Button appeared") }
        )
    }

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(
                    "",
                    destination: LoggedInView(),
                    isActive: $shouldGoToLoggedInView
                )
                headerText
                Spacer()
                    .frame(height: 100.0)
                accessSecureContentButton
                Spacer()
                noBioAuthButton
                Spacer()
                infoText
                goToSettingsButton
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }

    private func performBiometricLogin () {
        self.viewModel.authenticateUser {
            switch $0 {
            case .success:
                self.moveToNewScreen()

            case .failure(let error):
                print(error)
            }
        }
    }

    private func moveToNewScreen () {
        shouldGoToLoggedInView = true
    }

    private func goTosettings () {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { _ in })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
