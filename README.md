# Brewify – Blockchain Coffee Traceability (Truffle Edition)

End‑to‑end demo dApp untuk menelusuri batch kopi (NFT) dari panen hingga pengiriman. README ini memandu setup **Truffle + Ganache + Sepolia + Infura** serta integrasi **Next.js** frontend + **QR Code**.

---

## 0) MVP Scope (Minimum Viable Product)

1. **Kontrak** `CoffeeBatchNFT` (ERC‑721) dengan **status lifecycle**: `Harvested → Processed → Packed → Shipped → Delivered`.
2. **Migrasi** & **deploy** ke **Ganache** (lokal) dan **Sepolia** (testnet).
3. **Halaman verifikasi** di Next.js: scan **QR** → buka URL detail batch berdasarkan `tokenId`.
4. **Admin panel sederhana** untuk **mint** NFT + **update status**.

> Fitur opsional: Escrow sederhana & marketplace.

---

## 1) Framework: Truffle

* **Migrasi terstruktur** (migrations) cocok untuk tugas kampus & pembelajaran.
* Integrasi **Ganache** sangat mulus.
* Lebih sedikit konfigurasi untuk skenario dasar.

> Untuk pengujian lanjutan, Hardhat dapat dipertimbangkan di masa depan, namun implementasi proyek ini **berfokus penuh pada Truffle**.

---

## 2) Prasyarat

* Node.js ≥ 18
* Git, VS Code + ekstensi Solidity
* MetaMask
* **Ganache** (GUI/CLI)
* Akun **Infura** (untuk RPC Sepolia)

---

## 3) Struktur Proyek

```
brewify/
├─ contracts/                  # proyek Truffle (kontrak, migrasi, test)
│  ├─ contracts/               # *.sol (CoffeeBatchNFT.sol, Escrow.sol, ...)
│  ├─ migrations/              # file migrasi deploy
│  ├─ test/                    # unit tests
│  ├─ truffle-config.js        # konfigurasi network/compilers
│  ├─ .env                     # private keys & API keys
│  └─ package.json
├─ frontend/                   # Next.js dApp (wagmi/viem/ethers)
└─ README.md
```

**Apa yang “masuk ke contracts (Truffle)” & Ganache?**

* Folder **`contracts`** menyimpan source Solidity, script migrasi, konfigurasi jaringan (termasuk Ganache & Sepolia) dan testing.
* **Ganache** digunakan sebagai **node lokal** + **wallet development** (alamat & private key dummy) untuk **uji cepat** deploy & transaksi.

---

## 3.1) Instalasi & Setup

Clone repositori ini dan install dependensi untuk kedua bagian proyek.

1. **Install dependensi untuk Kontrak (Truffle):**

   ```bash
   cd brewify/contracts
   npm install
   ```

2. **Install dependensi untuk Frontend (Next.js):**

   ```bash
   cd ../frontend
   npm install
   ```

## 4) Setup Infura API Key

1. Buka [https://infura.io](https://infura.io) → **Create New Key** → pilih **Ethereum**
2. Catat **Project ID** (mis. `123abc...`)
3. Endpoint Sepolia: `https://sepolia.infura.io/v3/<Project_ID>`

Tambahkan ke `.env` (di folder `contracts/`):

```env
INFURA_API_KEY=123abc456def789...
```

Nanti dipakai di `truffle-config.js`.

---

## 5) Setup Kontrak (Truffle)

### Inisialisasi & Kompilasi

```bash
cd brewify/contracts
npx truffle init # hanya jika memulai dari awal
npx truffle compile
```

### Dependencies (Kontrak)

* **`truffle`**: Framework untuk compile, migrate, dan test.
* **`dotenv`**: Memuat variabel rahasia dari file `.env`.
* **`@truffle/hdwallet-provider`**: Provider yang menandatangani transaksi memakai **private key**.
* **`@openzeppelin/contracts`**: Kumpulan kontrak **audited** (ERC‑721, AccessControl, dll).

### Kontrak Utama `contracts/CoffeeBatchNFT.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CoffeeBatchNFT is ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    enum Status { Unknown, Harvested, Processed, Packed, Shipped, Delivered }
    mapping(uint256 => Status) public tokenStatus;
    uint256 private _nextId = 1;

    event BatchMinted(address indexed to, uint256 indexed tokenId, string uri);
    event StatusUpdated(uint256 indexed tokenId, Status newStatus);

    constructor() ERC721("Brewify Coffee Batch", "BREW") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }
    function mintBatch(address to, string memory uri) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = _nextId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        tokenStatus[tokenId] = Status.Harvested;
        emit BatchMinted(to, tokenId, uri);
    }
    function updateStatus(uint256 tokenId, Status newStatus) external onlyRole(MINTER_ROLE) {
        require(_exists(tokenId), "Nonexistent token");
        tokenStatus[tokenId] = newStatus;
        emit StatusUpdated(tokenId, newStatus);
    }
    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721URIStorage, AccessControl) returns (bool)
    { return super.supportsInterface(interfaceId); }
}
```

### Migrasi `migrations/1_deploy_contracts.js`

```js
const CoffeeBatchNFT = artifacts.require("CoffeeBatchNFT");
module.exports = function (deployer) {
  deployer.deploy(CoffeeBatchNFT);
};
```

### Konfigurasi Jaringan `truffle-config.js`

```js
require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');
const { PRIVATE_KEY_GANACHE, PRIVATE_KEY_SEPOLIA, INFURA_API_KEY } = process.env;

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
    },
    sepolia: {
      provider: () => new HDWalletProvider([
        PRIVATE_KEY_SEPOLIA
      ], `https://sepolia.infura.io/v3/${INFURA_API_KEY}`),
      network_id: 11155111,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
  },
  compilers: { solc: { version: "0.8.20" } },
};
```

### .env contoh

```env
PRIVATE_KEY_GANACHE=0x<64 hex>
PRIVATE_KEY_SEPOLIA=0x<64 hex>
INFURA_API_KEY=123abc456def789...
```

---

## 6) Jalankan di Ganache (Lokal)

1. Buka **Ganache** (default RPC `http://127.0.0.1:7545`).
2. Pastikan **`.env`** berisi `PRIVATE_KEY_GANACHE`.
3. Compile & Migrate:

