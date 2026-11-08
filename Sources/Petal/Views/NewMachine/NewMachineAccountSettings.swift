import Luminare
import PetalCore
import SwiftUI

struct NewMachineAccountSettings: View {
    @Binding var account: GuestAccount
    @Binding var confirmPassword: String

    var body: some View {
        PetalSection("Account") {
            LuminareCompose("Full name") {
                PetalTextField(text: $account.fullName)
            }

            LuminareCompose("Username") {
                PetalTextField(text: $account.username)
            }

            LuminareCompose("Password") {
                PetalSecureField(text: $account.password)
            }

            LuminareCompose("Confirm") {
                PetalSecureField(text: $confirmPassword)
            }

            if !confirmPassword.isEmpty && account.password != confirmPassword {
                LuminareCompose {
                    Text("Passwords don’t match.")
                        .font(PetalText.caption)
                        .foregroundStyle(.red)
                } label: {
                    EmptyView()
                }
            }
        }
    }
}
