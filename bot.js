const {
    default: makeWASocket,
    useMultiFileAuthState,
    DisconnectReason
} = require("@whiskeysockets/baileys")

const qrcode = require("qrcode-terminal")

async function startBot() {
    const { state, saveCreds } = await useMultiFileAuthState('./auth')

    const sock = makeWASocket({
        auth: state,
        browser: ["SaraswathiApp", "Chrome", "1.0.0"]
    })

    // IMPORTANT: Show QR Code Manually
    sock.ev.on("connection.update", (update) => {
        const { connection, qr } = update

        if (qr) {
            console.log("SCAN THIS QR CODE:")
            qrcode.generate(qr, { small: true })
        }

        if (connection === "open") {
            console.log("WhatsApp Connected Successfully! 🎉")
        }

        if (connection === "close") {
            console.log("Connection closed. Reconnecting...")
            startBot()
        }
    })

    sock.ev.on('creds.update', saveCreds)

    // SEND OTP FUNCTION
    global.sendOTP = async (number, otp) => {
        const chatId = number + "@s.whatsapp.net"
        const msg = `Your login OTP from Saraswathi Tiffins:\n\n*${otp}*\n\nValid for 5 minutes.`
        await sock.sendMessage(chatId, { text: msg })
    }
}

startBot()
