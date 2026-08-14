// OpenFreebuds/Views/BuyMeCoffee/BuyMeCoffeeView.swift

import SwiftUI
import OFBCore
import CoreImage.CIFilterBuiltins

struct BuyMeCoffeeView: View {
    @State private var copied = false

    private let cryptoAddress = "0xe26c0DC422EF744816Ca3B2d210e6214fdC4e18E"
    private let cryptoNetwork = "BEP20 (BSC – Binance Smart Chain)"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Banner
                VStack(spacing: 12) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                        .padding(16)
                        .background(Circle().fill(Color.orange.opacity(0.15)))

                    Text(L10n.tr("buy_me_coffee_title"))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(L10n.tr("buy_me_coffee_desc"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(24)
                .frame(maxWidth: .infinity)

                // Support Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.title3)
                        Text("Support FreebudsMAC Development")
                            .font(.headline)
                    }

                    Text("FreebudsMAC là ứng dụng mã nguồn mở hoàn toàn miễn phí mang trải nghiệm điều khiển tai nghe HUAWEI & HONOR mượt mà lên macOS.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            if let url = URL(string: "https://ko-fi.com/X4P324ZPZ3") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "cup.and.saucer.fill")
                                Text("Support on Ko-fi")
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(red: 1.0, green: 0.37, blue: 0.36))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            if let url = URL(string: "https://github.com/devduong") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Star on GitHub")
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))

                // Crypto Donation Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "bitcoinsign.circle.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                        Text("Donate via Crypto")
                            .font(.headline)
                        Spacer()
                        Text("BEP20")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.orange.opacity(0.15)))
                            .foregroundColor(.orange)
                    }

                    HStack(spacing: 20) {
                        if let qrImage = generateQRCode(from: cryptoAddress) {
                            Image(nsImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 140, height: 140)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Network")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text(cryptoNetwork)
                                    .font(.system(size: 12, weight: .medium))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Wallet Address")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.secondary)
                                Text(cryptoAddress)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .textSelection(.enabled)
                                    .foregroundColor(.primary)
                            }

                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(cryptoAddress, forType: .string)
                                copied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copied = false
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                                    Text(copied ? "Copied!" : "Copy Address")
                                        .fontWeight(.semibold)
                                }
                                .font(.caption)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(copied ? Color.green : Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)

                            Text("Scan the QR code or copy the address to send any BEP20 token (USDT, BNB, BUSD, etc.)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
            }
            .padding(20)
        }
    }

    // MARK: - QR Code Generator

    private func generateQRCode(from string: String) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let scale = 10.0
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }

        return NSImage(cgImage: cgImage, size: NSSize(width: transformed.extent.width, height: transformed.extent.height))
    }
}