```bash
cd brewify/contracts
npx truffle compile
npx truffle migrate --network development
```

---

## 7) Deploy ke Sepolia (Testnet)

```bash
npx truffle migrate --network sepolia
```

> Simpan **alamat kontrak** hasil deploy untuk dipakai di frontend (`build/contracts/CoffeeBatchNFT.json`).

---

## 8) Frontend (Next.js) + Wallet + QR

```bash
cd brewify/frontend
npm install
npm run dev
```

Frontend berjalan di `http://localhost:3000`.

### Dependencies Frontend

* **`wagmi`**: Hooks React untuk interaksi wallet & kontrak.
* **`viem`**: Client EVM modern.
* **`ethers`**: Library Ethereum populer.
* **`@rainbow-me/rainbowkit`**: UI koneksi wallet siap pakai.
* **`qrcode.react`**: Komponen React untuk render QR langsung di UI.

### Contoh Halaman Verifikasi QR

```tsx
'use client';
import { useParams } from 'next/navigation';
import { QRCode } from 'qrcode.react';

export default function VerifyPage() {
  const { tokenId } = useParams<{ tokenId: string }>();
  const verifyUrl = typeof window !== 'undefined'
    ? `${window.location.origin}/verify/${tokenId}`
    : `https://example.com/verify/${tokenId}`;

  return (
    <div className="p-6 space-y-4">
      <h1 className="text-2xl font-bold">Batch #{String(tokenId)}</h1>
      <p>Scan QR untuk melihat detail on-chain batch kopi.</p>
      <QRCode value={verifyUrl} size={192} includeMargin />
    </div>
  );
}
```

---

## 9) IPFS Metadata (contoh)

```json
{
  "name": "Brewify Batch #1",
  "description": "Origin, farmer, roast, harvest date...",
  "image": "ipfs://<CID_IMAGE>",
  "attributes": [
    {"trait_type": "Origin", "value": "Lombok"},
    {"trait_type": "Process", "value": "Washed"}
  ]
}
```

Upload ke Pinata/Filebase → gunakan URI `ipfs://CID` saat mint.

---

## 10) FAQ & Troubleshooting

* **Error provider**: periksa `INFURA_API_KEY` dan koneksi internet.
* **Insufficient funds**: pastikan akun Sepolia memiliki ETH faucet.
* **Nonce mismatch / Ganache error**: restart Ganache dan ulangi migrasi.
* **ABI mismatch**: re-compile & re-migrate; pastikan frontend memakai ABI terbaru.

---

## 11) Keamanan & Git

```gitignore
node_modules/
contracts/build/
frontend/.next/
.env
.env.*
```

Jangan unggah private key/API key ke repo publik. Gunakan **ENV**.

---

## 12) Ringkas Perintah

```bash
# Kontrak (lokal)
cd contracts
npx truffle compile
npx truffle migrate --network development

# Deploy ke Sepolia
npx truffle migrate --network sepolia

# Frontend
cd ../frontend
npm run dev
```

---

## 13) Catatan Simulasi / Tugas Kampus

Proyek ini dapat dijalankan **sepenuhnya lokal** menggunakan Ganache tanpa biaya gas. Untuk uji publik, gunakan **Sepolia** melalui **Infura**.