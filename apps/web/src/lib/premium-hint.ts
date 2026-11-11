// A hint, kept on this device, that the last signed-in account here had Premium. A tiny script in
// the page <head> (PREMIUM_HINT_SCRIPT) copies it onto <html data-premium> before the first paint,
// so a reload shows the PREMIUM tag straight away instead of flashing the upgrade pill. It only
// chooses what shows while the real answer loads; the API still decides (usePremium).
export const PREMIUM_HINT_KEY = 'gleefy.premium-hint.v1';
export const PREMIUM_HINT_SCRIPT = `try{if(localStorage.getItem('${PREMIUM_HINT_KEY}')==='1')document.documentElement.dataset.premium='1'}catch(e){}`;
