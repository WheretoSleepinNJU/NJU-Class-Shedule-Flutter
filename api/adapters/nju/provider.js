async function scheduleHtmlProvider() {
  // Nanjing University undergraduate selection page:
  // usually reaches .../grablessons.do and contains JSON in body text.
  const text = (document.body && document.body.innerText
      ? document.body.innerText
      : '').trim();
  if (!text) {
    throw new Error('Empty page body. Please login and open course page first.');
  }
  return text;
}
