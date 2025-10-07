require('dotenv').config();
const { JsonRpcProvider, Contract } = require('ethers');

const RPC   = process.env.AMOY_RPC_URL;
const PROXY = '0xf471af2aFF654A07CD9f55B6cfa22dD019FbaFEf';
const ABI   = [
  'function paymentToken() view returns (address)',
  'function novaToken() view returns (address)'
];

(async () => {
  const provider = new JsonRpcProvider(RPC);
  const c = new Contract(PROXY, ABI, provider);

  try {
    console.log('paymentToken():', await c.paymentToken());
  } catch {
    console.log('paymentToken() failed -> old impl or bad ABI');
  }
  try {
    console.log('novaToken():', await c.novaToken());
  } catch {
    console.log('novaToken() failed -> alias missing (not critical).');
  }
})();
