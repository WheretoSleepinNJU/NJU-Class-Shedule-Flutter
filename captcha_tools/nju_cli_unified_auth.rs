use std::collections::HashMap;

use aes::{
    Aes128,
    cipher::{BlockEncryptMut, KeyIvInit, block_padding::Pkcs7},
};
use anyhow::{Context, Result, anyhow};
use base64::{Engine as _, engine::general_purpose};
use reqwest::Client;
use scraper::{Html, Selector};

const LOGIN_URL: &str = "https://authserver.nju.edu.cn/authserver/login";
const CAPTCHA_URL: &str = "https://authserver.nju.edu.cn/authserver/getCaptcha.htl";

/// 登录南京大学统一认证，直接返回登录成功后的 CASTGC cookie。
///
/// 调用方应传入启用了 cookie store/provider 且禁用自动重定向的 `reqwest::Client`，因为
/// 登录页、验证码、登录提交需要复用同一组 cookie，且 CASTGC 位于登录响应的 Set-Cookie
/// 中。验证码会使用 ddddocr 内置模型识别。
pub async fn login(
    client: &Client,
    username: impl Into<String>,
    password: impl AsRef<str>,
) -> Result<String> {
    let login_page = client
        .get(LOGIN_URL)
        .send()
        .await
        .context("failed to request NJU auth login page")?
        .error_for_status()
        .context("NJU auth login page returned an error status")?
        .text()
        .await
        .context("failed to read NJU auth login page")?;
    let context = extract_context(&login_page)?;

    let captcha = client
        .get(CAPTCHA_URL)
        .send()
        .await
        .context("failed to request NJU auth captcha")?
        .error_for_status()
        .context("NJU auth captcha returned an error status")?
        .bytes()
        .await
        .context("failed to read NJU auth captcha")?;

    let captcha_answer = recognize_captcha(&captcha)?;

    submit_login(
        client,
        context,
        username.into(),
        password.as_ref(),
        captcha_answer,
    )
    .await
}

/// 检查 client 是否已持有有效的统一认证登陆态，未登录或登陆态过期时报错。
///
/// 已登录（cookie 带有效 CASTGC）时访问登录页不会再出现密码登录表单；
/// 未登录或登陆态过期时会返回带 `form#pwdFromId` 的登录页。
pub async fn ensure_logged_in(client: &Client) -> Result<()> {
    let login_page = client
        .get(LOGIN_URL)
        .send()
        .await
        .context("failed to request NJU auth login page")?
        .error_for_status()
        .context("NJU auth login page returned an error status")?
        .text()
        .await
        .context("failed to read NJU auth login page")?;

    if login_page.contains("pwdFromId") {
        return Err(anyhow!(
            "not logged in or the login has expired; run `nju-cli login --username USERNAME --password PASSWORD` first"
        ));
    }

    Ok(())
}

fn recognize_captcha(captcha: &[u8]) -> Result<String> {
    let classifier =
        ddddocr::ddddocr_classification().context("failed to initialize ddddocr classifier")?;

    classifier
        .classification(captcha)
        .map(|answer| answer.trim().to_string())
        .context("failed to recognize NJU auth captcha with ddddocr")
}

async fn submit_login(
    client: &Client,
    context: HashMap<String, String>,
    username: String,
    password: &str,
    captcha_answer: String,
) -> Result<String> {
    let salt = context
        .get("pwdEncryptSalt")
        .context("failed to find password encryption salt")?;

    let mut form = context.clone();
    form.insert("username".to_string(), username);
    form.insert("password".to_string(), encrypt_password(password, salt));
    form.insert("captchaResponse".to_string(), captcha_answer);
    form.insert("dllt".to_string(), "mobileLogin".to_string());

    let response = client
        .post(LOGIN_URL)
        .form(&form)
        .send()
        .await
        .context("failed to submit NJU auth login form")?;

    if let Some(cookie) = response.cookies().find(|cookie| cookie.name() == "CASTGC") {
        return Ok(cookie.value().to_string());
    }

    let html = response
        .text()
        .await
        .context("failed to read NJU auth login failure page")?;
    Err(anyhow!(extract_login_error(&html).unwrap_or_else(|| {
        "NJU auth login failed, but no error message was found".to_string()
    })))
}

/// 从统一认证登录页提取提交登录表单需要的隐藏字段。
pub fn extract_context(login_page: &str) -> Result<HashMap<String, String>> {
    let document = Html::parse_document(login_page);
    let selector = Selector::parse("form#pwdFromId input")
        .map_err(|err| anyhow!("failed to parse login input selector: {err}"))?;
    let mut context = HashMap::new();

    for input in document.select(&selector) {
        let value = input.value();
        if value.attr("type") != Some("hidden") {
            continue;
        }

        let Some(name) = value.attr("name").or_else(|| value.attr("id")) else {
            continue;
        };
        let Some(input_value) = value.attr("value") else {
            continue;
        };

        context.insert(name.to_string(), input_value.to_string());
    }

    Ok(context)
}

/// 加密统一认证密码字段。
pub fn encrypt_password(password: &str, salt: &str) -> String {
    type Aes128CbcEnc = cbc::Encryptor<Aes128>;

    let iv = "a".repeat(16).into_bytes();
    let cipher = Aes128CbcEnc::new(salt.as_bytes().into(), iv.as_slice().into());
    let ciphertext =
        cipher.encrypt_padded_vec_mut::<Pkcs7>(("a".repeat(64) + password).into_bytes().as_slice());

    general_purpose::STANDARD.encode(ciphertext)
}

fn extract_login_error(html: &str) -> Option<String> {
    let document = Html::parse_document(html);
    let selector = Selector::parse("#showErrorTip, form#casLoginForm span.auth_error").ok()?;

    document
        .select(&selector)
        .next()
        .map(|node| node.text().collect::<String>().trim().to_string())
        .filter(|message| !message.is_empty())
}
